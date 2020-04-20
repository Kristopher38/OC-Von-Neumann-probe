local AutoYielder = {}
AutoYielder.__index = AutoYielder
setmetatable(AutoYielder, {__call = function(cls, yieldInterval)
    local self = {}
    self.lastYieldTime = os.clock()
    self.yieldInterval = yieldInterval or 4.5

	setmetatable(self, cls)
	return self
end })

function AutoYielder:yield()
    local now = os.clock()
    if now - self.lastYieldTime >= self.yieldInterval then
        coroutine.yield()
        self.lastYieldTime = now
    end
end

function AutoYielder:reset()
    self.lastYieldTime = os.clock()
end

return AutoYielder