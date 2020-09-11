local utils = require("utils")
local nav = require("navigation")
local locTracker = require("locationtracker")
local blacklistMap = require("blacklistmap")
local vec3 = require("vec3")

local Block = utils.makeClass(function(self, position)
    self.position = position -- can be either a vec3 or a table of vec3s, allows for multiblock blocks
end)

function Block:goTo()
    nav.goTo(self.position)
end

function Block:relativeSide()
    local adjacentBlock = utils.isInstance(self.position, vec3) and self.position or nav.adjacentBlock(locTracker.position, self.position)
    assert(adjacentBlock, "Robot is not adjacent to a block")
    return nav.relativeSide(locTracker.position, adjacentBlock)
end

function Block:setBreaking(bool)
    if utils.isInstance(self.position, vec3) then
        blacklistMap[self.position] = not bool
    else
        for i = 1, #self.position do
            blacklistMap[self.position[i]] = not bool
        end
    end
end

function Block:denyBreaking()
    self:setBreaking(false)
end

function Block:allowBreaking()
    self:setBreaking(true)
end

return Block