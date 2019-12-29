local robot = require("robot")
local component = require("component")
local geolyzer = component.geolyzer

local vec3 = require("vec3")
local VectorMap = require("vectormap")

local map = VectorMap()

-- scan the sorrounding 20x20x20 area (temporary code)
function map.scanMap()
	for x=-4,3,1 do
		for z=-4,3,1 do
			local scanData = geolyzer.scan(x, z, -9, 1, 1, 20)
       		for i=1,20 do
            	local assumedBlock = "minecraft:air"
				if scanData[i] < 0.4 then assumedBlock = "minecraft:air"
				elseif scanData[i] < 2.75 then assumedBlock = "minecraft:stone"
				elseif scanData[i] < 95 then assumedBlock = "minecraft:ore"
				else assumedBlock = "minecraft:water" end
				map[vec3(robot.position.x + x, robot.position.y + i - 10, robot.position.z + z)] = assumedBlock
       		end
		end
	end
end

return map