package.loaded.navigation = nil
local blacklistMap = require("blacklistmap")
local event = require("event")
local locTracker = require("locationtracker")
local utils = require("utils")
local nav = require("navigation")
local vec3 = require("vec3")
local ScanBatch = require("scanbatch")

print("Scanning map")
local sc = ScanBatch():scanAround(vec3(16, 16, 16))
print("Scan finished")

while target ~= locTracker.position do
	local _, _, _, _, _, _, _, _, _, _, BLOCK_POSITION_X, BLOCK_POSITION_Y, BLOCK_POSITION_Z, _, _, _, _ = event.pull("interact_world_block_right")
	local target = vec3(math.ceil(BLOCK_POSITION_X), math.ceil(BLOCK_POSITION_Y), math.ceil(BLOCK_POSITION_Z))
	if target ~= locTracker.position then
        blacklistMap[target] = true
        print("Adding block "..tostring(target).." to blacklist")
    else
        break
    end
end

print("Waiting for target")

while true do
	local _, _, _, _, _, _, _, _, _, _, BLOCK_POSITION_X, BLOCK_POSITION_Y, BLOCK_POSITION_Z, _, _, _, _ = event.pull("interact_world_block_right")
	local target = vec3(math.ceil(BLOCK_POSITION_X), math.ceil(BLOCK_POSITION_Y), math.ceil(BLOCK_POSITION_Z))
	if target ~= locTracker.position then
        utils.timeIt(nav.goTo, target, true)
    end
end
