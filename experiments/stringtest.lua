local computer = require("computer")

local function freeMemory()
    local result = 0
    -- force garbage collection
	for i = 1, 10 do
	  result = math.max(result, computer.freeMemory())
	  os.sleep(0)
	end
	return result
end

freeMemory() -- ensures more stable results
local before = freeMemory()
local s = {}
for i = 1, 1024 do
    s[i] = "abcdefgh"
end
local after = freeMemory()

print(string.format("Memory before: %d, memory after: %d, difference: %d", before, after, before - after))