local HookModule = require("hookmodule")
local testhookOriginal = require("testhookoriginal")

local testhook4 = HookModule("testhook4")

function testhook4.hello()
    testhook4:callOriginal(testhook4.hello)
    print("Hello from test hook 4")
end

function testhook4:start()
    testhookOriginal.hello = testhook4:hook(testhookOriginal.hello, self.hello)
    return self
end

function testhook4:stop()
    testhookOriginal.hello = testhook4:unhook(self.hello)
    return self
end

return testhook4