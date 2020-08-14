local HookModule = require("hookmodule")
local testhookOriginal = require("testhookoriginal")

local testhook3 = HookModule("testhook3")

function testhook3.hello()
    testhook3:callOriginal(testhook3.hello)
    print("Hello from test hook 3")
end

function testhook3:start()
    testhookOriginal.hello = testhook3:hook(testhookOriginal.hello, self.hello)
    return self
end

function testhook3:stop()
    testhookOriginal.hello = testhook3:unhook(self.hello)
    return self
end

return testhook3