local HookModule = require("hookmodule")
local component = require("component")
local sides = require("sides")
local vec3 = require("vec3")
local nav = require("navigation")
local robot = component.robot

local locTracker = HookModule()

function locTracker:start()
    robot.move = self:hook(robot.move, self.move)
    robot.turn = self:hook(robot.turn, self.turn)

    if component.isAvailable("glasses") then
        component.glasses.startLinking(username)
        local lookingAt = component.glasses.getUserLookingAt(username)
        local orientationString
        while sides[orientationString] == nil do
            io.stdout:write("\nPlease enter robot's orientation in the following format: <facing: east|west|north|south>: ")
            orientationString = io.stdin:read()
        end

        locTracker.position = vec3(lookingAt.x, lookingAt.y, lookingAt.z)
        locTracker.orientation = sides[orientationString]
    else
        local location
        while location == nil or sides[location[4]] == nil do
            io.stdout:write("\nPlease enter robot's coordinates and orientation in the following format: <x> <y> <z> <facing: east|west|north|south>: ")
            local locationString = io.stdin:read()
            location = {string.gmatch(locationString, "(%-?%d+) (%d+) (%-?%d+) (%a+)$")()}
        end
        
        locTracker.position = vec3(tonumber(location[1]), tonumber(location[2]), tonumber(location[3]))
        locTracker.orientation = sides[location[4]]
    end

    return self
end

function locTracker:stop()
    robot.move = self:unhook(self.move)
    robot.turn = self:unhook(self.turn)

    return self
end

function locTracker.move(side)
    local result, reason = locTracker:callOriginal(locTracker.move, side)
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
        locTracker.position = nav.coordsFromOffset(locTracker.position, offsetVector, locTracker.orientation)
    end
    return result, reason
end

local lookupClockwise = {[sides.north] = sides.east, [sides.east] = sides.south, [sides.south] = sides.west, [sides.west] = sides.north}
local lookupAntiClockwise = {[sides.north] = sides.west, [sides.east] = sides.north, [sides.south] = sides.east, [sides.west] = sides.south}
function locTracker.turn(clockwise)
    local result = locTracker:callOriginal(locTracker.turn, clockwise)
    if result then
        locTracker.orientation = clockwise and lookupClockwise[locTracker.orientation] or lookupAntiClockwise[locTracker.orientation]
    end
    return result
end

return locTracker:start()