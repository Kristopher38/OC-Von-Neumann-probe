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
local sides = require("sides")
local computer = require("computer")

local Furnace = utils.makeClass(function(self, position)
    self:__initBase(Block(position))
    self.lastInsert = computer.uptime()
    self.lastUpdate = computer.uptime()
    self.smeltingTicksLeft = 0
    self.fuelTicksLeft = 0
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
    return 0
end

function Furnace:updateProgress()
    local deltaTicks = (computer.uptime() - (self.lastInsert > self.lastUpdate and self.lastInsert or self.lastUpdate)) * 20 -- 20 ticks per 1 second
    self.fuel.size = self.fuel.size - deltaTicks // burntimes[self.fuel.name]
    if self.fuel.size <= 0 then
        self.fuel = nil
    end
    self.raw.size = self.raw.size - deltaTicks // 200 -- smelting one item takes 200 ticks
    if self.raw.size <= 0 then
        self.raw = nil
    end
    if not self.smelted then
        self.smelted = {
            size = 0
        }
    end
    self.smelted.size = self.smelted.size + deltaTicks // 200
end

function Furnace:put(itemOrIndex, amount, slotType)
    amount = amount or ((type(itemOrIndex) == "table" and itemOrIndex.size ~= nil) and itemOrIndex.size or 1)
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

        if index then
            local item = utils.deepCopy(invTracker.inventory.slots[index])
            if self:timeLeft() <= 0 or utils.compareItems(item, self.slots[slotType]) then
                robot.select(index)
                local beforeSize = robot.count()
                invcontroller.dropIntoSlot(self:relativeSide(), 1, amount, self.slotSides[slotType])
                local deltaSize = beforeSize - robot.count()
                amount = amount - deltaSize
                amountTransfered = amountTransfered + deltaSize

                self.lastInsert = computer.uptime()
                self.slots[slotType] = item
            else
                break
            end
        else
            break
        end
    end
    return amountTransfered
end

function Furnace:take(amount, slotType)
    amount = amount or ((type(itemOrIndex) == "table" and itemOrIndex.size ~= nil) and itemOrIndex.size or 1)
    local taken = invcontroller.suckFromSlot(self:relativeSide(), 1, amount, self.slotSides[slotType])
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