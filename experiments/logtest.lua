package.loaded.utils = nil
package.loaded.logging = nil
package.loaded.loghandlers = nil
local component = require("component")
local internet = component.internet

local logging = require("logging")
local handlers = require("loghandlers")

local log = logging:getLogger("testlogger")
local logfile = io.open("logfile.log", "a")
log:setLevel(logging.DEBUG)
log:addHandler(handlers.HttpHandler(logging.INFO, "http://127.0.0.1:8080"))
log:addHandler(handlers.StreamHandler(logging.DEBUG, logfile))

log:info("foo")
log:debug("bar")
logging:info("baz")