local computer = require("computer")
local utils = require("utils")
local logLevel = require("loglevel")
local logHandlers = require("loghandlers")

local Logging = logLevel

---------- Logger class ----------

local Logger = {}
Logger.__index = Logger
setmetatable(Logger, {__call = function(cls, name, level, handlers, format, dateFormat)
    local self = {}
    self.name = name or "root"
    self.level = level or logLevel.NOTSET
    self.handlers = handlers or { logHandlers.StreamHandler(logLevel.NOTSET) }
    self.format = format or "[%s][%s] %s: %s\n" -- timestamp [name] level: message

	setmetatable(self, cls)
	return self
end })

function Logger:setLevel(level)
    self.level = level
end

function Logger:formatDate(time)
    local ms = ((time % 1) * 1000) // 1
    return string.format("%s.%03u", os.date('%Y-%m-%d %H:%M:%S', time), ms)
end

function Logger:addHandler(handler)
    table.insert(self.handlers, handler)
end

function Logger:removeHandler(handler)
    for i, h in ipairs(self.handlers) do
        if h == handler then
            table.remove(self.handlers, i)
            break
        end
    end
end

function Logger:hasHandlers()
    return #self.handlers > 0
end

function Logger:log(level, msg, ...)
    if level >= self.level then
        local formatted = string.format(self.format, self:formatDate(utils.realTime()), self.name, Logging[level], string.format(msg, ...))
        for i, handler in ipairs(self.handlers) do
            handler:log(level, formatted)
        end
    end
end

function Logger:debug(msg, ...)
    return self:log(logLevel.DEBUG, msg, ...)
end

function Logger:info(msg, ...)
    return self:log(logLevel.INFO, msg, ...)
end

function Logger:warning(msg, ...)
    return self:log(logLevel.WARNING, msg, ...)
end

function Logger:error(msg, ...)
    return self:log(logLevel.ERROR, msg, ...)
end

function Logger:critical(msg, ...)
    return self:log(logLevel.CRITICAL, msg, ...)
end


---------- Logging class ----------

Logging.loggers = {
    root = Logger()
}

function Logging:getLogger(name)
    if not self.loggers[name] then
        self.loggers[name] = Logger(name)
    end
    return self.loggers[name]
end

setmetatable(Logging, {__index = Logging.loggers.root})

return Logging