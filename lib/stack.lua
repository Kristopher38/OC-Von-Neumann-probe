local utils = require("utils")

local Stack = utils.makeClass(function(self)

end)

function Stack:push(v)
    self[#self + 1] = v
end

function Stack:pop()
    local tmp = self[#self]
    self[#self] = nil
    return tmp
end

function Stack:top()
    return self[#self]
end

function Stack:size()
    return #self
end