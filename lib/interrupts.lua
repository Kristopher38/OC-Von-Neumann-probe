local nav = require("navigation")
local locTracker = require("locationtracker")

local interrupts = {
    lowFuel = {
        name = "Low fuel",
        priority = 1,
    },
    lowEnergy = {
        name = "Low energy",
        priority = 2,
    },
    fullInventory = {
        name = "Full inventory",
        priority = 3,
    },
    smeltingFinished = {
        name = "Smelting finished",
        priority = 4,
    },
    cropCheck = {
        name = "Crop growth check",
        priority = 5,
    }
}

function interrupts.lowFuel.checkFunc()
    -- calculate worst case scenario where we would need 
    local distance = nav.heuristicManhattan(locTracker.position, --[[ charger position here ]])
    local energySafeReturn = distance * 35.4
    -- 15 (movement cost) + 2.5 (turn cost) + 0.05 (swing cost) + 21 * (0.25 + 0.6) ((8 ticks turning + 8 ticks moving + 5 ticks breaking a block) * (base robot running cost + active chunkloader cost))
    if computer.energy() < energySafeReturn then
        return interrupts.lowFuel.name, --[[ function for returning to the charger ]], interrupts.lowFuel.priority
    end
end

return interrupts