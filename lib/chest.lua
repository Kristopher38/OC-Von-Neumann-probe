local utils = require("utils")
local Inventory = require("inventory")
local nav = require("navigation")
local robot = require("robot")
local component = require("component")
local blacklistMap = require("blacklistmap")
local utils = require("utils")
local vec3 = require("vec3")
local invcontroller = component.inventory_controller

local Chest = {}
Chest.__index = Chest
setmetatable(Chest, {__index = Inventory, __call = function(cls, positions, size)
    positions = utils.isInstance(positions, vec3) and {positions} or positions -- where the chest blocks are located in the world (this allows for multiblock storage)
    local self = Inventory(size or #positions * 27) -- amount of slots which the chest has defaults to 27 * number of blocks (standard minecraft chest)
    self.positions = positions
    -- automatically add chest positions to blacklist
    for i = 1, #positions do
        blacklistMap[positions[i]] = true
    end
	setmetatable(self, cls)
	return self
end })

--[[ navigates to the chest position --]]
function Chest:goTo()
    nav.goTo(self.positions, true)
end

--[[ returns on which side of the robot the chest is --]]
function Chest:relativeOrientation()
    local adjacentBlock = nav.adjacentBlock(robot.position, self.positions)
    assert(adjacentBlock, "Robot is not adjacent to the chest")
    return nav.relativeOrientation(robot.position, adjacentBlock)
end

function Chest:refresh()
    local side = self:relativeOrientation()
    self.size = invcontroller.getInventorySize(side)

    for i = 1, self.size do
        self.slots[i] = invcontroller.getStackInSlot(side, i)
    end
end

function Chest:put(itemOrIndex, amount)
    amount = amount or 1
    local amountLeft = amount
    local side = self:relativeOrientation()
    while amountLeft > 0 do
        local itemIndex
        local targetIndex
        if type(itemOrIndex) == "table" then -- itemOrIndex is an item
            itemIndex = robot.inventory:findIndex(itemOrIndex, 1)
            targetIndex = self:findIndex(itemOrIndex, 1, true)
        elseif robot.inventory.slots[itemOrIndex] then -- itemOrIndex is valid index
            itemIndex = itemOrIndex
            targetIndex = self:findIndex(robot.inventory.slots[itemOrIndex], 1, true)
            -- when supplying index, take either maximum possible amount if amount > size, or specified amount if amount < size
            amount = math.min(robot.inventory.slots[itemIndex].size, amount)
            amountLeft = amount
        else
            -- if itemOrIndex is not an item and not a valid slot, break and return
            break
        end
        targetIndex = targetIndex or self:emptySlot() -- take first empty slot if no already present item found or slot is full

        if itemIndex and targetIndex then
            local item = robot.inventory.slots[itemIndex]
            robot.select(itemIndex)
            local beforeSize = robot.count()
            invcontroller.dropIntoSlot(side, targetIndex, amountLeft)
            local deltaSize = beforeSize - robot.count()
            amountLeft = amountLeft - deltaSize

            if deltaSize > 0 then
                if self.slots[targetIndex] == nil then
                    self.slots[targetIndex] = item
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
    return amount - amountLeft
end

function Chest:take(itemOrIndex, amount)
    amount = amount or 1
    local amountLeft = amount
    local side = self:relativeOrientation()
    while amountLeft > 0 do
        local itemIndex
        local targetIndex
        if type(itemOrIndex) == "table" then -- itemOrIndex is an item
            itemIndex = self:findIndex(itemOrIndex, 1)
            targetIndex = robot.inventory:findIndex(itemOrIndex, 1, true)
        elseif self.slots[itemOrIndex] then -- itemOrIndex is a valid index
            itemIndex = itemOrIndex
            targetIndex = robot.inventory:findIndex(self.slots[itemOrIndex], 1, true)
            -- when supplying index, take either maximum possible amount if amount > size, or specified amount if amount < size
            amount = math.min(self.slots[itemIndex].size, amount)
            amountLeft = amount
        else
            -- if itemOrIndex is not an item and not a valid slot, break and return
            break
        end
        targetIndex = targetIndex or robot.inventory:emptySlot()

        if itemIndex and targetIndex then
            local item = self.slots[itemIndex]
            robot.select(targetIndex)
            local beforeSize = robot.inventory:count(item)
            invcontroller.suckFromSlot(side, itemIndex, amountLeft)
            local deltaSize = robot.inventory:count(item) - beforeSize
            amountLeft = amountLeft - deltaSize

            item.size = item.size - deltaSize
            if item.size <= 0 then
                self.slots[itemIndex] = nil
            end
        else
            -- if itemIndex is nil, that means we didn't find a specified item in chest's inventory or the index is out of bounds so we break and return
            -- if targetIndex is nil, that means we didn't fin a suitable or free slots in robot's inventory so we break and return
            -- if self.slots[itemIndex] is nil, that means chest's is empty (happens when the user supplies index) so we break and return
            break
        end
    end
    return amount - amountLeft
end

return Chest