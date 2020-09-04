local PriorityQueue = require("priorityqueue")
local Stack = require("stack")
local utils = require("utils")
local interrupts = require("interrupts")
local locTracker = require("locationtracker")

local JobsMachine = utils.makeClass(function()
    local self = {}
    self.jobs = PriorityQueue()
    self.periodics = {}
    return self
end)

function JobsMachine:put(jobName, jobFunc, prioriy)
    local jobCoro = coroutine.create(jobFunc)
    self.jobs:put({
        name = jobName,
        coro = jobCoro
    }, priority)
    self:updateJob(self:current())
end

function JobsMachine:pop()
    self.jobs:pop()
end

function JobsMachine:current()
    return self.jobs:top()
end

function JobsMachine:saveJob(job)
    job.orientation = locTracker.orientation
    job.position = utils.deepCopy(locTracker.position)
end

function JobsMachine:returnToJob(job)
    nav.goTo(job.position)
    nav.faceBlock(job.orientation)
end

function JobsMachine:start()
    while self.jobs:size() > 0 do
        -- run functions which need to be called periodically
        for i = 1, #self.periodics do
            local name, f, priority = self.periodics[i]()
            -- if we got a result that means there's an interrupt and we need to process it according to priorities
            if name then
                self:put(name, f, priority)
            end
        end

        local currentJob = self:current()
        self:returnToJob(currentJob)
        coroutine.resume(currentJob.coro)
        self:saveJob(currentJob)
        local status = coroutine.status(currentJob.coro)
        if status == "suspended" then
        
        elseif status == "dead" then
            self:pop() -- job has finished
        end
    end
end