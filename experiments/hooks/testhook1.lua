local HookModule = require("hookmodule")
local testhookOriginal = require("testhookoriginal")

local testhook1 = HookModule("testhook1")

function testhook1.hello()
    testhook1:callOriginal(testhook1.hello)
    print("Hello from test hook 1")
end

function testhook1:start()
    testhookOriginal.hello = testhook1:hook(testhookOriginal.hello, self.hello)
    return self
end

function testhook1:stop()
    testhookOriginal.hello = testhook1:unhook(self.hello)
    return self
end

return testhook1