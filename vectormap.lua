local function hashVector(vector)
	-- return tostring(vector.x) .. ":" .. tostring(vector.y) .. ":" .. tostring(vector.z)
	return (vector.y * 257 + vector.x) * 263 + vector.z
end

local function isVec3(vector)
	return  type(vector) == "table" and
			vector.x ~= nil and
			vector.y ~= nil and
			vector.z ~= nil
end

local function index(self, vector)
	if isVec3(vector) then -- check if vector
		local hashed = hashVector(vector)
		if self._internalMap[hashed] ~= nil then
			return self._internalMap[hashed]
		else
			return nil -- return something else, possibly some enum.not_present
		end
	else
		if vector == "count" then
			local count = 0
			for elem in pairs(self._internalMap) do
				count = count + 1
			end
			return count
		else
			rawget(self, vector)
		end
	end
end

local function newindex(self, vector, mapElement)
	if isVec3(vector) then
		self._internalMap[hashVector(vector)] = mapElement
	else
		rawset(self, vector, mapElement)
	end
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