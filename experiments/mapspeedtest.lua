package.loaded.vectormap = nil
package.loaded.vectorchunk = nil
package.loaded.vec3 = nil
local VectorMap = require("vectormap")
local utils = require("utils")
local inspect = require("inspect")
local sides = require("sides")
local vec3 = require("vec3")
local VectorChunk = require("vectorchunk")

local v = VectorChunk(vec3(), true)

local x = 31
local y = 31
local z = 31

function fill()
    local totalTimeReal = 0
    local totalTimeCpu = 0
    for i = 0,x do
        for j = 0,y do
            for k = 0,z do
                local vector = vec3(x, y, z)
                local randomnum = math.random(-64, 64)
                local real, cpu
                _, real, cpu = utils.timeIt(false, v.set, v, vector, vec3(64, 23, 734))
                totalTimeReal = totalTimeReal + real
                totalTimeCpu = totalTimeCpu + cpu
            end
        end
    end
    return totalTimeCpu
end

function read()
    local totalTimeReal = 0
    local totalTimeCpu = 0
    local tmp = nil
    local mt = getmetatable(v)
    for i = 1,x do
        for j = 1,y do
            for k = 1,z do
                local vec = vec3(x, y, z)
                local real, cpu
                tmp, real, cpu = utils.timeIt(false, v.at, v, vec)
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
local elemCount = x*y*z
print("elements in map: ", elemCount)