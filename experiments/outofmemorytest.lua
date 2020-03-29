package.loaded.vectormap = nil
package.loaded.vectorchunk = nil
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

local startMem = math.max(utils.freeMemory(), utils.freeMemory(), utils.freeMemory())

math.randomseed(os.time())

local x = 31
local y = 31
local z = 31

local idx = 0
for i = 0,x do
	for j = 0,y do
		for k = 0,z do
			idx = idx + 1
			local vector = vec3(i, j, k)
			local randomnum = math.random(0, 543)
			if testIndexes then
				v:setIndex(idx, vector)
			else
				v:set(vector, randomnum)
			end
		end
	end
end

local i, real, cpu = utils.timeIt(false, function(d) 
	local i = 0
	local iter, cls, j
	if testIndexes then
		iter, cls, j = d:ipairs()
	else
		iter, cls, j = d:pairs()
	end
	for key,val in iter, cls, j do
		i = i + 1
	end
	return i
end, v)

print("cpu iteration time:", cpu)
local endMem = math.max(utils.freeMemory(), utils.freeMemory(), utils.freeMemory())
local elemCount = i
print("starting memory: ", startMem)
print("ending memory: ", endMem)
print("bytes taken: ", startMem - endMem)
print("bytes per element: ", (startMem - endMem)/elemCount)
print("elements in map: ", elemCount)