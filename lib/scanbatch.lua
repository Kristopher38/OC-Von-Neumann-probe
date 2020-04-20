local component = require("component")
local geolyzer = component.geolyzer
local robot = require("robot")

local map = require("map")
local vec3 = require("vec3")
local blockType = require("blockType")
local VectorChunk = require("vectorchunk")
local VectorMap = require("vectormap")
local utils = require("utils")

local debug = require("debug")

local ScanBatch = {}
ScanBatch.__index = ScanBatch
setmetatable(ScanBatch, {__call = function(cls)
	local self = {}
	self.scans = VectorChunk(true, false)
	setmetatable(self, cls) -- cls = PriorityQueue
	return self
end })

--[[ scan the sorrounding sizex x sizey x sizez area with robot roughly in the center
TODO: implement cube packing algorithm --]]
function ScanBatch:scanAround(sizeVector)
    local startx = -math.floor(sizeVector.x / 2)
    local endx = math.floor(sizeVector.x / 2) - (sizeVector.x % 2 == 0 and 1 or 0)
    local starty = -math.floor(sizeVector.y / 2)
    local startz = -math.floor(sizeVector.z / 2)
    local endz = math.floor(sizeVector.z / 2) - (sizeVector.z % 2 == 0 and 1 or 0)
    for x = startx, endx, 1 do
        for z = startz, endz, 1 do
            local scanData = geolyzer.scan(x, z, starty, 1, 1, sizeVector.y)
            for i = 1, sizeVector.z do
                map[robot.position + vec3(x, i + starty - 1, z)] = scanData[i]
            end
        end
    end
    self.scans[robot.position + vec3(startx, starty, startz)] = sizeVector
end

--[[ scan the provided quad, note that w, d and h should be positive nonzero because of
readability (the scan will still work but you may get the results different than expected,
e.g. when providing w = -2 you'll get result as if length of width was 4
Also note that geolyzer scans orientation are absolute, regardless of robot's current orientation
and this function as of now doesn't correct for this (TODO: correct this with coordsFromOffset). 
The linear table returned from geolyzer.scan should be interpreted as: first, values go towards
positive x, then towards positive z, then towards positive y --]]
function ScanBatch:scanQuad(offsetVector, sizeVector)
	local scanData = geolyzer.scan(offsetVector.x, offsetVector.z, offsetVector.y, sizeVector.x, sizeVector.z, sizeVector.y)
	local i = 1
	for y = 0, sizeVector.y - 1 do
		for z = 0, sizeVector.z - 1 do
            for x = 0, sizeVector.x - 1 do
				map[robot.position + offsetVector + vec3(x, y, z)] = scanData[i]
                i = i + 1
			end
		end
    end
    self.scans[robot.position + offsetVector] = sizeVector
end
    
function ScanBatch:scanLayer()
    local quads = {
		{vec3(0, 0, -8), vec3(8, 1, 8)},
		{vec3(0, 0, 0), vec3(8, 1, 8)},
		{vec3(-8, 0, -8), vec3(8, 1, 8)},
		{vec3(-8, 0, 0), vec3(8, 1, 8)}
	}
	for i, quad in ipairs(quads) do
		self:scanQuad(table.unpack(quad))
	end
end

function ScanBatch:query(_blockType)
    if type(_blockType) ~= "table" then
        _blockType = {_blockType}
    end
    local results = VectorMap()
    for offsetVector, sizeVector in pairs(self.scans) do
        for x = 0, sizeVector.x - 1 do
            for y = 0, sizeVector.y - 1 do
                for z = 0, sizeVector.z - 1 do
                    local blockVector = vec3(offsetVector.x + x, offsetVector.y + y, offsetVector.z + z)
                    local assumedBlock = map.assumeBlockType(map[blockVector])
                    if utils.hasValue(_blockType, assumedBlock) then
                        results[blockVector] = assumedBlock
                    end
                end
            end
        end
    end
    return results
end

function ScanBatch:queryPairs(_blockType)
    if type(_blockType) ~= "table" then
        _blockType = {_blockType}
    end

    local scansIterator = pairs(self.scans)
    local offsetVector, sizeVector = scansIterator(self.scans, nil)
    local x, y, z = 0, 0, 0
    local function iterator(self, index)
        while offsetVector do
            if x < sizeVector.x then
                if y < sizeVector.y then
                    if z < sizeVector.z then
                        local blockVector = vec3(offsetVector.x + x, offsetVector.y + y, offsetVector.z + z)
                        local assumedBlock = map.assumeBlockType(map[blockVector])
                        z = z + 1
                        if utils.hasValue(_blockType, assumedBlock) then
                            return blockVector, assumedBlock
                        end
                    else
                        z = 0
                        y = y + 1
                    end
                else
                    y, z = 0, 0
                    x = x + 1
                end
            else
                x, y, z = 0, 0, 0
                offsetVector, sizeVector = scansIterator(self.scans, offsetVector)
            end
        end
    end

    return iterator, self, nil
end

return ScanBatch