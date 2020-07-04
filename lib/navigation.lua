local sides = require("sides")
local robot = require("robot")
local computer = require("computer")
local component = require("component")
local geolyzer = component.geolyzer

local vec3 = require("vec3")
local PriorityQueue = require("priorityqueue")
local VectorMap = require("vectormap")
local map = require("map")
local blacklistMap = require("blacklistmap")
local debug = require("debug")
local VectorChunk = require("vectorchunk")
local blockType = require("blocktype")
local utils = require("utils")
local autoyielder = require("autoyielder")

local navigation = {}

--[[ Calculate coordinates from offset vector and orientation. coordsVec 
is a base vector to which we "add" offsetVec, taking into account provided 
facingSide. offsetVec is a vector with three fields:
1. moving forward/backward - positive is forward, negative is backward
2. moving up/down - positive is up, negative is down
3. moving right/left - positive is right, negative is left --]]
function navigation.coordsFromOffset(coordsVec, offsetVec, facingSide)
	facingSide = facingSide or robot.orientation
	local y = coordsVec.y + offsetVec.y
	
	if facingSide == sides.posz then -- equivalent to sides.south
		return vec3(coordsVec.x - offsetVec.z, y, coordsVec.z + offsetVec.x)
	end
	if facingSide == sides.negz then -- equivalent to sides.north
		return vec3(coordsVec.x + offsetVec.z, y, coordsVec.z - offsetVec.x)
	end
	if facingSide == sides.posx then -- equivalent to sides.east
		return vec3(coordsVec.x + offsetVec.x, y, coordsVec.z + offsetVec.z)
	end
	if facingSide == sides.negx then -- equivalent to sides.west
		return vec3(coordsVec.x - offsetVec.x, y, coordsVec.z - offsetVec.z)
	end
end

--[[ calculates orientation robot has to be in to go from fromNode to toNode,
assuming the blocks (nodes) are adjacent to each other (in other words:
orientation that robot will have after moving from one block to another)
respectVertical decides whether to return identical orientation as fromOrientation
since it doesn't change the robot's orientation, or respect vertical changes and
return sides.negy or sides.posy when nodes are vertically adjacent --]]
function navigation.calcOrientation(fromNode, toNode, fromOrientation, respectVertical)
	fromOrientation = fromOrientation or robot.orientation
	respectVertical = respectVertical or false
	local dx = toNode.x - fromNode.x
	local dy = toNode.y - fromNode.y
	local dz = toNode.z - fromNode.z
	if dx == -1 then
		return sides.negx -- equivalent to sides.west
	elseif dx == 1 then
		return sides.posx -- equivalent to sides.east
	elseif dz == -1 then
		return sides.negz -- equivalent to sides.north
	elseif dz == 1 then
		return sides.posz -- equivalent to sides.south
	elseif dy ~= 0 then
		if not respectVertical then
			return fromOrientation -- if we're moving vertically orientation stays the same
		elseif dy == -1 then
			return sides.negy
		elseif dy == 1 then
			return sides.posy
		end
	else
		error("Supplied blocks are not adjacent: " .. tostring(fromNode) .. " and " .. tostring(toNode))
	end
end

function navigation.areBlocksAdjacent(first, second)
    local delta = first - second
    return (math.abs(delta.x) + math.abs(delta.y) + math.abs(delta.z)) == 1
end

function navigation.adjacentBlock(position, blockTable)
    position = position or robot.position
    for i = 1, #blockTable do
        if navigation.areBlocksAdjacent(position, blockTable[i]) then
            return blockTable[i]
        end
    end
end

function navigation.isOppositeDirection(orientationFirst, orientationSecond)
	--[[ sides api numbers are so that if you do integer division by 2 on them,
	it means that one direction is opposite to the other --]]
	return math.floor(orientationFirst / 2) == math.floor(orientationSecond / 2)
end

--[[ calculates the block's orientation relative to fromOrientation (robot.orientation
by default, which means - on which side of the robot it is), either specifying
the block coordinates or it's orientation (toNodeOrOrientation) as from
calcOrientation (used for smart turning) --]]
function navigation.relativeOrientation(fromNode, toNodeOrOrientation, fromOrientation)
	local toNode
	local toOrientation
	if utils.isInstance(toNodeOrOrientation, vec3) then
		toNode = toNodeOrOrientation
	else
		toOrientation = toNodeOrOrientation
	end
	fromOrientation = fromOrientation or robot.orientation
	--[[ if toOrientation is specified, toNode is nil so we don't call calcOrientation with invalid param
	if on the other hand toOrientation is nil, toNode is specified instead and we can calculate orientation from it --]]
	toOrientation = toOrientation or navigation.calcOrientation(fromNode, toNode, fromOrientation, true)
	if toOrientation == fromOrientation then
		return sides.front
	elseif toOrientation == sides.negy or toOrientation == sides.posy then
		return toOrientation
	elseif navigation.isOppositeDirection(toOrientation, fromOrientation) then
		return sides.back
	else
		local directionDelta = fromOrientation - toOrientation
		--[[ sides api numbers are so that if you subtract current from target orientation,
		you can make decision which way to turn based on result's sign and parity --]]
		if directionDelta > 0 then
			if (directionDelta % 2) == 0 then
				return sides.right
			else
				return sides.left
			end
		else
			if (directionDelta % 2) == 0 then
				return sides.left
			else
				return sides.right
			end
		end
	end
end

function navigation.calcCostForPath(path, costFunction, skipGoal, initialPosition, initialOrientation)
	costFunction = costFunction or navigation.costTime
	skipGoal = skipGoal or false
	initialPosition = initialPosition or robot.position
	initialOrientation = initialOrientation or robot.orientation

	local orientation = initialOrientation
	local totalCost = navigation.costTime(initialPosition, path[#path], initialOrientation)
	for i = #path, 2, -1 do
		totalCost = totalCost + navigation.costTime(path[i], path[i-1], orientation)
		orientation = navigation.calcOrientation(path[i], path[i-1], orientation)
	end
	if skipGoal then
		-- subtract turning cost
		totalCost = totalCost - navigation.costTime(path[2], path[1], orientation, true, false, true)
	end
	return totalCost
end

--[[ detect robot orientation using geolyzer as it always returns the scan() data in the same order
independently of the robot orientation --]]
function navigation.detectOrientation()
    local orientationMappings = {[2] = sides.north, [4] = sides.west, [6] = sides.east, [8] = sides.south}
    local firstScan = geolyzer.scan(-1, -1, 0, 3, 3, 1) -- scan 3x3x1 area with robot in the center

    for i = 1,4 do -- try a maximum of 4 turns to try 4 different sides
        if robot.swing() then
            local secondScan = geolyzer.scan(-1, -1, 0, 3, 3, 1) -- second scan after destroying a block
            for j = 2,8,2 do -- we're interested only in indexes 2, 4, 6 or 8 in scan() data as only those can change
                if firstScan[j] ~= secondScan[j] then -- if data has changed that means it's the block we dug earlier
                    return orientationMappings[j] -- return proper orientation based on the index that's changed
                end
            end
        else
            robot.turnRight() -- if we didn't dig anything try another side
        end
    end
    error("Couldn't detect orientation, make sure the robot has at least one block horizontally around it")
end

--[[ returns six neighbouring blocks (nodes) that a block (node) has, 
one for each side of the block, TODO: potential for optimization (loop
unrolling and Y bounds checking only for neighbours above and below) --]]
function navigation.neighbours(node)
	local neighbourNodes = {}
	local offsetVectors = {vec3(1, 0, 0), vec3(-1, 0, 0), vec3(0, 1, 0), vec3(0, -1, 0), vec3(0, 0, 1), vec3(0, 0, -1)}
	for i, offsetVector in ipairs(offsetVectors) do
		local neighbourNode = node + offsetVector
		-- don't bother returning neighbour for y = 0 since it's all bedrock
		if neighbourNode.y < 256 and neighbourNode.y > 0 and not blacklistMap[neighbourNode] then
			-- little optimization to not query map every time as it's costly (bedrock exists only on y <= 4)
			if neighbourNode.y < 5 then
				if map.assumeBlockType(map[neighbourNode]) ~= blockType.bedrock then
					table.insert(neighbourNodes, neighbourNode)
				end
			else
				table.insert(neighbourNodes, neighbourNode)
			end
		end
	end
	return neighbourNodes
end

-- returns manhattan distance between two blocks (nodes) with additional turning cost
function navigation.heuristicManhattan(fromNode, toNode)
	return math.abs(fromNode.x - toNode.x) + 
		   math.abs(fromNode.y - toNode.y) +
		   math.abs(fromNode.z - toNode.z) +
		   ((fromNode.x - toNode.x ~= 0 and fromNode.z - toNode.z ~= 0) and 1 or 0)
end

function navigation.heuristicEuclidean(fromNode, toNode)
	return math.sqrt((toNode.x - fromNode.x)^2 + (toNode.y - fromNode.y)^2 + (toNode.z - fromNode.z)^2)
end

function navigation.heuristicAStar(fromNode, toNode)
	local _, cost = navigation.aStar(toNode, fromNode)
	return cost
end

--[[ returns cost for moving between two adjacent blocks (nodes), taking into account
target block's hardness which requires mining it and possible turning cost --]]
function navigation.costTime(fromNode, toNode, fromOrientation, ignoreWalking, ignoreTurning, ignoreBreaking) -- time-based cost function
	ignoreWalking = ignoreWalking or false
	ignoreTurning = ignoreTurning or false
	ignoreBreaking = ignoreBreaking or false
	local totalCost = 0
	local afterOrientation = navigation.calcOrientation(fromNode, toNode, fromOrientation)

	-- base cost for moving
	if not ignoreWalking then
		totalCost = totalCost + 1
	end
	-- cost for turning
	if not ignoreTurning and fromOrientation ~= afterOrientation then
		if navigation.isOppositeDirection(fromOrientation, afterOrientation) then
			totalCost = totalCost + 2 -- turn around cost
		else
			totalCost = totalCost + 1 -- turning left or right cost
		end 
	end
	-- cost for breaking blocks, TODO: check hardness of different materials
	if not ignoreBreaking and map.assumeBlockType(map[toNode]) ~= blockType.air then
		totalCost = totalCost + 1.555
	end
	return totalCost
end

--[[ Performs A* algorithm on a global map variable to find the shortest path from start to goal blocks (nodes).
Returns path as a table of vec3 coordinates from goal to start block (without the starting block itself)
and cost to reach the goal block --]]
function navigation.aStar(goals, start, startOrientation, cost, heuristic, neighbours)
	--local startMem = utils.freeMemory()
	goals = utils.isInstance(goals, vec3) and {goals} or goals
    assert(#goals > 0, "No goals supplied to find paths to")
	start = start or robot.position
	startOrientation = startOrientation or robot.orientation
	cost = cost or navigation.costTime
	heuristicFunc = heuristic or navigation.heuristicManhattan
	heuristic = function(fromNode, goalsTable)
		local min = #goalsTable > 0 and math.huge or 0
		for _, goal in ipairs(goalsTable) do
			local cost = heuristicFunc(fromNode, goal)
			if cost < min then
				min = cost
			end
		end
		return min
	end
    neighbours = neighbours or navigation.neighbours

	local openQueue = PriorityQueue()
	local cameFrom = VectorChunk(true)
	local costSoFar = VectorChunk()
    local orientation = VectorChunk()
    local closestGoal

    --[[ Temporarily unblacklist blocks that are on the goals list, so that the neighbours function can actually
    return the goal block, otherwise the algorithm runs out of memory. If there are multiple goals, a path that goes
    through a blacklisted block that was unblacklisted here won't ever be returned, because that would mean there's
    a block that's nearer than the one we're going to, so a path to that nearer block will be returned instead. --]]
    local unblacklisted = {}
    for _, goal in ipairs(goals) do
        if blacklistMap[goal] then
            blacklistMap[goal] = false
            unblacklisted[#unblacklisted + 1] = goal
        end
    end
	
	openQueue:put(start, 0)
	costSoFar[start] = 0
	orientation[start] = startOrientation
    
	-- run until queue is empty - never happens as map is never empty
	while not openQueue:empty() do
		local currentNode = openQueue:pop()

		-- terminate algorithm if we reached the any of the goal blocks (node)
		if utils.hasValue(goals, currentNode) then
			closestGoal = currentNode
			break
		end
        
        -- for each neighbour in our currentNode neighbours
		for i, nextNode in pairs(neighbours(currentNode)) do
            local newCost = costSoFar[currentNode] + cost(currentNode, nextNode, orientation[currentNode])
			-- if we haven't visited the block (node) yet or it has smaller cost than previously
			if cameFrom[nextNode] == nil or 
               newCost < costSoFar[nextNode] then
                -- put it in the open blocks (nodes) set to expand later and update the tables with cost, path and orientation
				openQueue:put(nextNode, newCost + heuristic(nextNode, goals))
				costSoFar[nextNode] = newCost
				cameFrom[nextNode] = currentNode
				orientation[nextNode] = navigation.calcOrientation(currentNode, nextNode, orientation[currentNode]) -- TODO: reduce call here since it's being called twice (first time in cost()) if condition is true
			end
		end

		autoyielder.yield()
    end

    -- blacklist previously unblacklisted blocks
    for _, block in ipairs(unblacklisted) do
        blacklistMap[block] = true
    end
    
	-- reconstruct path
	local path = {}
	local currentNode = closestGoal
	while currentNode ~= start do
		--debug.drawCube(currentNode, debug.color.green, 1.0)
		table.insert(path, currentNode)
		currentNode = cameFrom[currentNode]
	end

	--local endMem = utils.freeMemory()
	--[[ print("Starting memory:", startMem)
	print("Ending memory: ", endMem)
	print("Memory used:", startMem - endMem) ]]

	return path, costSoFar[closestGoal]
end

-- performs traveling salesman problem algorithm using nearest neighbour algorithm
function navigation.tspGreedy(initialTour, startNode, endNode, heuristic)
	assert(initialTour and #initialTour > 0, "No nodes supplied to arrange in a tour")
	heuristic = heuristic or navigation.heuristicManhattan
	local optimizedTour = {}
	local tour = utils.deepCopy(initialTour)
	local totalCost = 0
	local dummyNode = vec3(math.huge, math.huge, math.huge)
	local loopTour = startNode == nil or endNode == nil

	local function heuristicCost(fromNode, toNode)
		if (fromNode == dummyNode or toNode == dummyNode) and
		   (fromNode == startNode or fromNode == endNode or toNode == startNode or toNode == endNode) then
			return 0
		else
			return heuristic(fromNode, toNode)
		end
	end

	if not loopTour then
		table.insert(tour, dummyNode)
		-- add startNode and endNode to the table if they don't exist
		if not utils.findIndex(tour, startNode) then
			table.insert(tour, startNode)
		end
		if not utils.findIndex(tour, endNode) then
			table.insert(tour, endNode)
		end
	end
	local currentNodeIndex = utils.findIndex(tour, startNode) -- start at starting node

	while #tour > 1 do
		local currentNode = table.remove(tour, currentNodeIndex)
		table.insert(optimizedTour, currentNode)

		-- search for nearest neighbour of current node
		local bestNodeIndex = 1
		local bestNodeDistance = heuristicCost(currentNode, tour[1])
		for i, node in ipairs(tour) do
			local nodeDistance = heuristicCost(currentNode, node)
			if nodeDistance < bestNodeDistance then
				bestNodeDistance = nodeDistance
				bestNodeIndex = i
			end
		end

		-- update loop variables to process next node and add to total cost
		currentNodeIndex = bestNodeIndex
		totalCost = totalCost + bestNodeDistance
	end

	table.insert(optimizedTour, table.remove(tour, 1))
	
	if loopTour then
		totalCost = totalCost + heuristicCost(optimizedTour[1], optimizedTour[#optimizedTour])
	else
		local dummyIndex = utils.findIndex(optimizedTour, dummyNode)
		print(dummyIndex)
		local finalTour = {}
		for i = dummyIndex - 1, 1, -1 do
			table.insert(finalTour, optimizedTour[i])
		end
		for i = #optimizedTour, dummyIndex + 1, -1 do
			table.insert(finalTour, optimizedTour[i])
		end
		optimizedTour = finalTour
	end
	return optimizedTour, totalCost
end

function navigation.tspTwoOpt(tour, startNode, endNode, heuristic)
	assert(tour and #tour > 0, "No nodes supplied to arrange in a tour")
	heuristic = heuristic or navigation.heuristicManhattan
	local loopTour = startNode == nil or endNode == nil
	local optimizedTour = utils.deepCopy(tour)

	local twoOptExchange = function(tour, _i, _k)
		local newTour = {}
		for i = 0, _i - 1 do
			table.insert(newTour, tour[i])
		end
		for i = _k, _i, -1 do
			table.insert(newTour, tour[i])
		end
		for i = _k + 1, #tour do
			table.insert(newTour, tour[i])
		end
		return newTour
	end
	local heuristicCost = function(tour)
		local totalCost = 0
		for i = 1, #tour - 1 do
			totalCost = totalCost + heuristic(tour[i], tour[i+1])
		end

		if loopTour then
			totalCost = totalCost + heuristic(tour[1], tour[#tour])
		end
		return totalCost
	end

	--[[ put start node and end node at the start and end of the table respectively if
	we aren't making a looped tour --]]
	if not loopTour then
		-- if start and end nodes already exist in the tour, remove them
		local startNodeIndex = utils.findIndex(optimizedTour, startNode)
		if startNodeIndex then
			table.remove(optimizedTour, startNodeIndex)
		end
		local endNodeIndex = utils.findIndex(optimizedTour, endNode)
		if endNodeIndex then
			table.remove(optimizedTour, endNodeIndex)
		end
		table.insert(optimizedTour, 1, startNode)
		table.insert(optimizedTour, endNode)
	end
	
	local bestDistance = heuristicCost(optimizedTour)
	--[[ process the table, skipping first and last node if we're not looping the tour
	to keep them as first and last --]]
	::startAgain::
	for i = 2, #optimizedTour - (loopTour and 1 or 2) do
		for k = i, #optimizedTour - (loopTour and 0 or 1) do
			local newTour = twoOptExchange(optimizedTour, i, k)
			local newDistance = heuristicCost(newTour)
			if newDistance < bestDistance then
				bestDistance = newDistance
				optimizedTour = newTour
				goto startAgain
			end
		end
	end

	return optimizedTour, bestDistance
end

function navigation.shortestTour(nodes, startNode, endNode)
	return navigation.tspTwoOpt(navigation.tspGreedy(nodes), startNode, endNode)
end

-- finds nearest block to fromNode in a VectorMap or table of vectors
function navigation.nearestBlock(nodes, fromNode, heuristic)
	fromNode = fromNode or robot.position
	heuristic = heuristic or navigation.heuristicManhattan
    local minDist = math.huge
	local minVector

	for _, vector in ipairs(nodes) do
		local heuristicDistance = heuristic(fromNode, vector)
		if heuristicDistance < minDist then
			minDist = heuristicDistance
			minVector = vector
		end
	end
	return minVector, minDist
end

--[[ performs robot turning with minimal number of turns, either by specifying direction
or node to turn towards, returns robot's orientation after turning --]]
function navigation.faceBlock(nodeOrDirection)
    -- check if we're not already facing the desired direction 
	if robot.orientation ~= nodeOrDirection then
		--[[ returns block's relative orientation based either on the node to which we should turn towards or the
		direction the node is facing as returned from calcOrientation --]]
		local relativeOrientation = navigation.relativeOrientation(robot.position, nodeOrDirection, robot.orientation)
		if relativeOrientation == sides.left then
			robot.turnLeft()
		elseif relativeOrientation == sides.right then
			robot.turnRight()
		elseif relativeOrientation == sides.back then
			robot.turnAround()
		end
	end
	return robot.orientation
end

--[[ performs robot navigation through a path which should be a table of adjacent
blocks as vec3 elements, e.g. a path returned by navigate.aStar.
Parameter skipGoal defines if the robot should go into the goal block or stop
navigation after reaching second-to-last block and turning towards it --]]
function navigation.navigatePath(path, skipGoal)
	-- default skipGoal to false
	skipGoal = skipGoal or false

	for i = #path, (skipGoal and 2 or 1), -1 do
        -- calculate which way we should be facing and perform turning 
		local targetOrientation = navigation.faceBlock(path[i])
        
        -- perform moving depending on vertical difference of two adjacent blocks
		local delta = robot.position - path[i]
		local nodeHasBlock = map.assumeBlockType(map[path[i]]) ~= blockType.air

		--[[ safe movement with fallbacks if scan info is not accurate or sand/gravel
		falls in front of the robot, currently doesn't support entities --]]
		if delta.y == 0 then
			if nodeHasBlock then
				robot.swing()
				computer.pullSignal(0.1)
			end
			while not robot.forward() do
				robot.swing()
				computer.pullSignal(0.1)
			end
		elseif delta.y == -1 then
			if nodeHasBlock then
				robot.swingUp()
				computer.pullSignal(0.1)
			end
			while not robot.up() do
				robot.swingUp()
				computer.pullSignal(0.1)
			end
		else
			if nodeHasBlock then
				robot.swingDown()
				computer.pullSignal(0.1)
			end
			while not robot.down() do
				robot.swingDown()
				computer.pullSignal(0.1)
			end
		end

        -- update the globals
		map[path[i]] = blockType.air
		
		-- yield to the OS
		computer.pullSignal(0.1)
	end
	if #path > 0 and skipGoal then
		navigation.faceBlock(path[1])
	end
end

function navigation.goTo(goals, skipGoal, start, startOrientation, cost, heuristic)
	local path, cost = navigation.aStar(goals, start, startOrientation, cost, heuristic)
	navigation.navigatePath(path, skipGoal)
	-- return goal (if user supplied multiple goals he might not know which was the closest) and cost taken to reach there
	return path[1], cost
end

return navigation