local component = require("component")
local sides = require("sides")
local geolyzer = component.geolyzer
local utils = require("utils")
local map = require("map")

--[[ blocks (vectors) to be inspected, either by comparing to currently 
mined ore or analyzed by the geolyzer for higher operation speed --]]
local toCheckVectors = {}
local toMineVectors = {} -- blocks (vectors) to be mined
local robotFacing = sides.front -- robot's absolute map orientation (assume front = east)
local robotPosition = vec3(0, 70, 0) -- robot's absolute map position 

-- modifies global state
local function addOffsetToCheck(offsetVec)
	if not hasDuplicateValue(toCheckVectors, vector) then
		table.insert(toCheckVectors, coordsFromOffset(robotPosition, offsetVec, robotFacing))
	end
end

-- modifies global state
local function addOffsetToMine(offsetVec)
	if not hasDuplicateValue(toMineVectors, vector) then
		table.insert(toMineVectors, coordsFromOffset(robotPosition, offsetVec, robotFacing))
	end
end

local function pickNextTarget(toCheck, toMine)
	return nil
end

-- modifies global state
local function mineOreLump(oreName)
	local lumpDepleted = false
	
	while not lumpDelpeted do
		robot.swing()
		addOffsetToCheck(vec3(2, 0, 0)) -- block two blocks in front
		addOffsetToCheck(vec3(1, 1, 0)) -- block front-up
		addOffsetToCheck(vec3(1, -1, 0)) -- block front-down
		if robot.compareUp() then
			addOffsetToMine(vec3(0, 1, 0)) -- block above
			-- robot.swingUp()
			-- addOffsetToCheck({0, 2, 0}) -- block above
			-- addOffsetToCheck({-1, 1, 0}) -- block above-behind
			-- no need to add block above-front because it was added as block front-up before
		end
		if robot.compareDown() then
			addOffsetToMine(vec3(0, -1, 0)) -- block below
			-- robot.swingDown()
			-- addOffsetToCheck({0, -2, 0}) -- block below
			-- addOffsetToCheck({-1, -1, 0}) -- block below-behind
			-- no need to add block below-front because it was added as block front-down before
		end
		if geolyzer.analyze(sides.left)["name"] == oreName then
			addOffsetToMine(vec3(0, 0, -1)) -- block to the left
		end
		if geolyzer.analyze(sides.right)["name"] == oreName then
			addOffsetToMine(vec3(0, 0, 1)) -- block to the right
		end
		
		local nextTarget = pickNextTarget(toCheckVectors, toMineVectors)
		-- 
	end
end

map[robotPosition] = "minecraft:air"
mineOreLump("minecraft:iron_ore")

--[[ Coord system
# MC logic
Coords... North: z--, East: x++, South: z++, West: x--, Up: y++, Down: y--
Coords... X points East, Z points South, Y points Up
Facing... 0: South, 1: West, 2: North, 3: East
Facing... Starts at South, goes clockwise --]]