local event = require("event")
local component = require("component")
local hologram
local modem

if component.isAvailable("hologram") then
    hologram = component.hologram
else
    error("This script requires hologram to run")
end

if component.isAvailable("modem") and component.modem.isWireless() then
    modem = component.modem
else
    error("This script requires wireless network card")
end

local pattern = "Robot position: %[(%-?%d+), (%d+), (%-?%d+)%]"
modem.open(108)

local function msgHandler(ev, receiver, sender, port, dist, msg)
    local x, y, z = string.match(msg, pattern)
    if x and y and z then
    
    end
end

event.listen("modem_message", msgHandler)

while true do
    os.sleep()
end