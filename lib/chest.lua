local utils = require("utils")
local Inventory = require("inventory")
local nav = require("navigation")
local robot = require("robot")
local locTracker = require("locationtracker")
local invTracker = require("inventorytracker")
local component = require("component")
local blacklistMap = require("blacklistmap")
local utils = require("utils")
local vec3 = require("vec3")
local Block = require("block")
local invcontroller = component.inventory_controller

local Chest = utils.makeClass(function(self, positions, size)
    -- amount of slots which the chest has defaults to 27 * number of blocks (standard minecraft chest)
    size = size or utils.isInstance(positions, vec3) and 27 or #positions * 27
    self:__initBase(Inventory(size), Block(positions))
    -- automatically add chest positions to blacklist
    self:denyBreaking()
end)

--[[ fully refreshes the internal in-memory cache of chest size and contents ]]
function Chest:refresh()
    local i = 0
    for item in invcontroller.getAllStacks(self:relativeSide()) do
        i = i + 1
        if next(item) ~= nil then
            self.slots[i] = item
        end
    end
    self.size = i
end

--[[ Puts items in the chest, provided that the robot is adjacent to it, specifying either slot index
of the robot inventory, or item table. Amount, when the item is specified using item table
can be in range from 1 to +inf, but the real upper limit is the actual amount of items of specified type
in the robot inventory. This method will transfer items from different slots if an item When the item is specified
using item table. When the item is specified using slot index, the range is from 1 to the max stack size of
an item, and only items from that slot index will be transfered. Amount can also be specified by using the 'size'
field in an item table, but is overriden if the 'amount' argument is set, and if none are set, 'amount'
defaults to 1. Returns the amount of items transfered ]]
function Chest:put(itemOrIndex, amount)
    amount = amount or ((type(itemOrIndex) == "table" and itemOrIndex.size ~= nil) and itemOrIndex.size or 1)
    local amountTransfered = 0
    while amount > 0 do
        local itemIndex
        local targetIndex
        if type(itemOrIndex) == "table" then -- itemOrIndex is an item
            itemIndex = invTracker.inventory:findIndex(itemOrIndex, 1)
            targetIndex = self:findIndex(itemOrIndex, 1, true)
        elseif invTracker.inventory.slots[itemOrIndex] then -- itemOrIndex is valid index
            itemIndex = itemOrIndex
            targetIndex = self:findIndex(invTracker.inventory.slots[itemOrIndex], 1, true)
            -- when supplying index, take either maximum possible amount if amount > size, or specified amount if amount < size
            amount = math.min(invTracker.inventory.slots[itemIndex].size, amount)
        else
            -- if itemOrIndex is not an item and not a valid slot, break and return
            break
        end
        targetIndex = targetIndex or self:emptySlot() -- take first empty slot if no already present item found or slot is full

        if itemIndex and targetIndex then
            robot.select(itemIndex)
            local beforeSize = robot.count()
            invcontroller.dropIntoSlot(self:relativeSide(), targetIndex, amount)
            local deltaSize = beforeSize - robot.count()
            amount = amount - deltaSize
            amountTransfered = amountTransfered + deltaSize

            if deltaSize > 0 then
                if self.slots[targetIndex] == nil then
                    self.slots[targetIndex] = utils.deepCopy(invTracker.inventory.slots[itemIndex])
                    self.slots[targetIndex].size = deltaSize
                else
                    self.slots[targetIndex].size = self.slots[targetIndex].size + deltaSize
                end
            end
        else
            -- if itemIndex is nil, that means we didn't find a specified item in the robot inventory or index is out of bounds so we break and return
            -- if targetIndex is nil, that means there weren't any suitable or free slots left for an item so we break and return
            break
        end
    end
    return amountTransfered
end

--[[ Takes items from the chest, provided that the robot is adjacent to it, specifying either slot index
of the chest inventory, or item table. Amount, when the item is specified using item table
can be in range from 1 to +inf, but the real upper limit is the actual amount of items of specified type
in the chest inventory. This method will transfer items from different slots if an item When the item is specified
using item table. When the item is specified using slot index, the range is from 1 to the max stack size of
an item, and only items from that slot index will be transfered. Amount can also be specified by using the 'size'
field in an item table, but is overriden if the 'amount' argument is set, and if none are set, 'amount'
defaults to 1. Returns the amount of items transfered ]]
function Chest:take(itemOrIndex, amount)
    amount = amount or ((type(itemOrIndex) == "table" and itemOrIndex.size ~= nil) and itemOrIndex.size or 1)
    local amountTransfered = 0
    while amount > 0 do
        local itemIndex
        local targetIndex
        if type(itemOrIndex) == "table" then -- itemOrIndex is an item
            itemIndex = self:findIndex(itemOrIndex, 1)
            targetIndex = invTracker.inventory:findIndex(itemOrIndex, 1, true)
        elseif self.slots[itemOrIndex] then -- itemOrIndex is a valid index
            itemIndex = itemOrIndex
            targetIndex = invTracker.inventory:findIndex(self.slots[itemOrIndex], 1, true)
            -- when supplying index, take either maximum possible amount if amount > size, or specified amount if amount < size
            amount = math.min(self.slots[itemIndex].size, amount)
        else
            -- if itemOrIndex is not an item and not a valid slot, break and return
            break
        end
        targetIndex = targetIndex or invTracker.inventory:emptySlot()

        if itemIndex and targetIndex then
            local item = self.slots[itemIndex]
            robot.select(targetIndex)
            local beforeSize = invTracker.inventory:count(item)
            invcontroller.suckFromSlot(self:relativeSide(), itemIndex, amount)
            local deltaSize = invTracker.inventory:count(item) - beforeSize
            amount = amount - deltaSize
            amountTransfered = amountTransfered + deltaSize
            
            item.size = item.size - deltaSize
            if item.size <= 0 then
                self.slots[itemIndex] = nil
            end
        else
            -- if itemIndex is nil, that means we didn't find a specified item in chest's inventory or the index is out of bounds so we break and return
            -- if targetIndex is nil, that means we didn't fin a suitable or free slots in robot's inventory so we break and return
            break
        end
    end
    return amountTransfered
end

return Chest