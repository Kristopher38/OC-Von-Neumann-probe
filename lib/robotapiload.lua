local filesystem = require("filesystem")
-- workaround for not yet mounted magic filesystem with robot.lua
local robot
-- search all filesystems for robot.lua
for fs in filesystem.list("/mnt") do
    local robotPath = filesystem.concat("/mnt", fs, "/lib/robot.lua")
    if filesystem.exists(robotPath) then
        -- if filesystem with robot.lua found, execute and cache it so other modules can use it
        robot = dofile(robotPath)
        package.loaded.robot = robot
        break
    end
end

if not robot then
    error("robot.lua not found, make sure you're running from a robot")
end

return robot