local function vec3eq(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

local function vec3tostring(a)
	return "[" .. a.x .. ", " .. a.y .. ", " .. a.z .. "]"
end

local mt = {__eq = vec3eq,
			__tostring = vec3tostring}

-- constructs vector as a table with "x", "y", "z" keys from table of 3 coordinates or 3 coordinate arguments
local function vec3(_x, _y, _z)
	local xx, yy, zz
	if type(_x) == "table" then -- construct from table
		xx = _x[1] or 0
		yy = _x[2] or 0
		zz = _x[3] or 0
	else -- construct from three coordinates
		xx = _x or 0
		yy = _y or 0
		zz = _z or 0
	end
	local vec = {x=xx, y=yy, z=zz}
	setmetatable(vec, mt)
	return vec
end

return vec3