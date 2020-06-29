local utils = require("utils")
local Inventory = require("inventory")
local nav = require("navigation")
local robot = require("robot")
local component = require("component")
local invcontroller = component.inventory_controller

local Chest = {}
Chest.__index = Chest
setmetatable(Chest, {__call = function(cls, positions, size)
    positions = type(positions) == "table" and positions or {positions} -- where the chest blocks are located in the world (this allows for multiblock storage)
    local self = Inventory(size or #positions * 27) -- amount of slots which the chest has defaults to 27 * number of blocks (standard minecraft chest)
    self.blocks = positions
	setmetatable(self, cls)
	return self
end })

--[[ navigates to the chest position --]]
function Chest:goTo()
    nav.goTo(self.blocks, true)
end

--[[ returns on which side of the robot the chest is --]]
function Chest:relativeSide()
    local adjacentBlock = nav.adjacentBlock(robot.position, self.blocks)
    assert(adjacentBlock, "Robot is not adjacent to the chest")
    return nav.relativeSide(robot.position, adjacentBlock)
end

function Chest:put(itemOrIndex, amount)
    local item
    local index
    if type(itemOrIndex) == "table" then
        item = itemOrIndex
    else
        index = itemOrIndex
    end
    amount = amount or 64
    local side = self:relativeSide()
end

function Chest:retrieve(itemOrIndex, amount)

end

return Chest