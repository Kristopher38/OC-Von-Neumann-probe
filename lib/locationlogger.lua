local HookModule = require("hookmodule")
local component = require("component")
local robot
local locTracker = require("locationtracker")
local handlers = require("logHandlers")
local logging = require("logging")
local log = logging:getLogger("location")
log:setLevel(logging.DEBUG)
log:addHandler(handlers.HttpHandler(logging.DEBUG, "http://93.181.131.201:8080"))

local locLogger = HookModule("locationlogger")

function locLogger:start()
    if component.isAvailable("robot") then
        robot = component.robot
    else
        error("This library requires to be run on a robot")
    end

    robot.move = self:hook(robot.move, locLogger.move)
    return self
end

function locLogger:stop()
    robot.move = self:unhook(robot.move)
    return self
end

function locLogger.move(side)
    local result, reason = locLogger:callOriginal(locLogger.move, side)
    log:info("Robot position: %s", locTracker.position)
    return result, reason
end

return locLogger:start()