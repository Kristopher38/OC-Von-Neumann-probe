local vec3 = require("vec3")
local utils = require("utils")

local VectorChunk = {}
VectorChunk.__index = VectorChunk
setmetatable(VectorChunk, {__call = function(cls, offset, centerOffset, packValues)
    local self = {}
    self.data = {}
    self.offset = centerOffset and offset - vec3(2048, offset.y, 2048) or (offset or vec3(0, 0, 0))
    self.packValues = packValues or false

    setmetatable(self, cls)
    return self
end })

--[[ Packs x, y, z values in range x: [0, 4095], y: [0, 255], z: [0, 4095]
into a single integer. The packed format is [x: 12 bits, y: 8 bits, z: 12 bits] --]]
local function packxyz(x, y, z, offset)
    return (((x - offset.x) & 0x00000FFF) << 20) | (((y - offset.y) & 0x000000FF) << 12) | ((z - offset.z) & 0x00000FFF)
end

--- unpacks vector as a single integer into x, y, z values
local function unpackxyz(number, offset)
    return ((number & 0xFFF00000) >> 20) + offset.x, ((number & 0x000FF000) >> 12) + offset.y, (number & 0x00000FFF) + offset.z
end

-- all that verbosity below is for extra performance

function VectorChunk:at(vec)
    local value = rawget(self.data, packxyz(vec.x, vec.y, vec.z, self.offset))
    return self.packValues and (value and vec3(unpackxyz(value, self.offset)) or nil) or value
end

function VectorChunk:atxyz(x, y, z)
    local value = rawget(self.data, packxyz(x, y, z, self.offset))
    return self.packValues and (value and vec3(unpackxyz(value, self.offset)) or nil) or value
end

--[[ function VectorChunk:atIndex(index)
    return vec3(unpackxyz(self.data[index]))
end ]]

--[[ function VectorChunk:atIndexXyz(idx)
    return unpackxyz(self.data[vec])
end ]]

function VectorChunk:set(vec, elem)
    rawset(self.data, packxyz(vec.x, vec.y, vec.z, self.offset), self.packValues and packxyz(elem.x, elem.y, elem.z, self.offset) or elem)
end

function VectorChunk:setxyz(x, y, z, elem)
    rawset(self.data, packxyz(x, y, z, self.offset), self.packValues and packxyz(elem.x, elem.y, elem.z, self.offset) or elem)
end

--[[ function VectorChunk:insert(vec)
    table.insert(self.data, packxyz(vec.x, vec.y, vec.z, self.offset))
end ]]

--[[ function VectorChunk:setIndex(index, vec)
    self.data[index] = packxyz(vec.x, vec.y, vec.z, self.offset)
end ]]

function VectorChunk.__index(self, vec)
    if utils.isInstance(vec, vec3) then
        return self:at(vec)
    --[[ elseif type(vec) == "number" then
        return self:atIndex(vec) ]]
    else
        return getmetatable(self)[vec] -- gets the metatable with methods and metamethods
    end
end

function VectorChunk.__newindex(self, vec, elem)
    if utils.isInstance(vec, vec3) then
        self:set(vec, elem)
    --[[ elseif type(vec) == "number" then
        self:setIndex(vec, elem) -- vec is index, elem is the vector to be set ]]
    else
        rawset(self, vec, elem)
    end
end

function VectorChunk.__pairs(self)
    local function statelessIterator(self, index)
        local element
        index, element = next(self.data, index and packxyz(index.x, index.y, index.z, self.offset) or index)
        if element then
            return vec3(unpackxyz(index, self.offset)), self.packValues and vec3(unpackxyz(element, self.offset)) or element
        end
    end

    return statelessIterator, self, nil
end

--[[ function VectorChunk.__ipairs(self)
    local function statelessIterator(self, index)
        index = index + 1
        local element = self.data[index]
        if element then
            return index, vec3(unpackxyz(element, self.offset))
        end
    end

    return statelessIterator, self, 0
end ]]

return VectorChunk