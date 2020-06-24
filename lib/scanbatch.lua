local component = require("component")
local geolyzer = component.geolyzer
local robot = require("robot")

local map = require("map")
local vec3 = require("vec3")
local blockType = require("blockType")
local VectorChunk = require("vectorchunk")
local VectorMap = require("vectormap")
local utils = require("utils")
local sides = require("sides")

local debug = require("debug")

local ScanBatch = {}
ScanBatch.__index = ScanBatch
setmetatable(ScanBatch, {__call = function(cls)
	local self = {}
	self.scans = VectorChunk(true, false)
	setmetatable(self, cls) -- cls = PriorityQueue
	return self
end })

--[[ finds a vector which x, y, z components define dimensions of a cuboid which is (almost) the most optimal one
to fill another larger cuboid sizeVector with cuboids of that size, with algorithm described here:
https://stackoverflow.com/questions/37644269/dividing-a-cuboid-of-n-into-smaller-cuboids-of-m-volume --]]
function ScanBatch:packCubes(sizeVector)
    local minCubes = math.ceil(sizeVector.x / 4) * math.ceil(sizeVector.y / 4) * math.ceil(sizeVector.z / 4)
    local solution = vec3(4, 4, 4)
    for x = 1, math.min(sizeVector.x, 64) do
        for y = 1, math.min(sizeVector.y, 64 // x) do
            local z = 64 // (x * y)
            local numCubes = math.ceil(sizeVector.x / x) * math.ceil(sizeVector.y / y) * math.ceil(sizeVector.z / z)
            if numCubes < minCubes then
                minCubes = numCubes
                solution.x = x
                solution.y = y
                solution.z = z
            end
        end
    end

    return solution, minCubes
end

--[[ scan an area of any size, volumes larger than 64 are handled by dividing the space into the least possible
amount of cuboids that fill the entire space to minimize delay and energy consumption ]]
function ScanBatch:scanArea(offsetVector, sizeVector)
    local scanSize = self:packCubes(sizeVector)

    for x = 0, math.ceil(sizeVector.x / scanSize.x) - 1 do
        for y = 0, math.ceil(sizeVector.y / scanSize.y) - 1 do
            for z = 0, math.ceil(sizeVector.z / scanSize.z) - 1 do
                local iterationOffset = vec3(x * (scanSize.x), y * (scanSize.y), z * (scanSize.z))
                local overflow = iterationOffset + scanSize - sizeVector
                overflow.x = math.max(0, overflow.x)
                overflow.y = math.max(0, overflow.y)
                overflow.z = math.max(0, overflow.z)
                self:scanQuad(offsetVector + iterationOffset, scanSize - overflow)
            end
        end
    end
end

--[[ scan an area around the robot, with robot roughly in the center --]]
function ScanBatch:scanAround(sizeVector)
    local offsetVector = vec3(-sizeVector.x // 2, -sizeVector.y // 2, -sizeVector.z // 2)
    self:scanArea(offsetVector, sizeVector)
end

--[[ scan a 16x16 area around the robot, with robot roughly in the center and an optional vertical offset --]]
function ScanBatch:scanLayer(offsetY)
    offsetY = offsetY or 0
    self:scanArea(vec3(-8, offsetY, -8), vec3(16, 1, 16))
end

--[[ takes the offset and size vectors and rotates them so that the origin point and dimensions for
geolyzer.scan are relative to the robot's orientation --]]
function ScanBatch:correctForOrientation(offsetVector, sizeVector)
    if robot.orientation == sides.east then
        return offsetVector, sizeVector
    elseif robot.orientation == sides.west then
        return vec3(-offsetVector.x - sizeVector.x + 1, offsetVector.y, -offsetVector.z - sizeVector.z + 1), sizeVector
    elseif robot.orientation == sides.south then
        return vec3(-offsetVector.z - sizeVector.z + 1, offsetVector.y, offsetVector.x), vec3(sizeVector.z, sizeVector.y, sizeVector.x)
    else -- robot.orientation == sides.north
        return vec3(offsetVector.z, offsetVector.y, -offsetVector.x - sizeVector.x + 1), vec3(sizeVector.z, sizeVector.y, sizeVector.x)
    end
end

--[[ scan the provided quad, note that x, y and z of sizeVector should all be non-negative values
for readability and to avoid unexpected behavior (the scan will still work but you may get different
results than expected, e.g. when providing x = -2 you'll get result as if x was 4
offsetVector takes into account robot's orientation, in other words offset is relative to where
the robot is currently looking (x offset means forward/backward, y means up/down and z means left/right)
The linear table returned from geolyzer.scan should be interpreted as: first, values go towards
positive x, then towards positive z, then towards positive y --]]
function ScanBatch:scanQuad(offsetVector, sizeVector)
    offsetVector, sizeVector = self:correctForOrientation(offsetVector, sizeVector) -- correct for robot's orientation
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

--[[ make a query for a list of coordinates containing a specific block type or specific block types,
returns a table of vec3 values which are absolute coordinates where the specific block types were detected ]]
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

-- same as ScanBatch:query but returns an iterator instead of a table
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