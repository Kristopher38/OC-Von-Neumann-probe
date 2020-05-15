local nav = require("navigation")
local ScanBatch = require("scanbatch")
local utils = require("utils")
local VectorChunk = require("vectorchunk")
local robot = require("robot")
local vec3 = require("vec3")
local blockType = require("blocktype")
local map = require("map")

local autoyielder = require("autoyielder")
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
        local lump = VectorChunk(false, true)

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
    
    local lumps = VectorChunk(false, true)
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
    log:debug("Scanning ore lump at location %s", robot.position)
    local oresScanBatch = mining.scanOre(oreSide)
    local ores = oresScanBatch:query(blockType.ore)
    local oreLumps = mining.oreLumpsFromOres(ores)
    local nearestOreLumpCenter = nav.nearestBlock(utils.keys(oreLumps))
    local nearestOreLump = oreLumps[nearestOreLumpCenter]
    log:debug("Starting mining ore lump with center at %s", nearestOreLumpCenter)
    if nearestOreLump then
        while true do
            local oreLocations = utils.keys(nearestOreLump)
            if #oreLocations == 0 then
                break
            end
            -- goes to the nearest ore block
            local nearestOre = nav.goTo(oreLocations, true)
            log:debug("Mining nearest ore at %s", nearestOre)
            robotComponent.swing(nav.relativeOrientation(robot.position, nearestOre))
            nearestOreLump[nearestOre] = nil
        end
    end
    log:info("Mined ore lump with center at %s", nearestOreLumpCenter)
end

function mining.mineChunk()
    local bedrockReached = false
    local scanBatch = ScanBatch()
    local startPos = utils.deepCopy(robot.position)

    log:info("Mining chunk started, going down until bedrock is hit")
    while not bedrockReached do
        scanBatch:scanLayer()
        log:debug("Free memory at Y = %u: %u", robot.position.y, utils.freeMemory())
        robot.swingDown()
        if not robot.down() then
            bedrockReached = true
        end
    end

    local oreLumps = mining.oreLumpsFromOres(scanBatch:query(blockType.ore))
    local oreLumpCenters = utils.keys(oreLumps)
    log:info("Bedrock reached, found %u ore lumps", #oreLumpCenters)
    if #oreLumpCenters > 0 then
        log:info("Proceeding to mine all ore lumps")
        local oreLumpsTour, tourDistance = nav.shortestTour(oreLumpCenters, robot.position, startPos)
        log:debug("Calculated a tour to mine ore lumps with a distance of %f", tourDistance)
        -- delete last item - starting position
        table.remove(oreLumpsTour, #oreLumpsTour)
        table.remove(oreLumpsTour, 1)
        for i, oreLumpCenter in ipairs(oreLumpsTour) do
            local oreLump = oreLumps[oreLumpCenter]
            -- clear entries in oreLump that aren't ores anymore since we've already mined them
            for vec, hardness in pairs(oreLump) do
                if map.assumeBlockType(map[vec]) ~= blockType.ore then
                    oreLump[vec] = nil
                end
            end
            local oreVectors = utils.keys(oreLumps[oreLumpCenter])
            if #oreVectors > 0 then
                local nearestOre = nav.goTo(oreVectors, true)
                log:debug("Went to the nearest ore (of ore lump on route): %s", nearestOre)
                mining.mineOreLump(nav.relativeOrientation(robot.position, nearestOre))
            end
        end
    end
    log:info("Mined all ores within a chunk, going back to the start position: %s", startPos)
    nav.goTo(startPos)
end

return mining