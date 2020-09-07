local utils = require("utils")
local event = require("event")
local component = require("component")
local modem = component.modem

if not modem.isWireless() then
    error("Robot requires wireless network card to function properly")
end

local BaseComputer = utils.makeClass(function(self)
    self.modemAddr = nil
    self.commsPort = 1957 -- year of von Neumann's death
    self.cmdDelay = 0.5 -- wait 10 ticks before assuming the packet got lost
    self.wakeCmd = nil
    self.wakeDelay = 6.0  -- OpenOS boot time on tier 1 hardware
    self.pingCmd = "ping"
    self.assemblerStartCmd = "assemblerStart"
    self.assemblerStatusCmd = "assemblerStatus"
end)

function BaseComputer:assurePortOpen()
    if not modem.isOpen(self.commsPort) then
        modem.open(self.commsPort)
    end
end

function BaseComputer:sendCmd(command, delay, retries, broadcast)
    retries = retries or 1
    broadcast = broadcast or false

    self:assurePortOpen()
    for i = 1, retries do
        if broadcast then
            modem.broadcast(self.commsPort, command)
        else
            modem.send(self.modemAddr, self.commsPort, command)
        end
        local response = table.pack(event.pull(delay, "modem_message"))
        if response.n > 0 then
            return response
        else
            return nil
        end
    end
end

function BaseComputer:wake(retries)
    retries = retries or 1
    for i = 1, retries do
        self:sendCmd(self.wakeCmd, self.wakeDelay, 1, true)
        if self:ping() then
            return true
        end
    end
    return false
end

function BaseComputer:ping(retries)
    local response = self:sendCmd(self.pingCmd, self.cmdDelay, retries, false)
    return response ~= nil
end

function BaseComputer:configure()

end

function BaseComputer:assemblerStart(retries)
    local response = self:sendCmd(self.assemblerStartCmd, self.cmdDelay, retries, false)
    
end

function BaseComputer:assemblerStatus(retries)
    local response = self:sendCmd(self.assemblerStatusCmd, self.cmdDelay, retries, false)
end

function BaseComputer:shutdown(retries)
    retries = retries or 1
    for i = 1, retries do
        self:sendCmd(self.shutdownCmd, self.cmdDelay, 1, false)
        if not self:ping() then
            return true
        end
    end
    return false
end

return BaseComputer