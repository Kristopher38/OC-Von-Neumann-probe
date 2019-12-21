local VectorMap = require("vectormap")
local utils = require("utils")
local inspect = require("inspect")
local sides = require("sides")


local c = require("computer")
function freeMemory()
  local result = 0
  for i = 1, 10 do
    result = math.max(result, c.freeMemory())
    os.sleep(0)
  end
  return result
end

local v = VectorMap()
local startMem = math.max(freeMemory(), freeMemory(), freeMemory())

math.randomseed(os.time())

for i = 1,32  do
	for j = 1,32 do
		for k = 1,64 do
			local num
			if k < 50 then
				num = sides[k%7]
			else
				num = k*2.435
			end
			v[vec3(math.random(-64, 64), math.random(-64, 64), math.random(-64, 64))] = math.random(-5235, 4769833333333)
			if i == 4 and j == 28 and k == 68 then
				--goto exit
			end
		end
	end
end
::exit::
local endMem = math.max(freeMemory(), freeMemory(), freeMemory())
local elemCount = v.count
print("starting memory: ", startMem)
print("ending memory: ", endMem)
print("bytes taken: ", startMem - endMem)
print("bytes per element: ", (startMem - endMem)/elemCount)
print("elements in map: ", elemCount)
--print(inspect(v))