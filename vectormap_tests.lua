local VectorMap = require("vectormap")
local vec3 = require("vec3")

local function testIndexNewIndex()
	local map = VectorMap()
	map[vec3(7, 1, 3)] = "minecraft:air"
	local testGet = map[vec3(7, 1, 3)] == "minecraft:air"
	local testNotFound = map[vec3(3, 7, 5)] == nil
	return testGet and testNotFound
end

local function testAll()
	local tests = {testIndexNewIndex}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
	end
end

testAll()