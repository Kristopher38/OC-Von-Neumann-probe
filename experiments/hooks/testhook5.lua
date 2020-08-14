local HookModule = require("hookmodule")
local testhookOriginal = require("testhookoriginal")

local testhook5 = HookModule("testhook5")

function testhook5.hello()
    testhook5:callOriginal(testhook5.hello)
    print("Hello from test hook 5")
end

function testhook5:start()
    testhookOriginal.hello = testhook5:hook(testhookOriginal.hello, self.hello)
    return self
end

function testhook5:stop()
    testhookOriginal.hello = testhook5:unhook(self.hello)
    return self
end

return testhook5