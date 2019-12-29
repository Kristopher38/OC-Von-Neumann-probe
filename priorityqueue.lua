-- Priority queue implemented using binary min heap
local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue
setmetatable(PriorityQueue, {__call = function(cls)
	local self = {}
	self.heap = {}	-- uses binary heap (min heap) for backend
	self.endIndex = 1 -- points to space *after* last element
	setmetatable(self, cls) -- cls = PriorityQueue
	return self
end })

-- pops and returs element at the top of the queue (with smallest priority)
function PriorityQueue:pop()
	local minNode = self.heap[1].element
	-- swap root node with the last node
	self.endIndex = self.endIndex - 1
	self.heap[1] = self.heap[self.endIndex]
	self.heap[self.endIndex] = nil
	local parentIndex = 1
	local childIndex = 2
	--[[ checks which child is smaller and returns offset from base child index
	(0 if first child is smaller, 1 if second child is smaller) --]]
	local minChildOffset = function(a, b)
		if a == nil then return 1
		elseif b == nil or a.priority < b.priority then return 0
		else return 1 end
	end

	-- while elements not in order (while parent smaller or equal to children - min heap)
	while (childIndex < self.endIndex and 
	       self.heap[parentIndex].priority >= self.heap[childIndex].priority) or
		  (childIndex + 1 < self.endIndex and 
		   self.heap[parentIndex].priority >= self.heap[childIndex + 1].priority) do
		local temp = self.heap[parentIndex]
		local childOffset = minChildOffset(self.heap[childIndex], self.heap[childIndex + 1])
		-- swap them
		self.heap[parentIndex] = self.heap[childIndex + childOffset]
		self.heap[childIndex + childOffset] = temp
		parentIndex = childIndex + childOffset
		childIndex = 2 * parentIndex
	end
	return minNode
end

-- puts an element into the queue with specified priority
function PriorityQueue:put(_element, _priority)
	local heapNode = {element = _element, priority = _priority}
	self.heap[self.endIndex] = heapNode -- insert new node at the end of the heap
	local childIndex = self.endIndex
	local parentIndex = math.floor(childIndex/2)
	self.endIndex = self.endIndex + 1
	
	-- while elements not in order (while parent smaller or equal to child - min heap)
	while parentIndex > 0 and self.heap[parentIndex].priority >= self.heap[childIndex].priority do
		-- swap them
		local temp = self.heap[childIndex]
		self.heap[childIndex] = self.heap[parentIndex]
		self.heap[parentIndex] = temp
		childIndex = parentIndex
		parentIndex = math.floor(childIndex/2)
	end
end

-- returns element at the top of the queue without popping it
function PriorityQueue:top()
	return self.heap[1].element
end

-- returns if queue is empty
function PriorityQueue:empty()
	return self.endIndex <= 1
end

-- returns queue size
function PriorityQueue:size()
	return self.endIndex - 1
end

return PriorityQueue