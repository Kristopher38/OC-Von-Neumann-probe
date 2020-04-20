local AutoYielder = {}
AutoYielder.lastYieldTime = os.clock()
AutoYielder.yieldInterval = 4.5

function AutoYielder.yield()
    local now = os.clock()
    if now - AutoYielder.lastYieldTime >= AutoYielder.yieldInterval then
        coroutine.yield()
        AutoYielder.lastYieldTime = now
    end
end

function AutoYielder.reset()
    AutoYielder.lastYieldTime = os.clock()
end

return AutoYielder