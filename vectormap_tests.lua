local VectorMap = require("vectormap")
local inspect = require("inspect")
local utils = require("utils")

local function testIndexNewIndex()
	map[vec3(7, 1, 3)] = "minecraft:air"
	local testGet = map[vec3(7, 1, 3)] == "minecraft:air"
	local testNotFound = map[vec3(3, 7, 5)] == nil
	map._internal = {}
	return testGet and testNotFound
end

local function testAll()
	local tests = {testIndexNewIndex}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
	end
end



local v = VectorMap()
v[vec3(1, 2, 3)] = "dupa"
print(inspect(v))
print(v[vec3(1, 2, 3)])
if v[vec3(5,4,3)] == nil then
	print("wohoo")
end

--testAll()