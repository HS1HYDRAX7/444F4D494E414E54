-- Universal fallback when the current game is not in the supported list.
local M = {
    Name = "Universal",
    Options = { builtInFly = true },
}

local TABS = {
    { "tab_player", "Lucide:user", { "movement", "screen" } },
    { "tab_visuals", "Lucide:eye", { "background" } },
    { "tab_misc", "Lucide:wrench", { "scripts", "explorer" } },
}

M.errors = {}

local function note(ctx, text)
    table.insert(M.errors, text)
    if ctx and type(ctx.warn) == "function" then
        pcall(ctx.warn, "[Universal] " .. text)
    end
end

local function guarded(ctx, label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        note(ctx, label .. " failed: " .. tostring(err))
    end
    return ok
end

function M.Init(ctx)
    M.errors = {}
    ctx.gameKey = "universal"
    ctx.game = "Universal"
    return true
end

function M.Build(ctx, window)
    local H = ctx.ui
    for _, entry in ipairs(TABS) do
        local tab = window:AddTab({ Name = ctx.L(entry[1]) or entry[1], Icon = entry[2] })
        for _, featName in ipairs(entry[3]) do
            local ok, feat = pcall(function()
                return ctx.modules:require("shared/features/" .. featName)
            end)
            if ok and feat and type(feat.Build) == "function" then
                guarded(ctx, featName, feat.Build, tab, ctx)
            end
        end
    end
end

return M
