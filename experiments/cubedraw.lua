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

utils.freeMemory()
dbg.init()
dbg.clearWidgets()

local expanded = VectorMap()

local function expand(toExpand, level)
    if level == 0 then return end
    autoYield()
    dbg.drawCube(toExpand, dbg.color.red)
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
                dbg.drawCubeShape(baseOffset+vec3(x, y, z), color)
            end
        end
    end
end

--expand(robot.position+vec3(0, 6, 0), 3)
--dbg.drawLineShape(robot.position, robot.position+vec3(0, 10, 20), nil, nil, 0.5)

utils.timeIt(drawbigcube, robot.position+vec3(0, 1, 0), vec3(12, 12, 12), dbg.color.green)
utils.timeIt(drawbigcube, robot.position+vec3(-20, 1, 0), vec3(12, 12, 12), dbg.color.red)
utils.timeIt(drawbigcube, robot.position+vec3(-20, 1, -20), vec3(12, 12, 12), dbg.color.blue)
utils.timeIt(drawbigcube, robot.position+vec3(0, 1, -20), vec3(12, 12, 12), dbg.color.yellow)
utils.timeIt(drawbigcube, robot.position+vec3(0, 20, -20), vec3(12, 12, 12), dbg.color.pink)
utils.timeIt(drawbigcube, robot.position+vec3(-20, 20, -20), vec3(12, 12, 12), dbg.color.aqua)
utils.timeIt(drawbigcube, robot.position+vec3(0, 20, 0), vec3(12, 12, 12), dbg.color.darkGreen)
utils.timeIt(drawbigcube, robot.position+vec3(-20, 20, 0), vec3(12, 12, 12), dbg.color.white)

utils.timeIt(dbg.commit)
print(utils.freeMemory())
