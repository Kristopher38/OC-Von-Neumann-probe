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
        local dropIndex
        if type(itemOrIndex) == "table" then -- itemOrIndex is an item
            itemIndex = robot.inventory:findIndex(itemOrIndex, 1)
            dropIndex = self:findIndex(itemOrIndex, 1, true)
        else -- itemOrIndex is an index
            itemIndex = itemOrIndex
            dropIndex = self:findIndex(robot.inventory.slots[itemOrIndex], 1, true)
        end
        dropIndex = dropIndex or self:emptySlot() -- take first empty slot if no already present item found or slot is full
        if not itemIndex or not dropIndex then
            break
        end

        local item = robot.inventory.slots[itemIndex]
        robot.select(itemIndex)
        local beforeSize = robot.count()
        invcontroller.dropIntoSlot(side, dropIndex, amountLeft)
        local deltaSize = beforeSize - robot.count()
        amountLeft = amountLeft - deltaSize

        if deltaSize > 0 then
            if self.slots[dropIndex] == nil then
                self.slots[dropIndex] = item
                self.slots[dropIndex].size = deltaSize
            else
                self.slots[dropIndex].size = self.slots[dropIndex].size + deltaSize
            end
        end
    end
    return amount - amountLeft
end

function Chest:take(itemOrIndex, amount)

end

return Chest