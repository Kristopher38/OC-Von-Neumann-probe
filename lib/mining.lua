local nav = require("navigation")
local ScanBatch = require("scanbatch")
local utils = require("utils")
local VectorMap = require("vectormap")
local robot = require("robot")
local vec3 = require("vec3")
local blockType = require("blocktype")
local map = require("map")

local autoyield = require("autoyielder")
local logging = require("logging")
local log = logging:getLogger("mining")
log:setLevel(logging.DEBUG)

local component = require("component")
local sides = require("sides")
local geolyzer = component.geolyzer
local robotComponent = component.robot

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
    log:info("Scanning ore lump...")
    local oresScanBatch = mining.scanOre(oreSide)
    local ores = oresScanBatch:query(blockType.ore)
    local neighbourOreLumps = mining.oreLumpsFromOres(ores)
    local currentOreLump = neighbourOreLumps[nav.nearestBlock(utils.keys(neighbourOreLumps))]
    if currentOreLump then
        while #currentOreLump > 0 do
            local nearestOre = utils.timeIt(nav.nearestBlock, currentOreLump, robot.position, nav.heuristicAStar)
            nav.goTo(nearestOre, true)
            robotComponent.swing(nav.relativeOrientation(robot.position, nearestOre))
            currentOreLump[nearestOre] = nil
            autoyielder.yield()
        end
    end
    log:info("Finished mining ore lump.")
end

function mining.mineChunk()
    local bedrockReached = false
    local scanBatch = ScanBatch()
    local startPos = utils.deepCopy(robot.position)

    while not bedrockReached do
        scanBatch:scanLayer()
        log:debug("Free memory: %u", utils.freeMemory())
        robot.swingDown()
        if not robot.down() then
            bedrockReached = true
        end
    end

    log:info("Calculating ore lumps...")
    local oreLumps = mining.oreLumpsFromOres(scanBatch:query(blockType.ore))
    log:info("Calculating fastest tour...")
    local oreLumpsTour = nav.shortestTour(utils.keys(oreLumps), robot.position, startPos)
    -- delete last item - starting position
    table.remove(oreLumpsTour, #oreLumpsTour)
    table.remove(oreLumpsTour, 1)
    log:info("Mining lumps...")
    for i, oreLump in ipairs(oreLumpsTour) do
        local nearestOre
        repeat
            nearestOre = nav.nearestBlock(oreLumps[oreLump])
        until map.assumeBlockType(map[nearestOre]) == blockType.ore
        log:info("Going to the nearest ore (of ore lump on route): %s", tostring(nearestOre))
        nav.goTo(nearestOre, true)
        mining.mineOreLump(nav.relativeOrientation(robot.position, nearestOre))
    end
    nav.goTo(startPos)
end

return mining