local component = require("component")
local glasses = component.glasses

local PriorityQueue = require("priorityqueue")
local utils = require("utils")

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

function debug.init()
	glasses.startLinking("Kristopher38")
	glasses.setRenderPosition("absolute")
end

--[[ debug.cubes = PriorityQueue()
debug.cubes.n = 0 ]]
function debug.drawCube2(vector, color, opacity)
	opacity = opacity or 0.5
	local cube = glasses.addCube3D()
	cube.addTranslation(vector.x, vector.y, vector.z)
	cube.addColor(color[1], color[2], color[3], opacity)
	cube.setVisibleThroughObjects(true)
--[[     debug.cubes:put(cube, debug.cubes.n)
	debug.cubes.n = debug.cubes.n + 1
	if cubes:size() > 255 then
		cubes:pop().removeWidget()
	end ]]
end

local shape
local numCubes = 0
local objData = {}
function debug.drawCube(vector, color, opacity)
	if shape == nil then
		shape = glasses.addOBJModel3D()
		--shape = glasses.addCustom3D()
		--shape.setGLMODE("TRIANGLES")
		--shape.setShading("FLAT")
		shape.setCulling(false)
	end
	opacity = opacity or 0.5

	local vertices = {
		0, 1, 1, 
		0, 0, 1, 
		1, 0, 1, 
		1, 1, 1, 
		0, 1, 0, 
		0, 0, 0, 
		1, 0, 0, 
		1, 1, 0, 
	}

	local faces = {
		1, 2, 3, 4,
		8, 7, 6, 5,
		4, 3, 7, 8,
		5, 1, 4, 8,
		5, 6, 2, 1,
		2, 6, 7, 3,
	}

	local n = #objData
	for i = 3, #vertices, 3 do
		objData[n + 1] = "v"
		objData[n + 2] = vector.x + vertices[i-2]
		objData[n + 3] = vector.y + vertices[i-1]
		objData[n + 4] = vector.z + vertices[i]
		objData[n + 5] = "\n"
		n = n + 5
		--objData = objData .. string.format("v %i %i %i\n", vector.x + vertices[i-2], vector.y + vertices[i-1], vector.z + vertices[i])
	end
	for i = 4, #faces, 4 do
		objData[n + 1] = "f"
		objData[n + 2] = faces[i-3] + 8*numCubes
		objData[n + 3] = faces[i-2] + 8*numCubes
		objData[n + 4] = faces[i-1] + 8*numCubes
		objData[n + 5] = faces[i] + 8*numCubes
		objData[n + 6] = "\n"
		n = n + 6
		--objData = objData .. string.format("f %i %i %i %i\n", faces[i-3] + 8*numCubes, faces[i-2] + 8*numCubes, faces[i-1] + 8*numCubes, faces[i] + 8*numCubes)
	end

	--shape.loadOBJ(objData)
	numCubes = numCubes + 1
	-- workaround for an extra vertex required to draw the last triangle
	--[[ shape.setVertex(shape.getVertexCount(), vector.x + vertices[1], vector.y + vertices[2], vector.z + vertices[3])
	for i = 6, #vertices, 3 do
		shape.addVertex(vector.x + vertices[i-2], vector.y + vertices[i-1], vector.z + vertices[i])
	end ]]
	--print(numCubes)
	--shape.addTranslation(vector.x, vector.y, vector.z)
	shape.addColor(color[1], color[2], color[3], opacity)
	shape.setVisibleThroughObjects(true)
end

function debug.commit()
	local function concatDivide(t, sep, i, j)
		sep = sep or " "
		i = i or 1
		j = j or #t

		local result, str = pcall(table.concat, t, sep, i, j)
		if result then
			return str
		else
			print("CATCHED OUT OF MEMORY ERROR")
			utils.freeMemory()
			local str1 = concatDivide(t, sep, i, math.floor(j / 2))
			local str2 = concatDivide(t, sep, math.floor(j / 2) + 1, j)
			return str1 .. sep .. str2
		end
	end

	local objStr = concatDivide(objData, " ")
	shape.loadOBJ(objStr)
end

function debug.drawText(vector, text, color, opacity, fontSize)
	color = color or debug.color.black
	opacity = opacity or 0.5
	fontSize = fontSize or 6
	local textWidget = glasses.addText3D()
	textWidget.setText(text)
	textWidget.setFontSize(fontSize)
	textWidget.addTranslation(vector.x, vector.y, vector.z)
	textWidget.addColor(color[1], color[2], color[3], opacity)
	textWidget.setVisibleThroughObjects(true)
end

function debug.clearWidgets()
    glasses.removeAll()
end

return debug