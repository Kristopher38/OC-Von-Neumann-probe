package.loaded.mining = nil
local mining = require("mining")
local debug = require("debug")

debug.init()
debug.clearWidgets()

mining.mineChunk()