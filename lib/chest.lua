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
setmetatable(Chest, {__call = function(cls, positions, size)
    positions = utils.isInstance(positions, vec3) and {positions} or positions -- where the chest blocks are located in the world (this allows for multiblock storage)
    local self = Inventory(size or #positions * 27) -- amount of slots which the chest has defaults to 27 * number of blocks (standard minecraft chest)
    self.blocks = positions
    -- automatically add chest positions to blacklist
    for i = 1, #positions do
        blacklistMap[positions[i]] = true
    end
	setmetatable(self, cls)
	return self
end })

--[[ navigates to the chest position --]]
function Chest:goTo()
    nav.goTo(self.blocks, true)
end

--[[ returns on which side of the robot the chest is --]]
function Chest:relativeOrientation()
    local adjacentBlock = nav.adjacentBlock(robot.position, self.blocks)
    assert(adjacentBlock, "Robot is not adjacent to the chest")
    return nav.relativeOrientation(robot.position, adjacentBlock)
end

function Chest:put(itemOrIndex, amount)
    amount = amount or 1
    local side = self:relativeOrientation()
    local itemIndex
    local dropIndex
    if type(itemOrIndex) == "table" then -- itemOrIndex is an item
        local inspect = require("inspect")
        print(inspect(robot.inventory))
        itemIndex = robot.inventory:findIndex(itemOrIndex, 1)
        dropIndex = self:findIndex(item, 1)
    else -- itemOrIndex is an index
        itemIndex = itemOrIndex
        dropIndex = self:findIndex(robot.inventory.slots[itemOrIndex], 1)
    end
    assert(itemIndex, "Specified item not found in the robot inventory")
    dropIndex = dropIndex or self.inventory:emptySlot() -- default to first empty slot
    assert(dropIndex, "No space left in the chest for the specified item")

    local item = robot.inventory.slots[itemIndex]

    robot.select(itemIndex)
    local beforeSize = robot.count()
    invcontroller.dropIntoSlot(side, dropIndex, amount)
    local deltaSize = beforeSize - robot.count()

    if deltaSize > 0 then
        if self.inventory.slots[itemIndex] == nil then
            self.inventory.slots[itemIndex] = item
            self.inventory.slots[itemIndex].size = deltaSize
        else
            self.inventory.slots[itemIndex].size = self.inventory.slots[itemIndex].size + deltaSize
        end
    end
end

function Chest:retrieve(itemOrIndex, amount)

end

return Chest