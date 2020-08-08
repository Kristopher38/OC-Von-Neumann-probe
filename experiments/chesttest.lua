package.loaded.navigation = nil
package.loaded.inventory = nil
package.loaded.chest = nil
local robot = require("robot")
local Chest = require("chest")
local vec3 = require("vec3")
local utils = require("utils")
local Inventory = require("inventory")
local invTracker = require("inventorytracker")

c = Chest(vec3(212, 72, 247), 27)

c:refresh()
local item = {label = "Cobblestone", size = 63}
print(c:put(item, 23))
c:printContents()
invTracker.inventory:printContents()
utils.waitForInput()
print(c:take(item, math.huge))
c:printContents()
invTracker.inventory:printContents()

