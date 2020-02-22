package.loaded.vectormap = nil
package.loaded.vectorchunk = nil
local VectorMap = require("vectormap")
local utils = require("utils")
local inspect = require("inspect")
local sides = require("sides")
local vec3 = require("vec3")
local VectorChunk = require("vectorchunk")

local v = VectorChunk(vec3(), false)--VectorMap(vec3(16, 16, 16))
local startMem = math.max(utils.freeMemory(), utils.freeMemory(), utils.freeMemory())

math.randomseed(os.time())

local x = 63
local y = 31
local z = 31

local str = ""

for i = 0,x  do
	for j = 0,y do
		for k = 0,z do
			local vector = vec3(i, j, k) --vec3(math.random(0, 64), math.random(0, 64), math.random(0, 64))
			local randomnum = math.random(0, 543)--vec3(math.random(0, 64), math.random(0, 64), math.random(0, 64))
			v[vector] = randomnum
			--str = str .. tostring(math.random(0, 9))
		end
	end
end

local i, real, cpu = utils.timeIt(function(v) 
	local i = 0
	for key,val in pairs(v) do
		i = i + 1
	end
	return i
end, v)

print("cpu time:", cpu)
::exit::
local endMem = math.max(utils.freeMemory(), utils.freeMemory(), utils.freeMemory())
local elemCount = i
print("starting memory: ", startMem)
print("ending memory: ", endMem)
print("bytes taken: ", startMem - endMem)
print("bytes per element: ", (startMem - endMem)/elemCount)
print("elements in map: ", elemCount)
print(str)

--[[ for k,v in pairs(v) do
	print(k, v)
end ]]