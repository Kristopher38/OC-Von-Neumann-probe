package.loaded.vectormap = nil
local VectorMap = require("vectormap")
local utils = require("utils")
local inspect = require("inspect")
local sides = require("sides")
local vec3 = require("vec3")

local v = VectorMap(vec3(16, 16, 16))
local startMem = math.max(utils.freeMemory(), utils.freeMemory(), utils.freeMemory())

math.randomseed(os.time())

local x = 16
local y = 16
local z = 16

for i = 1,x  do
	for j = 1,y do
		for k = 1,z do
			local vector = vec3(math.random(-16, 15), math.random(0, 31), math.random(-16, 15))
			local randomnum = math.random(-64, 64) 
			v[vector] = randomnum
			--print(vector, randomnum)
			--[[ if i == 4 and j == 28 and k == 68 then
				goto exit
			end ]]
		end
	end
end

--[[ local i = 0
for key,val in pairs(v._internalMap) do
	v._internalMap[key] = nil
	if i == 30000 then
		break
	end
	i = i + 1
end ]]
::exit::
local endMem = math.max(utils.freeMemory(), utils.freeMemory(), utils.freeMemory())
local elemCount = x*y*z--v.count
print("starting memory: ", startMem)
print("ending memory: ", endMem)
print("bytes taken: ", startMem - endMem)
print("bytes per element: ", (startMem - endMem)/elemCount)
print("elements in map: ", elemCount)

--[[ for k,v in pairs(v) do
	print(k, v)
end ]]