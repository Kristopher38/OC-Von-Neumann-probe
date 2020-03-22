package.loaded.scanbatch = nil
package.loaded.navigation = nil
package.loaded.utils = nil
local nav = require("navigation")
local vec3 = require("vec3")
local debug = require("debug")
local ScanBatch = require("scanbatch")
local blockType = require("blocktype")
local inspect = require("inspect")
local utils = require("utils")
local event = require("event")
local robot = require("robot")
local VectorMap = require("vectormap")

debug.init()
debug.clearWidgets()

--[[ while true do
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

        local sum = vec3(0, 0, 0)
        local count = 0
        for coords, ore in sb:queryPairs(blockType.ore) do
            sum = sum + coords
            count = count + 1
        end
        local avg = vec3(sum.x / count, sum.y / count, sum.z / count)
        debug.clearWidgets()
        debug.drawCubeFloat(avg, debug.color.red, 1)
	end
end ]]


local ores = {}
local numores = 30
for i = 1, numores do
    table.insert(ores, vec3(math.random(55, 95), 73, math.random(800, 840)))
end 

local maxDist = 0
local maxDistNodeA
local maxDistNodeB
for i = 1, numores do
    for j = 1, numores do
        local dist = nav.heuristicEuclidean(ores[i], ores[j]) 
        if dist > maxDist then
            maxDist = dist
            maxDistNodeA = ores[i]
            maxDistNodeB = ores[j]
        end
    end
end

print("start: ", maxDistNodeA)
print("end: ", maxDistNodeB)

local tsppath = utils.timeIt(nav.tspGreedy, ores, maxDistNodeA, maxDistNodeB)
--tsppath = utils.timeIt(nav.tspTwoOpt, tsppath, vec3(58, 70, 813), vec3(83, 72, 812))
--print("best distance: ", bestdist)

debug.drawText(tsppath[1], 1, debug.color.green, 1)
for i = 2, #tsppath - 1 do
    debug.drawText(tsppath[i], tostring(i), debug.color.darkRed, 1)
    os.sleep(0)
end
debug.drawText(tsppath[#tsppath], #tsppath, debug.color.green, 1)

for i = 2, #tsppath do
    --print(i-1, "->", i, ": ", tsppath[i-1], tsppath[i])
    debug.drawLine(tsppath[i-1], tsppath[i])
end

if maxDistNodeA ~= tsppath[1] then
    print("First nodes not equal")
end
if maxDistNodeB ~= tsppath[#tsppath] then
    print("Second nodes not equal")
end

--debug.drawLine(tsppath[1], tsppath[#tsppath])
debug.commit()



--[[ utils.waitForInput()
tsppath = utils.timeIt(nav.tspTwoOpt, tsppath)
for i, node in ipairs(tsppath) do
    debug.drawText(node, tostring(i), debug.color.darkGreen, 1)
    os.sleep(0)
end ]]

