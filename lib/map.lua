local robot = require("robot")
local component = require("component")
local geolyzer = component.geolyzer

local vec3 = require("vec3")
local VectorMap = require("vectormap")
local blockType = require("blocktype")

local map = VectorMap(vec3(256, 128, 256))

function map.assumeBlockType(hardness)
	if hardness ~= nil then
		if hardness < 0 then assumedType = blockType.bedrock
		elseif hardness < 0.4 then assumedType = blockType.air
		elseif hardness < 2.75 then assumedType = blockType.stone
		elseif hardness < 95 then assumedType = blockType.ore
		else assumedType = blockType.fluid end
		return assumedType
	else
		return blockType.unknown
	end
end

return map