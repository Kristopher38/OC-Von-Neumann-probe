local robot = require("robot")
local component = require("component")
local geolyzer = component.geolyzer

local vec3 = require("vec3")
local VectorMap = require("vectormap")

local map = VectorMap(vec3(256, 128, 256))

function map.assumeBlock(hardness)
	local assumedBlock = "minecraft:air"
	if hardness < 0.4 then assumedBlock = "minecraft:air"
	elseif hardness < 2.75 then assumedBlock = "minecraft:stone"
	elseif hardness < 95 then assumedBlock = "minecraft:ore"
	else assumedBlock = "minecraft:water" end
	return assumedBlock
end

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
				map[vec3(robot.position.x + x, robot.position.y + i + starty - 1, robot.position.z + z)] = map.assumeBlock(scanData[i])
       		end
		end
	end
end

--[[ scan the provided quad, note that w, d and h should be positive nonzero because of
readability (the scan will still work but you may get the results different than expected,
e.g. when providing w = -2 you'll get result as if length of width was 4
Also note that geolyzer scans orientation are absolute, regardless of robot's current orientation
and this function as of now doesn't correct for this. The linear table returned from geolyzer.scan
should be interpreted as: first, values go towards positive x, then towards positive z, then
towards positive y --]]
function map.scan(x, z, y, w, d, h)
	local scanData = geolyzer.scan(x, z, y, w, d, h)
	local i = 1
	for yy = 0, h - 1 do
		for zz = 0, d - 1 do
			for xx = 0, w - 1 do
				map[vec3(robot.position.x + x + xx, robot.position.y + y + yy, robot.position.z + z + zz)] = map.assumeBlock(scanData[i])
				i = i + 1
			end
		end
	end
end

return map