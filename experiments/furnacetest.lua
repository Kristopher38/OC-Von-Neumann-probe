local component = require("component")
local sides = require("sides")
local invcontroller = component.inventory_controller
local Furnace = require("furnace")
local vec3 = require("vec3")

f = Furnace(vec3(89, 64, 817))
invcontroller.getStackInSlot(sides.front, 2)