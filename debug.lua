local component = require("component")
local glasses = component.glasses

local PriorityQueue = require("priorityqueue")

local debug = {}

debug.color =  {black={0, 0, 0}, 
				grey={0.75, 0.75, 0.75},
				red={1, 0, 0},
				green={0, 1, 0},
				yellow={1, 1, 0},
				blue={0, 0, 1},
				pink={1, 0, 1},
				aqua={0, 1, 1},
				white={1, 1, 1},
				darkRed={0.5, 0, 0},
				darkGreen={0, 0.5, 0},
				darkYellow={0.5, 0.5, 0},
				darkBlue={0, 0, 0.5},
				darkPink={0.5, 0, 0.5},
				darkAqua={0, 0.5, 0.5},
				darkGrey={0.5, 0.5, 0.5}}

--[[ debug.cubes = PriorityQueue()
debug.cubes.n = 0 ]]
function debug.drawCube(vector, cubeColor, cubeOpacity)
	cubeOpacity = cubeOpacity or 0.5
	local cube = glasses.addCube3D()
	cube.addTranslation(vector.x, vector.y, vector.z)
	cube.addColor(cubeColor[1], cubeColor[2], cubeColor[3], cubeOpacity)
	cube.setVisibleThroughObjects(true)
--[[     debug.cubes:put(cube, debug.cubes.n)
	debug.cubes.n = debug.cubes.n + 1
	if cubes:size() > 255 then
		cubes:pop().removeWidget()
	end ]]
end

function debug.clearWidgets()
    glasses.removeAll()
end

return debug