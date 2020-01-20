local component = require("component")
local geolyzer = component.geolyzer
local inspect = require("inspect")

local argv = {...}
for i, arg in ipairs(argv) do
    argv[i] = tonumber(arg)
end

print(inspect(geolyzer.scan(table.unpack(argv))))