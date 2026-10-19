local M = {
    Name = "Pressure",
    -- Hard version so the window never falls back to hub/Forsaken version
    Version = "1.1.0",
    -- the script's own latest version key (from its changelog strings)
    VersionKey = "pressure_version2",
}

local BUNDLED = { esp = true, anti = true, automation = true }

local FEATURES = {
    esp = "games/pressure/features/esp",
    anti = "games/pressure/features/anti",
    movement = "shared/features/movement",
    automation = "games/pressure/features/automation",
    screen = "shared/features/screen",
    misc = "shared/features/misc",
}

local FEATURE_ORDER = { "esp", "movement", "automation", "anti", "screen", "misc" }

local TABS = {
    { "tab_visuals", "Lucide:eye", { "esp" } },
    { "tab_movement", "Lucide:footprints", { "movement" } },
    { "tab_automation", "Lucide:bot", { "automation" } },
    { "tab_anti", "Lucide:shield", { "anti" } },
    { "tab_world", "Lucide:map", { "screen" } },
    { "tab_misc", "Lucide:wrench", { "misc" } },
}

function M.Init(ctx)
    -- Ensure Pressure strings are present even if app.lua failed to load them
    pcall(function()
        local pack = ctx.modules:require("games/pressure/strings")
        if type(pack) == "table" then
            for code, strings in pairs(pack) do
                if type(strings) == "table" then
                    ctx.addStrings(code, strings)
                end
            end
        end
    end)

    -- Guarantee the version key exists in every language pack (prevents showing hub/Forsaken version)
    pcall(function()
        local versions = {
            pressure_version2 = "1.1.0",
            pressure_version1 = "1.0.0",
            pressure_date2 = "2026-10-12",
            pressure_date1 = "2026-10-09",
        }
        for _, code in ipairs({ "en", "pt", "es", "ru" }) do
            ctx.addStrings(code, versions)
        end
    end)

    local data = ctx.modules:require("games/pressure/data")
    M.data = data
    M.features = {}

    local bundled = {}
    local okBundle, bundleResult = pcall(function()
        return ctx.modules:require("games/pressure/features")
    end)
    if okBundle and type(bundleResult) == "table" then
        bundled = bundleResult
    else
        ctx.warn("pressure features bundle failed: " .. tostring(bundleResult))
    end

    for _, name in ipairs(FEATURE_ORDER) do
        local ok, feature = pcall(function()
            if BUNDLED[name] then
                local mod = bundled[name]
                if type(mod) ~= "table" then
                    error("missing bundled feature: " .. name)
                end
                return mod
            end
            return ctx.modules:require(FEATURES[name])
        end)
        if not ok or type(feature) ~= "table" then
            ctx.warn("pressure feature load failed (" .. name .. "): " .. tostring(feature))
        else
            if type(feature.Register) == "function" then
                local okReg, regErr = pcall(feature.Register, ctx, data)
                if not okReg then
                    ctx.warn("pressure feature register failed (" .. name .. "): " .. tostring(regErr))
                end
            end
            M.features[name] = feature
        end
    end
end

function M.Build(window, ctx)
    for _, entry in ipairs(TABS) do
        local label = ctx.L(entry[1])
        if type(label) ~= "string" or label == "" or label == entry[1] then
            -- Hard fallback names if i18n key leaked through
            local fallback = {
                tab_visuals = "Visuals",
                tab_movement = "Movement",
                tab_automation = "Automation",
                tab_anti = "Anti",
                tab_world = "World",
                tab_misc = "Misc",
            }
            label = fallback[entry[1]] or entry[1]
        end

        local okTab, tab = pcall(function()
            return window:AddTab({ Name = label, Icon = entry[2] })
        end)
        if not okTab or tab == nil then
            ctx.warn("pressure tab failed (" .. tostring(entry[1]) .. "): " .. tostring(tab))
        else
            for _, name in ipairs(entry[3]) do
                local feature = M.features[name]
                if not feature or type(feature.Build) ~= "function" then
                    ctx.warn("pressure feature missing for tab (" .. name .. ")")
                else
                    local okBuild, buildErr = pcall(feature.Build, tab, ctx, M.data)
                    if not okBuild then
                        ctx.warn("pressure feature build failed (" .. name .. "): " .. tostring(buildErr))
                    end
                end
            end
        end
    end
end

return M
