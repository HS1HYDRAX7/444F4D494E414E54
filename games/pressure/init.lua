local M = {
    Name = "Pressure",
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

-- Fixed order so a failure in one feature never skips the rest of Init.
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
    local data = ctx.modules:require("games/pressure/data")
    M.data = data
    M.features = {}

    local bundled
    local okBundle, bundleResult = pcall(function()
        return ctx.modules:require("games/pressure/features")
    end)
    if okBundle and type(bundleResult) == "table" then
        bundled = bundleResult
    else
        ctx.warn("pressure features bundle failed: " .. tostring(bundleResult))
        bundled = {}
    end

    for _, name in ipairs(FEATURE_ORDER) do
        local path = FEATURES[name]
        local ok, feature = pcall(function()
            if BUNDLED[name] then
                local mod = bundled[name]
                if not mod then
                    error("missing bundled feature: " .. name)
                end
                return mod
            end
            return ctx.modules:require(path)
        end)
        if not ok or type(feature) ~= "table" then
            ctx.warn("pressure feature load failed (" .. name .. "): " .. tostring(feature))
        else
            local okReg, regErr = pcall(feature.Register, ctx, data)
            if not okReg then
                ctx.warn("pressure feature register failed (" .. name .. "): " .. tostring(regErr))
            end
            M.features[name] = feature
        end
    end
end

function M.Build(window, ctx)
    for _, entry in ipairs(TABS) do
        local tabName = ctx.L(entry[1])
        if type(tabName) ~= "string" or tabName == "" then
            tabName = entry[1]
        end

        local okTab, tab = pcall(function()
            return window:AddTab({ Name = tabName, Icon = entry[2] })
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
