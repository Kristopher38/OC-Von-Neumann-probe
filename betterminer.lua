package.loaded.mining = nil
local mining = require("mining")
local debug = require("debug")
local sides = require("sides")

debug.init()
debug.clearWidgets()

--mining.mineOreLump(sides.front)
mining.mineChunk()