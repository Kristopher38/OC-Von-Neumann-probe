local vec3 = require("vec3")
local VectorChunk = require("vectorchunk")

--[[ using VectorChunk means faster lookup time, but slightly higher memory consumption (second argument means "use floats"
or in other words - no constraints on vector components' values) and no saving/loading to/from disk, but it shouldn't
be an issue since the amount of blacklisted blocks should be tiny (only base blocks like e.g. computer, chests, furnaces
should be blacklisted) --]]
local blacklistMap = VectorChunk(false, true)

return blacklistMap