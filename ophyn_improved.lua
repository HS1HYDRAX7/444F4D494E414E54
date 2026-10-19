--[[
    Ophyn UI Library - Enhanced Version (Part 1/2)
    Modern design with smooth animations and better organization
    Based on original ophyn.lua with significant improvements
]]

local modules = {}
local cache = {}

local function import(path)
    local cached = cache[path]
    if cached ~= nil then
        return cached
    end
    local loader = modules[path]
    if not loader then
        error("module not found: " .. tostring(path))
    end
    local ok, value = pcall(loader)
    if not ok then
        error("failed to load module " .. tostring(path) .. ": " .. tostring(value))
    end
    cache[path] = value
    return value
end

-- Enhanced color palettes
local THEMES = {
    Dark = {
        bg = Color3.fromRGB(12, 12, 16),
        panel = Color3.fromRGB(24, 24, 32),
        input = Color3.fromRGB(32, 32, 40),
        card = Color3.fromRGB(28, 28, 36),
        stroke = Color3.fromRGB(45, 45, 55),
        btn2 = Color3.fromRGB(36, 38, 48),
        btn2Hover = Color3.fromRGB(50, 54, 68),
        text = Color3.fromRGB(245, 248, 255),
        muted = Color3.fromRGB(130, 140, 160),
        accent = Color3.fromRGB(0, 200, 255),
        accent_secondary = Color3.fromRGB(100, 220, 255),
        warn = Color3.fromRGB(255, 185, 0),
        success = Color3.fromRGB(80, 250, 123),
        error = Color3.fromRGB(255, 85, 85),
        submitBg = Color3.fromRGB(0, 200, 255),
        submitText = Color3.fromRGB(12, 12, 16),
        glowBase = Color3.fromRGB(0, 220, 255),
        glowFrom = Color3.fromRGB(100, 240, 255),
        glowTo = Color3.fromRGB(0, 180, 255),
        confetti = {Color3.fromRGB(0, 200, 255), Color3.fromRGB(100, 220, 255), Color3.fromRGB(200, 240, 255), Color3.fromRGB(80, 250, 123)},
    },
    Amethyst = {
        bg = Color3.fromRGB(14, 11, 16),
        panel = Color3.fromRGB(24, 19, 28),
        input = Color3.fromRGB(20, 16, 22),
        card = Color3.fromRGB(28, 23, 32),
        stroke = Color3.fromRGB(48, 38, 55),
        btn2 = Color3.fromRGB(38, 32, 44),
        btn2Hover = Color3.fromRGB(52, 44, 60),
        text = Color3.fromRGB(240, 235, 245),
        muted = Color3.fromRGB(130, 120, 140),
        accent = Color3.fromRGB(230, 190, 255),
        accent_secondary = Color3.fromRGB(240, 200, 255),
        warn = Color3.fromRGB(245, 180, 100),
        success = Color3.fromRGB(110, 220, 155),
        error = Color3.fromRGB(255, 105, 105),
        submitBg = Color3.fromRGB(230, 190, 255),
        submitText = Color3.fromRGB(18, 12, 22),
        glowBase = Color3.fromRGB(230, 200, 255),
        glowFrom = Color3.fromRGB(255, 255, 255),
        glowTo = Color3.fromRGB(220, 180, 255),
        confetti = {Color3.fromRGB(230, 190, 255), Color3.fromRGB(110, 220, 155), Color3.fromRGB(255, 255, 255), Color3.fromRGB(245, 180, 100)},
    },
    Carmim = {
        bg = Color3.fromRGB(10, 10, 10),
        panel = Color3.fromRGB(20, 17, 17),
        input = Color3.fromRGB(16, 14, 14),
        card = Color3.fromRGB(24, 20, 20),
        stroke = Color3.fromRGB(38, 32, 32),
        btn2 = Color3.fromRGB(32, 28, 28),
        btn2Hover = Color3.fromRGB(46, 40, 40),
        text = Color3.fromRGB(240, 236, 236),
        muted = Color3.fromRGB(130, 122, 122),
        accent = Color3.fromRGB(230, 45, 55),
        accent_secondary = Color3.fromRGB(240, 150, 150),
        warn = Color3.fromRGB(240, 176, 108),
        success = Color3.fromRGB(120, 210, 140),
        error = Color3.fromRGB(240, 120, 120),
        submitBg = Color3.fromRGB(139, 17, 27),
        submitText = Color3.fromRGB(255, 255, 255),
        glowBase = Color3.fromRGB(255, 120, 120),
        glowFrom = Color3.fromRGB(255, 90, 90),
        glowTo = Color3.fromRGB(200, 20, 35),
        confetti = {Color3.fromRGB(230, 45, 55), Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 255, 255)},
    },
}

local IMAGES = {
    GLOW = "rbxassetid://8992230677",
    SHADOW = "rbxassetid://6014261993",
    CLOSEICON = "rbxassetid://10738956374",
    CHECKMARK = "rbxassetid://10738957391",
    CHEVRONUP = "rbxassetid://10738958595",
    CHEVRONDOWN = "rbxassetid://10738958939",
    KEY = "rbxassetid://10738960173",
    SUBMIT = "rbxassetid://10738961016",
    LINK = "rbxassetid://10738961859",
    DISCORD = "rbxassetid://10738962702",
    MOONICON = "rbxassetid://10738963545",
    SUNICON = "rbxassetid://10738964388",
}

local CONFIG = {
    W = 640, H = 480, SIDEW = 180, TOPBARH = 40, TABSBARH = 35,
    SECTIONPADDING = 16, ELEMENTPADDING = 12,
    SLIDETIME = 0.4, TABINTIME = 0.35, TABSTAGGER = 0.06, TABSTAGGERMAX = 0.2, TABSLIDE = 20,
    NOTIFTRANSPARENCY = 0.1, NOTIFCOLOR = "card", NOTIFBLUR = 8,
    FONTFAMILY = "rbxassetid://12187365364",
    NOTIFW = 280, MAXNOTIFS = 5,
}

local TweenService = game:GetService("TweenService")

local function tween(instance, time, props, style, direction)
    local info = TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function make(className, props, parent)
    local instance = Instance.new(className)
    for k, v in pairs(props) do instance[k] = v end
    if parent then instance.Parent = parent end
    return instance
end

local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness, transparency, applyMode)
    make("UIStroke", { Color = color, Thickness = thickness or 1, Transparency = transparency or 0, ApplyStrokeMode = applyMode or Enum.ApplyStrokeMode.Border }, parent)
end

local function gradient(parent, rotation, colors)
    local grad = make("UIGradient", { Rotation = rotation or 90, Color = ColorSequence.new(colors or {Color3.new(1,1,1), Color3.new(0.5,0.5,0.5)}) }, parent)
    return grad
end

local themeIndex = 1
local C = {}
local function loadTheme(theme)
    for k, v in pairs(theme) do C[k] = v end
end
loadTheme(THEMES.Dark)

local FONT, FONTBOLD
local function resolveFont(family, weight, style)
    local ok, font = pcall(function() return Font.new(family or CONFIG.FONTFAMILY, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal) end)
    return ok and font or Enum.Font.Gotham
end
FONT = resolveFont(CONFIG.FONTFAMILY, Enum.FontWeight.Regular)
FONTBOLD = resolveFont(CONFIG.FONTFAMILY, Enum.FontWeight.Bold)

local COLORPROPS = { BackgroundColor3 = true, TextColor3 = true, ImageColor3 = true, Color = true, PlaceholderColor3 = true }
local bindings = {}
local fontBindings = {}

local function fontFor(entryFont)
    if fontSettings and fontSettings.ui then
        local u = fontSettings.ui
        return entryFont.bold and Font.new(u.Family, Enum.FontWeight.Bold, u.Style) or u
    end
    return entryFont.bold and FONTBOLD or FONT
end

local function markBoldFont(inst)
    for _, entryFont in ipairs(fontBindings) do
        if entryFont.inst == inst then
            entryFont.bold = true
            inst.FontFace = fontFor(entryFont)
            return
        end
    end
end

local function createContext(config, theme, images)
    local ctx = {
        C = C, images = images or IMAGES, FONT = FONT, FONTBOLD = FONTBOLD,
        make = make, corner = corner, stroke = stroke, tween = tween, gradient = gradient,
        loadTheme = function(themeName) loadTheme(THEMES[themeName] or THEMES.Dark) end,
        state = { ready = false, closing = false, popupOpen = false },
        prep = function(container)
            local items = {}
            local function add(inst)
                if inst:IsA("GuiObject") then
                    items[#items + 1] = { inst, "BackgroundTransparency", inst.BackgroundTransparency }
                    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                        items[#items + 1] = { inst, "TextTransparency", inst.TextTransparency }
                    elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                        items[#items + 1] = { inst, "ImageTransparency", inst.ImageTransparency }
                    elseif inst:IsA("ScrollingFrame") then
                        items[#items + 1] = { inst, "ScrollBarImageTransparency", inst.ScrollBarImageTransparency }
                    end
                end
                for _, child in ipairs(inst:GetChildren()) do add(child) end
            end
            add(container)
            return items
        end,
        fade = function(items, target, time)
            time = time or 0.2
            for _, item in ipairs(items) do
                local inst, prop, start = item[1], item[2], item[3]
                if inst.Parent then
                    local goal = start + (target - start) * (1 - start)
                    tween(inst, time, { [prop] = goal })
                end
            end
        end,
        frame = function(parent, x, y, w, h, color, transparency)
            return make("Frame", { Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, w, 0, h), BackgroundColor3 = color and C[color] or C.bg, BackgroundTransparency = transparency or 1, BorderSizePixel = 0 }, parent)
        end,
        text = function(parent, str, x, y, w, h, size, color, align)
            return make("TextLabel", { Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, w, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0, Text = str, TextSize = size, TextColor3 = color and C[color] or C.text, TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, FontFace = FONT }, parent)
        end,
        round = function(parent, radius, strokeColor)
            corner(parent, radius)
            if strokeColor then stroke(parent, strokeColor, 1, 0.35) end
        end,
        icon = function(parent, x, y, color, image)
            local holder = ctx.frame(parent, x, y, 16, 16)
            make("ImageLabel", { Name = "iconglow", Size = UDim2.new(2, 0, 2, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = IMAGES.GLOW, ImageColor3 = color or C.accent, ImageTransparency = 0.9, ZIndex = 0 }, holder)
            local img = make("ImageLabel", { Name = "iconimage", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ImageColor3 = color or C.accent }, holder)
            if type(image) == "string" then img.Image = image
            elseif type(image) == "table" then
                img.Image = image.Image
                if image.RectSize then img.ImageRectSize = image.RectSize end
                if image.RectOffset then img.ImageRectOffset = image.RectOffset end
            end
            return holder
        end,
        decor = function(parent, w, h, x, y, transparency, rotation)
            local img = make("ImageLabel", { Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0, x, 0, y), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = IMAGES.GLOW, ImageColor3 = C.glowBase, ImageTransparency = transparency or 0.8, ScaleType = Enum.ScaleType.Stretch }, parent)
            gradient(img, rotation or 90, {C.glowFrom, C.glowTo})
            return img
        end,
        iconRole = function(role)
            local roles = { accent = C.accent, muted = C.muted, text = C.text, warn = C.warn, error = C.error, success = C.success }
            return roles[role] or C.accent
        end,
        tintIcons = true, markBoldFont = markBoldFont, root = nil, cfg = config or {},
    }
    return ctx
end

-- Dialog System
modules["components/window/dialog"] = function()
    return function()
        local Dialog = {}
        function Dialog.new(ctx, callbacks)
            callbacks = callbacks or {}
            local C = ctx.C
            local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
            local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
            local state = ctx.state

            local popup = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10, Visible = false }, ctx.canvas)
            local dim = make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, popup)
            ctx.round(dim, 10)

            local popupCard = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 300, 0, 160), BackgroundColor3 = C.card, BorderSizePixel = 0 }, popup)
            ctx.round(popupCard, 14)
            ctx.stroke(popupCard, C.stroke, 1, 0.3)

            local title = text(popupCard, callbacks.Title or "Confirm", 20, 20, 260, 24, 16, "text")
            title.FontFace = ctx.FONTBOLD
            local message = text(popupCard, callbacks.Text or "Are you sure?", 20, 50, 260, 40, 13, "muted")
            message.TextWrapped = true

            local cancelBtn = make("TextButton", { Position = UDim2.new(0, 20, 0, 120), Size = UDim2.new(0, 100, 0, 32), BackgroundColor3 = C.btn2, BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, Text = callbacks.CancelText or "Cancel", TextSize = 13, TextColor3 = C.text, FontFace = ctx.FONT }, popupCard)
            ctx.round(cancelBtn, 8)
            local confirmBtn = make("TextButton", { Position = UDim2.new(0, 160, 0, 120), Size = UDim2.new(0, 100, 0, 32), BackgroundColor3 = C.accent, BackgroundTransparency = 0, BorderSizePixel = 0, AutoButtonColor = false, Text = callbacks.ConfirmText or "Confirm", TextSize = 13, TextColor3 = C.submitText, FontFace = ctx.FONTBOLD }, popupCard)
            ctx.round(confirmBtn, 8)

            local popupItems = prep(popup)
            fade(popupItems, 0)

            local function show()
                if not state.ready or state.popupOpen or state.closing then return end
                state.popupOpen = true
                popup.Visible = true
                fade(popupItems, 1, 0.25)
            end

            local function hide()
                if not state.popupOpen or state.closing then return end
                state.popupOpen = false
                fade(popupItems, 0, 0.2)
                task.delay(0.25, function() popup.Visible = false end)
            end

            cancelBtn.MouseButton1Click:Connect(hide)
            confirmBtn.MouseButton1Click:Connect(function()
                if callbacks.onConfirm then callbacks.onConfirm() end
                hide()
            end)

            return { show = show, hide = hide }
        end
        return Dialog
    end
end

-- Notification System
modules["components/window/notification"] = function()
    return function(ctx)
        local C = ctx.C
        local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
        local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
        local NOTIFW = ctx.cfg.NOTIFW or 280
        local NOTIFTRANSPARENCY = ctx.cfg.NOTIFTRANSPARENCY or 0.1
        local NOTIFCOLOR = ctx.cfg.NOTIFCOLOR or "card"
        local notifCount = 0

        local function createNotification(props)
            notifCount = notifCount + 1
            local wrapper = make("Frame", { Size = UDim2.new(0, NOTIFW, 0, 60), Position = UDim2.new(1, 10, 0, (notifCount - 1) * 70), BackgroundTransparency = 1, BorderSizePixel = 0 }, ctx.root)
            local notif = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C[NOTIFCOLOR], BackgroundTransparency = NOTIFTRANSPARENCY, BorderSizePixel = 0 }, wrapper)
            ctx.round(notif, 10)
            ctx.stroke(notif, C.stroke, 1, 0.35)
            local title = text(notif, props.Title or "Notification", 12, 10, NOTIFW - 20, 20, 14, "text")
            local message = text(notif, props.Text or "", 12, 35, NOTIFW - 20, 20, 12, "muted")
            wrapper.Position = UDim2.new(1, -10, 0, (notifCount - 1) * 70)
            tween(wrapper, 0.3, { Position = UDim2.new(1, -10, 0, (notifCount - 1) * 70) }, Enum.EasingStyle.Quint)
            task.delay(props.Duration or 5, function()
                tween(wrapper, 0.3, { Position = UDim2.new(1, -NOTIFW - 10, 0, (notifCount - 1) * 70) })
                task.delay(0.3, function() wrapper:Destroy() end)
            end)
            return wrapper
        end
        return { new = createNotification }
    end
end

-- Key System (Simplified)
modules["components/window/ui"] = function()
    return function(options)
        options = options or {}
        local ctx = createContext(options.Config or {}, options.Theme, options.Images)
        ctx.cfg = options
        local C = ctx.C
        local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
        local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade

        local keySystem = { window = nil, keyInput = nil, getKeyBtn = nil }
        keySystem.window = make("Frame", { Name = "KeySystem", Size = UDim2.new(0, 400, 0, 300), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.bg, BorderSizePixel = 0, Visible = false }, ctx.canvas)
        ctx.corner(keySystem.window, 12)
        ctx.stroke(keySystem.window, C.accent, 1, 0)

        local title = text(keySystem.window, options.Title or "Key System", 20, 20, 0, 30, 18, "text")
        title.FontFace = ctx.FONTBOLD
        title.AutomaticSize = Enum.AutomaticSize.X

        local desc = text(keySystem.window, options.Description or "Enter your key", 20, 45, 360, 40, 12, "muted")
        desc.TextWrapped = true

        keySystem.keyInput = make("TextBox", { Position = UDim2.new(0, 20, 0, 100), Size = UDim2.new(1, -40, 0, 36), BackgroundColor3 = C.input, BackgroundTransparency = 0, BorderSizePixel = 0, Text = "", TextSize = 13, TextColor3 = C.text, PlaceholderColor3 = C.muted, PlaceholderText = options.Placeholder or "Enter key...", FontFace = ctx.FONT }, keySystem.window)
        ctx.round(keySystem.keyInput, 8)
        ctx.stroke(keySystem.keyInput, C.stroke, 1, 0.3)

        keySystem.getKeyBtn = make("TextButton", { Position = UDim2.new(0, 20, 0, 150), Size = UDim2.new(1, -40, 0, 32), BackgroundColor3 = C.accent, BackgroundTransparency = 0, BorderSizePixel = 0, AutoButtonColor = false, Text = options.GetKeyText or "Get Key", TextSize = 13, TextColor3 = C.submitText, FontFace = ctx.FONTBOLD }, keySystem.window)
        ctx.round(keySystem.getKeyBtn, 8)

        local submitBtn = make("TextButton", { Position = UDim2.new(0, 20, 0, 200), Size = UDim2.new(1, -40, 0, 32), BackgroundColor3 = C.success, BackgroundTransparency = 0, BorderSizePixel = 0, AutoButtonColor = false, Text = options.SubmitText or "Submit", TextSize = 13, TextColor3 = Color3.new(1, 1, 1), FontFace = ctx.FONTBOLD }, keySystem.window)
        ctx.round(submitBtn, 8)

        local status = text(keySystem.window, "", 20, 240, 360, 20, 12, "warn")
        status.TextXAlignment = Enum.TextXAlignment.Center

        keySystem.getKeyBtn.MouseButton1Click:Connect(function()
            if options.GetKeyUrl and options.GetKeyUrl:match("^https?://") then
                if request then request({ Url = options.GetKeyUrl }) end
            end
        end)

        submitBtn.MouseButton1Click:Connect(function()
            local key = keySystem.keyInput.Text
            if key == "" then
                status.Text = "Please enter a key"
                status.TextColor3 = C.error
                return
            end
            if options.Callback then
                local success, message = options.Callback(key)
                status.Text = success and "Key accepted!" or (message or "Invalid key")
                status.TextColor3 = success and C.success or C.error
                if success then keySystem:close() end
            end
        end)

        function keySystem:open()
            keySystem.window.Visible = true
            tween(keySystem.window, 0.4, { BackgroundTransparency = 0 })
        end
        function keySystem:close()
            tween(keySystem.window, 0.4, { BackgroundTransparency = 1 })
            task.delay(0.4, function() keySystem.window.Visible = false end)
        end
        return keySystem
    end
end

-- Main KeySystem export
local KeySystem = {}
function KeySystem.new(options)
    return import("components/window/ui").new(options)
end
function KeySystem.SetTheme(themeName)
    if THEMES[themeName] then loadTheme(THEMES[themeName]) end
end
function KeySystem.GetThemes() return THEMES end

return KeySystem
