local component = require("component")
local geolyzer = component.geolyzer

local realHardness = 3
local distance = 31
local highestDeviation = 0

for i=1,200 do
    highestDeviation = math.max(highestDeviation, math.abs(realHardness - geolyzer.scan(distance, 31, 31, 1, 1, 1)[1]))
end

print("Highest deviation from real hardness (" .. tostring(realHardness) .. ") at a distance of " .. tostring(distance) .. " is " .. tostring(highestDeviation))