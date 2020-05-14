local computer = require("computer")

local Logging = {
    NOTSET = 0,
    DEBUG = 10,
    INFO = 20,
    WARNING = 30,
    ERROR = 40,
    CRITICAL = 50,
    
    [0] = "NOTSET",
    [10] = "DEBUG",
    [20] = "INFO",
    [30] = "WARNING",
    [40] = "ERROR",
    [50] = "CRITICAL",
}

local Logger = {}
Logger.__index = Logger
setmetatable(Logger, {__call = function(cls, name, level, format, dateFormat)
    local self = {}
    self.name = name or "root"
    self.level = level or Logging.INFO
    self.format = format or "[%s][%s] %s: %s\n" -- timestamp [name] level: message

	setmetatable(self, cls)
	return self
end })

function Logger:setLevel(level)
    self.level = level
end

function Logger:formatDate()
    local time = computer.uptime()
    local ms = ((time % 1) * 1000) // 1
    local s = (time // 1) % 60
    local m = (time // 60) % 60
    local h = (time // 3600) % 60
    return string.format("%02u:%02u:%02u.%03u", h, m, s, ms)
end

function Logger:log(level, msg, ...)
    if level >= self.level then
        local formatted = string.format(self.format, self:formatDate(), self.name, Logging[level], string.format(msg, ...))
        io.stdout:write(formatted)
    end
end

function Logger:debug(msg, ...)
    return self:log(Logging.DEBUG, msg, ...)
end

function Logger:info(msg, ...)
    return self:log(Logging.INFO, msg, ...)
end

function Logger:warning(msg, ...)
    return self:log(Logging.WARNING, msg, ...)
end

function Logger:error(msg, ...)
    return self:log(Logging.ERROR, msg, ...)
end

function Logger:critical(msg, ...)
    return self:log(Logging.CRITICAL, msg, ...)
end

Logging.loggers = {
    root = Logger()
}

function Logging:getLogger(name)
    if not self.loggers[name] then
        self.loggers[name] = Logger(name)
    end
    return self.loggers[name]
end

setmetatable(Logging, {__index = function(self, index)
    return self.loggers.root[index]
end })

return Logging