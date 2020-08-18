local HookModule = require("hookmodule")
local component = require("component")
local sides = require("sides")
local vec3 = require("vec3")
local robot

local locTracker = HookModule("locationtracker")

function locTracker:start()
    if component.isAvailable("robot") then
        robot = component.robot
    else
        error("This library requires to be run on a robot")
    end

    robot.move = self:hook(robot.move, self.move)
    robot.turn = self:hook(robot.turn, self.turn)

    local success
    local users
    if component.isAvailable("glasses") then
        success, users = component.glasses.startLinking()
    end

    if success then
        if #users == 0 then
            local connectedUsers = component.glasses.getConnectedPlayers()
            for i = 1, #connectedUsers do
                users[i] = connectedUsers[i][1]
            end
        end

        local username
        if #users == 1 then
            username = users[1]
        else
            io.stdout:write("\nPlease enter your username: ")
            username = io.stdin:read()
        end
        local lookingAt = component.glasses.getUserLookingAt(username)
        local orientationString
        while sides[orientationString] == nil do
            io.stdout:write("\nPlease enter robot's orientation in the following format: <facing: east|west|north|south>: ")
            orientationString = io.stdin:read()
        end

        locTracker.position = vec3(lookingAt.x, lookingAt.y, lookingAt.z)
        locTracker.orientation = sides[orientationString]
    else -- glasses not available or couldn't link with glasses
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
        if side == sides.forward or side == sides.back then
            local offset = side == sides.forward and 1 or -1
            if locTracker.orientation == sides.posz then
                locTracker.position.z = locTracker.position.z + offset
            elseif locTracker.orientation == sides.negz then
                locTracker.position.z = locTracker.position.z - offset
            elseif locTracker.orientation == sides.posx then
                locTracker.position.x = locTracker.position.x + offset
            else
                locTracker.position.x = locTracker.position.x - offset
            end
        elseif side == sides.up then
            locTracker.position.y = locTracker.position.y + 1
        else
            locTracker.position.y = locTracker.position.y - 1
        end
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