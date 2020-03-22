local utils = require("utils")
local vec3 = require("vec3")
local VectorChunk = require("vectorchunk")
local inspect = require("inspect")

local VectorMap = {}
VectorMap.__index = VectorMap
VectorMap.fileHeader = "<c4lllc1"
VectorMap.magicString = "CHNK"
VectorMap.extension = "chnk"
VectorMap.chunkFolder= "/home/chunks/"
setmetatable(VectorMap, {__call = function(cls, _chunkSize, _storedType)
	local self = {}
	self.chunks = {}
	self.chunkSize = _chunkSize or vec3(4096, 256, 4096)
	self.storedType = _storedType or "f"
	-- order is important since we're overriding __newindex method!
	-- setmetatable has to be called after setting fields
	setmetatable(self, cls) -- cls is current table: VectorMap
	return self
end })

-- converts vector from global coordinates to local coordinates in a chunk calculated using given chunk offset
local function localFromAbsolute(vector, chunkSize)
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
	return string.pack("<lll", x, y, z)
end

local function unpackxyz(number)
	return string.unpack("<lll", number)
end

function VectorMap:at(vector)
	local x, y, z = offsetFromAbsolute(vector, self.chunkSize)
	local chunk = self.chunks[packxyz(x, y, z)]
	if chunk ~= nil then
		local localx, localy, localz = localFromAbsolute(vector, self.chunkSize)
		return chunk:atxyz(localx, localy, localz)
	else
		return nil -- return something else, possibly some enum.not_present
	end
end

function VectorMap:set(vector, element)
	local x, y, z = offsetFromAbsolute(vector, self.chunkSize)
	local chunkHash = packxyz(x, y, z)
	if self.chunks[chunkHash] == nil then
		self.chunks[chunkHash] = VectorChunk()
	end
	local localx, localy, localz = localFromAbsolute(vector, self.chunkSize)
	self.chunks[chunkHash]:setxyz(localx, localy, localz, element)
end

function VectorMap:getPackFormat(dataFormat)
	return "<" .. dataFormat
end

function VectorMap:getFileName(chunkCoords)
	return self.chunkFolder .. tostring(chunkCoords) .. "." .. self.extension
end

function VectorMap:saveChunk(coords)
	local chunkCoords = vec3(offsetFromAbsolute(coords, self.chunkSize))
	local chunkHash = packxyz(chunkCoords.x, chunkCoords.y, chunkCoords.z)
	local data = string.pack(self.fileHeader, self.magicString, self.chunkSize.x, self.chunkSize.y, self.chunkSize.z, self.storedType)
	local packFormat = self:getPackFormat(self.storedType)
	for x = 0, self.chunkSize.x - 1 do
		for y = 0, self.chunkSize.y - 1 do
			for z = 0, self.chunkSize.z - 1 do
				local block = self.chunks[chunkHash]:atxyz(x, y, z)
				data = data .. string.pack(packFormat, block and block or -1)
			end
		end
	end
	
	local filePath = self:getFileName(chunkCoords)
	local chunkFile = io.open(filePath, "w")
	chunkFile:write(data)
	chunkFile:close()
end

function VectorMap:loadChunk(coords)
	local chunkCoords = vec3(offsetFromAbsolute(coords, self.chunkSize))
	local chunkHash = packxyz(chunkCoords.x, chunkCoords.y, chunkCoords.z)
	local filePath = self:getFileName(chunkCoords)
	local chunkFile = io.open(filePath, "r")
	
	if io.type(chunkFile) == "file" then
		local magicString, chunkSizex, chunkSizey, chunkSizez, dataFormat = string.unpack(self.fileHeader, chunkFile:read(8))

		if magicString == self.magicString and
		chunkSizex == self.chunkSize.x and 
		chunkSizey == self.chunkSize.y and 
		chunkSizez == self.chunkSize.z then
			local packFormat = self:getPackFormat(dataFormat)
			local formatSize = string.packsize(packFormat)
			
			for x = 0, self.chunkSize.x - 1 do
				for y = 0, self.chunkSize.y - 1 do
					for z = 0, self.chunkSize.z - 1 do
						local block = string.unpack(packFormat, chunkFile:read(formatSize))
						self.chunks[chunkHash]:setxyz(x, y, z, block ~= -1 and block or nil)
					end
				end
			end
		end
	end
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

function VectorMap.__len(self)
	local len = 0
	for k, v in pairs(self) do
		len = len + 1
	end
	return len
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
			index, element = chunkIterator(chunk, index and vec3(localFromAbsolute(index, self.chunkSize)) or index)
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