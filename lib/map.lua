local vec3 = require("vec3")
local VectorMap = require("vectormap")
local blockType = require("blocktype")
local utils = require("utils")
local VectorChunk = require("vectorchunk")
local filesystem = require("filesystem")
local computer = require("computer")
local logging = require("logging")
local handlers = require("loghandlers")
local log = logging:getLogger("map"):setLevel(logging.DEBUG):addHandler(handlers.StreamHandler(logging.DEBUG, io.open("maplog.log", "a")))

local map = VectorMap(false, false, vec3(16, 16, 16))
map.storedType = "f"
map.fileHeader = "<c4lll"
map.magicString = "CHNK"
map.extension = "chunk"
map.chunkFolder = "/home/chunks/"
map.savedChunks = {} -- list of chunks stored on disk

-- rougly the amount of memory a single full chunk takes, it's the element count * 2 (key+value) * 9 (each element,
-- both key and value, takes 9 bytes) + 1024 (extra for metadata stored in a chunk)
map.chunkMemorySize = map.chunkSize.x * map.chunkSize.y * map.chunkSize.z * 2 * 9 + 1024
map.loadedChunks = 0
map.maxMemoryUsage = 150000 -- 1024 * 1024; -- 1MB
map.maxLoadedChunks = map.maxMemoryUsage // map.chunkMemorySize

-- initialize which chunks we already have stored on disk
for chunkfile in filesystem.list(map.chunkFolder) do
    local filename, extension = string.match(filesystem.name(chunkfile), "(.+)%.(.+)")
    if extension == map.extension then
        local x, y, z = string.match(filename, "%[(%-?%d+) (%-?%d+) (%-?%d+)%]")
        x = tonumber(x)
        y = tonumber(y)
        z = tonumber(z)
        map.savedChunks[string.pack("<lll", x, y, z)] = true
        log:debug("Detected chunk on disk: %d %d %d", x, y, z)
    end
end

function map.assumeBlockType(hardness)
    local assumedType
	if hardness ~= nil then
		if hardness < 0 then assumedType = blockType.bedrock
        elseif hardness < 0.4 then assumedType = blockType.air
        elseif hardness < 1.25 then assumedType = blockType.dirt
		elseif hardness < 2.75 then assumedType = blockType.stone
		elseif hardness < 95 then assumedType = blockType.ore
		else assumedType = blockType.fluid end
		return assumedType
	else
		return blockType.unknown
	end
end

function map:getFileName(chunkCoords)
	return string.format("%s[%d %d %d].%s", self.chunkFolder, chunkCoords.x, chunkCoords.y, chunkCoords.z, self.extension)
end

function map:saveChunk(coords, absolute)
	local chunkCoords = absolute and vec3(coords.x // self.chunkSize.x, coords.y // self.chunkSize.y, coords.z // self.chunkSize.z) or coords
	local chunk = self.chunks[string.pack("<lll", chunkCoords.x, chunkCoords.y, chunkCoords.z)]
	local data = {string.pack(self.fileHeader, self.magicString, self.chunkSize.x, self.chunkSize.y, self.chunkSize.z, self.storedType)}
    
    if chunk then
        for x = 0, self.chunkSize.x - 1 do
            for y = 0, self.chunkSize.y - 1 do
                for z = 0, self.chunkSize.z - 1 do
                    local block = chunk:atxyz(x, y, z)
                    data[#data+1] = string.pack(self.storedType, block and block or -1)
                end
            end
        end
    end
    
    
	local filePath = self:getFileName(chunkCoords)
	local chunkFile = io.open(filePath, "w")
    if chunkFile then
        log:debug("Saving chunk %s to disk at %s", chunkCoords, filePath)
        chunkFile:write(table.concat(data))
        chunkFile:close()
    end
end

function map:unloadChunk(coords, absolute)
    local chunkCoords = absolute and vec3(coords.x // self.chunkSize.x, coords.y // self.chunkSize.y, coords.z // self.chunkSize.z) or coords
    log:debug("Unloading chunk %s", chunkCoords)
    local chunkHash = string.pack("<lll", chunkCoords:unpack())
    self.chunks[chunkHash] = nil
    self.savedChunks[chunkHash] = true
    self.loadedChunks = self.loadedChunks - 1;
end

function map:ensureMemForChunk()
    while self.loadedChunks > self.maxLoadedChunks - 1 do
        local min = math.huge
        local oldestHash = nil
        for hash, chunk in pairs(self.chunks) do
            if chunk.lastAccess < min then
                min = chunk.lastAccess
                oldestHash = hash
            end
        end
        
        if oldestHash then
            local chunkVec = vec3(string.unpack("<lll", oldestHash))
            self:saveChunk(chunkVec)
            self:unloadChunk(chunkVec)
            local freeMemory = utils.freeMemory()
            log:debug("Freed memory after unloading a chunk, free memory: %s", freeMemory)
        else
            error("Not enough memory to load a chunk, ensure that the device have enough memory available")
        end
    end
end

function map:loadChunk(coords, absolute)
	local chunkCoords = absolute and vec3(coords.x // self.chunkSize.x, coords.y // self.chunkSize.y, coords.z // self.chunkSize.z) or coords
    local chunkHash = string.pack("<lll", chunkCoords.x, chunkCoords.y, chunkCoords.z)
    if not self.chunks[chunkHash] then
        self.chunks[chunkHash] = VectorChunk(self.packValues, self.allowFloats, vec3(0, 0, 0))
    end
    
    local chunk = self.chunks[chunkHash]
	local filePath = self:getFileName(chunkCoords)
	local chunkFile, reason = filesystem.open(filePath, "rb")
    chunk.lastAccess = computer.uptime()
    log:debug("Trying to load chunk %s", chunkCoords)
    
    if chunkFile then
        log:debug("free memory: %d", utils.freeMemory())
        local header = chunkFile:read(string.packsize(self.fileHeader))
        if header then
            local magicString, chunkSizex, chunkSizey, chunkSizez, dataFormat = string.unpack(self.fileHeader, header)
            if magicString == self.magicString and
            chunkSizex == self.chunkSize.x and 
            chunkSizey == self.chunkSize.y and 
            chunkSizez == self.chunkSize.z then
                self:ensureMemForChunk()
                local formatSize = string.packsize(self.storedType)
                log:debug("free memory: %d", utils.freeMemory())
                local buf = {}
                repeat
                    local read = chunkFile:read(math.huge)
                    buf[#buf+1] = read
                until read == nil
                local data = table.concat(buf)
                
                --log:debug("%s", data)
                for x = 0, self.chunkSize.x - 1 do
                    for y = 0, self.chunkSize.y - 1 do
                        for z = 0, self.chunkSize.z - 1 do
                            --log:debug("%d", (x * self.chunkSize.y * self.chunkSize.z + y * self.chunkSize.z + z)*formatSize + 1)
                            local block = string.unpack(self.storedType, data, (x * self.chunkSize.y * self.chunkSize.z + y * self.chunkSize.z + z)*formatSize + 1)
                            chunk:setxyz(x, y, z, block ~= -1 and block or nil)
                        end
                    end
                end
            else
                error("Invalid file format or mismatching chunk sizes")
            end
        else
            error(string.format("Chunk file %s empty", filePath))
        end
    else
        error(string.format("Failed to open chunk file: %s", reason))
    end

    self.loadedChunks = self.loadedChunks + 1;
    log:debug("Successfully loaded chunk %s", chunkCoords)
    chunkFile:close()
end

-- override default VectorMap at and set methods
function map:at(vector)
    local chunkHash, x, y, z = self:getHashAndLocalCoords(vector, false)
    local chunk = self.chunks[chunkHash]
    
    if not chunk and self.savedChunks[chunkHash] then
        self:loadChunk(vector, true) 
    end

    if chunk then
        self.chunks[chunkHash].lastAccess = computer.uptime()
		return chunk:atxyz(vector.x % self.chunkSize.x, vector.y % self.chunkSize.y, vector.z % self.chunkSize.z)
	else
		return nil -- return something else, possibly some enum.not_present
	end
end

function map:set(vector, element)
    local chunkHash, x, y, z = self:getHashAndLocalCoords(vector, false)
    if not self.chunks[chunkHash] then
        self:ensureMemForChunk()
        if self.savedChunks[chunkHash] then
            self:loadChunk(vector, true)
        else
            self.chunks[chunkHash] = VectorChunk(self.packValues, self.allowFloats, vec3(0, 0, 0))
            self.loadedChunks = self.loadedChunks + 1
        end
    end
    self.chunks[chunkHash].lastAccess = computer.uptime()
    self.chunks[chunkHash]:setxyz(x, y, z, element)
end

return map