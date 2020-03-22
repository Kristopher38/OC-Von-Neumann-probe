package.loaded.debug = nil
local dbg = require("debug")
local vec3 = require("vec3")
local robot = require("robot")
local component = require("component")
local glasses = component.glasses
local event = require("event")
local navigation = require("navigation")
local utils = require("utils")
local VectorMap = require("vectormap")

local startTime = os.clock()

local function autoYield()
    if os.clock() - startTime > 4.0 then
        os.sleep(0)
        startTime = os.clock()
    end
end

dbg.init()
dbg.clearWidgets()

local expanded = VectorMap()

local function expand(toExpand, level)
    if level == 0 then return end
    autoYield()
    dbg.drawCube(toExpand, "red")
    local vectors = {vec3(0, 0, 1), vec3(0, 1, 0), vec3(1, 0, 0), vec3(0, 0, -1), vec3(0, -1, 0), vec3(-1, 0, 0)}
    for i, node in pairs(vectors) do
        local nextExpansion = toExpand + node
        if expanded[nextExpansions] == nil then
            expanded[nextExpansion] = true
            expand(nextExpansion, level - 1)
        end
    end
end

local function drawbigcube(baseOffset, size, color)
    for x = 0, size.x-1 do
        for y = 0, size.y-1 do
            for z = 0, size.z-1 do
                dbg.drawCube(baseOffset+vec3(x, y, z), color)
            end
        end
    end
end


--expand(robot.position+vec3(0, 6, 0), 7)

--[[ utils.timeIt(drawbigcube, robot.position+vec3(0, 1, 0), vec3(12, 12, 12), "green")
utils.timeIt(drawbigcube, robot.position+vec3(-20, 1, 0), vec3(12, 12, 12), "red")
utils.timeIt(drawbigcube, robot.position+vec3(-20, 1, -20), vec3(12, 12, 12), "blue")
utils.timeIt(drawbigcube, robot.position+vec3(0, 1, -20), vec3(12, 12, 12), "yellow")
utils.timeIt(drawbigcube, robot.position+vec3(0, 20, -20), vec3(12, 12, 12), "pink")
utils.timeIt(drawbigcube, robot.position+vec3(-20, 20, -20), vec3(12, 12, 12), "aqua")
utils.timeIt(drawbigcube, robot.position+vec3(0, 20, 0), vec3(12, 12, 12), "darkGreen")
utils.timeIt(drawbigcube, robot.position+vec3(-20, 20, 0), vec3(12, 12, 12), "white") ]]

dbg.drawLine(robot.position, robot.position+vec3(0, 10, 20), nil, nil, 0.5)

--dbg.drawCube(robot.position+vec3(0, 0, -1), "red")
--dbg.drawCube(robot.position+vec3(0, 0, -2), dbg.color.red, 0.8)

utils.timeIt(dbg.commit)
print(utils.freeMemory())

--dbg.drawCube(vec3(72, 64, 840), dbg.color.red, 0.8)
--[[ local shape = glasses.addCustom3D()
shape.setGLMODE("TRIANGLE_STRIP")
shape.setShading("SMOOTH")

local color = dbg.color.red
--shape.addTranslation(vector.x, vector.y, vector.z)
shape.addColor(color[1], color[2], color[3], opacity)
shape.setVisibleThroughObjects(true)

while true do
    local EVENT, ID, USER, PLAYER_POSITION_X, PLAYER_POSITION_Y, PLAYER_POSITION_Z, 
		PLAYER_LOOKAT_X, PLAYER_LOOKAT_Y, PLAYER_LOOKAT_Z, PLAYER_EYE_HEIGHT, 
		BLOCK_POSITION_X, BLOCK_POSITION_Y, BLOCK_POSITION_Z, BLOCK_SIDE, 
        PLAYER_ROTATION, PLAYER_PITCH, PLAYER_FACING = event.pull("interact_world_block_right")
    print("Adding vertex:", BLOCK_POSITION_X, BLOCK_POSITION_Y, BLOCK_POSITION_Z)
    shape.addVertex(PLAYER_LOOKAT_X, PLAYER_LOOKAT_Y, PLAYER_LOOKAT_Z)
end ]]

