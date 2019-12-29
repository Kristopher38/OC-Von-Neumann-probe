local robot = require("robot")
local component = require("component")
local geolyzer = component.geolyzer

local vec3 = require("vec3")
local VectorMap = require("vectormap")

local map = VectorMap()

-- scan the sorrounding sizex x sizey x sizez area with robot roughly in the center
function map.scanMap(sizex, sizey, sizez)
    local startx = -math.floor(sizex / 2)
    local endx = math.floor(sizex / 2) - (sizex % 2 == 0 and 1 or 0)
    local starty = -math.floor(sizey / 2)
    --local endy = math.floor(sizey / 2) - (sizey % 2 == 0 and 1 or 0)
    local startz = -math.floor(sizez / 2)
    local endz = math.floor(sizez / 2) - (sizez % 2 == 0 and 1 or 0)
	for x = startx, endx, 1 do
		for z = startz, endz, 1 do
            local scanData = geolyzer.scan(x, z, starty, 1, 1, sizey)
            for i = 1, sizez do
            	local assumedBlock = "minecraft:air"
				if scanData[i] < 0.4 then assumedBlock = "minecraft:air"
				elseif scanData[i] < 2.75 then assumedBlock = "minecraft:stone"
				elseif scanData[i] < 95 then assumedBlock = "minecraft:ore"
				else assumedBlock = "minecraft:water" end
				map[vec3(robot.position.x + x, robot.position.y + i + starty - 1, robot.position.z + z)] = assumedBlock
       		end
		end
	end
end

return map