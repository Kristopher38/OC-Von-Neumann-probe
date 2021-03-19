local locTracker = require("locationtracker")
local ScanBatch = require("scanbatch")
local map = require("map")
local vec3 = require("vec3")
local autoyielder = require("autoyielder")
local VectorChunk = require("vectorchunk")
local utils = require("utils")

local orig = VectorChunk()

s = ScanBatch()
s:scanArea(vec3(-7, 0, -7), vec3(16, 16, 16))

for vec, val in pairs(map) do
    orig[vec] = val
end

map:saveChunk(locTracker.position, true)
local before = utils.freeMemory()
map:unloadChunk(locTracker.position, true)
local after = utils.freeMemory()

print(string.format("Memory used by one chunk: %d (before unloading: %d, after unloading: %d", after-before, before, after))

map:loadChunk(locTracker.position, true)

local orig2 = VectorChunk()

for vec, val in pairs(map) do
    orig2[vec] = val
end

for vec1, val1 in pairs(orig) do
    if orig2[vec1] ~= val1 then
        error(string.format("mismatch on vector %s: expected %.20f, got %s", tostring(vec1), val1, tostring(orig2[vec1])))
    end
    autoyielder.yield()
end

map:unloadChunk(locTracker.position, true)