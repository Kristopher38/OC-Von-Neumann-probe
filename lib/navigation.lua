local sides = require("sides")
local robot = require("robot")
local component = require("component")
local geolyzer = component.geolyzer

local vec3 = require("vec3")
local PriorityQueue = require("priorityqueue")
local VectorMap = require("vectormap")
local map = require("map")
local debug = require("debug")
local VectorChunk = require("vectorchunk")
local blockType = require("blocktype")
local utils = require("utils")

local navigation = {}

--[[ Calculate coordinates from offset vector and orientation. coordsVec 
is a base vector to which we "add" offsetVec, taking into account provided 
facingSide. offsetVec is a vector with three fields:
1. moving forward/backward - positive is forward, negative is backward
2. moving up/down - positive is up, negative is down
3. moving right/left - positive is right, negative is left --]]
function navigation.coordsFromOffset(coordsVec, offsetVec, facingSide)
	facingSide = facingSide or sides.posx
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
orientation that robot will have after moving from one block to another) --]]
function navigation.calcOrientation(fromNode, toNode, fromOrientation)
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
		return fromOrientation -- if we're moving vertically orientation stays the same
	else
		error("Supplied blocks are not adjacent: " .. tostring(fromNode) .. " and " .. tostring(toNode))
	end
end

function navigation.isOppositeDirection(orientationFirst, orientationSecond)
	--[[ sides api numbers are so that if you do integer division by 2 on them,
	it means that one direction is opposite to the other --]]
	return math.floor(orientationFirst / 2) == math.floor(orientationSecond / 2)
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
		if neighbourNode.y < 256 and neighbourNode.y > 0 then
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

-- returns manhattan distance between two blocks (nodes)
function navigation.heuristicManhattan(fromNode, toNode)
	return math.abs(fromNode.x - toNode.x) + 
		   math.abs(fromNode.y - toNode.y) +
		   math.abs(fromNode.z - toNode.z) +
		   ((fromNode.x - toNode.x ~= 0 and fromNode.z - toNode.z ~= 0) and 1 or 0)
end

function navigation.heuristicEuclidean(fromNode, toNode)
	return math.sqrt((fromNode.x - fromNode.x)^2 + (fromNode.y - fromNode.y)^2 + (fromNode.z - fromNode.z)^2)
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
function navigation.aStar(goal, start, startOrientation, cost, heuristic)
	local startMem = utils.freeMemory()
	start = start or robot.position
	startOrientation = startOrientation or robot.orientation
	cost = cost or navigation.costTime
	heuristic = heuristic or navigation.heuristicManhattan
	local openQueue = PriorityQueue()
	local cameFrom = VectorChunk(robot.position, true, true)
	local costSoFar = VectorChunk(robot.position, true)
	local orientation = VectorChunk(robot.position, true)
	
	openQueue:put(start, 0)
	costSoFar[start] = 0
	orientation[start] = startOrientation
    
    -- run until queue is empty - never happens as map is never empty
	while not openQueue:empty() do
		local currentNode = openQueue:pop()

        -- terminate algorithm if we reached the goal block (node)
		if currentNode == goal then
			break
		end
        
        -- for each neighbour in our currentNode neighbours
		for i, nextNode in pairs(navigation.neighbours(currentNode)) do
            local newCost = costSoFar[currentNode] + cost(currentNode, nextNode, orientation[currentNode])
			-- if we haven't visited the block (node) yet or it has smaller cost than previously
			if cameFrom[nextNode] == nil or 
               newCost < costSoFar[nextNode] then
                -- put it in the open blocks (nodes) set to expand later and update the tables with cost, path and orientation
				openQueue:put(nextNode, newCost + heuristic(nextNode, goal))
				costSoFar[nextNode] = newCost
				cameFrom[nextNode] = currentNode
				orientation[nextNode] = navigation.calcOrientation(currentNode, nextNode, orientation[currentNode]) -- TODO: reduce call here since it's being called twice (first time in cost()) if condition is true
			end
		end
    end
    
	-- reconstruct path
	local path = {}
	local currentNode = goal
    while currentNode ~= start do
		table.insert(path, currentNode)
		currentNode = cameFrom[currentNode]
	end

	local endMem = utils.freeMemory()
	print("Starting memory:", startMem)
	print("Ending memory: ", endMem)
	print("Memory used:", startMem - endMem)

	return path, costSoFar[goal]
end

-- performs traveling salesman problem algorithm using nearest neighbour algorithm
function navigation.tspGreedy(nodes)
	local path = {}
	local totalCost = 0
	local currentNodeIndex = 1

	while #nodes > 1 do
		local currentNode = table.remove(nodes, currentNodeIndex)
		table.insert(path, currentNode)

		-- search for nearest neighbour of current node
		local bestNodeIndex = 1
		local bestNodeDistance = navigation.heuristicManhattan(currentNode, nodes[1])
		for i, node in ipairs(nodes) do
			local nodeDistance = navigation.heuristicManhattan(currentNode, node)
			if nodeDistance < bestNodeDistance then
				bestNodeDistance = nodeDistance
				bestNodeIndex = i
			end
		end

		-- update loop variables to process next node and add to total cost
		currentNodeIndex = bestNodeIndex
		totalCost = totalCost + bestNodeDistance
	end

	table.insert(path, table.remove(nodes, 1))
	totalCost = totalCost + navigation.heuristicManhattan(path[1], path[#path])
	return path, totalCost
end

function navigation.tspTwoOpt(tour)
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
			totalCost = totalCost + navigation.heuristicManhattan(tour[i], tour[i+1])
		end
		totalCost = totalCost + navigation.heuristicManhattan(tour[1], tour[#tour])
		return totalCost
	end

	local optimizedTour = utils.deepCopy(tour)
	local bestDistance = heuristicCost(optimizedTour)
	::startAgain::
	for i = 2, #optimizedTour - 1 do
		for k = i, #optimizedTour do
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

-- performs robot turning with minimal number of turns
function navigation.smartTurn(direction)
    -- check if we're not already facing the desired direction 
    if robot.orientation ~= direction then
		if navigation.isOppositeDirection(robot.orientation, direction) then
			robot.turnAround()
		else
            local directionDelta = robot.orientation - direction
            --[[ sides api numbers are so that if you subtract current from target orientation,
            you can make decision which way to turn based on result's sign and parity --]]
			if directionDelta > 0 then
				if (directionDelta % 2) == 0 then
					robot.turnRight()
				else
					robot.turnLeft()
				end
			else
				if (directionDelta % 2) == 0 then
					robot.turnLeft()
				else
					robot.turnRight()
				end
			end
		end
	end
end

-- turns the robot to face adjacent block (node) with minimal number of turns and returns it's orientation after turning
function navigation.faceBlock(node)
    local targetOrientation = navigation.calcOrientation(robot.position, node, robot.orientation)
	navigation.smartTurn(targetOrientation)
    return targetOrientation
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
			end
			while not robot.forward() do
				robot.swing()
			end
		elseif delta.y == -1 then
			if nodeHasBlock then
				robot.swingUp()
			end
			while not robot.up() do
				robot.swingUp()
			end
		else
			if nodeHasBlock then
				robot.swingDown()
			end
			while not robot.down() do
				robot.swingDown()
			end
		end

        -- update the globals
        map[path[i]] = blockType.air
	end
	if #path > 0 and skipGoal then
		navigation.faceBlock(path[1])
	end
end

function navigation.goTo(goal, skipGoal, start, startOrientation, cost, heuristic)
	skipGoal = skipGoal or false
	local path, cost = navigation.aStar(goal, start, startOrientation, cost, heuristic)
	navigation.navigatePath(path, skipGoal)
end

return navigation