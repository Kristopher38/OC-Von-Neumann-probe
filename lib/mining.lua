local nav = require("navigation")
local ScanBatch = require("scanbatch")
local utils = require("utils")
local VectorMap = require("vectormap")
local robot = require("robot")
local vec3 = require("vec3")
local blockType = require("blocktype")
local map = require("map")

local component = require("component")
local sides = require("sides")
local geolyzer = component.geolyzer

local debug = require("debug")
local inspect = require("inspect")

local mining = {}

-- finds the average of coordinates of all ores in an ore lump ("center" of an ore lump)
function mining.getOreLumpCenter(oreLump)
    local sum = vec3(0, 0, 0)
    local count = 0
    for vector, block in pairs(oreLump) do
        sum = sum + vector
        count = count + 1
    end
    return vec3(sum.x // count, sum.y // count, sum.z // count)
end

function mining.oreLumpsFromOres(oreVectors)
    local function oreLumpFloodFill(vector)
        local lump = VectorMap()

        local function floodFill(vector)
            if oreVectors[vector] then
                lump[vector] = oreVectors[vector]
                oreVectors[vector] = nil
                for i, neighbour in ipairs(nav.neighbours(vector)) do
                    if oreVectors[neighbour] then
                        floodFill(neighbour)
                    end
                end
            end
        end

        floodFill(vector)
        return lump
    end
    
    local lumps = VectorMap()
    local vector, block = pairs(oreVectors)(oreVectors, nil)
    while vector do
        local oreLump = oreLumpFloodFill(vector)
        lumps[mining.getOreLumpCenter(oreLump)] = oreLump
        -- reassign pairs after each iteration since oreVectors changes during iteration
        vector, block = pairs(oreVectors)(oreVectors, nil)
    end
    return lumps
end

function mining.getNearestOre(oreLump)
    local min = math.huge
    local minOre
    for vector, block in pairs(oreLump) do
        local heuristicDistance = nav.heuristicManhattan(robot.position, vector)
        if heuristicDistance < min then
            min = heuristicDistance
            minOre = vector
        end
    end
    return minOre, min
end

function mining.scanOre(oreSide)
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

function mining.mineOreLump(oreSide)
    print("Scanning ore lump...")
    local oresScanBatch = mining.scanOre(oreSide)
    local ores = oresScanBatch:query(blockType.ore)
    while #ores > 0 do
        local nearestOre = mining.getNearestOre(ores)
        nav.goTo(nearestOre, true)
        robot.swing(nav.relativeOrientation(robot.position, ore))
        ores[nearestOre] = nil
    end
    --[[ print("Calculating fastest ore tour...")
    local oreTour = nav.tspTwoOpt(nav.tspGreedy(utils.keys(ores)))
    print("Mining ore lump...")
    print(inspect(oreTour))
    for i, ore in pairs(oreTour) do
        if map.assumeBlockType(map[ore]) == blockType.ore then
            print("Going to next ore on route: " .. tostring(ore))
            nav.goTo(ore, true)
            print("Mining ore block...")
            robot.swing(nav.relativeOrientation(robot.position, ore))
        end
    end ]]
    print("Finished mining ore lump.")
end

function mining.mineChunk()
    local bedrockReached = false
    local scanBatch = ScanBatch()
    local startPos = utils.deepCopy(robot.position)

    while not bedrockReached do
        scanBatch:scanLayer()
        print(utils.freeMemory())
        robot.swingDown()
        if not robot.down() then
            bedrockReached = true
        end
    end

    print("Calculating ore lumps...")
    local oreLumps = mining.oreLumpsFromOres(scanBatch:query(blockType.ore))
    print("Calculating fastest tour...")
    local oreLumpsTour = nav.tspTwoOpt(nav.tspGreedy(utils.keys(oreLumps)))
    print("Mining lumps...")
    for i, oreLump in pairs(oreLumpsTour) do
        local nearestOre = mining.getNearestOre(oreLumps[oreLump])
        print("Going to the nearest ore (of ore lump on route): " .. tostring(nearestOre))
        nav.goTo(nearestOre, true)
        mining.mineOreLump(nav.relativeOrientation(robot.position, nearestOre))
    end

    -- startPos should also be included in tspGreedy nodes as goal parameter, and 
    -- robot.position should be included as start parameter
    nav.goTo(startPos)

--[[         while #ores > 0 do
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
        
    end ]]
end

return mining