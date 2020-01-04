local component = require("component")
local sides = require("sides")
local robot = require("robot")
local geolyzer = component.geolyzer
local glasses = component.glasses

local utils = require("utils")
local map = require("map")
local nav = require("navigation")
local vec3 = require("vec3")

glasses.startLinking("Kristopher38")
glasses.setRenderPosition("absolute")
local lookingAt = glasses.getUserLookingAt("Kristopher38")
robot.position = vec3(lookingAt.x, lookingAt.y, lookingAt.z)
robot.orientation = sides.west -- nav.detectOrientation()
glasses.removeAll()
print("Mapping...")
map.scanMap(9, 9, 9)
print("Mapped count", map.count)
print("Finished mapping sorrounding area")

--[[ blocks (vectors) to be inspected, either by comparing to currently 
mined ore or analyzed by the geolyzer for higher operation speed --]]
local toMineVectors = {} -- blocks to be mined

local function pickNextTargetPath()
	local bestPath
	local bestCost = math.huge
	local bestPos
	for i, target in ipairs(toMineVectors) do
		local path, cost = nav.aStar(robot.position, robot.orientation, target)
		if cost < bestCost then
			bestCost = cost
			bestPath = path
			bestPos = i
		end
	end
	if bestPath ~= nil then
		table.remove(toMineVectors, bestPos)
		return bestPath
	else
		error("Couldn't find best target")
	end
end

local function mineOreLump()
	table.insert(toMineVectors, nav.coordsFromOffset(robot.position, vec3(1, 0, 0), robot.orientation))

	while #toMineVectors > 0 do
		local nextTargetPath = pickNextTargetPath()
		local target = table.remove(nextTargetPath, 1)
		nav.navigatePath(nextTargetPath)
		nav.faceBlock(target)
		local deltaY = robot.position.y - target.y
		if deltaY == 0 then
			robot.swing()
		elseif deltaY == -1 then
			robot.swingUp()
		else
			robot.swingDown()
		end
		map[target] = "minecraft:air"

		for i, vector in ipairs(nav.neighbours(target)) do
			if map[vector] == "minecraft:ore" then
				if not utils.hasDuplicateValue(toMineVectors, vector) then
					table.insert(toMineVectors, vector)
				end
			end
		end
	end
end

mineOreLump()