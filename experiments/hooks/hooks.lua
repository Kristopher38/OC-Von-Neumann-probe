local hookOrder = dofile("hookorder.lua")
package.loaded.hookorder = hookOrder
local testhookOriginal = require("testhookoriginal")
local testhook1 = require("testhook1")
local testhook3 = require("testhook3")
local testhook2 = require("testhook2")
local testhook4 = require("testhook4")
local testhook5 = require("testhook5")
local utils = require("utils")

testhook4:start()
testhook5:start()
testhook3:start()
testhook1:start()
testhook2:start()

-- expected output: original, 1, 2, 3, 4, 5
testhookOriginal.hello()

utils.waitForInput()
os.execute("reboot")