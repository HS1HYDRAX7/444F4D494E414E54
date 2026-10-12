-- Gives WindUI and Rayfield the API the scripts were written against (the Vind API), so the games and the shared
-- features do not change when the interface is switched. Vind itself is used directly and needs no adapter.
--
-- Elements a library cannot show (tables, consoles, cards, progress bars...) become a paragraph with their text,
-- so the game still builds and the information is still shown, as text.
local M = {}

local function noop() end

-- Stands in for an element the library cannot show: every call is accepted and does nothing.
local function ghost()
    return setmetatable({}, { __index = function() return noop end })
end

local function safe(fn)
    local ok, value = pcall(fn)
    if ok then
        return value
    end
    return nil
end

local function keyName(value)
    if type(value) == "string" then
        return value
    end
    if type(value) == "table" and type(value.Name) == "string" then
        return value.Name
    end
    return nil
end

-- the scripts write "Lucide:house", the libraries read "lucide:house"
local function iconName(value)
    if type(value) ~= "string" then
        return nil
    end
    return (value:gsub("^(%a+):", function(prefix)
        return string.lower(prefix) .. ":"
    end))
end

local function sectionName(name)
    if type(name) == "table" then
        return tostring(name.Name or name.Text or "")
    end
    return tostring(name or "")
end

local function joinCells(list)
    local cells = {}
    for _, cell in ipairs(list) do
        table.insert(cells, tostring(cell))
    end
    return table.concat(cells, " | ")
end

local function rowsText(rows)
    if type(rows) ~= "table" then
        return ""
    end
    local lines = {}
    for _, row in ipairs(rows) do
        if type(row) == "table" then
            table.insert(lines, joinCells(row))
        else
            table.insert(lines, tostring(row))
        end
    end
    return table.concat(lines, "\n")
end

-- the text of a degraded element: its columns, rows, description and text
local function describe(o)
    local parts = {}
    if type(o.Columns) == "table" then
        table.insert(parts, joinCells(o.Columns))
    end
    local rows = rowsText(o.Rows)
    if rows ~= "" then
        table.insert(parts, rows)
    end
    if type(o.Description) == "string" then
        table.insert(parts, o.Description)
    end
    if type(o.Text) == "string" then
        table.insert(parts, o.Text)
    end
    return table.concat(parts, "\n")
end

local function inList(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end
    return false
end

-- WindUI: windows are lib:CreateWindow, tabs are window:Tab, elements are tab:Toggle, tab:Dropdown...
local function windui(lib)
    local api = {}

    local function element(raw)
        local e = {}
        function e.Set(_, value)
            safe(function()
                raw:Set(value)
            end)
        end
        e.SetValue = e.Set
        function e.Refresh(_, values)
            safe(function()
                raw:Refresh(values)
            end)
        end
        function e.Destroy()
            safe(function()
                raw:Destroy()
            end)
        end
        return e
    end

    local function notify(o)
        o = type(o) == "table" and o or {}
        safe(function()
            lib:Notify({ Title = o.Title or "Dominant", Content = o.Text or "", Duration = o.Duration or 4 })
        end)
    end

    local container

    container = function(target)
        local c = {}

        local function paragraph(title, text)
            safe(function()
                target:Paragraph({ Title = title, Desc = text })
            end)
        end

        local function degraded(title, o)
            if type(o) ~= "table" then
                o = {}
            end
            paragraph(title, describe(o))
            return ghost()
        end

        function c.AddSection(_, name)
            local raw = safe(function()
                return target:Section({ Title = sectionName(name) })
            end)
            if raw then
                return container(raw)
            end
            return ghost()
        end

        function c.AddSubTab(_, o)
            return c.AddSection(c, o)
        end

        function c.AddParagraph(_, o)
            o = type(o) == "table" and o or {}
            paragraph(o.Title or "", o.Text or "")
            return ghost()
        end

        function c.AddToggle(_, o)
            return element(safe(function()
                return target:Toggle({ Title = o.Text or "Toggle", Desc = o.Description, Value = o.Default == true, Callback = o.Callback })
            end))
        end

        function c.AddDropdown(_, o)
            return element(safe(function()
                return target:Dropdown({ Title = o.Text or "Dropdown", Desc = o.Description, Values = o.Options or {}, Value = o.Default, Callback = o.Callback })
            end))
        end

        function c.AddTextbox(_, o)
            return element(safe(function()
                return target:Input({ Title = o.Text or "Input", Desc = o.Description, Value = o.Default or "", Placeholder = o.Placeholder or "", Callback = o.Callback })
            end))
        end

        function c.AddSlider(_, o)
            return element(safe(function()
                return target:Slider({ Title = o.Text or "Slider", Desc = o.Description, Step = o.Increment or 1, Value = { Min = o.Min or 0, Max = o.Max or 100, Default = o.Default or o.Min or 0 }, Callback = o.Callback })
            end))
        end

        function c.AddButton(_, o)
            safe(function()
                target:Button({ Title = o.Text or "Button", Desc = o.Description, Callback = o.Callback })
            end)
            return ghost()
        end

        function c.AddKeybind(_, o)
            return element(safe(function()
                return target:Keybind({ Title = o.Text or "Keybind", Desc = o.Description, Value = keyName(o.Default) or "None", Callback = o.Callback })
            end))
        end

        function c.AddColorPicker(_, o)
            return element(safe(function()
                return target:Colorpicker({ Title = o.Text or "Color", Default = o.Default, Callback = o.Callback })
            end))
        end

        function c.AddTable(_, o)
            return degraded(type(o) == "table" and o.Title or "Table", o)
        end
        function c.AddProgress(_, o)
            return degraded(type(o) == "table" and o.Text or "Progress", o)
        end
        function c.AddConsole(_, o)
            return degraded("Console", o)
        end
        function c.AddCard(_, o)
            return degraded(type(o) == "table" and o.Title or "", o)
        end
        function c.AddChangelogEntry(_, o)
            o = type(o) == "table" and o or {}
            return degraded(tostring(o.Version or "") .. " " .. tostring(o.Date or ""), { Description = rowsText(o.Changes) })
        end
        function c.AddSystemInfoGrid(_, o)
            return degraded("System info", o)
        end
        function c.AddDefaultCreditsPanel(_, o)
            return degraded("Credits", o)
        end

        return c
    end

    local function windowApi(raw)
        local w = {}
        function w.AddTab(_, o)
            o = type(o) == "table" and o or {}
            local tab = safe(function()
                return raw:Tab({ Title = o.Name or "Tab", Icon = iconName(o.Icon) })
            end)
            if tab then
                return container(tab)
            end
            return ghost()
        end
        function w.Notify(_, o)
            notify(o)
        end
        return setmetatable(w, { __index = function() return noop end })
    end

    function api.CreateWindow(_, o)
        o = type(o) == "table" and o or {}
        local raw = safe(function()
            return lib:CreateWindow({
                Title = o.Title or "Dominant",
                Author = o.Subtitle or "",
                Folder = "Dominant",
                Icon = iconName(o.Icon),
                Size = o.Size,
                Resizable = o.Resizable ~= false,
                Transparent = false,
            })
        end)
        if not raw then
            error("WindUI could not open the window")
        end
        return windowApi(raw)
    end

    function api.Notify(_, o)
        notify(o)
    end

    return setmetatable(api, { __index = function() return noop end })
end

-- Rayfield: windows are lib:CreateWindow, tabs are window:CreateTab, elements are tab:CreateToggle...
-- Rayfield sections are headings on the tab, so elements added after a section still belong to the tab.
local function rayfield(lib)
    local api = {}

    local function element(raw)
        local e = {}
        function e.Set(_, value)
            safe(function()
                raw:Set(value)
            end)
        end
        e.SetValue = e.Set
        function e.Destroy()
            safe(function()
                raw:Destroy()
            end)
        end
        return e
    end

    local function notify(o)
        o = type(o) == "table" and o or {}
        safe(function()
            lib:Notify({ Title = o.Title or "Dominant", Content = o.Text or "", Duration = o.Duration or 4 })
        end)
    end

    local container

    container = function(tab)
        local c = {}

        local function paragraph(title, text)
            safe(function()
                tab:CreateParagraph({ Title = title, Content = text })
            end)
        end

        local function degraded(title, o)
            if type(o) ~= "table" then
                o = {}
            end
            paragraph(title, describe(o))
            return ghost()
        end

        function c.AddSection(_, name)
            safe(function()
                tab:CreateSection(sectionName(name))
            end)
            return c
        end

        function c.AddSubTab(_, o)
            return c.AddSection(c, o)
        end

        function c.AddParagraph(_, o)
            o = type(o) == "table" and o or {}
            paragraph(o.Title or "", o.Text or "")
            return ghost()
        end

        function c.AddToggle(_, o)
            return element(safe(function()
                return tab:CreateToggle({
                    Name = o.Text or "Toggle",
                    CurrentValue = o.Default == true,
                    Flag = o.Flag or o.Text or "toggle",
                    Callback = function(value)
                        if o.Callback then
                            o.Callback(value)
                        end
                    end,
                })
            end))
        end

        function c.AddDropdown(_, o)
            local options = type(o.Options) == "table" and o.Options or {}
            local current = {}
            if inList(options, o.Default) then
                current = { o.Default }
            end
            local raw = safe(function()
                return tab:CreateDropdown({
                    Name = o.Text or "Dropdown",
                    Options = options,
                    CurrentOption = current,
                    MultipleOptions = false,
                    Flag = o.Flag or o.Text or "dropdown",
                    Callback = function(selected)
                        local value = selected
                        if type(selected) == "table" then
                            value = selected[1]
                        end
                        if o.Callback then
                            o.Callback(value)
                        end
                    end,
                })
            end)
            local e = element(raw)
            function e.Set(_, value)
                safe(function()
                    raw:Set(type(value) == "table" and value or { value })
                end)
            end
            e.SetValue = e.Set
            function e.Refresh(_, values)
                safe(function()
                    raw:Refresh(values)
                end)
            end
            return e
        end

        -- Rayfield's input has no default text, so only the placeholder and the callback are passed
        function c.AddTextbox(_, o)
            return element(safe(function()
                return tab:CreateInput({
                    Name = o.Text or "Input",
                    PlaceholderText = o.Placeholder or "",
                    RemoveTextAfterFocusLost = false,
                    Callback = function(text)
                        if o.Callback then
                            o.Callback(text)
                        end
                    end,
                })
            end))
        end

        function c.AddSlider(_, o)
            return element(safe(function()
                return tab:CreateSlider({
                    Name = o.Text or "Slider",
                    Range = { o.Min or 0, o.Max or 100 },
                    Increment = o.Increment or 1,
                    Suffix = o.Suffix or "",
                    CurrentValue = o.Default or o.Min or 0,
                    Flag = o.Flag or o.Text or "slider",
                    Callback = function(value)
                        if o.Callback then
                            o.Callback(value)
                        end
                    end,
                })
            end))
        end

        function c.AddButton(_, o)
            safe(function()
                tab:CreateButton({
                    Name = o.Text or "Button",
                    Callback = function()
                        if o.Callback then
                            o.Callback()
                        end
                    end,
                })
            end)
            return ghost()
        end

        function c.AddKeybind(_, o)
            return element(safe(function()
                return tab:CreateKeybind({
                    Name = o.Text or "Keybind",
                    CurrentKeybind = keyName(o.Default) or "None",
                    HoldToInteract = false,
                    Flag = o.Flag or o.Text or "keybind",
                    Callback = function()
                        if o.Callback then
                            o.Callback()
                        end
                    end,
                })
            end))
        end

        function c.AddColorPicker(_, o)
            return degraded(type(o) == "table" and o.Text or "Color", { Description = tostring(type(o) == "table" and o.Default or "") })
        end

        function c.AddTable(_, o)
            return degraded(type(o) == "table" and o.Title or "Table", o)
        end
        function c.AddProgress(_, o)
            return degraded(type(o) == "table" and o.Text or "Progress", o)
        end
        function c.AddConsole(_, o)
            return degraded("Console", o)
        end
        function c.AddCard(_, o)
            return degraded(type(o) == "table" and o.Title or "", o)
        end
        function c.AddChangelogEntry(_, o)
            o = type(o) == "table" and o or {}
            return degraded(tostring(o.Version or "") .. " " .. tostring(o.Date or ""), { Description = rowsText(o.Changes) })
        end
        function c.AddSystemInfoGrid(_, o)
            return degraded("System info", o)
        end
        function c.AddDefaultCreditsPanel(_, o)
            return degraded("Credits", o)
        end

        return c
    end

    local function windowApi(raw)
        local w = {}
        function w.AddTab(_, o)
            o = type(o) == "table" and o or {}
            local tab = safe(function()
                return raw:CreateTab(o.Name or "Tab", nil)
            end)
            if tab then
                return container(tab)
            end
            return ghost()
        end
        function w.Notify(_, o)
            notify(o)
        end
        return setmetatable(w, { __index = function() return noop end })
    end

    function api.CreateWindow(_, o)
        o = type(o) == "table" and o or {}
        local raw = safe(function()
            return lib:CreateWindow({
                Name = o.Title or "Dominant",
                LoadingTitle = o.Title or "Dominant",
                LoadingSubtitle = o.Subtitle or "",
                ConfigurationSaving = { Enabled = false },
                Discord = { Enabled = false },
                KeySystem = false,
            })
        end)
        if not raw then
            error("Rayfield could not open the window")
        end
        return windowApi(raw)
    end

    function api.Notify(_, o)
        notify(o)
    end

    return setmetatable(api, { __index = function() return noop end })
end

-- Cascade: cascade.New makes the app, app:Window and win:Tab make the window and its tabs, and elements are
-- components on a page (page:Toggle, page:Slider...). Cascade elements have no title, so each one gets a Label above it.
local function cascade(lib)
    local api = {}
    local app = nil

    local function ensureApp()
        if not app then
            app = safe(function()
                return lib.New({})
            end)
        end
        return app
    end

    local function keyCode(value)
        local name = keyName(value)
        if not name then
            return nil
        end
        return safe(function()
            return Enum.KeyCode[name]
        end)
    end

    local function roundTo(value, increment)
        if type(increment) == "number" and increment > 0 then
            return math.floor(value / increment + 0.5) * increment
        end
        return value
    end

    local function notify(o)
        o = type(o) == "table" and o or {}
        safe(function()
            ensureApp():Notification({ Title = o.Title or "Dominant", Subtitle = o.Text or "", Duration = o.Duration or 4 })
        end)
    end

    local function element(raw)
        local e = {}
        function e.Set(_, value)
            safe(function()
                raw.Value = value
            end)
        end
        e.SetValue = e.Set
        function e.Destroy()
            safe(function()
                raw:Destroy()
            end)
        end
        return e
    end

    local container

    container = function(page)
        local c = {}

        local function label(text)
            if text and text ~= "" then
                safe(function()
                    page:Label({ Text = tostring(text) })
                end)
            end
        end

        local function degraded(title, o)
            if type(o) ~= "table" then
                o = {}
            end
            safe(function()
                page:PageSection({ Title = tostring(title or ""), Subtitle = describe(o) })
            end)
            return ghost()
        end

        function c.AddSection(_, name)
            safe(function()
                page:PageSection({ Title = sectionName(name) })
            end)
            return c
        end

        function c.AddSubTab(_, o)
            return c.AddSection(c, o)
        end

        function c.AddParagraph(_, o)
            o = type(o) == "table" and o or {}
            safe(function()
                page:PageSection({ Title = tostring(o.Title or ""), Subtitle = tostring(o.Text or "") })
            end)
            return ghost()
        end

        function c.AddToggle(_, o)
            label(o.Text)
            return element(safe(function()
                return page:Toggle({
                    Value = o.Default == true,
                    ValueChanged = function(_, value)
                        if o.Callback then
                            o.Callback(value)
                        end
                    end,
                })
            end))
        end

        function c.AddDropdown(_, o)
            label(o.Text)
            local options = type(o.Options) == "table" and o.Options or {}
            local startIndex = nil
            for index, item in ipairs(options) do
                if item == o.Default then
                    startIndex = index
                end
            end
            return element(safe(function()
                return page:PopUpButton({
                    Options = options,
                    Value = startIndex,
                    ValueChanged = function(_, index)
                        if o.Callback then
                            o.Callback(options[index])
                        end
                    end,
                })
            end))
        end

        function c.AddSlider(_, o)
            label(o.Text)
            return element(safe(function()
                return page:Slider({
                    Minimum = o.Min or 0,
                    Maximum = o.Max or 100,
                    Value = o.Default or o.Min or 0,
                    ValueChanged = function(_, value)
                        if o.Callback then
                            o.Callback(roundTo(value, o.Increment))
                        end
                    end,
                })
            end))
        end

        function c.AddTextbox(_, o)
            label(o.Text)
            return element(safe(function()
                return page:TextField({
                    Placeholder = o.Placeholder or "",
                    Value = tostring(o.Default or ""),
                    ValueChanged = function(_, text)
                        if o.Callback then
                            o.Callback(text)
                        end
                    end,
                })
            end))
        end

        function c.AddKeybind(_, o)
            label(o.Text)
            return element(safe(function()
                return page:KeybindField({
                    Placeholder = "None",
                    Value = keyCode(o.Default),
                    ValueChanged = function(_, key)
                        if o.Callback then
                            o.Callback(key)
                        end
                    end,
                })
            end))
        end

        function c.AddButton(_, o)
            safe(function()
                page:Button({
                    Label = o.Text or "Button",
                    State = "Secondary",
                    Pushed = function()
                        if o.Callback then
                            o.Callback()
                        end
                    end,
                })
            end)
            return ghost()
        end

        function c.AddColorPicker(_, o)
            return degraded(type(o) == "table" and o.Text or "Color", { Description = tostring(type(o) == "table" and o.Default or "") })
        end

        function c.AddTable(_, o)
            return degraded(type(o) == "table" and o.Title or "Table", o)
        end
        function c.AddProgress(_, o)
            return degraded(type(o) == "table" and o.Text or "Progress", o)
        end
        function c.AddConsole(_, o)
            return degraded("Console", o)
        end
        function c.AddCard(_, o)
            return degraded(type(o) == "table" and o.Title or "", o)
        end
        function c.AddChangelogEntry(_, o)
            o = type(o) == "table" and o or {}
            return degraded(tostring(o.Version or "") .. " " .. tostring(o.Date or ""), { Description = rowsText(o.Changes) })
        end
        function c.AddSystemInfoGrid(_, o)
            return degraded("System info", o)
        end
        function c.AddDefaultCreditsPanel(_, o)
            return degraded("Credits", o)
        end

        return c
    end

    local function windowApi(win)
        local w = {}
        function w.AddTab(_, o)
            o = type(o) == "table" and o or {}
            local page = safe(function()
                return ensureApp():Page({})
            end)
            if not page then
                return ghost()
            end
            safe(function()
                win:Tab({ Title = o.Name or "Tab", Icon = iconName(o.Icon), Page = page })
            end)
            return container(page)
        end
        function w.Notify(_, o)
            notify(o)
        end
        return setmetatable(w, { __index = function() return noop end })
    end

    function api.CreateWindow(_, o)
        o = type(o) == "table" and o or {}
        local win = safe(function()
            return ensureApp():Window({
                Title = o.Title or "Dominant",
                Subtitle = o.Subtitle or "",
                Draggable = true,
                Resizable = o.Resizable ~= false,
                Size = o.Size,
            })
        end)
        if not win then
            error("Cascade could not open the window")
        end
        return windowApi(win)
    end

    function api.Notify(_, o)
        notify(o)
    end

    return setmetatable(api, { __index = function() return noop end })
end

-- Returns the Vind-shaped API for a library. Vind (kind "vind") is returned as it is.
function M.wrap(kind, lib)
    if kind == "cascade" then
        return cascade(lib)
    end
    if kind == "windui" then
        return windui(lib)
    end
    if kind == "rayfield" then
        return rayfield(lib)
    end
    return lib
end

return M
