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

function VectorMap.__index(self, vector, ...)
	if utils.isInstance(vector, vec3) then
		local chunkOffset = self:offsetFromAbsolute(vector)
		local chunkHash = tostring(chunkOffset)
		if self.chunks[chunkHash] ~= nil then
			local localCoords = self:localFromAbsolute(vector, chunkOffset)
			if self.chunks[chunkHash][localCoords] ~= nil then
				return self.chunks[chunkHash][localCoords]
			else
				return nil -- return something else
			end
		else
			return nil -- return something else, possibly some enum.not_present
		end
	else
		return getmetatable(self)[vector] -- dealing with something else than vector index
	end
end

function VectorMap.__newindex(self, vector, element)
	if utils.isInstance(vector, vec3) then
		local chunkOffset = self:offsetFromAbsolute(vector)
		local chunkHash = tostring(chunkOffset)
		if self.chunks[chunkHash] == nil then 
			self.chunks[chunkHash] = VectorChunk(chunkOffset)
		end
		local localCoords = self:localFromAbsolute(vector, chunkOffset)
		self.chunks[chunkHash][localCoords] = element
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
			index, element = chunkIterator(chunk, index and self:localFromAbsolute(index, vec3.tovec3(chunkIndex)) or index)
			if element then
				return self:absoluteFromLocal(index, vec3.tovec3(chunkIndex)), element
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

-- converts vector from global coordinates to local coordinates calculated using given offset
function VectorMap:localFromAbsolute(vector, offset)
    local localVector = vec3()
    localVector.x = vector.x % (self.chunkSize.x)
    localVector.y = vector.y % (self.chunkSize.y)
	localVector.z = vector.z % (self.chunkSize.z)
    return localVector
end

function VectorMap:absoluteFromLocal(vector, offset)
	local absoluteVector = vec3()
	absoluteVector.x = vector.x + self.chunkSize.x * offset.x
	absoluteVector.y = vector.y + self.chunkSize.y * offset.y
	absoluteVector.z = vector.z + self.chunkSize.z * offset.z
	return absoluteVector
end

-- calculates chunk offset from absolute coordinates
function VectorMap:offsetFromAbsolute(vector)
	local offset = vec3()
	offset.x = math.floor(vector.x / self.chunkSize.x)
	offset.y = math.floor(vector.y / self.chunkSize.y)
	offset.z = math.floor(vector.z / self.chunkSize.z)
	return offset
end

return VectorMap