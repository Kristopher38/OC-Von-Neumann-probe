local event = require("event")

local AutoYielder = {}
AutoYielder.lastYieldTime = os.clock()
AutoYielder.yieldInterval = 4.5

function AutoYielder.yield()
    local now = os.clock()
    if now - AutoYielder.lastYieldTime >= AutoYielder.yieldInterval then
        event.pull(0.1)
        AutoYielder.lastYieldTime = now
    end
end

function AutoYielder.reset()
    AutoYielder.lastYieldTime = os.clock()
end

return AutoYielder