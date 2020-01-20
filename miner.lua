local component = require("component")
local sides = require("sides")
local robot = require("robot")
local geolyzer = component.geolyzer
local glasses = component.glasses

local utils = require("utils")
local map = require("map")
local nav = require("navigation")
local vec3 = require("vec3")
local ScanBatch = require("scanbatch")
local blockType = require("blocktype")
local debug = require("debug")
local inspect = require("inspect")

glasses.startLinking("Kristopher38")
glasses.setRenderPosition("absolute")
glasses.removeAll()

--[[ blocks (vectors) to be inspected, either by comparing to currently 
mined ore or analyzed by the geolyzer for higher operation speed --]]
local toMineVectors = {} -- blocks to be mined

local function pickNextTargetPath()
	local bestPath
	local bestCost = math.huge
	local bestPos
	for i, target in ipairs(toMineVectors) do
		local path, cost = nav.aStar(target)
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

local function scanOre(oreSide)
	print("scanning ore lump")
	local batch = ScanBatch()
	local quads = { ["minecraft:coal_ore"] = {
			{vec3(5, -3, -5), vec3(1, 7, 6)},
			{vec3(-5, 3, -5), vec3(10, 1, 6)},
			{vec3(-5, 2, -5), vec3(10, 1, 6)},
			{vec3(-5, 1, -5), vec3(10, 1, 6)},
			{vec3(-5, 0, -5), vec3(10, 1, 6)},
			{vec3(-5, -1, -5), vec3(10, 1, 6)},
			{vec3(-5, -2, -5), vec3(10, 1, 6)},
			{vec3(-5, -3, -5), vec3(10, 1, 6)},
			{vec3(-5, 3, 1), vec3(11, 1, 5)},
			{vec3(-5, 2, 1), vec3(11, 1, 5)},
			{vec3(-5, 1, 1), vec3(11, 1, 5)},
			{vec3(-5, 0, 1), vec3(11, 1, 5)},
			{vec3(-5, -1, 1), vec3(11, 1, 5)},
			{vec3(-5, -2, 1), vec3(11, 1, 5)},
			{vec3(-5, -3, 1), vec3(11, 1, 5)}
		}
	}

	local blockData = geolyzer.analyze(oreSide)
	--for i, quad in ipairs(quads[blockData.name]) do
	for i, quad in ipairs(quads["minecraft:coal_ore"]) do
		batch:scanQuad(table.unpack(quad))
	end
	return batch
end

local function mineOreLump(firstOreVector)
	print("mining ore lump")
	table.insert(toMineVectors, firstOreVector)

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
		map[target] = blockType.air

		for i, vector in ipairs(nav.neighbours(target)) do
			if map.assumeBlockType(map[vector]) == blockType.ore then
				if not utils.hasDuplicateValue(toMineVectors, vector) then
					table.insert(toMineVectors, vector)
				end
			end
		end
	end
end

local function scanLayer()
	print("scanning layer y="..tostring(robot.position.y))
	local batch = ScanBatch()
	local quads = {
		{vec3(0, 0, -8), vec3(8, 1, 8)},
		{vec3(0, 0, 0), vec3(8, 1, 8)},
		{vec3(-8, 0, -8), vec3(8, 1, 8)},
		{vec3(-8, 0, 0), vec3(8, 1, 8)}
	}
	for i, quad in ipairs(quads) do
		batch:scanQuad(table.unpack(quad))
	end
	return batch
end


local bedrockReached = false

while not bedrockReached do
	local batch = scanLayer()
	local ores = batch:query(blockType.ore)
	local robotColumnPos = utils.deepCopy(robot.position)
	while #ores > 0 do
		print("finding neares ore...")
		local min = math.huge
		local minOre
		for i, ore in ipairs(ores) do
			local heuristicDistance = nav.heuristicManhattan(robot.position, ore)
			if heuristicDistance < min then
				min = heuristicDistance
				minOre = ore
			end
		end
		print("nearest ore found, navigating")
		local path = nav.aStar(minOre)
		nav.navigatePath(path, true)
		print("navigation finished")
		local oreSide
		local deltaY = robot.position.y - path[1].y
		print("deltaY = "..tostring(deltaY))
		if deltaY == 0 then
			oreSide = sides.front
		elseif deltaY == -1 then
			oreSide = sides.up
		else
			oreSide = sides.down
		end
		local oreLumpBatch = scanOre(oreSide)
		mineOreLump(minOre)
		ores = batch:query(blockType.ore)
	end
	print("going back to the digging column")
	local path = nav.aStar(robotColumnPos)
	nav.navigatePath(path)
	robot.swingDown()
	if not robot.down() then
		bedrockReached = true
	end
end
