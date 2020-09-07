local utils = require("utils")
local blacklistMap = require("blacklistmap")
local navigation = require("navigation")
local vec3 = require("vec3")
local locTracker= require("locationtracker")

local Charger = utils.makeClass(function(self, position)
    local position = position
    blacklistMap[position] = true
end)

function Charger:goTo()
    navigation.goTo(navigation.coordsFromOffset(self.position, vec3(0, 1, 0)))
end

function Charger:isOn()
    if locTracker.position == navigation.coordFromOffset(self.position, vec3(0, 1, 0)) then
        local energy = computer.energy()
        os.sleep(0.5)
        return computer.energy() - energy > 0
    else
        error("Robot is not above the charger")
    end
end

function Charger:charge(targetCharge, eps)
    if self:isOn() then
        targetCharge = targetCharge or 1.0
        eps = eps or 0.001
        local currentCharge = computer.energy() / computer.maxEnergy()
        while currentCharge < targetCharge - eps do
            os.sleep(0.5)
            currentCharge = computer.energy() / computer.maxEnergy()
        end
    end
end

return Charger