local utils = require("utils")
local logLevel = require("loglevel")
local component = require("component")
local internet
if component.isAvailable("internet") then
    internet = component.internet
end
local modem
if component.isAvailable("modem") then
    modem = component.modem
end

---------- Handler class and builtin handlers ----------

local handlers = {}

handlers.Handler = utils.makeClass(function(self, level, logFunc)
    self.level = level or logLevel.NOTSET
    self.log = logFunc or function(self, level, msg) end
end)

handlers.StreamHandler = utils.makeClass(function(self, level, stream)
    self:__initBase(handlers.Handler(level, function(self, level, msg)
        if level >= self.level then
            self.stream:write(msg)
            self.stream:flush()
        end
    end))
    self.stream = stream or io.stdout
end)

handlers.HttpHandler = utils.makeClass(function(self, level, address)
    if internet then
        self:__initBase(handlers.Handler(level, function(self, level, msg)
            if level >= self.level then
                local r = internet.request(address, msg)
                r:close()
            end
        end))
    else
        error("HTTP handler requires an internet card to run")
    end
end)

handlers.BroadcastHandler = utils.makeClass(function(self, level, port)
    if modem then
        self:__initBase(handlers.Handler(level, function(self, level, msg)
            if level >= self.level then
                modem.broadcast(port, msg)
            end
        end))
    else
        error("Broadcast handler requires a network card to run")
    end
end, handlers.Handler)

return handlers