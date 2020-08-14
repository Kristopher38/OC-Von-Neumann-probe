local vec3 = require("vec3")
local utils = require("utils")
local locTracker = require("locationtracker")

local VectorChunk = {}
--VectorChunk.__index = VectorChunk

setmetatable(VectorChunk, {__call = function(cls, packValues, allowFloats, offset)
    local self = {}
    self.hashData = {}
    self.arrayData = {}
    -- default offset to locTracker.position, and if it doesn't exist, default to vector [0, 0, 0]
    self.offset = offset and offset or (locTracker.position and (locTracker.position - vec3(2048, locTracker.position.y, 2048)) or vec3(0, 0, 0))
    self.pack = allowFloats and cls.packFloat or cls.packInt
    self.unpack = allowFloats and cls.unpackFloat or cls.unpackInt
    self.packValues = packValues or false

    setmetatable(self, cls)
    return self
end })

--[[ Packs x, y, z values in range x: [0, 4095], y: [0, 255], z: [0, 4095]
into a single integer. The packed format is [x: 12 bits, y: 8 bits, z: 12 bits] --]]
function VectorChunk:packInt(x, y, z)
    local offset = self.offset
    return (((x - offset.x) & 0x00000FFF) << 20) |
           (((y - offset.y) & 0x000000FF) << 12) |
           ((z - offset.z) & 0x00000FFF)
end

--- unpacks vector as a single integer into x, y, z values
function VectorChunk:unpackInt(number)
    local offset = self.offset
    return ((number & 0xFFF00000) >> 20) + offset.x,
           ((number & 0x000FF000) >> 12) + offset.y,
           (number & 0x00000FFF) + offset.z
end

-- packs vector with floating point coordinates into a string using string.pack 
function VectorChunk:packFloat(x, y, z)
    local offset = self.offset
    return string.pack(">fff", x - offset.x, y - offset.y, z - offset.z)
end

-- unpacks vector with floating point coordinates from string into x, y, z value using string.unpack
function VectorChunk:unpackFloat(number)
    local offset = self.offset
    local x, y, z = string.unpack(">fff", number)
    return x + offset.x, y + offset.y, z + offset.z
end

--[[ below are raw methods for accessing data without using __index and __newindex, with their
optimized versions (not needing a vec3 object as constructing new table is inefficient) having
"xyz" suffix --]]

function VectorChunk:at(vec)
    local value = self.hashData[self:pack(vec.x, vec.y, vec.z)]
    return self.packValues and (value and vec3(self:unpack(value)) or nil) or value
end

function VectorChunk:atxyz(x, y, z)
    local value = self.hashData[self:pack(x, y, z)]
    return self.packValues and (value and vec3(self:unpack(value)) or nil) or value
end

function VectorChunk:atIndex(index)
    return self.arrayData[index] and vec3(self:unpack(self.arrayData[index])) or nil
end

function VectorChunk:set(vec, elem)
    self.hashData[self:pack(vec.x, vec.y, vec.z)] = self.packValues and self:pack(elem.x, elem.y, elem.z) or elem
end

function VectorChunk:setxyz(x, y, z, elem)
    self.hashData[self:pack(x, y, z)] = self.packValues and self:pack(elem.x, elem.y, elem.z) or elem
end

function VectorChunk:setIndex(index, vec)
    self.arrayData[index] = vec and self:pack(vec.x, vec.y, vec.z) or nil
end

function VectorChunk:setIndexXyz(index, x, y, z)
    self.arrayData[index] = self:pack(x, y, z)
end

function VectorChunk:insert(pos, vec)
    if vec then
        table.insert(self.arrayData, pos, self:pack(vec.x, vec.y, vec.z))
    else
        vec = pos
        self.arrayData[#self.arrayData + 1] = vec and self:pack(vec.x, vec.y, vec.z) or nil
    end
end

function VectorChunk:remove(index)
    return vec3(self:unpack(table.remove(self.arrayData, index)))
end

function VectorChunk.__index(self, index)
    if utils.isInstance(index, vec3) then
        return self:at(index)
    elseif type(index) == "number" then
        return self:atIndex(index)
    else
        return getmetatable(self)[index] -- gets the metatable with methods and metamethods and returns a method
    end
end

function VectorChunk.__newindex(self, index, elem)
    if utils.isInstance(index, vec3) then
        self:set(index, elem)
    elseif type(index) == "number" then
        self:setIndex(index, elem)
    else
        rawset(self, index, elem) -- dealing with raw table elements
    end
end

-- not guaranteed to be the largest index
function VectorChunk.__len(self)
    return #self.arrayData
end

function VectorChunk.__pairs(self)
    local function statelessIterator(self, index)
        local element
        index, element = next(self.hashData, index and self:pack(index.x, index.y, index.z) or index)
        if element then
            return vec3(self:unpack(index)), self.packValues and vec3(self:unpack(element)) or element
        end
    end

    return statelessIterator, self, nil
end

-- another way of writing pairs(VectorChunkObject) to make it more standardized in line with VectorChunk.ipairs
function VectorChunk:pairs()
    return self.__pairs(self)
end

--[[ Lua 5.3 doesn't support __ipairs metamethod anymore, so we use custom-named function returning an
iterator (note that ipairs(VectorChunkObject) will still work because standard ipairs now uses the
index metamethod which is implemented above) --]]
function VectorChunk:ipairs()
    local function statelessIterator(self, index)
        index = index + 1
        local element = self.arrayData[index]
        if element then
            return index, vec3(self:unpack(element))
        end
    end

    return statelessIterator, self, 0
end

return VectorChunk