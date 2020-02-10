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

-- converts vector from global coordinates to local coordinates in a chunk calculated using given chunk offset
local function localFromAbsolute(vector, offset, chunkSize)
    return vector.x % (chunkSize.x), vector.y % (chunkSize.y), vector.z % (chunkSize.z)
end

-- calculates global coordinates from local coordinates in a chunk using given chunk offset
local function absoluteFromLocal(vector, offset, chunkSize)
	return vector.x + chunkSize.x * offset.x, vector.y + chunkSize.y * offset.y, vector.z + chunkSize.z * offset.z
end

-- calculates chunk offset from global coordinates
local function offsetFromAbsolute(vector, chunkSize)
	return math.floor(vector.x / chunkSize.x), math.floor(vector.y / chunkSize.y), math.floor(vector.z / chunkSize.z)
end

local function packxyz(x, y, z)
	return string.pack("<LLL", x, y, z)
end

local function unpackxyz(number)
	return string.unpack("<LLL", number)
end

function VectorMap:at(vector)
	local x, y, z = offsetFromAbsolute(vector, self.chunkSize)
	local chunk = self.chunks[packxyz(x, y, z)]
	if chunk ~= nil then
		local localx, localy, localz = localFromAbsolute(vector, chunkOffset, self.chunkSize)
		return chunk:atxyz(localx, localy, localz)
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

function VectorMap:saveChunk(coords)
	local chunkx, chunky, chunkz = offsetFromAbsolute(coords, self.chunkSize)
	local chunkHash = packxyz(chunkx, chunky, chunkz)
	data = string.pack("<LLL", map.chunkSize.x, map.chunkSize.y, map.chunkSize.z)
	for x = 0, map.chunkSize.x - 1 do
		for y = 0, map.chunkSize.y - 1 do
			for z = 0, map.chunkSize.z - 1 do
				local block = map.chunks[chunkHash]:atxyz(x, y, z)
				if block == nil then
					block = -1
				end
				data = data .. string.pack("<f", block)
			end
		end
	end
	local filePath = "/home/chunks/" .. tostring(vec3(chunkx, chunky, chunkz)) .. ".chnk"
	local chunkFile = io.open(filePath, "w")
	chunkFile:write(data)
	chunkFile:close()
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
			local chunkVector = vec3(unpackxyz(chunkIndex))
			index, element = chunkIterator(chunk, index and vec3(localFromAbsolute(index, chunkVector, self.chunkSize)) or index)
			if element then
				return vec3(absoluteFromLocal(index, chunkVector, self.chunkSize)), element
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