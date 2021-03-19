local locTracker = require("locationtracker")
local ScanBatch = require("scanbatch")
local map = require("map")
local vec3 = require("vec3")
local autoyielder = require("autoyielder")
local VectorChunk = require("vectorchunk")
local utils = require("utils")
local nav  = require("navigation")

local s = ScanBatch()
local startPos = utils.deepCopy(locTracker.position)

for i = 1, 4 do
    s:scanArea(vec3(-7, -16, -7), vec3(16, 16, 16))
    if i ~= 4 then
        nav.goTo(locTracker.position - vec3(0, 16, 0))
    end
end

print(map.loadedChunks)
for k,v in pairs(map.chunks) do
    print(k,v)
end
-- map:saveChunk(locTracker.position)
-- local before = utils.freeMemory()
-- map:unloadChunk(locTracker.position)
-- local after = utils.freeMemory()

-- print(string.format("Memory used by one chunk: %d (before unloading: %d, after unloading: %d", after-before, before, after))