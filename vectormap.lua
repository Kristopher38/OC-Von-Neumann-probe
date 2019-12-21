local function hashVector(vector)
	-- return tostring(vector.x) .. ":" .. tostring(vector.y) .. ":" .. tostring(vector.z)
	--return (vector.y * 257 + vector.x) * 30000000001 + vector.z
	return (vector.y * 257 + vector.x) * 263 + vector.z
	-- return (vector.x * 30000000193 + vector.z) * 30000000001 + vector.y

end

local function index(self, vector)
	if type(vector) == "table" and
	   vector.x ~= nil and 
	   vector.y ~= nil and 
	   vector.z ~= nil then -- check if vector
		local hashed = hashVector(vector)
		if self._internalMap[hashed] ~= nil then
		-- if self._internalMap[vector.x] ~= nil or 
		   -- self._internalMap[vector.x][vector.y] ~= nil then
			-- return self._internalMap[vector.x][vector.y][vector.z]
			return self._internalMap[hashed]
		else
			return nil -- return something else, possibly some enum.not_present
		end
	else
		local count = 0
		if vector == "count" then
			for elem in pairs(self._internalMap) do
				count = count + 1
			end
			-- for xx in pairs(self._internalMap) do
				-- for yy in pairs(self._internalMap[xx]) do
					-- for zz in pairs(self._internalMap[xx][yy]) do
						-- count = count + 1
					-- end
				-- end
			-- end
		end
		return count
		--error("VectorMap can only be indexed with vec3, tried indexing with " .. type(vector))
	end
end

local function newindex(self, vector, mapElement)
	self._internalMap[hashVector(vector)] = mapElement
	
	-- if self._internalMap[vector.x] == nil then 
		-- self._internalMap[vector.x] = {} 
	-- end
	-- if self._internalMap[vector.x][vector.y] == nil then 
		-- self._internalMap[vector.x][vector.y] = {} 
	-- end
	-- if self._internalMap[vector.x][vector.y][vector.z] == nil then 
		-- self._internalMap[vector.x][vector.y][vector.z] = {} 
	-- end
	-- self._internalMap[vector.x][vector.y][vector.z] = mapElement
end

local VectorMap = {__index = index,
				   __newindex = newindex}

-- VectorMap constructor
setmetatable(VectorMap, {__call = function(cls)
	local self = {}
	self._internalMap = {}
	-- order is important since we're overriding __newindex method!
	-- setmetatable has to be called after setting fields
	setmetatable(self, cls) -- cls is current table: VectorMap
	return self
end })

return VectorMap