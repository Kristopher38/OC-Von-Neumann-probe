local vec3 = require("vec3")

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

local function testAll()
	local tests = {testVec3, testVec3eq}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
    end
end

testAll()