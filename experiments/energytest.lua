local component = require("component")
local geolyzer = component.geolyzer
local utils = require("utils")

utils.timeIt(utils.energyIt, geolyzer.scan, 0, 0, 0, 8, 8, 1)