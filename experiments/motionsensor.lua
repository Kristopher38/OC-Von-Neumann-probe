local component = require("component")
local motion_sensor = component.motion_sensor
local debug = require("debug")
local vec3 = require("vec3")
local event = require("event")
local robot = require("robot")
local ScanBatch = require("scanbatch")
local navigation = require("navigation")
local keyboard = require("keyboard")
local computer = require("computer")

local sc = ScanBatch()
for i = -1, 2 do
    sc:scanLayer(i)
end

debug.init()
debug.clearWidgets()

local exit = false
local x, y, z, name
local new = false

local function motionCallback(ev, id, _x, _y, _z, _name)
    x = robot.position.x + _x
    y = robot.position.y + _y
    z = robot.position.z + _z
    name = _name
    new = true
end

local function keydownCallback(ev, id, char, code, playerName)
    if code == keyboard.keys.c and keyboard.isControlDown() then
        exit = true
    end
end

event.listen("key_down", keydownCallback)
event.listen("motion", motionCallback)

while not exit do
    if new then
        new = false
        local cubeCoords = vec3(tonumber(x), tonumber(y), tonumber(z)) + vec3(0.5, 1, 0.5)
        debug.drawCube(cubeCoords, debug.color.red)
        local roundedVec = cubeCoords:round()
        navigation.goTo(roundedVec, true)
        robot.swing()
    end
    event.pull(0.2)
end

event.ignore("motion", motionCallback)
event.ignore("key_down", keydownCallback)

