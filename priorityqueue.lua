local inspect = require("inspect")

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue
setmetatable(PriorityQueue, {__call = function(cls)
	local self = {}
	self.heap = {}	-- uses binary heap (min heap) for backend
	self.endIndex = 1 -- points to space *after* last element
	setmetatable(self, cls) -- cls = PriorityQueue
	return self
end })

function PriorityQueue:pop()
	local maxNode = self.heap[1]
	-- swap root node with the last node
	self.endIndex = self.endIndex - 1
	self.heap[1] = self.heap[self.endIndex]
	self.heap[self.endIndex] = nil
	local parentIndex = 1
	local childIndex = 2
	
	-- while elements not in order (while parent smaller or equal to children - min heap)
	while (childIndex < self.endIndex and 
	       self.heap[parentIndex].priority >= self.heap[childIndex].priority) or
		  (childIndex + 1 < self.endIndex and 
		   self.heap[parentIndex].priority >= self.heap[childIndex + 1].priority) do
		local temp = self.heap[parentIndex]
		
		if childIndex < self.endIndex and
		   self.heap[parentIndex].priority >= self.heap[childIndex].priority then
		    -- if first child bigger, swap it with parent
			self.heap[parentIndex] = self.heap[childIndex]
			self.heap[childIndex] = temp
			parentIndex = childIndex
		elseif childIndex + 1 < self.endIndex and 
			   self.heap[parentIndex].priority >= self.heap[childIndex + 1].priority then
			-- if second child bigger, swap it with parent
			self.heap[parentIndex] = self.heap[childIndex + 1]
			self.heap[childIndex + 1] = temp
			parentIndex = childIndex + 1
		end
		childIndex = 2 * parentIndex
	end
	return maxNode
end

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

function PriorityQueue:top()
	return self.heap[1]
end

function PriorityQueue:empty()
	return self.endIndex <= 1
end

return PriorityQueue