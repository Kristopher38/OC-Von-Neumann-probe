package.loaded.debug = nil
local dbg = require("debug")
local vec3 = require("vec3")
local robot = require("robot")
local component = require("component")
local glasses = component.glasses
local event = require("event")
local navigation = require("navigation")
local utils = require("utils")

dbg.init()
dbg.clearWidgets()

local function expand(toExpand, level)
    if level == 0 then return end

    dbg.drawCube(toExpand, dbg.color.red, 0.8)
    for i, node in pairs(navigation.neighbours(toExpand)) do
        expand(node, level - 1)
    end
end

utils.timeIt(expand, robot.position+vec3(0, 6, 0), 5)


--dbg.drawCube(robot.position+vec3(0, 0, -1), dbg.color.red, 0.8)
--dbg.drawCube(robot.position+vec3(0, 0, -2), dbg.color.red, 0.8)

dbg.commit()

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

