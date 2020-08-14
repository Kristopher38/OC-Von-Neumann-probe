local utils = require("utils")
local logLevel = require("loglevel")
local component = require("component")
local internet
if component.isAvailable("internet") then
    internet = component.internet
end

---------- Handler class and builtin handlers ----------

local handlers = {}

handlers.Handler = utils.makeClass(function(level, logFunc)
    local self = {}
    self.level = level or logLevel.NOTSET
    self.log = logFunc or function(self, level, msg) end
	return self
end)

handlers.StreamHandler = utils.makeClass(function(level, stream)
    local self = handlers.Handler(level, function(self, level, msg)
        if level >= self.level then
            self.stream:write(msg)
            self.stream:flush()
        end
    end)
    self.stream = stream or io.stdout
    return self
end, handlers.Handler)

handlers.HttpHandler = utils.makeClass(function(level, address)
    if internet then
        local self = handlers.Handler(level, function(self, level, msg)
            if level >= self.level then
                local r = internet.request(address, msg)
                r:close()
            end
        end)
        return self
    else
        error("HTTP handler requires an internet card to run")
    end
end, handlers.Handler)

return handlers