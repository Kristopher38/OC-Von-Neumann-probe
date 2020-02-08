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
	local vector = vec3()
	local delimx = string.find(str, ",")
	local delimy = string.find(str, ",", delimx + 1)
	local delimz = string.find(str, "]", delimy + 1)
	vector.x = tonumber(string.sub(str, 2, delimx - 1))
	vector.y = tonumber(string.sub(str, delimx + 2, delimy - 1))
	vector.z = tonumber(string.sub(str, delimy + 2, delimz - 1))
	return vector
end

return vec3