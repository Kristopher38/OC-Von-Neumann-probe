local HookModule = require("hookmodule")
local testhookOriginal = require("testhookoriginal")

local testhook2 = HookModule("testhook2")

function testhook2.hello()
    testhook2:callOriginal(testhook2.hello)
    print("Hello from test hook 2")
end

function testhook2:start()
    testhookOriginal.hello = testhook2:hook(testhookOriginal.hello, self.hello)
    return self
end

function testhook2:stop()
    testhookOriginal.hello = testhook2:unhook(self.hello)
    return self
end

return testhook2