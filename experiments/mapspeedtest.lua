package.loaded.vectormap = nil
package.loaded.vectorchunk = nil
package.loaded.vec3 = nil
local VectorMap = require("vectormap")
local utils = require("utils")
local inspect = require("inspect")
local sides = require("sides")
local vec3 = require("vec3")
local VectorChunk = require("vectorchunk")

local testMap = false
local testIndexes = false

print("Testing " .. (testMap and "VectorMap" or "VectorChunk") .. " with " .. (testIndexes and "integer indexes" or "vector indexes"))

local v
if testMap then
	v = VectorMap(false, false)
else
	v = VectorChunk(false, false, vec3())
end

local x = 31
local y = 31
local z = 31

local function fill()
    local totalTimeReal = 0
    local totalTimeCpu = 0
    local idx = 0
    for i = 0,x do
        for j = 0,y do
            for k = 0,z do
                local vector = vec3(i, j, k)
                local randomnum = math.random(-64, 64)
                local _, real, cpu
                idx = idx + 1
                if testIndexes then
                    _, real, cpu = utils.timeIt(false, v.setIndex, v, idx, vector)
                else
                    _, real, cpu = utils.timeIt(false, v.set, v, vector, randomnum)
                end
                totalTimeReal = totalTimeReal + real
                totalTimeCpu = totalTimeCpu + cpu
            end
        end
    end
    return totalTimeCpu
end

local function read()
    local totalTimeReal = 0
    local totalTimeCpu = 0
    local idx = 0
    for i = 0,x do
        for j = 0,y do
            for k = 0,z do
                local vector = vec3(i, j, k)
                local tmp, real, cpu
                idx = idx + 1
                if testIndexes then
                    tmp, real, cpu = utils.timeIt(false, v.atIndex, v, idx)
                else
                    tmp, real, cpu = utils.timeIt(false, v.at, v, vector)
                end
                totalTimeReal = totalTimeReal + real
                totalTimeCpu = totalTimeCpu + cpu
            end
        end
    end
    return totalTimeCpu
end

local fillavg = 0
local readavg = 0
for i = 1, 10 do
    fillavg = fillavg + fill()
    readavg = readavg + read()
    os.sleep(0)
end

print("Fill:", fillavg/10)
print("Read:", readavg/10)

::exit::
local elemCount = (x+1)*(y+1)*(z+1)
print("elements in map: ", elemCount)