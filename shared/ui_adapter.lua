-- Gives WindUI, Rayfield and Cascade the API the scripts were written against (the Vind API), so the games and the
-- shared features do not change when the interface is switched. Vind itself is used directly and needs no adapter.
--
-- Elements a library cannot show become a paragraph with their text. The things only Vind had (Confirm dialogs, Flags,
-- the theme colours, Unload) are provided here for every library.
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

local function make(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props) do
        object[key] = value
    end
    object.Parent = parent
    return object
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

local function roundTo(value, increment)
    if type(increment) == "number" and increment > 0 then
        return math.floor(value / increment + 0.5) * increment
    end
    return value
end

-- The theme colours the scripts read from Dominant.Vind.Theme (the same mapping core/vind.lua uses)
local function themeFrom(palette)
    palette = type(palette) == "table" and palette or {}
    return {
        Background = palette.bg,
        Surface = palette.input,
        Card = palette.card,
        Text = palette.text,
        TextDim = palette.muted,
        Accent = palette.accent,
        Outline = palette.stroke,
        Border = palette.stroke,
        Button = palette.btn2,
        ButtonHover = palette.btn2Hover,
        Input = palette.input,
        Placeholder = palette.muted,
        Stroke = palette.stroke,
    }
end

local ELEMENTS = { "AddToggle", "AddDropdown", "AddTextbox", "AddSlider", "AddKeybind", "AddColorPicker" }
local PACED = {
    "AddToggle", "AddDropdown", "AddTextbox", "AddSlider", "AddKeybind", "AddColorPicker", "AddButton",
    "AddParagraph", "AddSection", "AddTable", "AddProgress", "AddConsole", "AddCard", "AddChangelogEntry",
    "AddSystemInfoGrid", "AddDefaultCreditsPanel",
}

-- Libraries build each element with many instances and connections. Building hundreds of them in one frame freezes the
-- client, so every few elements the build waits one frame. This only happens when the build runs in a task that can
-- wait (the loader's build does); otherwise the build simply carries on.
local builtCount = 0
local function pace()
    builtCount = builtCount + 1
    if builtCount % 6 == 0 and coroutine.isyieldable() then
        task.wait()
    end
end

-- Every element that has a Flag (or a Text) is kept, so Dominant.Vind.Flags[flag]:Set(value) reaches it, and every
-- element and section is paced
local function remember(c, flags)
    local isElement = {}
    for _, name in ipairs(ELEMENTS) do
        isElement[name] = true
    end
    for _, name in ipairs(PACED) do
        local original = c[name]
        if original then
            c[name] = function(self, o)
                local result = original(self, o)
                if isElement[name] and type(o) == "table" and result then
                    local key = o.Flag or o.Text
                    if key then
                        flags[key] = result
                    end
                end
                pace()
                return result
            end
        end
    end
    return c
end

-- Confirm: a small dialog built here, so it works the same with every library. If it cannot be shown, the answer is no.
local function confirmDialog(o)
    o = type(o) == "table" and o or {}
    local finished = false
    local gui = nil

    local function finish(answer)
        if finished then
            return
        end
        finished = true
        if gui then
            safe(function()
                gui:Destroy()
            end)
        end
        if type(o.Callback) == "function" then
            safe(function()
                o.Callback(answer)
            end)
        end
    end

    local built = pcall(function()
        local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
        gui = make("ScreenGui", { Name = "DominantConfirm", ResetOnSpawn = false, DisplayOrder = 500 }, parent)
        local shade = make("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
        }, gui)
        local card = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 160),
            BackgroundColor3 = Color3.fromRGB(14, 14, 14),
            BorderSizePixel = 0,
        }, shade)
        make("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(20, 16),
            Size = UDim2.new(1, -40, 0, 24),
            Text = tostring(o.Title or ""),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(20, 46),
            Size = UDim2.new(1, -40, 0, 56),
            Text = tostring(o.Text or ""),
            TextColor3 = Color3.fromRGB(150, 150, 150),
            TextSize = 13,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, card)
        local cancel = make("TextButton", {
            Position = UDim2.fromOffset(20, 112),
            Size = UDim2.new(0.5, -28, 0, 34),
            BackgroundColor3 = Color3.fromRGB(38, 38, 38),
            BorderSizePixel = 0,
            Text = tostring(o.Cancel or "Cancel"),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
        }, card)
        local confirm = make("TextButton", {
            Position = UDim2.new(0.5, 8, 0, 112),
            Size = UDim2.new(0.5, -28, 0, 34),
            BackgroundColor3 = Color3.fromRGB(235, 235, 235),
            BorderSizePixel = 0,
            Text = tostring(o.Confirm or "Confirm"),
            TextColor3 = Color3.fromRGB(10, 10, 10),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
        }, card)
        cancel.Activated:Connect(function()
            finish(false)
        end)
        confirm.Activated:Connect(function()
            finish(true)
        end)
    end)
    if not built then
        finish(false)
    end
end

-- Screen size and touch detection, used to size Cascade on phones and tablets
local function screenSize()
    local ok, size = pcall(function()
        return workspace.CurrentCamera.ViewportSize
    end)
    if ok and size then
        return size.X, size.Y
    end
    return 1280, 720
end

local function touchDevice()
    local ok, input = pcall(function()
        return game:GetService("UserInputService")
    end)
    if not ok or not input then
        return false
    end
    return input.TouchEnabled == true and input.KeyboardEnabled ~= true
end

-- WindUI: windows are lib:CreateWindow, tabs are window:Tab, elements are tab:Toggle, tab:Dropdown...
local function windui(lib, palette)
    local api = {}
    local flags = {}
    local handle = nil

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

        return remember(c, flags)
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
        handle = raw
        return windowApi(raw)
    end

    function api.Notify(_, o)
        notify(o)
    end
    function api.Confirm(_, o)
        confirmDialog(o)
    end
    function api.Unload()
        if handle then
            safe(function()
                handle:Destroy()
            end)
        end
    end

    api.Flags = flags
    api.Theme = themeFrom(palette)
    return setmetatable(api, { __index = function() return noop end })
end

-- Rayfield: windows are lib:CreateWindow, tabs are window:CreateTab, elements are tab:CreateToggle...
-- Rayfield sections are headings on the tab, so elements added after a section still belong to the tab.
local function rayfield(lib, palette)
    local api = {}
    local flags = {}
    local opened = false

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

        return remember(c, flags)
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
        opened = true
        return windowApi(raw)
    end

    function api.Notify(_, o)
        notify(o)
    end
    function api.Confirm(_, o)
        confirmDialog(o)
    end
    function api.Unload()
        if opened then
            safe(function()
                lib:Destroy()
            end)
        end
    end

    api.Flags = flags
    api.Theme = themeFrom(palette)
    return setmetatable(api, { __index = function() return noop end })
end

-- Cascade: cascade.New makes the app, app:Window and win:Tab make the window and its tabs, and elements are components
-- on a page (page:Toggle, page:Slider...). Cascade elements have no title, so each one gets a Label above it.
-- Cascade is opened in its dark theme, sized to the screen on phones and tablets, and its first tab is selected.
local function cascade(lib, palette)
    local api = {}
    local flags = {}
    local app = nil
    local selectedOne = false

    local function ensureApp()
        if not app then
            local darkTheme = lib.Themes and lib.Themes.Dark or nil
            app = safe(function()
                return lib.New({ Theme = darkTheme, WindowPill = true })
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

        return remember(c, flags)
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
            local selected = not selectedOne
            if selected then
                selectedOne = true
            end
            safe(function()
                win:Tab({ Title = o.Name or "Tab", Icon = iconName(o.Icon), Page = page, Selected = selected })
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
        local width, height = screenSize()
        local phone = touchDevice() or width < 700
        local size = o.Size
        local resizable = o.Resizable ~= false
        if phone then
            size = UDim2.fromOffset(math.min(width - 16, 440), math.min(height - 80, 470))
            resizable = false
        end
        local win = safe(function()
            return ensureApp():Window({
                Title = o.Title or "Dominant",
                Subtitle = o.Subtitle or "",
                Draggable = true,
                Resizable = resizable,
                Size = size,
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
    function api.Confirm(_, o)
        confirmDialog(o)
    end
    function api.Unload()
        if app then
            safe(function()
                app:Destroy()
            end)
        end
    end

    api.Flags = flags
    api.Theme = themeFrom(palette)
    return setmetatable(api, { __index = function() return noop end })
end

-- Returns the Vind-shaped API for a library. Vind (kind "vind") is returned as it is.
function M.wrap(kind, lib, palette)
    if kind == "cascade" then
        return cascade(lib, palette)
    end
    if kind == "windui" then
        return windui(lib, palette)
    end
    if kind == "rayfield" then
        return rayfield(lib, palette)
    end
    return lib
end

return M
