local PriorityQueue = require("priorityqueue")

-- Priority queue implemented using binary min heap
local TableQueue = {}
TableQueue.__index = TableQueue
setmetatable(TableQueue, {__call = function(cls)
	local self = {}
    self.heap = {[0] = math.huge}
	setmetatable(self, cls)
	return self
end })

-- pops and returs element at the top of the queue (with smallest priority)
function TableQueue:pop()
    return table.remove(self.heap, 1)
end

-- puts an element into the queue with specified priority
function TableQueue:put(element, priority)
    local heap = self.heap
    local low = 1
    local high = #heap
    while low <= high do
        local mid = (low + high) // 2
        if heap[mid - 1] >= priority and heap[mid] <= priority then
            table.insert(heap, mid, priority)
            return
        elseif (heap[mid] > priority) then
            low = mid + 1;
        else
            high = mid - 1;
        end 
    end
    heap[#heap + 1] = priority
end

-- returns element at the top of the queue without popping it
function TableQueue:top()
	return self.heap[1].element
end

-- returns if queue is empty
function TableQueue:empty()
	return #self.heap == 0
end

-- returns queue size
function TableQueue:size()
	return #self.heap
end

math.randomseed(0)


local pureLuaQueue = PriorityQueue()
local tableQueue = TableQueue()

local startTime = os.clock()

for i = 1, 100000 do
    --tableQueue:put(0, math.random())
    pureLuaQueue:put(0, math.random())
    --[[ if i % 10 == 0 then
        pureLuaQueue:pop()
    end ]]
end

local endTime = os.clock()

for i = 1, 100 do
    print(tableQueue.heap[i])
end

print()
print(string.format("%f", endTime - startTime))