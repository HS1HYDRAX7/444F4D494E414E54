local features = {}

features["player"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildPlayer(tab, H)
    end
    return M
end)()

features["auto"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildAutomation(tab, H)
    end
    return M
end)()

features["combat"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildCombat(tab, H)
    end
    return M
end)()

features["visuals"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildVisuals(tab, H)
    end
    return M
end)()

features["world"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildWorld(tab, H)
    end
    return M
end)()

features["fun"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildFun(tab, H)
    end
    return M
end)()

features["misc"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildMisc(tab, H)
            core.ctx.modules:require("shared/features/scripts").Build(tab, core.ctx)
    end
    return M
end)()

features["debug"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildDebug(tab, H)
    end
    return M
end)()

features["settings"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildSettings(window, tab, H)
    end
    return M
end)()

return features
