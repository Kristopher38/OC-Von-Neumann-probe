local bit32 = require("bit32")
local vec3 = require("vec3")
local utils = require("utils")

local VectorChunk = {}
VectorChunk.__index = VectorChunk
setmetatable(VectorChunk, {__call = function(cls)
    local self = {}

    setmetatable(self, cls)
    return self
end })

--[[ Packs single vec3 in range [0, 4095] x [0, 255] x [0, 4095] into a single integer.
The packed format is [x: 12 bits, y: 8 bits, z: 12 bits] Note: any non-integer value 
automatically gets rounded to the nearest integer --]]
local function pack(vector)
    if vector.x >= 0 and vector.x <= 4095 and
       vector.y >= 0 and vector.y <= 255 and
       vector.z >= 0 and vector.z <= 4095 then
        local x = bit32.lrotate(bit32.extract(vector.x, 0, 12), 20)
        local y = bit32.lrotate(bit32.extract(vector.y, 0, 8), 12)
        local z = bit32.extract(vector.z, 0, 12)
        return bit32.bor(x, y, z)
    else
        error("Supplied vector " .. tostring(vector) .. " isn't in range: x = [0, 4095], y = [0, 255], z = [0, 4095]")
    end
end

-- unpacks vector as a single integer into a vec3 object
local function unpack(number)
    local vector = vec3()
    vector.x = bit32.extract(number, 20, 12)
    vector.y = bit32.extract(number, 12, 8)
    vector.z = bit32.extract(number, 0, 12)
    return vector
end

function VectorChunk.__index(self, vector)
    if utils.isInstance(vector, vec3) then
        return rawget(self, pack(vector))
    else
        return getmetatable(self)[vector] -- gets the metatable with methods and metamethods
    end
end

function VectorChunk.__newindex(self, vector, element)
    if utils.isInstance(vector, vec3) then
        rawset(self, pack(vector), element)
    else
        rawset(self, vector, element)
    end
end

function VectorChunk.__pairs(self)
    local function statelessIterator(self, index)
        local element
        index, element = next(self, index and pack(index) or index)
        if element then
            return unpack(index), element
        end
    end

    return statelessIterator, self, nil
end

return VectorChunk