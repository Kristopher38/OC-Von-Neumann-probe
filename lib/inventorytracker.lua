local component = require("component")
local event = require("event")
local utils = require("utils")
local Inventory = require("inventory")
local HookModule = require("hookmodule")
local robot
local invcontroller
local generator
local crafting
local tractorBeam

local invTracker = HookModule("inventorytracker")

function invTracker:start()
    -- robot inventory init and methods override --
    if component.isAvailable("robot") then
        robot = component.robot
    else
        error("This library requires to be run on a robot")
    end
    if component.isAvailable("inventory_controller") then
        invcontroller = component.inventory_controller
    else
        error("This library requires inventory controller upgrade to be installed")
    end

    robot.swing = self:hook(robot.swing, self.swing)
    robot.use = self:hook(robot.use, self.use)
    robot.place = self:hook(robot.place, self.place)
    robot.select = self:hook(robot.select, self.select)
    robot.transferTo = self:hook(robot.transferTo, self.transferTo)
    robot.drop = self:hook(robot.drop, self.drop)
    robot.suck = self:hook(robot.suck, self.suck)

    self.inventory = Inventory(robot.inventorySize())
    self.inventory.selectedSlot = robot.select()

    -- init which requires inventory controller --
    for i = 1, self.inventory.size do
        if robot.count(i) > 0 then
            self.inventory.slots[i] = invcontroller.getStackInInternalSlot(i)
        end
    end

    self.ignoreUpdates = {}
    for i = 1, self.inventory.size do
        self.ignoreUpdates[i] = 0
    end

    invcontroller.equip()
    self.inventory.tool = invcontroller.getStackInInternalSlot(self.inventory.selectedSlot)
    invcontroller.equip()

    invcontroller.equip = self:hook(invcontroller.equip, self.equip)
    invcontroller.dropIntoSlot = self:hook(invcontroller.dropIntoSlot, self.dropIntoSlot)
    invcontroller.suckFromSlot = self:hook(invcontroller.suckFromSlot, self.suckFromSlot)

    -- init for other upgrades which can also modify inventory -- 
    if component.isAvailable("generator") then
        generator = component.generator
        generator.insert = self:hook(generator.insert, self.generatorInsert)
        generator.remove = self:hook(generator.remove, self.generatorRemove)
    end
    
    if component.isAvailable("crafting") then
        crafting = component.crafting
        crafting.craft = self:hook(crafting.craft, self.craft)
    end
    
    if component.isAvailable("tractorBeam") then
        tractorBeam = component.tractor_beam
        tractorBeam.suck = self:hook(tractorBeam.suck, self.tractorBeamSuck)
    end

    event.listen("inventory_changed", self.changeEvent)

    return self
end

function invTracker:stop()
    robot.swing = self:unhook(self.swing)
    robot.use = self:unhook(self.use)
    robot.place = self:unhook(self.place)
    robot.select = self:unhook(self.select)
    robot.transferTo = self:unhook(self.transferTo)
    robot.drop = self:unhook(self.drop)
    robot.suck = self:unhook(self.suck)

    invcontroller.equip = self:unhook(self.equip)
    invcontroller.dropIntoSlot = self:unhook(self.dropIntoSlot)
    invcontroller.suckFromSlot = self:unhook(self.suckFromSlot)

    if generator then
        generator.insert = self:unhook(self.generatorInsert)
        generator.remove = self:unhook(self.generatorRemove)
    end

    if crafting then
        crafting.craft = self:unhook(self.craft)
    end

    if tractorBeam then
        tractorBeam.suck = self:unhook(self.tractorBeamSuck)
    end

    event.ignore("inventory_changed", self.changeEvent)

    return self
end

function invTracker.changeEvent(eventName, slot)
    if invTracker.ignoreUpdates[slot] > 0 then
        invTracker.ignoreUpdates[slot] = invTracker.ignoreUpdates[slot] - 1
    else
        invTracker.inventory.slots[slot] = invcontroller.getStackInInternalSlot(slot)
    end
end

--[[ manyEventsForItem: for robot.swing this should be set to true, since each item added generates
two events, except for the first one in slot which generates one, where as for robot.suck,
inventory_controller.suckFromSlot and generator.remove this should be set to false as only one or two
events are generated per slot, not per item --]]
function invTracker.suckLogic(itemsSucked, manyEventsForItem, singleCraftAmount, forceUpdateInCraftingArea)
    -- default to false
    singleCraftAmount = singleCraftAmount or 1
    if forceUpdateInCraftingArea == nil then
        forceUpdateInCraftingArea = false
    end
    local suckedToSlots = {}
    if itemsSucked then
        --[[ itemsSucked can be number or bool (when calling from generator.remove or robot.swing),
        both will work, when it's bool we just iterate through all the slots ]]--
        local remaining = (type(itemsSucked) == "number" and itemsSucked or math.huge)
        local i = invTracker.inventory.selectedSlot
        local previousInfo = nil

        --[[ iterate through the slots starting from selected (because
        that's what OpenComputers does) to find where the items went
        and update the slot sizes in the process --]]
        while remaining > 0 do
            local newSlotSize = robot.count(i)
            if invTracker.inventory.slots[i] then
                -- count the difference in items and subtract that from remaining item amount
                local sizeDifference = newSlotSize - invTracker.inventory.slots[i].size
                if sizeDifference > 0 then
                    -- crafting workaround when crafted item amount is larger than amount of item used to craft it and it lands in crafting area
                    if forceUpdateInCraftingArea and utils.hasValue({1, 2, 3, 5, 6, 7, 9, 10, 11}, i) then
                        invTracker.inventory.slots[i] = invcontroller.getStackInInternalSlot(i)
                        invTracker.ignoreUpdates[i] = invTracker.ignoreUpdates[i] + 1
                    else
                        remaining = remaining - sizeDifference
                        invTracker.inventory.slots[i].size = newSlotSize
                        -- division is crafting workaround when crafted item amount is larger than amount of item used to craft it per slot (i.e. 1 plank - 4 sticks)
                        invTracker.ignoreUpdates[i] = invTracker.ignoreUpdates[i] + 2 * (manyEventsForItem and math.floor(sizeDifference/singleCraftAmount) or 1)
                    end
                    previousInfo = invTracker.inventory.slots[i]
                    table.insert(suckedToSlots, i)
                end
            elseif newSlotSize > 0 then
                -- if we encountered an empty slot that means the rest of the items went here
                -- if previously we added items to a different slot we can reuse that info
                if previousInfo ~= nil then
                    invTracker.inventory.slots[i] = utils.deepCopy(previousInfo)
                    invTracker.inventory.slots[i].size = newSlotSize
                else
                    invTracker.inventory.slots[i] = invcontroller.getStackInInternalSlot(i)
                end
                -- failproof (for theoretical situations where the rest of the items won't fit in a single slot)
                remaining = remaining - newSlotSize
                invTracker.ignoreUpdates[i] = invTracker.ignoreUpdates[i] + 2 * (manyEventsForItem and math.floor(newSlotSize/singleCraftAmount) or 1) - 1
                table.insert(suckedToSlots, i)
            end
            -- modulo arithmetic to wrap i around to contain it to <1, invTracker.inventory.size>
            i = i + 1
            if i % (invTracker.inventory.size + 1) == 0 then
                i = 1
            end
            -- exit after all slots have been checked, can't put this in loop condition since at least one iteration has to pass before this works
            if i == invTracker.inventory.selectedSlot then
                break
            end
        end
    end

    return suckedToSlots
end

function invTracker.dropLogic(success, generatesEvent)
    local selectedSlot = invTracker.inventory.selectedSlot
    if success then
        -- we don't have to check if slot exists because if it was empty success would be false
        local newSlotSize = robot.count(selectedSlot)
        if newSlotSize > 0 then
            invTracker.inventory.slots[selectedSlot].size = newSlotSize
        else
            invTracker.inventory.slots[selectedSlot] = nil
            if generatesEvent then
                invTracker.ignoreUpdates[selectedSlot] = invTracker.ignoreUpdates[selectedSlot] + 1
            end
        end
    end
end

function invTracker.swing(...)
    local success, reason = invTracker:callOriginal(invTracker.swing, ...)
    invTracker.suckLogic(success, true)
    return success, reason
end

function invTracker.use(...)
    -- use doesn't cause inventory_changed event to fire even when stack is entirely spent
    local success, interaction = invTracker:callOriginal(invTracker.use, ...)

    if success then
        if interaction == "item_placed" then
            invTracker.inventory:deductFromSlot(invTracker.inventory.tool, 1)
        end
    end

    return success, interaction
end

function invTracker.place(...)
    -- place doesn't cause inventory_changed event to fire even when stack is entirely spent
    local success, reason = invTracker:callOriginal(invTracker.place, ...)

    if success then
        invTracker.inventory:deductFromSlot(invTracker.inventory.selectedSlot, 1)
    end

    return success, reason
end

function invTracker.select(...)
    local selected = invTracker:callOriginal(invTracker.select, ...)
    invTracker.inventory.selectedSlot = selected
    return selected
end

function invTracker.transferTo(toSlot, ...)
    local selectedSlot = invTracker.inventory.selectedSlot
    -- first check if there's something to transfer
    if invTracker.inventory.slots[selectedSlot] ~= nil then
        -- then check if there's something occupying the target slot
        if invTracker.inventory.slots[toSlot] ~= nil then
            -- if items in selectedSlot and toSlot are identical (ignoring sizes of stacks, doesn't mean they're stackable)
            if utils.shallowCompare(invTracker.inventory.slots[selectedSlot], invTracker.inventory.slots[toSlot], {"size"}) then
                local areStackable = true
                -- if both items have nbt tags (we only need to check one since shallowCompare would only return true if both items had nbt tags)
                if invTracker.inventory.slots[selectedSlot].hasTag then
                    areStackable = robot.compareTo(toSlot, true)
                elseif invTracker.inventory.slots[selectedSlot].maxSize == 1 then
                    areStackable = false
                end

                if areStackable then
                    local success = invTracker:callOriginal(invTracker.transferTo, toSlot, ...)
                    --[[ if success is true that means the items are stackable --]]
                    if success then
                        local newSlotSize = robot.count(toSlot)
                        invTracker.inventory:deductFromSlot(selectedSlot, newSlotSize - invTracker.inventory.slots[toSlot].size)
                        invTracker.inventory.slots[toSlot].size = newSlotSize
                        --[[ we don't need to check if there are no items left in the selectedSlot since it doesn't generate an event
                        in this case --]]
                    end
                    return success
                end
            end
            -- if items are different or are identical but not stackable we swap them
            local success = invTracker:callOriginal(invTracker.transferTo, toSlot, ...)
            if success then
                local temp = utils.deepCopy(invTracker.inventory.slots[selectedSlot])
                invTracker.inventory.slots[selectedSlot] = invTracker.inventory.slots[toSlot]
                invTracker.inventory.slots[toSlot] = temp
                invTracker.ignoreUpdates[selectedSlot] = invTracker.ignoreUpdates[selectedSlot] + 2
                invTracker.ignoreUpdates[toSlot] = invTracker.ignoreUpdates[toSlot] + 2
            end
            return success
        else
            -- if slot at toSlot is empty, then just clone a table and set the size
            local success = invTracker:callOriginal(invTracker.transferTo, toSlot, ...)
            if success then
                local newSlotSize = robot.count(toSlot)
                invTracker.inventory.slots[toSlot] = utils.deepCopy(invTracker.inventory.slots[selectedSlot])
                invTracker.inventory.slots[toSlot].size = newSlotSize
                local itemsLeft = invTracker.inventory:deductFromSlot(selectedSlot, newSlotSize)
                if itemsLeft == 0 then
                    invTracker.ignoreUpdates[selectedSlot] = invTracker.ignoreUpdates[selectedSlot] + 1
                end
                invTracker.ignoreUpdates[toSlot] = invTracker.ignoreUpdates[toSlot] + 1
            end
            return success 
        end
    else
        return false
    end
end

function invTracker.drop(...)
    local success, reason = invTracker:callOriginal(invTracker.drop, ...)
    invTracker.dropLogic(success, true)
    return success, reason
end

function invTracker.suck(...)
    local itemsSucked = invTracker:callOriginal(invTracker.suck, ...)
    invTracker.suckLogic(itemsSucked, false)
    return itemsSucked
end

function invTracker.equip(...)
    local selectedSlot = invTracker.inventory.selectedSlot
    local success = invTracker:callOriginal(invTracker.equip, ...)

    if success then
        -- update fully in case player changed the tool since last update
        local newSlot = invcontroller.getStackInInternalSlot(selectedSlot)
        -- maximum of 2 events generated - one if there was something equipped, and one if we're equipping something new
        if newSlot ~= nil then
            invTracker.ignoreUpdates[selectedSlot] = invTracker.ignoreUpdates[selectedSlot] + 1
        end
        if invTracker.inventory.slots[selectedSlot] ~= nil then
            invTracker.ignoreUpdates[selectedSlot] = invTracker.ignoreUpdates[selectedSlot] + 1
        end
        invTracker.inventory.tool = invTracker.inventory.slots[selectedSlot]
        invTracker.inventory.slots[selectedSlot] = newSlot 
    end

    return success
end

function invTracker.dropIntoSlot(...)
    local success, reason = invTracker:callOriginal(invTracker.dropIntoSlot, ...)
    -- doesn't generate inventory_changed event
    invTracker.dropLogic(success, false)
    return success, reason
end

function invTracker.suckFromSlot(...)
    local itemsSucked = invTracker:callOriginal(invTracker.suckFromSlot, ...)
    invTracker.suckLogic(itemsSucked, false)
    return itemsSucked
end

function invTracker.generatorInsert(...)
    local success, reason = invTracker:callOriginal(invTracker.generatorInsert, ...)
    -- generator.insert works similarly to inventory_controller.dropIntoSlot (doesn't generate inventory_changed event when slot is spent) 
    invTracker.dropLogic(success, false)
    return success, reason
end

function invTracker.generatorRemove(...)
    -- generator.remove works similarly to robot.suck
    local success = invTracker:callOriginal(invTracker.generatorRemove, ...)
    invTracker.suckLogic(success, false)
    return success
end

function invTracker.craft(amount, singleCraftAmount)
    singleCraftAmount = singleCraftAmount or 1
    local success = invTracker:callOriginal(invTracker.craft, amount)
    -- important: run invTracker.suckLogic first
    local suckedToSlots = invTracker.suckLogic(success, true, singleCraftAmount, true)
    -- then update the crafting area
    for i = 1, 11 do
        -- skip elements which are not in the crafting area, empty ones and those already updated by invTracker.suckLogic
        if i % 4 ~= 0 and invTracker.inventory.slots[i] and not utils.hasValue(suckedToSlots, i) then
            invTracker.inventory:deductFromSlot(i, invTracker.inventory.slots[i].size - robot.count(i))
        end
    end
    --[[ note: if crafted item goes into the crafting area we can't easily detect to which slot, because while in reality
    internal crafting does it in several steps we only see the end result, so it generates extra inventory_changed event
    that we can't calculate the slot of ]]--

    return success
end

function invTracker.tractorBeamSuck(...)
    local success = invTracker:callOriginal(invTracker.tractorBeamSuck, ...)
    invTracker.suckLogic(success, false)
    return success
end

return invTracker:start()