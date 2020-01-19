local event = require("event")
local sides = require("sides")
local component = require("component")
local glasses = component.glasses

local nav = require("navigation")
local map = require("map")
local utils = require("utils")
local vec3 = require("vec3")
local robot = require("robot")
local ScanBatch = require("scanbatch")

glasses.startLinking("Kristopher38")
glasses.setRenderPosition("absolute")

glasses.removeAll()
print("Mapping...")
local batch = ScanBatch()
batch:scanAround(vec3(17, 17, 17))
print("Finished mapping sorrounding area")
while true do
	local EVENT, ID, USER, PLAYER_POSITION_X, PLAYER_POSITION_Y, PLAYER_POSITION_Z, 
		PLAYER_LOOKAT_X, PLAYER_LOOKAT_Y, PLAYER_LOOKAT_Z, PLAYER_EYE_HEIGHT, 
		BLOCK_POSITION_X, BLOCK_POSITION_Y, BLOCK_POSITION_Z, BLOCK_SIDE, 
		PLAYER_ROTATION, PLAYER_PITCH, PLAYER_FACING = event.pull("interact_world_block_right")
	local target = vec3(math.ceil(BLOCK_POSITION_X + robot.position.x), math.ceil(BLOCK_POSITION_Y + robot.position.y), math.ceil(BLOCK_POSITION_Z + robot.position.z))
	if target ~= robot.position then
		glasses.removeAll()
		local path = utils.timeIt(nav.aStar, target)
		nav.navigatePath(path, true)
	end
end