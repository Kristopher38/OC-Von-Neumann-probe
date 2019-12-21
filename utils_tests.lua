-- tests for utils
local utils = require("utils")
local sides = require("sides")
local map = require("map")

local function testVec3()
	local a = vec3(6, 4, -3)
	local b = vec3({2, -3, 6})
	local c = vec3({3, 7, -3}, 5)
	local d = vec3(7)
	
	local aTest = a.x == 6 and a.y == 4 and a.z == -3
	local bTest = b.x == 2 and b.y == -3 and b.z == 6
	local cTest = c.x == 3 and c.y == 7 and c.z == -3
	local dTest = d.x == 7 and d.y == 0 and d.z == 0
	
	return aTest and bTest and cTest and dTest
end

local function testVec3eq()
	local a = vec3(6, 4, -3)
	local b = vec3(-7, 1, 3)
	local c = vec3(6, 4, -3)
	
	local equalityTest = a == c
	local inequalityTest = not (a == b) and not (b == c)
	return equalityTest and inequalityTest
end

local function testHasDuplicateValue()
	local t = {5, "foo", vec3(6, 3, -4), "bar", vec3({6, 3, 0}), true, -7, print}
	
	local numberTest = hasDuplicateValue(t, 5) and hasDuplicateValue(t, -7) and not hasDuplicateValue(t, -4)
	local stringTest = hasDuplicateValue(t, "foo") and hasDuplicateValue(t, "bar") and not hasDuplicateValue(t, "baz")
	local boolTest = hasDuplicateValue(t, true) and not hasDuplicateValue(t, false)
	local nilTest = not hasDuplicateValue(t, nil)
	local functionTest = hasDuplicateValue(t, print) and not hasDuplicateValue(t, table.insert)
	local customTypeTest = hasDuplicateValue(t, vec3(6, 3, -4)) and hasDuplicateValue(t, vec3({6, 3, 0})) and not hasDuplicateValue(t, vec3(5, -3, 12))
	return numberTest and stringTest and boolTest and nilTest and functionTest and customTypeTest
end

local function testCoordsFromOffset()
	local staticCoords = vec3(73, 30, -58)
	
	local testSouth = coordsFromOffset(staticCoords, vec3(-3, 5, 4), sides.south) == vec3(69, 35, -61)
	local testNorth = coordsFromOffset(staticCoords, vec3(2, -3, 12), sides.north) == vec3(85, 27, -60)
	local testEast = coordsFromOffset(staticCoords, vec3(6, 3, -8), sides.east) == vec3(79, 33, -66)
	local testWest = coordsFromOffset(staticCoords, vec3(-1, 6, 7), sides.west) == vec3(74, 36, -65)
	
	return testSouth and testNorth and testEast and testWest
end

local function testAll()
	local tests = {testVec3, testVec3eq, testHasDuplicateValue, testCoordsFromOffset}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
	end
end

testAll()