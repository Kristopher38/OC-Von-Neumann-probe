local sides = require("sides")
local component = require("component")
local filesystem = require("filesystem")
local serialization = require("serialization")
local robot = component.robot
local glasses = component.glasses
local gpu = component.gpu

-- workaround for not yet mounted magic filesystem with robot.lua
local apiRobot
-- search all filesystems for robot.lua
for fs in filesystem.list("/mnt") do
    local robotApiPath = filesystem.concat("/mnt", fs, "/lib/robot.lua")
    if filesystem.exists(robotApiPath) then
        -- if filesystem with robot.lua found, execute and cache it so other modules can use it
        apiRobot = dofile(robotApiPath)
        package.loaded.robot = apiRobot
        break
    end
end

local nav = require("navigation")
local vec3 = require("vec3")

local username = "Kristopher38"
local storageFilepath = "/usr/misc/location.txt"
local originalMove = robot.move
local originalTurn = robot.turn

local function customMove(side)
    local result, reason = originalMove(side)
    if result then
        local offsetVector = vec3(0, 0, 0)
        if side == sides.forward then
            offsetVector.x = 1
        elseif side == sides.back then
            offsetVector.x = -1
        elseif side == sides.up then
            offsetVector.y = 1
        elseif side == sides.down then
            offsetVector.y = -1
        end
        robot.position = nav.coordsFromOffset(robot.position, offsetVector, robot.orientation)
    end
    return result, reason
end

local function customTurn(clockwise)
    local result = originalTurn(clockwise)
    if result then
        local lookupClockwise = {[sides.north] = sides.east, [sides.east] = sides.south, [sides.south] = sides.west, [sides.west] = sides.north}
        local lookupAntiClockwise = {[sides.north] = sides.west, [sides.east] = sides.north, [sides.south] = sides.east, [sides.west] = sides.south}
        robot.orientation = clockwise and lookupClockwise[robot.orientation] or lookupAntiClockwise[robot.orientation]
    end
    return result
end

local function saveToFile(location, orientation, path)
    local data = {["location"] = location, ["orientation"] = orientation}
    local file = io.open(path, "w")
    file:write(serialization.serialize(data))
    file:close()
end

local function loadFromFile(path)
    local file = io.open(path, "r")
    local data = serialization.unserialize(file:read("*a"))
    file:close()
    return data[location], data[orientation]
end

function start()
    robot.move = customMove
    robot.turn = customTurn
    setmetatable(apiRobot, {__index = robot, __newindex = robot})

    local w, h = gpu.getResolution()
    gpu.fill(1, 1, w, h, " ")

    if component.isAvailable("glasses") then
        glasses.startLinking(username)
        local lookingAt = glasses.getUserLookingAt(username)
        local orientationString
        while sides[orientationString] == nil do
            io.stdout:write("Please enter robot's orientation in the following format: <facing: east|west|north|south>: ")
            orientationString = io.stdin:read()
        end

        robot.position = vec3(lookingAt.x, lookingAt.y, lookingAt.z)
        robot.orientation = sides[orientationString]
    else
        local location
        while location == nil or sides[location[4]] == nil do
            io.stdout:write("Please enter robot's coordinates and orientation in the following format: <x> <y> <z> <facing: east|west|north|south>: ")
            local locationString = io.stdin:read()
            location = {string.gmatch(locationString, "(%-?%d+) (%d+) (%-?%d+) (%a+)$")()}
        end
        
        robot.position = vec3(tonumber(location[1]), tonumber(location[2]), tonumber(location[3]))
        robot.orientation = sides[location[4]]
    end
end

function stop()
    robot.move = originalMove
    robot.turn = originalTurn
    setmetatable(apiRobot, nil)

    robot.position = nil
    robot.orientation = nil
end