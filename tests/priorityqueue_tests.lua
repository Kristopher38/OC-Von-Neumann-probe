local PriorityQueue = require("priorityqueue")

local function checkHeapOrder(heap, index)
	index = index or 1
	local child1 = 2 * index
	local child2 = 2 * index + 1

	if child1 > #heap then
		return true
	end

	local child1test = false
	if heap[index].priority <= heap[child1].priority then
		child1test = checkHeapOrder(heap, child1)
	end

	local child2test = false
	if child2 > #heap then
		child2test = true
	elseif heap[index].priority <= heap[child2].priority then
		child2test = checkHeapOrder(heap, child2)
	end

	return child1test and child2test
end

local function testBug1()
	local priorities = {11.555, 9.555, 9.555, 11.555, 9.555, 11.555, 13.11, 11.11, 11.11, 13.11, 11.11, 13.11, 13.11}
end

local function testLotsElements()
	local pq = PriorityQueue()
	for i=1,8192 do
		local action = math.random(1, 3)
		if action <= 2.5 then
			pq:put(tostring(i), math.random(0, 1000000))
		else
			if not pq:empty() then
				pq:pop()
			end
		end
	end
	return checkHeapOrder(pq.heap)
end

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
	
	local correctOrderPut = {"el8", "el5", "el7", "el2", "el10", "el3", "el6", "el1", "el9", "el4"}
	local testOrderPut = true
	for i = 1,#pq.heap do
		if pq.heap[i] ~= correctOrderPut[i] then
			testOrder = false
		end
	end

	local testTopValue = pq:pop() == "el8"

	local correctOrderPop = {"el5", "el2", "el7", "el4", "el10", "el3", "el6", "el1", "el9"}
	local testOrderPop = true
	for i = 1,#pq.heap do
		if pq.heap[i].priority ~= correctOrderPop[i] then
			testOrder = false
		end
	end

	return testOrderPut and testTopValue and testOrderPop
end

local function testAll()
	local tests = {testPutPop, testLotsElements}
	for testIndex, testFunction in ipairs(tests) do
		print(testIndex, testFunction())
	end
end

testAll()