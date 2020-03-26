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

local tsppath = utils.timeIt(nav.shortestTour, ores, maxDistNodeA, maxDistNodeB)
--tsppath = utils.timeIt(nav.tspTwoOpt, tsppath, vec3(58, 70, 813), vec3(83, 72, 812))
--print("best distance: ", bestdist)

debug.drawText(tsppath[1], 1, debug.color.green, 1)
for i = 2, #tsppath - 1 do
    debug.drawText(tsppath[i], tostring(i), debug.color.darkRed, 1)
    os.sleep(0)
end
debug.drawText(tsppath[#tsppath], #tsppath, debug.color.green, 1)

for i = 2, #tsppath do
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

