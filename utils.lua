local sides = require("sides")
local PriorityQueue = require("priorityqueue")
local VectorMap = require("vectormap")

local function vec3eq(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

local mt = {__eq = vec3eq}

-- constructs vector as a table with "x", "y", "z" keys from table of 3 coordinates or 3 coordinate arguments
function vec3(_x, _y, _z)
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

--[[ Calculate coordinates from offset vector and orientation. coordsVec 
is a base vector to which we "add" offsetVec, taking into account provided 
facingSide. offsetVec is a vector with three fields:
1. moving forward/backward - positive is forward, negative is backward
2. moving up/down - positive is up, negative is down
3. moving right/left - positive is right, negative is left --]]
function coordsFromOffset(coordsVec, offsetVec, facingSide)
	local y = coordsVec.y + offsetVec.y
	
	if facingSide == sides.posz then -- equivalent to sides.south
		return vec3(coordsVec.x - offsetVec.z, y, coordsVec.z + offsetVec.x)
	end
	if facingSide == sides.negz then -- equivalent to sides.north
		return vec3(coordsVec.x + offsetVec.z, y, coordsVec.z - offsetVec.x)
	end
	if facingSide == sides.posx then -- equivalent to sides.east
		return vec3(coordsVec.x + offsetVec.x, y, coordsVec.z + offsetVec.z)
	end
	if facingSide == sides.negx then -- equivalent to sides.west
		return vec3(coordsVec.x - offsetVec.x, y, coordsVec.z - offsetVec.z)
	end
end

-- checks if element already exists in a table
function hasDuplicateValue(tab, value)
	for index, element in ipairs(tab) do
		if element == value then
			return true
		end
	end
	return false
end

function aStar(start, goal, heuristic)
	openQueue = PriorityQueue()
	cameFrom = VectorMap()
	costSoFar = VectorMap()
	
	openQueue:put(start, 0)
	costSoFar[start] = 0
	local currentNode
	local nodePriority = 1
	
	while not openQueue:empty() do
		currentNode = openQueue:pop()
		
		if currentNode == goal then
			break
		end
		
		for nextNode in neighbours(currentNode) do
			local newCost = costSoFar[currentNode] + cost(currentNode, nextNode)
			if cameFrom[nextNode] ~= nil or 
			   newCost < costSoFar[currentNode] then
				openQueue:put(nextNode, newCost + heuristic(currentNode, nextNode))
				costSoFar[nextNode] = newCost
				cameFrom[nextNode] = currentNode
			end
		end	
	end
	
	-- reconstruct path
	local path = {}
	currentNode = goal
	while currentNode ~= start do
		table.insert(path, currentNode)
		currentNode = cameFrom[currentNode]
	end
	table.insert(path, start)
	
end