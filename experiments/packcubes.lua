package.loaded.debug = nil
local vec3 = require("vec3")
local debug = require("debug")
local robot = require("robot")
local utils = require("utils")
local event = require("event")

debug.init()
debug.clearWidgets()

--[[ finds a vector which x, y, z components define dimensions of a cuboid which is (almost) the most optimal one
to fill another larger cuboid sizeVector with cuboids of that size --]]
local function packCubes(sizeVector)
    local minCubes = math.ceil(sizeVector.x / 4) * math.ceil(sizeVector.y / 4) * math.ceil(sizeVector.z / 4)
    local solution = vec3(4, 4, 4)
    for x = 1, math.min(sizeVector.x, 64) do
        for y = 1, math.min(sizeVector.y, 64 // x) do
            local z = 64 // (x * y)
            local numCubes = math.ceil(sizeVector.x / x) * math.ceil(sizeVector.y / y) * math.ceil(sizeVector.z / z)
            if numCubes < minCubes then
                minCubes = numCubes
                solution.x = x
                solution.y = y
                solution.z = z
            end
        end
    end

    return solution, minCubes
end

local args = {...}
args[1] = args[1] or 10
args[2] = args[2] or 10
args[3] = args[3] or 10
for i = 1, #args do
    args[i] = tonumber(args[i])
end

local problem = vec3(args[1], args[2], args[3])
local solution = packCubes(problem)
local offset = robot.position + vec3(1, 1, 1)
print(solution)

local function drawCubeOutline(startVector, sizeVector, color)
    for x = 0, sizeVector.x - 1 do
        debug.drawCubeShape(startVector + vec3(x, 0, 0), color)
        debug.drawCubeShape(startVector + vec3(x, sizeVector.y - 1, 0), color)
        debug.drawCubeShape(startVector + vec3(x, 0, sizeVector.z - 1), color)
        debug.drawCubeShape(startVector + vec3(x, sizeVector.y - 1, sizeVector.z - 1), color)
    end
    for y = 0, sizeVector.y - 1 do
        debug.drawCubeShape(startVector + vec3(0, y, 0), color)
        debug.drawCubeShape(startVector + vec3(sizeVector.x - 1, y, 0), color)
        debug.drawCubeShape(startVector + vec3(0, y, sizeVector.z - 1), color)
        debug.drawCubeShape(startVector + vec3(sizeVector.x - 1, y, sizeVector.z - 1), color)
    end
    for z = 0, sizeVector.z - 1 do
        debug.drawCubeShape(startVector + vec3(0, 0, z), color)
        debug.drawCubeShape(startVector + vec3(sizeVector.x - 1, 0, z), color)
        debug.drawCubeShape(startVector + vec3(0, sizeVector.y - 1, z), color)
        debug.drawCubeShape(startVector + vec3(sizeVector.x - 1, sizeVector.y - 1, z), color)
    end
end

local function drawBigCube(startVector, sizeVector, color)
    for x = 0, sizeVector.x - 1 do
        for y = 0, sizeVector.y - 1 do
            for z = 0, sizeVector.z - 1 do
                debug.drawCubeShape(startVector + vec3(x, y, z), color)
            end
        end
    end
end

drawCubeOutline(offset, problem, debug.color.red)
debug.commit()
--print("done drawing")
os.sleep(1)
--event.pull("interact_world_block_right")

--debug.clearWidgets()

for x = 0, math.ceil(problem.x / solution.x) - 1 do
    for y = 0, math.ceil(problem.y / solution.y) - 1 do
        for z = 0, math.ceil(problem.z / solution.z) - 1 do
            local pos = vec3(x * (solution.x), y * (solution.y), z * (solution.z))
            local overflow = pos + solution - problem
            overflow.x = math.max(0, overflow.x)
            overflow.y = math.max(0, overflow.y)
            overflow.z = math.max(0, overflow.z)
            local truncated = utils.deepCopy(solution) - overflow
            drawBigCube(pos + offset, truncated, debug.color.blue)
            debug.commit()
            os.sleep(0.1)
            --event.pull("interact_world_block_right")
        end
    end
end