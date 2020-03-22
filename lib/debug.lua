local component = require("component")
local glasses = component.glasses

local VectorMap = require("vectormap")
local utils = require("utils")

local inspect = require("inspect")

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

function debug.drawCubeFloat(vector, color, opacity)
	opacity = opacity or 0.5
	local cube = glasses.addCube3D()
	cube.addTranslation(vector.x, vector.y, vector.z)
	cube.addColor(color[1], color[2], color[3], opacity)
	cube.setVisibleThroughObjects(true)
end

local debugCubes = VectorMap()
local debugCubeColors = {}
local debugShapes = {}
function debug.drawCube(vector, color)
	debugCubes[vector] = color
	debugCubeColors[color] = true
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
			print("CATCHED OUT OF MEMORY ERROR, RANGE SIZE:", j-i)
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
	for color, _ in pairs(debugCubeColors) do
		local objShape = {}
		local numCubes = 0
		--[[ trade speed for lower memory consumption, essentially instead of O(n) we've got O(n^2) time complexity at worst
		since we're iterating over the set however many times there are colors, the more colors the closer it gets to O(n^2),
		but it allows us to draw more cubes than the ~2000 limit with 2MB of memory since we only need to keep in memory the
		objShape table of strings for the currently iterated color as opposed to keeping tables for all colors at the same time --]]
		for vector, cubeColor in pairs(debugCubes) do
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
			debugShapes[color].addColor(debug.color[color][1], debug.color[color][2], debug.color[color][3], 0.8)
			debugShapes[color].setVisibleThroughObjects(true)
		end
		debugShapes[color].loadOBJ(concatDivide(objShape, "\n"))
	end
end

function debug.drawLine(vectorA, vectorB, color, opacity, scale)
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
	line.addColor(color[1], color[2], color[3], opacity)
	line.setVisibleThroughObjects(true)

	line.loadOBJ(table.concat(objShape, "\n"))
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