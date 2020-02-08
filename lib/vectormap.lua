local utils = require("utils")
local vec3 = require("vec3")
local VectorChunk = require("vectorchunk")
local inspect = require("inspect")

local VectorMap = {}
VectorMap.__index = VectorMap
setmetatable(VectorMap, {__call = function(cls, _chunkSize)
	local self = {}
	self.chunks = {}
	self.chunkSize = _chunkSize or vec3(16, 16, 16)
	-- order is important since we're overriding __newindex method!
	-- setmetatable has to be called after setting fields
	setmetatable(self, cls) -- cls is current table: VectorMap
	return self
end })

-- converts vector from global coordinates to local coordinates calculated using given offset
local function localFromAbsolute(vector, offset, chunkSize)
    return vector.x % (chunkSize.x), vector.y % (chunkSize.y), vector.z % (chunkSize.z)
end

local function absoluteFromLocal(vector, offset, chunkSize)
	return vec3(vector.x + chunkSize.x * offset.x, vector.y + chunkSize.y * offset.y, vector.z + chunkSize.z * offset.z)
end

-- calculates chunk offset from absolute coordinates
local function offsetFromAbsolute(vector, chunkSize)
	return math.floor(vector.x / chunkSize.x), math.floor(vector.y / chunkSize.y), math.floor(vector.z / chunkSize.z)
end

local function packxyz(_x, _y, _z)
	local x = bit32.lrotate(bit32.extract(_x, 0, 12), 20)
	local y = bit32.lrotate(bit32.extract(_y, 0, 8), 12)
	local z = bit32.extract(_z, 0, 12)
	return bit32.bor(x, y, z)
end

function VectorMap:at(vector)
	local x, y, z = offsetFromAbsolute(vector, self.chunkSize)
	local chunk = self.chunks[packxyz(x, y, z)]
	if chunk ~= nil then
		local localx, localy, localz = localFromAbsolute(vector, chunkOffset, self.chunkSize)
		return chunk:atxyz(localx, localy, localz) --localCoords)
	else
		return nil -- return something else, possibly some enum.not_present
	end
end

function VectorMap:set(vector, element)
	local x, y, z = offsetFromAbsolute(vector, self.chunkSize)
	local chunkHash = packxyz(x, y, z)
	if self.chunks[chunkHash] == nil then 
		self.chunks[chunkHash] = VectorChunk(chunkOffset)
	end
	local localx, localy, localz = localFromAbsolute(vector, chunkOffset, self.chunkSize)
	self.chunks[chunkHash]:setxyz(localx, localy, localz, element)
end

function VectorMap.__index(self, vector)
	if utils.isInstance(vector, vec3) then
		return self:at(vector)
	else
		return getmetatable(self)[vector] -- dealing with something else than vector index
	end
end

function VectorMap.__newindex(self, vector, element)
	if utils.isInstance(vector, vec3) then
		self:set(vector, element)
	else
		rawset(self, vector, element) -- dealing with something else than vector index
	end
end

function VectorMap.__pairs(self)
	local chunk
	local chunkIterator
	local chunkIndex
	chunkIndex, chunk = next(self.chunks, nil)
	if chunk then
		chunkIterator = pairs(chunk)
	end
	local function iterator(self, index)
		if chunkIterator then
			local chunkVector = vec3.tovec3(chunkIndex)
			index, element = chunkIterator(chunk, index and vec3(table.unpack({localFromAbsolute(index, chunkVector, self.chunkSize)})) or index)
			if element then
				return absoluteFromLocal(index, chunkVector, self.chunkSize), element
			else
				chunkIndex, chunk = next(self.chunks, chunkIndex)
				if chunk then
					chunkIterator = pairs(chunk)
					return iterator(self, index)
				end
			end
		end
	end

	return iterator, self, nil
end



return VectorMap