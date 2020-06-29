local robot = require("robot")

local Inventory = {}
Inventory.__index = Inventory
setmetatable(Inventory, {__call = function(cls, size)
	local self = {}
    self.size = size or 27 -- amount of slots which the inventory has, defaults to 27 (standard minecraft chest)
    self.slots = {} -- table with item tables at each integer slot
	setmetatable(self, cls)
	return self
end })

--[[ compares two item tables, only by name and label fields --]]
function Inventory:compareItems(first, second)
    return first.name and second.name and first.name == second.name and
           first.label and second.label and first.label == second.label
end

--[[ finds the first occurrence of a specified item in the inventory, returns the index at which the item was found --]]
function Inventory:findIndex(item, minAmount)
    minAmount = minAmount or (item.size or 1) -- minAmount overrides item.size, but item.size (or 1) is used if there's no minAmount specified
    for i = 1, self.size do
        local invItem = self.slots[i]
        if invItem and self:compareItems(item, invItem) and invItem.size >= minAmount then
            return i
        end
    end
end

--[[ checks whether a specified item exists in the inventory, compares only name and label --]]
function Inventory:contains(item, minAmount)
    return self:findIndex(item, minAmount) ~= nil
end

--[[ checks whether a supplied item is the same as the one at the specified index --]]
function Inventory:isItemAt(item, index)
    local invItem = self.slots[index]
    return invItem and self:compareItems(item, invItem)
end

return Inventory