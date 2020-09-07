local component = require("component")
local utils = require("utils")
local event = require("event")
local modem = component.modem
local assembler = component.assembler
local computer = require("computer")

local Server = utils.makeClass(function(self)
    self.commands = {
        ping = self.ping
        assemblerStart = self.assemblerStart
        assemblerStatus = self.assemblerStatus
        shutdown = self.shutdown
    }

    event.listen("modem_message", function(...) self:messageHandler(...) end)
end)

function Server:messageHandler(ev, receiverAddr, senderAddr, port, distance, ...)
    local request = table.pack(...)
    local cmd = request[1]
    local response = table.pack(self.commands[cmd](self, table.unpack(request, 2)))
    modem.send()
end

function Server:assemblerStart()
    return assembler.start()
end

function Server:assemblerStatus()
    return assembler.status()
end

function Server:shutdown()
    return computer.shutdown()
end