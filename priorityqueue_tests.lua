local PriorityQueue = require("priorityqueue")
local inspect = require("inspect")

local function testPutPop()
	local pq = PriorityQueue()
	pq:put("el1", 11)
	pq:put("el2", 6)
	pq:put("el3", 8)
	pq:put("el4", 10)
	pq:put("el5", 3)
	pq:put("el6", 7)
	pq:put("el7", 6)
	pq:put("el8", 0)
	pq:put("el9", 11)
	pq:put("el10", 4)
	
	local correctOrderPut = {0, 3, 6, 6, 4, 8, 7, 11, 11, 10}
	local testOrderPut = true
	for i = 1,#pq.heap do
		if pq.heap[i].priority ~= correctOrderPut[i] then
			testOrder = false
		end
	end
	
	local testTopValue = pq:pop().priority == 0
	
	local correctOrderPop = {3, 6, 6, 10, 4, 8, 7, 11, 11}
	local testOrderPop = true
	for i = 1,#pq.heap do
		if pq.heap[i].priority ~= correctOrderPop[i] then
			testOrder = false
		end
	end
	
	return testOrderPut and testTopValue and testOrderPop
end

local function testAll()
	local tests = {testPutPop}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
	end
end

testAll()