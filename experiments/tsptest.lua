package.loaded.scanbatch = nil
package.loaded.navigation = nil
package.loaded.utils = nil
local nav = require("navigation")
local vec3 = require("vec3")
local ScanBatch = require("scanbatch")
local blockType = require("blocktype")
local inspect = require("inspect")
local utils = require("utils")
local event = require("event")
local robot = require("robot")
local VectorMap = require("vectormap")
local autoyielder = require("autoyielder")

local draw = false
local debug
if draw then
    debug = require("debug")
    debug.init()
    debug.clearWidgets()
end
--math.randomseed(0)

local ores = {}
local numores = 80
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

local tsppath, bestdist = table.unpack((utils.timeIt(nav.tspTwoOpt, nav.tspGreedy(ores, nil, nil, nav.heuristicEuclidean), maxDistNodeA, maxDistNodeB, nav.heuristicEuclidean)))
print("best distance new: ", bestdist)

local tsppathOld, bestdistOld = table.unpack((utils.timeIt(nav.tspTwoOptOld, nav.tspGreedy(ores, nil, nil, nav.heuristicEuclidean), maxDistNodeA, maxDistNodeB, nav.heuristicEuclidean)))
print("best distance old: ", bestdistOld)

--[[ for i = 1, #tsppath do
    assert(tsppath[i] == tsppathOld[i])
end ]]

if draw then
    debug.drawText(tsppath[1], 1, debug.color.green, 1)
    for i = 2, #tsppath - 1 do
        debug.drawText(tsppath[i], tostring(i), debug.color.darkRed, 1)
        autoyielder.yield()
    end
    debug.drawText(tsppath[#tsppath], #tsppath, debug.color.green, 1)

    for i = 2, #tsppath do
        debug.drawLineShape(tsppath[i-1], tsppath[i])
        autoyielder.yield()
    end
end

if maxDistNodeA ~= tsppath[1] then
    print("First nodes not equal")
end
if maxDistNodeB ~= tsppath[#tsppath] then
    print("Second nodes not equal")
end

