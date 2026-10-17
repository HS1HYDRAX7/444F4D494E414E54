local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local M = {}

local function greetingKey()
    local hour = tonumber(os.date("%H")) or 12
    if hour < 5 then
        return "greet_night"
    elseif hour < 12 then
        return "greet_morning"
    elseif hour < 18 then
        return "greet_afternoon"
    end
    return "greet_evening"
end

local function greeting(ctx)
    return ctx.L(greetingKey())
end

-- A text that remembers its key and arguments, so a language change can rebuild it (see core/i18n.lua).
-- An argument can be a plain value or { Key = ... } for a word that is translated too.
local function loc(ctx, key, args, suffix)
    local values, stored = {}, {}
    for index, arg in ipairs(args or {}) do
        if type(arg) == "table" then
            values[index] = ctx.L(arg.Key)
            stored[index] = "@" .. arg.Key
        else
            values[index] = tostring(arg)
            stored[index] = tostring(arg)
        end
    end
    local text = #values > 0 and ctx.L(key, table.unpack(values)) or ctx.L(key)
    return { Text = text .. (suffix or ""), Key = key, Args = stored, Suffix = suffix }
end

local function yes(ctx, flag)
    return flag and ctx.L("home_yes") or ctx.L("home_no")
end

local function fillChangelog(tab, ctx)
    for _, entry in ipairs(ctx.changelog or {}) do
        local changes = {}
        for _, change in ipairs(entry.changes) do
            table.insert(changes, { Type = change.type, Text = ctx.L(change.key) })
        end
        tab:AddChangelogEntry({
            Version = ctx.L(entry.version),
            Date = ctx.L(entry.date),
            Changes = changes,
        })
    end
end

function M.home(window, ctx)
    local home = window:AddTab({ Name = ctx.L("tab_home"), Icon = "Lucide:house" })
    local name = LocalPlayer.DisplayName or LocalPlayer.Name
    local function flag(value)
        return { Key = value and "home_yes" or "home_no" }
    end

    local status = {
        {
            Title = loc(ctx, "home_executor", { ctx.executor }),
            Subtitle = loc(ctx, "home_caps", { flag(ctx.caps.require), flag(ctx.caps.hookmetamethod), flag(ctx.caps.files) }),
            Cover = "Lucide:terminal",
        },
        { Title = loc(ctx, "sec_welcome"), Subtitle = loc(ctx, "home_text", { tostring(ctx.cfg.menu_key) }), Cover = "Lucide:sparkles" },
        { Title = loc(ctx, "home_title", { ctx.game or "Dominant" }), Subtitle = loc(ctx, "home_credits"), Cover = "Lucide:crown" },
    }


    home:AddShowcase({
        Title = loc(ctx, greetingKey(), nil, ", " .. name),
        Subtitle = loc(ctx, "home_title", { ctx.game or "Dominant" }),
        Cover = ctx.logoAsset or "Lucide:house",
        Sections = {
            { Title = loc(ctx, "sub_info"), Items = status },
        },
    })

    -- Updates: one compact card and a slider that moves between versions, instead of a long list
    local releases = ctx.changelog or {}
    if #releases > 0 then
        home:AddSection({ Text = ctx.L("sub_changelog"), Icon = "Lucide:file-text" })
        local function describe(index)
            local entry = releases[index]
            local lines = { ctx.L(entry.version) .. " · " .. ctx.L(entry.date) }
            for _, change in ipairs(entry.changes or {}) do
                table.insert(lines, "• " .. tostring(change.type) .. ": " .. ctx.L(change.key))
            end
            return table.concat(lines, "\n")
        end
        local notes = home:AddParagraph({ Title = ctx.L("sub_changelog"), Text = describe(1) })
        home:AddSlider({
            Text = "Version",
            Icon = "Lucide:history",
            Min = 1,
            Max = #releases,
            Increment = 1,
            Default = 1,
            Callback = function(value)
                notes:Set(describe(math.floor(value + 0.5)))
            end,
        })
    end

    home:AddSystemInfoGrid({ Description = ctx.L("home_executor", ctx.executor) })
end

function M.credits(window, ctx)
    local tab = window:AddTab({ Name = ctx.L("tab_credits"), Icon = "Lucide:heart" })

    local function person(key, icon)
        tab:AddParagraph({ Title = ctx.L(key), Icon = icon, Text = ctx.L(key .. "_d") })
    end

    tab:AddSection(ctx.L("credits_section_dominant"), "Lucide:code")
    person("credit_jonathan", "Lucide:crown")
    person("credit_claude", "Lucide:bot")
    person("credit_grok", "Lucide:sparkles")

    tab:AddSection(ctx.L("credits_section_vind"), "Lucide:heart-handshake")
    tab:AddParagraph({ Title = "Skinny", Icon = "Lucide:palette", Text = ctx.L("credit_vind_skinny_d") })
    tab:AddParagraph({ Title = "Shezz", Icon = "Lucide:layout-grid", Text = ctx.L("credit_vind_shezz_d") })
    tab:AddParagraph({ Title = "NoSkills", Icon = "Lucide:lightbulb", Text = ctx.L("credit_vind_noskills_d") })
    tab:AddParagraph({ Title = "Luxy_00", Icon = "Lucide:smartphone", Text = ctx.L("credit_vind_luxy_d") })
    tab:AddParagraph({ Title = "Elusive", Icon = "Lucide:rocket", Text = ctx.L("credit_vind_elusive_d") })

    tab:AddSection(ctx.L("credits_section_notice"), "Lucide:info")
    tab:AddParagraph({ Title = "Vind UI Reborn", Icon = "Lucide:layout-dashboard", Text = ctx.L("notice_vind") })
    tab:AddParagraph({ Title = "Ophyn", Icon = "Lucide:key", Text = ctx.L("notice_ophyn") })
    tab:AddParagraph({ Title = ctx.L("credits_line"), Icon = "Lucide:scale", Text = ctx.L("notice_disclaimer") })
end

function M.settings(window, ctx)
    local ui = ctx.ui
    local tab = window:AddTab({ Name = ctx.L("tab_settings"), Icon = "Lucide:settings" })

    ui.section(tab, "sec_language", "Lucide:languages")
    local names, currentName = {}, "English"
    for _, language in ipairs(ctx.Languages) do
        table.insert(names, language.Name)
        if language.Code == ctx.getLanguage() then
            currentName = language.Name
        end
    end
    ui.dropdown(tab, "language", names, "Lucide:languages", currentName, function(value)
        for _, language in ipairs(ctx.Languages) do
            if language.Name == value and language.Code ~= ctx.getLanguage() then
                ctx.setLanguage(language.Code)
                ctx.set("language", language.Code)
                ctx.notify(ctx.L("n_language"), "info", 3)
                break
            end
        end
    end)

    ui.section(tab, "sec_interface", "Lucide:layout-dashboard")
    ui.toggle(tab, "notifications", "Lucide:bell")
    ui.dropdown(tab, "name_mode", { "display", "username", "anonymous" }, "Lucide:user", ctx.cfg.name_mode or "display", function(value)
        ctx.set("name_mode", value)
        if ctx.window and ctx.window.SetUserInfo then
            ctx.window:SetUserInfo({ NameMode = value })
        end
    end)

    ctx.modules:require("shared/features/background").Build(tab, ctx)
    ctx.modules:require("shared/sounds").Build(tab, ctx)
    if ctx.gameSettings then
        ctx.gameSettings(tab, ctx)
    end

    ui.keybind(tab, "menu_key", "Lucide:keyboard", ctx.cfg.menu_key, function()
        if ctx.window then
            ctx.window:Toggle()
        end
    end, function(name)
        ctx.set("menu_key", name)
    end)

    if #ctx.hotkeys > 0 then
        ui.section(tab, "sec_hotkeys", "Lucide:keyboard")
        for _, hotkey in ipairs(ctx.hotkeys) do
            ui.keybind(tab, hotkey.label, "Lucide:keyboard", ctx.cfg[hotkey.key], hotkey.run, function(name)
                ctx.set(hotkey.key, name)
            end)
        end
    end

    ui.section(tab, "sec_config", "Lucide:save")
    local selected = ctx.getAutoload() or "default"
    local configDropdown

    local function configExists(name)
        for _, existing in ipairs(ctx.listConfigs()) do
            if existing == name then
                return true
            end
        end
        return false
    end

    -- The list always contains the current selection, so the dropdown and the name box never disagree.
    local function configOptions()
        local options = ctx.listConfigs()
        if not configExists(selected) then
            table.insert(options, 1, selected)
        end
        return options
    end

    local function refreshConfigs()
        if configDropdown then
            configDropdown:Refresh(configOptions())
        end
    end

    tab:AddTextbox({
        Text = ctx.L("config_name"),
        Icon = "Lucide:pencil",
        Placeholder = ctx.L("config_name_hint"),
        Default = selected,
        Callback = function(text)
            selected = ctx.sanitizeName(text)
            refreshConfigs()
        end,
    })
    configDropdown = tab:AddDropdown({
        Text = ctx.L("config_pick"),
        Icon = "Lucide:list",
        Options = configOptions(),
        Default = selected,
        Callback = function(value)
            if type(value) == "table" then
                value = value[1]
            end
            if type(value) == "string" and value ~= "" then
                selected = ctx.sanitizeName(value)
            end
        end,
    })

    ui.button(tab, "btn_config_save", "Lucide:save", function()
        local ok = ctx.saveConfig(selected)
        refreshConfigs()
        ctx.notify(ctx.L(ok and "n_config_saved" or "n_config_failed"), ok and "success" or "error", 3)
    end)
    ui.button(tab, "btn_config_load", "Lucide:folder-open", function()
        if configExists(selected) and ctx.loadConfig(selected) then
            ctx.applyAll()
            ctx.saveSession()
            ctx.notify(ctx.L("n_config_loaded"), "success", 3)
        else
            ctx.notify(ctx.L("n_config_missing"), "warning", 3)
        end
    end)
    ui.button(tab, "btn_config_delete", "Lucide:trash-2", function()
        if not configExists(selected) then
            ctx.notify(ctx.L("n_config_missing"), "warning", 3)
            return
        end
        local ok = ctx.deleteConfig(selected)
        if ctx.getAutoload() == selected then
            ctx.setAutoload("")
        end
        selected = "default"
        refreshConfigs()
        ctx.notify(ctx.L("n_config_deleted"), ok and "success" or "error", 3)
    end)
    ui.button(tab, "btn_config_autoload", "Lucide:zap", function()
        -- An autoload must point to a config that exists, so save it first if needed.
        if not configExists(selected) then
            ctx.saveConfig(selected)
        end
        ctx.setAutoload(selected)
        refreshConfigs()
        ctx.notify(ctx.L("n_autoload_set", selected), "success", 3)
    end)

    ui.button(tab, "btn_reset", "Lucide:rotate-ccw", function()
        ctx.library:Confirm({
            Title = ctx.L("confirm_reset_title"),
            Text = ctx.L("confirm_reset_text"),
            Window = window,
            Callback = function(confirmed)
                if confirmed then
                    ctx.reset()
                    ctx.applyAll()
                    ctx.saveSession()
                    ctx.notify(ctx.L("n_reset"), "warning", 3)
                end
            end,
        })
    end)
    ui.button(tab, "btn_unload", "Lucide:power", function()
        ctx.library:Confirm({
            Title = ctx.L("confirm_unload_title"),
            Text = ctx.L("confirm_unload_text"),
            Window = window,
            Callback = function(confirmed)
                if confirmed then
                    ctx.unload()
                end
            end,
        })
    end)
end

return M
