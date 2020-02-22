-- 3D vector
local vec3 = {}
vec3.__index = vec3
setmetatable(vec3, {__call = function(cls, _x, _y, _z)
	local self = {}
	self.x = _x or 0
	self.y = _y or 0
	self.z = _z or 0

	setmetatable(self, cls) -- cls is current table: vec3
	return self
end })

function vec3.__eq(self, other)
	return self.x == other.x and self.y == other.y and self.z == other.z
end

function vec3.__add(self, other)
	return vec3(self.x + other.x, self.y + other.y, self.z + other.z)
end

function vec3.__sub(self, other)
	return vec3(self.x - other.x, self.y - other.y, self.z - other.z)
end

function vec3.__tostring(self)
	return "[" .. self.x .. ", " .. self.y .. ", " .. self.z .. "]"
end

function vec3.tovec3(str)
	local vector = vec3(string.match(str, "%[(%-?%d+%.?%d-), (%d+%.?%d-), (%-?%d+%.?%d-)%]"))
	vector.x = tonumber(vector.x)
	vector.y = tonumber(vector.y)
	vector.z = tonumber(vector.z)
	return vector
end

return vec3