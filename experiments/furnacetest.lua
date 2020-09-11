package.loaded.furnace = nil
package.loaded.block = nil
package.loaded.utils = nil
local component = require("component")
local sides = require("sides")
local invcontroller = component.inventory_controller
local Furnace = require("furnace")
local vec3 = require("vec3")

f = Furnace(vec3(89, 64, 817))
f:putFuel({label="Stick"}, 8)
f:putRaw({label="Cobblestone"}, 2)
os.sleep(20.1)
f:takeSmelted(math.huge)