-- tests for utils
local utils = require("utils")
local sides = require("sides")
local vec3 = require("vec3")

local function testhasDuplicateValue()
	local t = {5, "foo", vec3(6, 3, -4), "bar", vec3({6, 3, 0}), true, -7, print}
	
	local numberTest = utils.hasValue(t, 5) and utils.hasValue(t, -7) and not utils.hasValue(t, -4)
	local stringTest = utils.hasValue(t, "foo") and utils.hasValue(t, "bar") and not utils.hasValue(t, "baz")
	local boolTest = utils.hasValue(t, true) and not utils.hasValue(t, false)
	local nilTest = not utils.hasValue(t, nil)
	local functionTest = utils.hasValue(t, print) and not utils.hasValue(t, table.insert)
	local customTypeTest = utils.hasValue(t, vec3(6, 3, -4)) and utils.hasValue(t, vec3({6, 3, 0})) and not utils.hasValue(t, vec3(5, -3, 12))
	return numberTest and stringTest and boolTest and nilTest and functionTest and customTypeTest
end

local function testAll()
	local tests = {testhasDuplicateValue}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
	end
end

testAll()