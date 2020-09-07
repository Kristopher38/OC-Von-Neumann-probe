local utils = require("utils")
local Inventory = require("inventory")
local nav = require("navigation")
local blacklistMap = require("blacklistmap")
local component = require("component")
local invcontroller = component.inventory_controller
local burntimes = require("burntimes")
local locTracker = require("locationtracker")
local invTracker = require("inventorytracker")
local robot = require("robot")
local Block = require("block")

local Furnace = utils.makeClass(function(self, position)
    self:__initBase(Block(position))
    self.lastInsert = {
        fuel = nil
        raw = nil
    }
    self.slots = {
        fuel = nil,
        raw = nil,
        smelted = nil
    }
    self:denyBreaking()
end)

Furnace.slotSides = {raw = sides.top, fuel = sides.front, smelted = sides.bottom}

--[[ estimates how much time is left to smelt specified amount of items, or all items if not specified --]]
function Furnace:timeLeft(amount)
    local elapsedTicks = (computer.uptime() - self.lastFuelInsert) * 20 -- 20 ticks per 1 second
    
end

function Furnace:put(itemOrIndex, amount, slotType)
    local amountTransfered = 0
    while amount > 0 do
        local index
        if type(itemOrIndex) == "table" then
            index = invTracker.inventory:findIndex(itemOrIndex, 1)
        elseif invTracker.inventory.slots[itemOrIndex] then
            index = itemOrIndex
        else
            break
        end

        local item = utils.deepCopy(invTracker.inventory.slots[index])
        if self:timeLeft() <= 0 or utils.compareItems(item, self.slots[slotType]) then
            robot.select(index)
            local beforeSize = robot.count()
            invcontroller.dropIntoSlot(self:relativeSide(), 1, amount, self.slotSides[slotType])
            local deltaSize = beforeSize - robot.count()
            amount = amount - deltaSize
            amountTransfered = amountTransfered + deltaSize

            self.lastInsert[slotType] = computer.uptime()
            self.slots[slotType] = item
        else
            break
        end
    end
    return amountTransfered
end

function Furnace:take(amount, slotType)
    local taken = invcontroller.suckFromSlot(self:relativeSide(), amount, self.slotSides[slotType])
    if taken > 0 then
        local slot = self.slots[slotType]
        slot.size = slot.size - taken
        if slot.size <= 0 then
            self.slots[slotType] = nil
        end
    end
    return taken
end

--[[ put fuel from robot inventory into the furnace --]]
function Furnace:putFuel(itemOrIndex, amount)
    return self:put(itemOrIndex, amount, "fuel")
end

function Furnace:putRaw(itemOrIndex, amount)
    return self:put(itemOrIndex, amount, "raw")
end

function Furnace:takeFuel(amount)
    return self:take(amount, "fuel")
end

function Furnace:takeRaw(amount)
    return self:take(amount, "raw")
end

function Furnace:takeSmelted(amount)
    return self:take(amount, "smelted")
end

return Furnace