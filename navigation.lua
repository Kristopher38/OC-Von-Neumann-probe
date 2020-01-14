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
one for  each side of the block --]]
function navigation.neighbours(node)
	local neighbourNodes = {}
	table.insert(neighbourNodes, vec3(node.x + 1, node.y, node.z))
	table.insert(neighbourNodes, vec3(node.x - 1, node.y, node.z))
	if node.y < 255 then
		table.insert(neighbourNodes, vec3(node.x, node.y + 1, node.z))
	end
	-- don't bother returning neighbour for y = 0 since it's all bedrock
	if node.y > 1 then
		table.insert(neighbourNodes, vec3(node.x, node.y - 1, node.z))
	end
	table.insert(neighbourNodes, vec3(node.x, node.y, node.z + 1))
	table.insert(neighbourNodes, vec3(node.x, node.y, node.z - 1))
	return neighbourNodes
end

-- returns manhattan distance between two blocks (nodes)
function navigation.heuristicManhattan(fromNode, toNode)
	return math.abs(fromNode.x - toNode.x) + 
		   math.abs(fromNode.y - toNode.y) +
		   math.abs(fromNode.z - toNode.z)
end

--[[ returns cost for moving between two adjacent blocks (nodes), taking into account
target block's hardness which requires mining it and possible turning cost --]]
function navigation.cost(fromNode, toNode, fromOrientation) -- time-based cost function
	local totalCost = 0
	local afterOrientation = navigation.calcOrientation(fromNode, toNode, fromOrientation)

	-- cost for turning
	if fromOrientation ~= afterOrientation then
		--[[ orientation numbers are so that if we divide them by 2 and they're the same, 
		they're opposite direction, so we need to turn around --]]
		if math.floor(fromOrientation / 2) == math.floor(afterOrientation / 2) then
			totalCost = totalCost + 2 -- turn around cost
		else
			totalCost = totalCost + 1 -- turning left or right cost
		end 
	end
	if map.assumeBlockType(map[toNode]) == blockType.air then -- TODO: check hardness of different materials
		totalCost = totalCost + 1 -- moving takes 0.45s
	else
		totalCost = totalCost + 2.555 -- mining takes 0.7s + 0.45s for moving = 1.15s = 2.(5) cost
	end
	return totalCost
end

--[[ Performs A* algorithm on a global map variable to find the shortest path from start to goal blocks (nodes).
Returns path as a table of vec3 coordinates from goal to start block (without the starting block itself)
and cost to reach the goal block --]]
function navigation.aStar(start, startOrientation, goal, heuristic)
    heuristic = heuristic or navigation.heuristicManhattan
	local openQueue = PriorityQueue()
	local cameFrom = VectorChunk()
	local costSoFar = VectorChunk()
	local orientation = VectorChunk()
	
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
            local newCost = costSoFar[currentNode] + navigation.cost(currentNode, nextNode, orientation[currentNode])
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
	return path, costSoFar[goal]
end

-- performs robot turning with minimal number of turns
function navigation.smartTurn(direction)
    -- check if we're not already facing the desired direction 
    if robot.orientation ~= direction then
       --[[ sides api numbers are so that if you do integer division by 2 on them,
        it means that one direction is opposite to the other --]]
		if math.floor(robot.orientation / 2) == math.floor(direction / 2)  then
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
	robot.orientation = targetOrientation
    return targetOrientation
end

--[[ performs robot navigation through a path which should be a table of adjacent
blocks as vec3 elements, e.g. a path returned by navigate.aStar.
Parameter includeGoal defines if the robot should go into the goal block or stop
navigation after reaching second-to-last block and turning towards it --]]
function navigation.navigatePath(path, includeGoal)
	-- default includeGoal to true
	if includeGoal == nil then
		includeGoal = true
	end

	for i = #path, (includeGoal and 1 or 2), -1 do
        -- calculate which way we should be facing and perform turning 
		local targetOrientation = navigation.faceBlock(path[i])
        
        -- perform moving depending on vertical difference of two adjacent blocks
        local deltaY = robot.position.y - path[i].y
		if deltaY == 0 then
			robot.swing()
			robot.forward()
		elseif deltaY == -1 then
			robot.swingUp()
			robot.up()
		else
			robot.swingDown()
			robot.down()
		end

        -- update the globals
		robot.orientation = targetOrientation
        robot.position = path[i]
        map[path[i]] = blockType.air
	end
	if not includeGoal then
		navigation.faceBlock(path[1])
	end
end

return navigation