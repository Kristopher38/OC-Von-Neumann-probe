local sides = require("sides")
local computer = require("computer")
local event = require("event")

local utils = {}

-- checks if element already exists in a table
function utils.hasDuplicateValue(tab, value)
	for index, element in ipairs(tab) do
		if element == value then
			return true
		end
	end
	for k, v in pairs(tab) do
		if v == value then
			return true
		end
	end
	return false
end

--[[ measures how much time execution of a function took, returns
function return value, real execution time and cpu execution time,
and additionally prints execution times --]]
function utils.timeIt(func, ...)
	local realBefore, cpuBefore = computer.uptime(), os.clock()
	local returnVal = func(table.unpack({...}))
	local realAfter, cpuAfter = computer.uptime(), os.clock()

	local realDiff = realAfter - realBefore
	local cpuDiff = cpuAfter - cpuBefore

	print(string.format('real%5dm%.3fs', math.floor(realDiff/60), realDiff%60))
	print(string.format('cpu %5dm%.3fs', math.floor(cpuDiff/60), cpuDiff%60))

	return returnVal, realDiff, cpuDiff
end

function utils.energyIt(func, ...)
	local before = computer.energy()
	local returnVal = func(table.unpack({...}))
	local after = computer.energy()

	local diff = after - before
	print(string.format("Energy spent: %f", diff))

	return returnVal, diff
end

function utils.freeMemory()
	local result = 0
	for i = 1, 10 do
	  result = math.max(result, computer.freeMemory())
	  os.sleep(0)
	end
	return result
end

function utils.waitForInput()
	event.pull("key_down")
end

return utils