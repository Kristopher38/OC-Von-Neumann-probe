local utils = require("utils")
local hookOrder = require("hookorder")

local modules = {}

local HookModule = utils.makeClass(function(name)
    local self = {}
    self.name = name or ""
    self.originals = {}

    assert(utils.findIndex(hookOrder, self.name), string.format("Hook module %s not defined in hookorder.lua", self.name))
    assert(not modules[self.name], string.format("Conflicting identical hook module name: %s", self.name))
    modules[self.name] = self

    return self
end)

function HookModule:hook(original, wrapper)
    local suppliedOriginal = original
    if not self.originals[wrapper] then
        -- find where we are on the priority list
        local selfIdx = utils.findIndex(hookOrder, self.name)
        -- iterate through modules with lower priority
        local inbetweenHook = false
        for i = selfIdx + 1, #hookOrder do
            local module = modules[hookOrder[i]]
            -- if module is loaded (is in the modules table) and has a wrapper under our 'original' key,
            -- that means we're hooking inbetween already loaded modules, and this one lower priority
            if module and module.originals[original] then
                -- after that we need to go back and iterate over modules with higher priority than the one found,
                -- from the current module up to our module...
                local tmpWrapper = original
                local tmpOriginal = module.originals[original]
                local tmpModule
                for j = i - 1, selfIdx, -1 do
                    tmpModule = modules[hookOrder[j]]
                    if tmpModule and tmpModule.originals[tmpOriginal] then
                        tmpWrapper = tmpOriginal
                        tmpOriginal = tmpModule.originals[tmpOriginal]
                        module = tmpModule
                    end
                end
                -- ...replace the original of lower priority module...
                module.originals[tmpWrapper] = wrapper
                -- ...and use that lower priority hook to use it as our original
                original = tmpOriginal
                inbetweenHook = true
                break
            end
        end
        self.originals[wrapper] = original

        -- if we're hooking inbetween, we need to keep the original the same since we're not at the lowest priority level,
        -- if we're not, that means we're hooking at the end of priority list so we return wrapper
        return inbetweenHook and suppliedOriginal or wrapper
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