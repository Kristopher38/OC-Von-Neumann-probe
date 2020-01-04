local robot = require("robot")
local event = require("event")
local keyboard = require("keyboard")

local exit = false
while not exit do
    local event, keyboardAddress, char, code, playerName = event.pull("key_down")
    
    if code == keyboard.keys.c and keyboard.isControlDown() then
        exit = true
    elseif code == keyboard.keys.w then
        robot.forward()
    elseif code == keyboard.keys.s then
        robot.back()
    elseif code == keyboard.keys.a then
        robot.turnLeft()
    elseif code == keyboard.keys.d then
        robot.turnRight()
    elseif code == keyboard.keys.f then
        robot.up()
    elseif code == keyboard.keys.c then
        robot.down()
    end
end