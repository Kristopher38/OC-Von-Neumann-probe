local component = require("component")
local robotApi = require("robotapiload") -- workaround script for magic filesystem with robot.lua
local event = require("event")
local utils = require("utils")
local inspect = require("inspect")
local robot = component.robot
local invcontroller = component.inventory_controller
local generator
local crafting
local tractorBeam

local originalSwing = robot.swing
local originalUse = robot.use
local originalPlace = robot.place
local originalSelect = robot.select
local originalTransferTo = robot.transferTo
local originalDrop = robot.drop
local originalSuck = robot.suck

local originalEquip = invcontroller.equip
local originalDropIntoSlot = invcontroller.dropIntoSlot
local originalSuckFromSlot = invcontroller.suckFromSlot

local originalGeneratorInsert
local originalGeneratorRemove

local originalCraft

local originalTractorBeamSuck

local ignoreUpdates
local function changeEvent(eventName, slot)
    if ignoreUpdates[slot] > 0 then
        print("IGNORING SLOW UPDATE OF INVENTORY SLOT:", slot)
        ignoreUpdates[slot] = ignoreUpdates[slot] - 1
    else
        print("SLOW UPDATE OF INVENTORY SLOT:", slot)
        robot.inventory.slots[slot] = invcontroller.getStackInInternalSlot(slot)
    end
end

-- deducts amount of items from specified slot of memory representation of inventory, returns amount of items left 
local function deductFromSlot(slot, amount)
    local selectedSlot = robot.inventory.slots[slot]
    if selectedSlot ~= nil then
        selectedSlot.size = selectedSlot.size - amount
        if selectedSlot.size <= 0 then
            robot.inventory.slots[slot] = nil
            return 0
        else
            return selectedSlot.size
        end
    else
        return 0
    end
end

local function customSwingLogic(success)
    if success then
        local previousInfo = nil
        for i = 1, robot.inventory.size do
            local newSlotSize = robot.count(i)
            if robot.inventory.slots[i] ~= nil then
                -- when there were already items in a slot and we're adding to the stack
                if newSlotSize ~= robot.inventory.slots[i].size then
                    -- each new item generates two events
                    ignoreUpdates[i] = ignoreUpdates[i] + 2 * (newSlotSize - robot.inventory.slots[i].size)
                    robot.inventory.slots[i].size = newSlotSize
                    previousInfo = robot.inventory.slots[i]
                end
            else
                -- when the slot was empty and we're creating new one
                if newSlotSize > 0 then
                    -- each new item generates two events except for the first one which generates one event so we're subtracting one
                    ignoreUpdates[i] = ignoreUpdates[i] + 2 * newSlotSize - 1
                    -- if we previously added to some other stack we can reuse stack info from there
                    if previousInfo ~= nil then
                        robot.inventory.slots[i] = utils.deepCopy(previousInfo)
                        robot.inventory.slots[i].size = newSlotSize
                    else
                        robot.inventory.slots[i] = invcontroller.getStackInInternalSlot(i)
                    end
                end
            end
        end
    end

    return success
end

--[[ manyEventsForItem: for robot.swing this should be set to true, since each item added generates
two events, except for the first one in slot which generates one, where as for robot.suck,
inventory_controller.suckFromSlot and generator.remove this should be set to false as only one or two
events are generated per slot, not per item --]]
local function customSuckLogic(itemsSucked, manyEventsForItem, singleCraftAmount, forceUpdateInCraftingArea)
    -- default to false
    if forceUpdateInCraftingArea == nil then
        forceUpdateInCraftingArea = false
    end
    local suckedToSlots = {}
    if itemsSucked then
        --[[ itemsSucked can be number or bool (when calling from generator.remove or robot.swing),
        both will work, when it's bool we just iterate through all the slots ]]--
        local remaining = (type(itemsSucked) == "number" and itemsSucked or math.huge)
        local i = robot.inventory.selectedSlot
        local previousInfo = nil

        --[[ iterate through the slots starting from selected (because
        that's what OpenComputers does) to find where the items went
        and update the slot sizes in the process --]]
        while remaining > 0 do
            local newSlotSize = robot.count(i)
            if robot.inventory.slots[i] then
                -- count the difference in items and subtract that from remaining item amount
                local sizeDifference = newSlotSize - robot.inventory.slots[i].size
                if sizeDifference > 0 then
                    -- crafting workaround when crafted item amount is larger than amount of item used to craft it and it lands in crafting area
                    if forceUpdateInCraftingArea and utils.hasValue({1, 2, 3, 5, 6, 7, 9, 10, 11}, i) then
                        robot.inventory.slots[i] = invcontroller.getStackInInternalSlot(i)
                        ignoreUpdates[i] = ignoreUpdates[i] + 1
                    else
                        remaining = remaining - sizeDifference
                        robot.inventory.slots[i].size = newSlotSize
                        -- division is crafting workaround when crafted item amount is larger than amount of item used to craft it per slot (i.e. 1 plank - 4 sticks)
                        ignoreUpdates[i] = ignoreUpdates[i] + 2 * (manyEventsForItem and math.floor(sizeDifference/singleCraftAmount) or 1)
                    end
                    previousInfo = robot.inventory.slots[i]
                    table.insert(suckedToSlots, i)
                end
            elseif newSlotSize > 0 then
                -- if we encountered an empty slot that means the rest of the items went here
                -- if previously we added items to a different slot we can reuse that info
                if previousInfo ~= nil then
                    robot.inventory.slots[i] = utils.deepCopy(previousInfo)
                    robot.inventory.slots[i].size = newSlotSize
                else
                    robot.inventory.slots[i] = invcontroller.getStackInInternalSlot(i)
                end
                -- failproof (for theoretical situations where the rest of the items won't fit in a single slot)
                remaining = remaining - newSlotSize
                ignoreUpdates[i] = ignoreUpdates[i] + 2 * (manyEventsForItem and math.floor(newSlotSize/singleCraftAmount) or 1) - 1
                table.insert(suckedToSlots, i)
            end
            -- modulo arithmetic to wrap i around to contain it to <1, robot.inventory.size>
            i = i + 1
            if i % (robot.inventory.size + 1) == 0 then
                i = 1
            end
            -- exit after all slots have been checked, can't put this in loop condition since at least one iteration has to pass before this works
            if i == robot.inventory.selectedSlot then
                break
            end
        end
    end

    return suckedToSlots
end

local function customDropLogic(success, generatesEvent)
    local selectedSlot = robot.inventory.selectedSlot
    if success then
        -- we don't have to check if slot exists because if it was empty success would be false
        local newSlotSize = robot.count()
        if newSlotSize > 0 then
            robot.inventory.slots[selectedSlot].size = newSlotSize
        else
            robot.inventory.slots[selectedSlot] = nil
            if generatesEvent then
                ignoreUpdates[selectedSlot] = ignoreUpdates[selectedSlot] + 1
            end
        end
    end
end

local function customSwing(side)
    local success, reason = originalSwing(side)
    customSuckLogic(success, true)
    return success, reason
end

local function customUse(side, sneaky, duration)
    -- use doesn't cause inventory_changed event to fire even when stack is entirely spent
    local success, interaction = originalUse(side, sneaky, duration)

    if success then
        if interaction == "item_placed" then
            deductFromSlot(robot.inventory.tool, 1)
        end
    end

    return success, interaction
end

local function customPlace(side, sneaky)
    -- place doesn't cause inventory_changed event to fire even when stack is entirely spent
    local success, reason = originalPlace(side, sneaky)

    if success then
        deductFromSlot(robot.inventory.selectedSlot, 1)
    end

    return success, reason
end

local function customSelect(slot)
    local selected = originalSelect(slot)
    robot.inventory.selectedSlot = selected
    return selected
end

local function customTransferTo(toSlot, amount)
    local selectedSlot = robot.inventory.selectedSlot
    -- first check if there's something to transfer
    if robot.inventory.slots[selectedSlot] ~= nil then
        -- then check if there's something occupying the target slot
        if robot.inventory.slots[toSlot] ~= nil then
            -- if items in selectedSlot and toSlot are identical (ignoring sizes of stacks, doesn't mean they're stackable)
            if utils.shallowCompare(robot.inventory.slots[selectedSlot], robot.inventory.slots[toSlot], {"size"}) then
                local areStackable = true
                -- if both items have nbt tags (we only need to check one since shallowCompare would only return true if both items had nbt tags)
                if robot.inventory.slots[selectedSlot].hasTag then
                    areStackable = robot.compareTo(toSlot, true)
                elseif robot.inventory.slots[selectedSlot].maxSize == 1 then
                    areStackable = false
                end

                if areStackable then
                    local success = originalTransferTo(toSlot, amount)
                    --[[ if success is true that means the items are stackable --]]
                    if success then
                        local newSlotSize = robot.count(toSlot)
                        deductFromSlot(selectedSlot, newSlotSize - robot.inventory.slots[toSlot].size)
                        robot.inventory.slots[toSlot].size = newSlotSize
                        --[[ we don't need to check if there are no items left in the selectedSlot since it doesn't generate an event
                        in this case --]]
                    end
                    return success
                end
            end
            -- if items are different or are identical but not stackable we swap them
            local success = originalTransferTo(toSlot, amount)
            if success then
                local temp = utils.deepCopy(robot.inventory.slots[selectedSlot])
                robot.inventory.slots[selectedSlot] = robot.inventory.slots[toSlot]
                robot.inventory.slots[toSlot] = temp
                ignoreUpdates[selectedSlot] = ignoreUpdates[selectedSlot] + 2
                ignoreUpdates[toSlot] = ignoreUpdates[toSlot] + 2
            end
            return success
        else
            -- if slot at toSlot is empty, then just clone a table and set the size
            local success = originalTransferTo(toSlot, amount)
            if success then
                local newSlotSize = robot.count(toSlot)
                robot.inventory.slots[toSlot] = utils.deepCopy(robot.inventory.slots[selectedSlot])
                robot.inventory.slots[toSlot].size = newSlotSize
                local itemsLeft = deductFromSlot(selectedSlot, newSlotSize)
                if itemsLeft == 0 then
                    ignoreUpdates[selectedSlot] = ignoreUpdates[selectedSlot] + 1
                end
                ignoreUpdates[toSlot] = ignoreUpdates[toSlot] + 1
            end
            return success 
        end
    else
        return false
    end
end

local function customDrop(side, amount)
    local success, reason = originalDrop(side, amount)
    customDropLogic(success, true)
    return success, reason
end

local function customSuck(side, amount)
    local itemsSucked = originalSuck(side, amount)
    customSuckLogic(itemsSucked, false)
    return itemsSucked
end

local function customEquip()
    local selectedSlot = robot.inventory.selectedSlot
    local success = originalEquip()

    if success then
        -- update fully in case player changed the tool since last update
        local newSlot = invcontroller.getStackInInternalSlot(selectedSlot)
        -- maximum of 2 events generated - one if there was something equipped, and one if we're equipping something new
        if newSlot ~= nil then
            ignoreUpdates[selectedSlot] = ignoreUpdates[selectedSlot] + 1
        end
        if robot.inventory.slots[selectedSlot] ~= nil then
            ignoreUpdates[selectedSlot] = ignoreUpdates[selectedSlot] + 1
        end
        robot.inventory.tool = robot.inventory.slots[selectedSlot]
        robot.inventory.slots[selectedSlot] = newSlot 
    end

    return success
end

local function customDropIntoSlot(side, slot, amount)
    local success, reason = originalDropIntoSlot(side, slot, amount)
    -- doesn't generate inventory_changed event
    customDropLogic(success, false)
    return success, reason
end

local function customSuckFromSlot(side, slot, amount)
    local itemsSucked = originalSuckFromSlot(side, slot, amount)
    customSuckLogic(itemsSucked, false)
    return itemsSucked
end

local function customGeneratorInsert(amount)
    local success, reason = originalGeneratorInsert(amount)
    -- generator.insert works similarly to inventory_controller.dropIntoSlot (doesn't generate inventory_changed event when slot is spent) 
    customDropLogic(success, false)
    return success, reason
end

local function customGeneratorRemove(amount)
    -- generator.remove works similarly to robot.suck
    local success = originalGeneratorRemove(amount)
    customSuckLogic(success, false)
    return success
end

local function customCraft(amount, singleCraftAmount)
    singleCraftAmount = singleCraftAmount or 1
    local success = originalCraft(amount)
    -- important: run customSuckLogic first
    local suckedToSlots = customSuckLogic(success, true, singleCraftAmount, true)
    -- then update the crafting area
    for i = 1, 11 do
        -- skip elements which are not in the crafting area, empty ones and those already updated by customSuckLogic
        if i % 4 ~= 0 and robot.inventory.slots[i] and not utils.hasValue(suckedToSlots, i) then
            deductFromSlot(i, robot.inventory.slots[i].size - robot.count(i))
        end
    end
    --[[ note: if crafted item goes into the crafting area we can't easily detect to which slot, because while in reality
    internal crafting does it in several steps we only see the end result, so it generates extra inventory_changed event
    that we can't calculate the slot of ]]--

    return success
end

local function customTractorBeamSuck()
    local success = originalTractorBeamSuck()
    customSuckLogic(success, false)
    return success
end

function start()
    -- robot inventory init and methods override --
    setmetatable(robotApi, {__index = robot, __newindex = robot})
    robot.swing = customSwing
    robot.use = customUse
    robot.place = customPlace
    robot.select = customSelect
    robot.transferTo = customTransferTo
    robot.drop = customDrop
    robot.suck = customSuck

    robot.inventory = {}
    robot.inventory.selectedSlot = robot.select()
    robot.inventory.size = robot.inventorySize()

    -- init which requires inventory controller --
    robot.inventory.slots = {}
    for i = 1, robot.inventory.size do
        if robot.count(i) > 0 then
            robot.inventory.slots[i] = invcontroller.getStackInInternalSlot(i)
        end
    end

    ignoreUpdates = {}
    for i = 1, robot.inventory.size do
        ignoreUpdates[i] = 0
    end

    invcontroller.equip()
    robot.inventory.tool = invcontroller.getStackInInternalSlot(robot.inventory.selectedSlot)
    invcontroller.equip()

    invcontroller.equip = customEquip
    invcontroller.dropIntoSlot = customDropIntoSlot
    invcontroller.suckFromSlot = customSuckFromSlot

    if component.isAvailable("generator") then
        generator = component.generator
        originalGeneratorInsert = generator.insert
        originalGeneratorRemove = generator.remove
        generator.insert = customGeneratorInsert
        generator.remove = customGeneratorRemove
    end
    
    if component.isAvailable("crafting") then
        crafting = component.crafting
        originalCraft = crafting.craft
        crafting.craft = customCraft
    end
    
    if component.isAvailable("tractorBeam") then
        tractorBeam = component.tractor_beam
        originalTractorBeamSuck = tractorBeam.suck
        tractorBeam.suck = customTractorBeamSuck
    end

    robot.inventory.dbg = function()
        local i = 0
        for slot, item in pairs(robot.inventory.slots) do
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

    robot.inventory.ign = function()
        for i = 1, robot.inventory.size do
            io.stdout:write("[" .. tostring(i) .. "] = " .. tostring(ignoreUpdates[i]))
            if i % 2 == 1 then
                io.stdout:write("\t")
            else
                io.stdout:write("\n")
            end
        end
    end

    event.listen("inventory_changed", changeEvent)
end

function stop()
    setmetatable(robotApi, nil)
    robot.swing = originalSwing
    robot.use = originalUse
    robot.place = originalPlace
    robot.select = originalSelect
    robot.transferTo = originalTransferTo
    robot.drop = originalDrop
    robot.suck = originalSuck
    robot.inventory = nil

    invcontroller.equip = originalEquip
    invcontroller.dropIntoSlot = originalDropIntoSlot
    invcontroller.suckFromSlot = originalSuckFromSlot

    if generator then
        generator.insert = originalGeneratorInsert
        generator.remove = originalGeneratorRemove
    end

    if crafting then
        crafting.craft = originalCraft
    end

    if tractorBeam then
        tractorBeam.suck = originalTractorBeamSuck
    end

    event.ignore("inventory_changed", changeEvent)
end

return inventory