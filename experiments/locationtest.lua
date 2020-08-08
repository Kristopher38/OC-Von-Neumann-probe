local locationTracker = require("locationtracker")
local robot = require("component").robot
local sides = require("sides")

robot.move(sides.down)
robot.turn(false)
print(locationTracker.position, locationTracker.orientation)