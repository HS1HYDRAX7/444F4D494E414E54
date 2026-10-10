local M = {
    Name = "Forsaken",
    Options = { builtInFly = false },
}

local FEATURE_FILE = "games/forsaken/features"

local TABS = {
    { "tab_player", "Lucide:user", { "player" } },
    { "tab_auto", "Lucide:bot", { "auto" } },
    { "tab_combat", "Lucide:swords", { "combat" } },
    { "tab_visuals", "Lucide:eye", { "visuals" } },
    { "tab_world", "Lucide:map", { "world" } },
    { "tab_fun", "Lucide:music", { "fun" } },
    { "tab_misc", "Lucide:wrench", { "misc" } },
    { "tab_debug", "Lucide:terminal", { "debug" } },
}

function M.Init(ctx)
    M.core = ctx.modules:require("games/forsaken/core")
    for key, default in pairs(M.core.Dominant.Defaults) do
        ctx.addSetting(key, default)
    end
    M.core.Dominant.Cfg = ctx.cfg
    M.features = ctx.modules:require(FEATURE_FILE)
end

function M.Build(window, ctx)
    local core = M.core
    core.bind(window, ctx)
    core.ctx = ctx
    local H = core.UI.Helpers(window)
    ctx.gameSettings = function(tab)
        M.features.settings.Build(tab, H, core, window)
    end
    for _, entry in ipairs(TABS) do
        local tab = window:AddTab({ Name = core.L(entry[1]), Icon = entry[2] })
        for _, name in ipairs(entry[3]) do
            M.features[name].Build(tab, H, core, window)
        end
    end
end

return M
