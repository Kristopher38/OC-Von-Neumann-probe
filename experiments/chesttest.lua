package.loaded.navigation = nil
package.loaded.inventory = nil
package.loaded.chest = nil
package.loaded.utils = nil
local robot = require("robot")
local Chest = require("chest")
local vec3 = require("vec3")
local utils = require("utils")
local Inventory = require("inventory")
local invTracker = require("inventorytracker")

c = Chest({vec3(88, 64, 819), vec3(87, 64, 819)})

c:refresh()
local item = {label = "Cobblestone", size = 63}
print(c:put(item, 23))
c:printContents()
invTracker.inventory:printContents()
utils.waitForInput()
print(c:take(item, math.huge))
c:printContents()
invTracker.inventory:printContents()

