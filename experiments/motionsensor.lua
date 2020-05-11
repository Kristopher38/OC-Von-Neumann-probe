local component = require("component")
local motion_sensor = component.motion_sensor
local debug = require("debug")
local vec3 = require("vec3")
local event = require("event")
local robot = require("robot")

debug.init()
debug.clearWidgets()

while true do
    local _, _, x, y, z, name = event.pull("motion")
    local cubeCoords = robot.position + vec3(tonumber(x), tonumber(y), tonumber(z)) + vec3(0.5, 1, 0.5)
    debug.drawCube(cubeCoords, debug.color.red)
end