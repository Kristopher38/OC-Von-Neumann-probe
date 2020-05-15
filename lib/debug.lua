local component = require("component")
local glasses = component.glasses

local VectorMap = require("vectormap")
local utils = require("utils")
local vec3 = require("vec3")

local inspect = require("inspect")

local debug = {}

debug.color =  {black=vec3(0, 0, 0),
				grey=vec3(0.75, 0.75, 0.75),
				red=vec3(1, 0, 0),
				green=vec3(0, 1, 0),
				yellow=vec3(1, 1, 0),
				blue=vec3(0, 0, 1),
				pink=vec3(1, 0, 1),
				aqua=vec3(0, 1, 1),
				white=vec3(1, 1, 1),
				darkRed=vec3(0.5, 0, 0),
				darkGreen=vec3(0, 0.5, 0),
				darkYellow=vec3(0.5, 0.5, 0),
				darkBlue=vec3(0, 0, 0.5),
				darkPink=vec3(0.5, 0, 0.5),
				darkAqua=vec3(0, 0.5, 0.5),
				darkGrey=vec3(0.5, 0.5, 0.5)}

function debug.init()
	glasses.startLinking("Kristopher38")
	glasses.setRenderPosition("absolute")
end

function debug.drawCube(vector, color, opacity)
	opacity = opacity or 0.5
	local cube = glasses.addCube3D()
	cube.addTranslation(vector.x, vector.y, vector.z)
	cube.addColor(color.x, color.y, color.z, opacity)
	cube.setVisibleThroughObjects(true)
end

function debug.drawText(vector, text, color, opacity, fontSize)
	color = color or debug.color.black
	opacity = opacity or 0.5
	fontSize = fontSize or 6
	local textWidget = glasses.addText3D()
	textWidget.setText(text)
	textWidget.setFontSize(fontSize)
	textWidget.addTranslation(vector.x, vector.y, vector.z)
	textWidget.addColor(color.x, color.y, color.z, opacity)
	textWidget.setVisibleThroughObjects(true)
end

function debug.clearWidgets()
	debugCubes = VectorMap(true, true)
	debugCubeColors = VectorMap(false, true)
	debugShapes = {}
    glasses.removeAll()
end

local debugCubes = VectorMap(true, true)
local debugCubeColors = VectorMap(false, true)
local debugShapes = {}
function debug.drawCubeShape(vector, color)
	color = color or debug.color.red
	debugCubes[vector] = color
	debugCubeColors[color] = true
end

function debug.drawLineShape(vectorA, vectorB, color, opacity, scale)
	color = color or debug.color.red
	opacity = opacity or 0.5
	scale = scale or 1

	local objShape = {}

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

	for i = 3, 12, 3 do
		table.insert(objShape, string.format("v %f %f %f", vectorA.x + vertices[i-2] * scale, vectorA.y + vertices[i-1] * scale, vectorA.z + vertices[i] * scale))
	end
	for i = 15, #vertices, 3 do
		table.insert(objShape, string.format("v %f %f %f", vectorB.x + vertices[i-2] * scale, vectorB.y + vertices[i-1] * scale, vectorB.z + vertices[i] * scale))
	end
	for i = 4, #faces, 4 do
		table.insert(objShape, string.format("f %i %i %i %i", faces[i-3], faces[i-2], faces[i-1], faces[i]))
	end

	local line = glasses.addOBJModel3D()
	line.setCulling(false)
	line.addColor(color.x, color.y, color.z, opacity)
	line.setVisibleThroughObjects(true)

	line.loadOBJ(table.concat(objShape, "\n"))
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
			utils.freeMemory()
			local str1 = concatDivide(t, sep, i, math.floor(j / 2))
			local str2 = concatDivide(t, sep, math.floor(j / 2) + 1, j)
			return str1 .. sep .. str2
		end
	end

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

	local counter = 0
	for color, _ in debugCubeColors:pairs() do
		local objShape = {}
		local numCubes = 0
		--[[ trade speed for lower memory consumption, essentially instead of O(n) we've got O(n^2) time complexity at worst
		since we're iterating over the set however many times there are colors, the more colors the closer it gets to O(n^2),
		but it allows us to draw more cubes than the ~2000 limit with 2MB of memory since we only need to keep in memory the
		objShape table of strings for the currently iterated color as opposed to keeping tables for all colors at the same time --]]
		for vector, cubeColor in debugCubes:pairs() do
			counter = counter + 1

			if color == cubeColor then
				for i = 3, #vertices, 3 do
					table.insert(objShape, string.format("v %i %i %i", vector.x + vertices[i-2], vector.y + vertices[i-1], vector.z + vertices[i]))
				end
				for i = 4, #faces, 4 do
					table.insert(objShape, string.format("f %i %i %i %i", faces[i-3] + 8*numCubes, faces[i-2] + 8*numCubes, faces[i-1] + 8*numCubes, faces[i] + 8*numCubes))
				end
				numCubes = numCubes + 1
			end
		end
		if debugShapes[color] == nil then
			debugShapes[color] = glasses.addOBJModel3D()
			debugShapes[color].setCulling(false)
			debugShapes[color].addColor(color.x, color.y, color.z, 0.8)
			debugShapes[color].setVisibleThroughObjects(true)
		end
		debugShapes[color].loadOBJ(concatDivide(objShape, "\n"))
	end
end

return debug