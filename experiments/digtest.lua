local component = require("component")
local geolyzer = component.geolyzer
local utils = require("utils")
local sides = require("sides")

function digdown()
    robot.swingDown()
    while robot.down() do
        geolyzer.analyze(sides.front)
        geolyzer.analyze(sides.front)
        geolyzer.analyze(sides.front)
        geolyzer.analyze(sides.front)
        robot.swingDown()
    end
end

utils.energyIt(digdown)