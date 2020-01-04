local vec3 = require("vec3")
local nav = require("navigation")
local sides = require("sides")

local function testCoordsFromOffset()
	local staticCoords = vec3(73, 30, -58)
	
	local testSouth = nav.coordsFromOffset(staticCoords, vec3(-3, 5, 4), sides.south) == vec3(69, 35, -61)
	local testNorth = nav.coordsFromOffset(staticCoords, vec3(2, -3, 12), sides.north) == vec3(85, 27, -60)
	local testEast = nav.coordsFromOffset(staticCoords, vec3(6, 3, -8), sides.east) == vec3(79, 33, -66)
	local testWest = nav.coordsFromOffset(staticCoords, vec3(-1, 6, 7), sides.west) == vec3(74, 36, -65)
	
	return testSouth and testNorth and testEast and testWest
end

local function testAll()
	local tests = {testCoordsFromOffset}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
	end
end

testAll()