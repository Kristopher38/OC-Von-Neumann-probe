local utils = require("utils")
local Inventory = require("inventory")
local nav = require("navigation")
local blacklistMap = require("blacklistmap")
local component = require("component")
local invcontroller = component.inventory_controller

local Furnace = utils.makeClass(function(position) 
    local self = {}
    self.position = position
    self.lastFuelInsert = computer.uptime()
    self.fuelSlot = nil
    self.rawSlot = nil
    self.smeltedSlot = nil

    blacklistMap[position] = true
    return self
end)

--[[ go to the side which can access fuel port --]]
function Furnace:goToFuel()
    -- go to the closest out of all 4 sides
    local sideBlocks = {
        self.position + vec3(1, 0, 0),
        self.position + vec3(-1, 0, 0),
        self.position + vec3(0, 0, 1),
        self.position + vec3(0, 0, -1)
    }
    nav.goTo(sideBlocks)
    nav.faceBlock(self.position)
end

--[[ go to the side which can access raw materials input port --]] 
function Furnace:goToRaw()
    nav.goTo(self.position + vec3(0, 1, 0), true)
end

--[[ go to the side which can access smelted materials output port --]]
function Furnace:goToSmelted()
    nav.goTo(self.position + vec3(0, -1, 0), true)
end

function Furnace:isCorrectlyPositioned(side)
    return nav.areBlocksAdjacent(robot.position, self.position) and 
           nav.relativeOrientation(robot.position, self.position) == side
end

--[[ put fuel from robot inventory into the furnace ]]
function Furnace:refuel(itemOrIndex, amount)
    -- fuel ports are on 4 furnace sides, so it needs to be in front of the robot
    if self:isCorrectlyPositioned(sides.front) then
        local index
        if type(itemOrIndex) == "table" then
            index = robot.inventory:findIndex(itemOrIndex, 1)
        else
            index = itemOrIndex
        end

        robot.select(index)
        local beforeSize = robot.count()
        invcontroller.dropIntoSlot(sides.front, 1, amount)
        local deltaSize = beforeSize - robot.count()

        self.lastFuelInsert = computer.uptime()
    end
end

function Furnace:putRaw(itemOrIndex, amount)

end

function Furnace:takeSmelted(index)

end

function Furnace:timeLeft()

end

return Furnace