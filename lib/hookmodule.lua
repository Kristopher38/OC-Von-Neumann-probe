local utils = require("utils")

local HookModule = utils.makeClass(function(priority)
    local self = {}
    self.priority = priority or 0
    self.originals = {}
    
    return self
end)

function HookModule:hook(original, wrapper)
    if not self.originals[wrapper] then
        self.originals[wrapper] = original
        return wrapper
    else
        error("Cannot hook into an already hooked function in the same module")
    end
end

function HookModule:unhook(wrapper)
    if self.originals[wrapper] then
        local original = self.originals[wrapper]
        self.originals[wrapper] = nil
        return original
    else
        error("Cannot unhook function which was not hooked into before")
    end
end

function HookModule:callOriginal(wrapper, ...)
    if self.originals[wrapper] then
        return self.originals[wrapper](...)
    else
        error("Cannot call original which was not hooked into")
    end
end

function HookModule:start()
    return self
end

function HookModule:stop()
    return self
end

return HookModule