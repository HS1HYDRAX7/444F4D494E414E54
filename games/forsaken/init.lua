-- Forsaken game module. Loads the core and the features, then builds the window tabs.
-- Every tab and every feature is built on its own, so a broken feature is reported
-- and the rest of the interface still appears.

local M = {
    Name = "Forsaken",
    Options = { builtInFly = false },
}

local CORE_FILE = "games/forsaken/core"
local FEATURE_FILE = "games/forsaken/features"

-- Tabs in window order: translation key, icon, and the feature modules built inside each tab.
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

M.core = nil
M.features = nil
M.errors = {}

-- Records a problem in the console and in M.errors, so it can be read later.
local function note(ctx, text)
    table.insert(M.errors, text)
    if ctx and type(ctx.warn) == "function" then
        pcall(ctx.warn, "[Forsaken] " .. text)
    end
end

-- Runs one piece of the interface. Returns true when it worked.
local function guarded(ctx, label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        note(ctx, label .. " failed: " .. tostring(err))
    end
    return ok
end

function M.Init(ctx)
    M.errors = {}

    local okCore, core = pcall(function()
        return ctx.modules:require(CORE_FILE)
    end)
    if not okCore or type(core) ~= "table" or type(core.Dominant) ~= "table" then
        note(ctx, "core did not load: " .. tostring(core))
        return false
    end
    M.core = core
    if ctx.onLanguageChange and not ctx.forsakenLanguageHooked and core.Dominant and core.Dominant.Strings then
        ctx.forsakenLanguageHooked = true
        ctx.onLanguageChange(function(from, to)
            core.Dominant.Lang = to
            ctx.retranslate(ctx.library and ctx.library._Root, from, to, { { core.Dominant.Strings[from], core.Dominant.Strings[to] } })
        end)
    end

    -- Default settings from the core become part of the saved configuration.
    for key, default in pairs(core.Dominant.Defaults or {}) do
        ctx.addSetting(key, default)
    end
    core.Dominant.Cfg = ctx.cfg

    local okFeatures, features = pcall(function()
        return ctx.modules:require(FEATURE_FILE)
    end)
    if not okFeatures or type(features) ~= "table" then
        note(ctx, "features did not load: " .. tostring(features))
        M.core = nil
        return false
    end
    M.features = features

    for _, entry in ipairs(TABS) do
        for _, name in ipairs(entry[3]) do
            local feature = features[name]
            if type(feature) ~= "table" or type(feature.Build) ~= "function" then
                note(ctx, "feature missing: " .. name)
            end
        end
    end
    return true
end

function M.Build(window, ctx)
    local core, features = M.core, M.features
    if not core or not features then
        note(ctx, "the interface is limited because the module did not load")
        return
    end

    core.ctx = ctx
    if not guarded(ctx, "bind", core.bind, window, ctx) then
        return
    end

    local okHelpers, H = pcall(core.UI.Helpers, window)
    if not okHelpers or type(H) ~= "table" then
        note(ctx, "helpers failed: " .. tostring(H))
        return
    end

    -- The settings section appears in the shared Settings tab.
    ctx.gameSettings = function(tab)
        local feature = features.settings
        if feature and feature.Build then
            guarded(ctx, "settings", feature.Build, tab, H, core, window)
        end
    end

    for _, entry in ipairs(TABS) do
        local okTab, tab = pcall(function()
            return window:AddTab({ Name = core.L(entry[1]), Icon = entry[2] })
        end)
        if not okTab or not tab then
            note(ctx, "tab " .. entry[1] .. " failed: " .. tostring(tab))
        else
            for _, name in ipairs(entry[3]) do
                local feature = features[name]
                if feature and feature.Build then
                    guarded(ctx, name, feature.Build, tab, H, core, window)
                end
            end
        end
    end

    if #M.errors > 0 then
        local message = "Forsaken: " .. #M.errors .. " part(s) failed to load. Check the console."
        if core.Dominant and type(core.Dominant.Notify) == "function" then
            pcall(core.Dominant.Notify, message, "error", 8)
        end
    end
end

return M
