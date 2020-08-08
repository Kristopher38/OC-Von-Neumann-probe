local utils = require("utils")

local Inventory = {}
Inventory.__index = Inventory
setmetatable(Inventory, {__call = function(cls, size)
	local self = {}
    self.size = size or 27 -- amount of slots which the inventory has, defaults to 27 (standard minecraft chest)
    self.slots = {} -- table with item tables at each integer slot
	setmetatable(self, cls)
	return self
end })

--[[ finds the first occurrence of a specified item in the inventory, returns the index at which the item was found --]]
function Inventory:findIndex(item, minAmount, notFull)
    minAmount = minAmount or (item.size or 1) -- minAmount overrides item.size, but item.size (or 1) is used if there's no minAmount specified
    for i = 1, self.size do
        local invItem = self.slots[i]
        if invItem and utils.compareItems(item, invItem) and invItem.size >= minAmount and (not notFull or invItem.size < invItem.maxSize) then
            return i
        end
    end
end

function Inventory:count(item)
    local count = 0
    for i = 1, self.size do
        local invItem = self.slots[i]
        if invItem and utils.compareItems(item, invItem) then
            count = count + invItem.size
        end
    end
    return count
end

--[[ checks whether a specified item exists in the inventory, compares only name and label --]]
function Inventory:contains(item, minAmount)
    return self:findIndex(item, minAmount) ~= nil
end

--[[ checks whether a supplied item is the same as the one at the specified index --]]
function Inventory:isItemAt(item, index)
    local invItem = self.slots[index]
    return invItem and utils.compareItems(item, invItem)
end

--[[ deducts amount of items from specified slot, returns amount of items left --]] 
function Inventory:deductFromSlot(slot, amount)
    local selectedSlot = self.slots[slot]
    if selectedSlot then
        selectedSlot.size = selectedSlot.size - amount
        if selectedSlot.size <= 0 then
            self.slots[slot] = nil
            return 0
        else
            return selectedSlot.size
        end
    else
        return 0
    end
end

--[[ returns first empty inventory slot index, if there are no empty slots returns nil ]]
function Inventory:emptySlot()
    for i = 1, self.size do
        if not self.slots[i] then
            return i
        end
    end
end

--[[ prints the inventory contents with slot number, item name and amount for each slot in the inventory, for debugging purposes ]]
function Inventory:printContents()
    local i = 0
    for slot, item in pairs(self.slots) do
        local colon = string.find(item.name, ":")
        io.stdout:write("[" .. tostring(slot) .. "] " .. string.sub(item.name, colon + 1) .. " = " .. tostring(item.size))
        if i % 2 == 0 then
            io.stdout:write("\t")
        else
            io.stdout:write("\n")
        end
        i = i + 1
    end
end

return Inventory