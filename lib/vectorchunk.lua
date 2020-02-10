local vec3 = require("vec3")
local utils = require("utils")

local VectorChunk = {}
VectorChunk.__index = VectorChunk
setmetatable(VectorChunk, {__call = function(cls)
    local self = {}

    setmetatable(self, cls)
    return self
end })

--[[ Packs x, y, z values in range x: [0, 4095], y: [0, 255], z: [0, 4095]
into a single integer. The packed format is [x: 12 bits, y: 8 bits, z: 12 bits] --]]
local function packxyz(x, y, z)
    return ((x & 0x00000FFF) << 20) | ((y & 0x000000FF) << 12) | (z & 0x00000FFF)
end

--- unpacks vector as a single integer into x, y, z values
local function unpackxyz(number)
    return (number & 0xFFF00000) >> 20, (number & 0x000FF000) >> 12, number & 0x00000FFF
end

function VectorChunk:at(vector)
    return rawget(self, packxyz(vector.x, vector.y, vector.z))
end

function VectorChunk:atxyz(x, y, z)
    return rawget(self, packxyz(x, y, z))
end

function VectorChunk:set(vector, element)
    rawset(self, packxyz(vector.x, vector.y, vector.z), element)
end

function VectorChunk:setxyz(x, y, z, element)
    rawset(self, packxyz(x, y, z), element)
end

function VectorChunk.__index(self, vector)
    if utils.isInstance(vector, vec3) then
        return self:at(vector)
    else
        return getmetatable(self)[vector] -- gets the metatable with methods and metamethods
    end
end

function VectorChunk.__newindex(self, vector, element)
    if utils.isInstance(vector, vec3) then
        self:set(vector, element)
    else
        rawset(self, vector, element)
    end
end

function VectorChunk.__pairs(self)
    local function statelessIterator(self, index)
        local element
        index, element = next(self, index and packxyz(index.x, index.y, index.z) or index)
        if element then
            return vec3(unpackxyz(index)), element
        end
    end

    return statelessIterator, self, nil
end

return VectorChunk