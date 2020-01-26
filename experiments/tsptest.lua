local nav = require("navigation")
local vec3 = require("vec3")
local debug = require("debug")
local ScanBatch = require("scanbatch")
local blockType = require("blocktype")
local inspect = require("inspect")
local utils = require("utils")
local event = require("event")
local robot = require("robot")

debug.clearWidgets()

while true do
	local EVENT, ID, USER, PLAYER_POSITION_X, PLAYER_POSITION_Y, PLAYER_POSITION_Z, 
		PLAYER_LOOKAT_X, PLAYER_LOOKAT_Y, PLAYER_LOOKAT_Z, PLAYER_EYE_HEIGHT, 
		BLOCK_POSITION_X, BLOCK_POSITION_Y, BLOCK_POSITION_Z, BLOCK_SIDE, 
		PLAYER_ROTATION, PLAYER_PITCH, PLAYER_FACING = event.pull("interact_world_block_%a+")
	local target = vec3(math.ceil(BLOCK_POSITION_X + robot.position.x), math.ceil(BLOCK_POSITION_Y + robot.position.y), math.ceil(BLOCK_POSITION_Z + robot.position.z))
	if target ~= robot.position then
        
        local sb = ScanBatch()

        sb:scanQuad(vec3(-2, 0, -2), vec3(4, 4, 4))
        sb:scanQuad(vec3(2, 0, -2), vec3(4, 4, 4))
        sb:scanQuad(vec3(-6, 0, -2), vec3(4, 4, 4))
        sb:scanQuad(vec3(6, 0, -2), vec3(4, 4, 4))

        local ores = sb:query(blockType.ore)
        local sum = vec3(0, 0, 0)
        for i, ore in ipairs(ores) do
            sum = sum + ore
        end
        local avg = vec3(sum.x / #ores, sum.y / #ores, sum.z / #ores)
        debug.clearWidgets()
        debug.drawCube(avg, debug.color.red, 1)
	end
end


--[[ local ores = {}
for i = 1, 50 do
    table.insert(ores, vec3(math.random(65, 85), math.random(64, 74), math.random(810, 830)))
end 

local tsppath = nav.tspGreedy(ores)
for i, node in ipairs(tsppath) do
    debug.drawText(node, tostring(i), debug.color.darkRed, 1)
    os.sleep(0)
end

utils.waitForInput()
tsppath = utils.timeIt(nav.tspTwoOpt, tsppath)
for i, node in ipairs(tsppath) do
    debug.drawText(node, tostring(i), debug.color.darkGreen, 1)
    os.sleep(0)
end ]]

