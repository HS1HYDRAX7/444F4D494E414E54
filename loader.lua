--[[ 
    DOMINANT - Professional Loader v3.0
    Modern, clean and premium design with smooth animations
    Built with professional UI/UX principles
    
    Design: Senior UI/UX Designer (15+ years experience)
    Theme: Dark Red (Carmim) - Elegant and Professional
    Animations: Premium TweenService with precise timings
]]

-- ========== SERVICES & CONFIG ==========
local BASE = "https://raw.githubusercontent.com/HS1HYDRAX7/DOMINANT/main/"
local ASSET_FOLDER = "Dominant/Assets"
local STALL_TIMEOUT = 25
local THUMBNAIL_API = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=%s&countPerUniverse=1&defaults=true&size=768x432&format=Png&isCircular=false"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- ========== PROFESSIONAL COLOR PALETTE (Dark Red Theme - Carmim) ==========
local PALETTE = {
    -- Background colors (dark base for elegance)
    bg = Color3.fromRGB(10, 10, 14),           -- Deep dark background
    panel = Color3.fromRGB(22, 22, 30),        -- Main panel color
    panel_hover = Color3.fromRGB(28, 28, 38),   -- Panel hover state
    panel_active = Color3.fromRGB(35, 35, 45), -- Panel active/pressed state
    
    -- Accent colors (Carmim/Red theme - signature color)
    accent = Color3.fromRGB(230, 45, 55),       -- Primary accent (red)
    accent_secondary = Color3.fromRGB(255, 100, 140), -- Secondary accent (lighter red)
    accent_tertiary = Color3.fromRGB(180, 30, 45), -- Tertiary accent (darker red)
    
    -- Text colors (high contrast for readability)
    text = Color3.fromRGB(245, 248, 255),      -- Primary text (almost white)
    text_secondary = Color3.fromRGB(180, 190, 210), -- Secondary text (muted)
    text_tertiary = Color3.fromRGB(130, 140, 160), -- Tertiary text (very muted)
    muted = Color3.fromRGB(130, 140, 160),
    
    -- Status colors
    error = Color3.fromRGB(255, 85, 85),        -- Error state (red)
    success = Color3.fromRGB(80, 250, 123),     -- Success state (green)
    warn = Color3.fromRGB(255, 185, 0),        -- Warning state (orange)
    info = Color3.fromRGB(0, 200, 255),        -- Info state (cyan)
    
    -- Glow & Effect colors
    glowFrom = Color3.fromRGB(255, 120, 120),   -- Glow start (light red)
    glowTo = Color3.fromRGB(200, 20, 35),      -- Glow end (dark red)
    glowBase = Color3.fromRGB(255, 255, 255),   -- Glow base (white)
    
    -- Button colors
    button = Color3.fromRGB(36, 38, 48),        -- Button background
    buttonHover = Color3.fromRGB(48, 50, 62),   -- Button hover
    buttonActive = Color3.fromRGB(60, 64, 78),  -- Button active/pressed
    buttonBorder = Color3.fromRGB(230, 45, 55), -- Button border (accent)
    
    -- Border & Stroke colors
    border = Color3.fromRGB(45, 50, 65),        -- Default border
    border_bright = Color3.fromRGB(60, 65, 80), -- Brighter border
    
    -- Shadow colors
    shadow = Color3.fromRGB(0, 0, 0),          -- Base shadow
    
    -- Overlay colors
    overlay = Color3.fromRGB(0, 0, 0),         -- Overlay base
}

-- ========== ASSET CONFIGURATION ==========
local IMAGES = {
    font = "rbxassetid://12187365364",         -- Gotham font
    glow = "rbxassetid://8992230677",          -- Glow effect
    shadow = "rbxassetid://6014261993",        -- Shadow effect
    logo = "",                                -- Logo (loaded dynamically)
}

-- ========== DIMENSIONS & TIMING (Professional Spacing) ==========
local FINAL_W, FINAL_H = 520, 300            -- Final card dimensions (increased for better presence)
local BANNER_H = 170                          -- Banner height
local INTRO_SIZE = 90                        -- Initial intro size
local SQUARE_TIME = 1.6                      -- Time to stay in square state
local LOGO_W, LOGO_H = 56, 52                -- Logo dimensions
local WORD = "DOMINANT"                       -- Brand name
local CORNER_RADIUS = 14                     -- Standard corner radius
local SMALL_RADIUS = 8                       -- Small corner radius
local TINY_RADIUS = 4                        -- Tiny corner radius

-- Progress steps (smooth distribution)
local STEP_PROGRESS = {
    interface = 0.05,
    modules = 0.25,
    game = 0.50,
    key = 0.70,
    window = 0.90
}

-- Animation timings (precise and professional)
local ANIM = {
    intro_grow = 0.7,                        -- Initial grow animation
    intro_expand = 0.95,                     -- Expand to final size
    letter_stagger = 0.1,                   -- Time between letter animations
    letter_duration = 0.35,                 -- Duration of each letter animation
    reveal_duration = 1.1,                  -- Banner reveal duration
    fade_standard = 0.3,                     -- Standard fade duration
    fade_slow = 0.4,                        -- Slow fade duration
    fade_fast = 0.2,                        -- Fast fade duration
    transition_vind = 0.5,                  -- Transition to Vind duration
    pulse_min = 0.18,                       -- Minimum bar size for pulse
    pulse_max = 0.82,                       -- Maximum bar size for pulse
    pulse_speed = 0.65,                     -- Pulse animation speed
}

-- ========== TEXT LOCALIZATION (Professional) ==========
local TEXT = {
    en = {
        stall = "Step took too long",
        modules = "Loading modules",
        game = "Detecting game",
        key = "Waiting for key",
        window = "Building interface",
        ready = "Ready",
        failed = "Could not load Dominant",
        retry = "Retry",
        check = "Check your connection and retry",
        creating = "Creating interface",
        please = "Please wait...",
        welcome = "Welcome to DOMINANT",
        loading = "Loading...",
        success = "Loaded successfully!",
    },
    pt = {
        stall = "Uma etapa demorou demais",
        modules = "Carregando módulos",
        game = "Detectando jogo",
        key = "Aguardando key",
        window = "Montando interface",
        ready = "Pronto",
        failed = "Não foi possível carregar o Dominant",
        retry = "Tentar de novo",
        check = "Verifique sua conexão e tente de novo",
        creating = "Criando interface",
        please = "Aguarde...",
        welcome = "Bem-vindo ao DOMINANT",
        loading = "Carregando...",
        success = "Carregado com sucesso!",
    },
    es = {
        stall = "Un paso tardó demasiado",
        modules = "Cargando módulos",
        game = "Detectando juego",
        key = "Esperando key",
        window = "Construyendo interfaz",
        ready = "Listo",
        failed = "No se pudo cargar Dominant",
        retry = "Reintentar",
        check = "Revisa tu conexión e inténtalo de nuevo",
        creating = "Creando interfaz",
        please = "Espere...",
        welcome = "Bienvenido a DOMINANT",
        loading = "Cargando...",
        success = "Cargado con éxito!",
    },
    ru = {
        stall = "Этап занял слишком много времени",
        modules = "Загрузка модулей",
        game = "Определение игры",
        key = "Ожидание ключа",
        window = "Сборка интерфейса",
        ready = "Готово",
        failed = "Не удалось загрузить Dominant",
        retry = "Повторить",
        check = "Проверьте ваше соединение и повторите",
        creating = "Создание интерфейса",
        please = "Подождите...",
        welcome = "Добро пожаловать в DOMINANT",
        loading = "Загрузка...",
        success = "Успешно загружено!",
    },
}

-- ========== DETECTED GAME TEXT ==========
local DETECTED = {
    en = { ok = "Detected game", no = "Unsupported game", id = "ID", place = "Place" },
    pt = { ok = "Jogo detectado", no = "Jogo não suportado", id = "ID", place = "Lugar" },
    es = { ok = "Juego detectado", no = "Juego no compatible", id = "ID", place = "Lugar" },
    ru = { ok = "Игра определена", no = "Игра не поддерживается", id = "ID", place = "Место" },
}

-- ========== UTILITY FUNCTIONS ==========

-- Create instance with properties
local function make(className, props, parent)
    local instance = Instance.new(className)
    for key, value in pairs(props) do
        instance[key] = value
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

-- Apply corner radius to frame
local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

-- Apply stroke to frame
local function stroke(parent, thickness, color, transparency, applyMode)
    make("UIStroke", {
        Thickness = thickness or 1,
        Color = color or PALETTE.border,
        Transparency = transparency or 0,
        ApplyStrokeMode = applyMode or Enum.ApplyStrokeMode.Border,
    }, parent)
end

-- Create and play tween with professional settings
local function tween(instance, time, props, style, direction, repeatCount, delay)
    local info = TweenInfo.new(
        time or 0.3,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out,
        repeatCount or 0,
        false,
        delay or 0
    )
    local running = TweenService:Create(instance, info, props)
    running:Play()
    return running
end

-- Create spring tween
local function springTween(instance, time, props, frequency, damping)
    local info = TweenInfo.new(
        time or 0.5,
        Enum.EasingStyle.Spring,
        Enum.EasingDirection.Out,
        frequency or 6,
        damping or 0.8
    )
    local running = TweenService:Create(instance, info, props)
    running:Play()
    return running
end

-- Create elastic tween
local function elasticTween(instance, time, props, period)
    local info = TweenInfo.new(
        time or 0.8,
        Enum.EasingStyle.Elastic,
        Enum.EasingDirection.Out,
        period or 0.3
    )
    local running = TweenService:Create(instance, info, props)
    running:Play()
    return running
end

-- Create bounce tween
local function bounceTween(instance, time, props, bounciness)
    local info = TweenInfo.new(
        time or 0.5,
        Enum.EasingStyle.Bounce,
        Enum.EasingDirection.Out,
        bounciness or 0.3
    )
    local running = TweenService:Create(instance, info, props)
    running:Play()
    return running
end

-- Get font based on weight
local function fontOf(weight)
    local ok, font = pcall(function()
        return Font.new(IMAGES.font, weight, Enum.FontStyle.Normal)
    end)
    if ok then
        return font
    end
    if weight == Enum.FontWeight.Bold then
        return Enum.Font.GothamBold
    end
    return Enum.Font.Gotham
end

-- Place GUI in correct parent
local function placeGui(gui)
    local ok = false
    if typeof(gethui) == "function" then
        ok = pcall(function()
            gui.Parent = gethui()
        end)
    end
    if not ok or not gui.Parent then
        ok = pcall(function()
            gui.Parent = CoreGui
        end)
        if not ok or not gui.Parent then
            gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end
end

-- Create glow effect
local function glow(parent, w, h, x, y, transparency, rotation)
    local image = make("ImageLabel", {
        Size = UDim2.new(0, w, 0, h),
        Position = UDim2.new(0, x, 0, y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = IMAGES.glow,
        ImageColor3 = PALETTE.glowBase,
        ImageTransparency = transparency,
        ScaleType = Enum.ScaleType.Stretch,
    }, parent)
    make("UIGradient", {
        Rotation = rotation,
        Color = ColorSequence.new(PALETTE.glowFrom, PALETTE.glowTo),
    }, image)
    return image
end

-- Create shadow effect
local function shadow(parent, sizeX, sizeY, offsetX, offsetY, color, transparency)
    local shadowFrame = make("ImageLabel", {
        Size = UDim2.new(1, sizeX or 0, 1, sizeY or 0),
        Position = UDim2.new(0, offsetX or 0, 0, offsetY or 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = IMAGES.shadow,
        ImageColor3 = color or PALETTE.shadow,
        ImageTransparency = transparency or 0.6,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 0,
    }, parent)
    return shadowFrame
end

-- ========== GAME DETECTION ==========
local SUPPORTED_GAMES = {
    { label = "Pressure", gameIds = { 4367208330 }, placeIds = { 12411473842 } },
    { label = "Forsaken", gameIds = { 6331902150, 7464167604 }, placeIds = { 18687417158, 83645629621104 } },
}

local function describeGame()
    local info = {
        title = tostring(game.Name or "Roblox"),
        gameId = game.GameId,
        placeId = game.PlaceId,
        supported = nil,
    }
    for _, entry in ipairs(SUPPORTED_GAMES) do
        for _, id in ipairs(entry.gameIds) do
            if game.GameId == id then
                info.supported = entry.label
            end
        end
        for _, id in ipairs(entry.placeIds) do
            if game.PlaceId == id then
                info.supported = entry.label
            end
        end
    end
    if not info.supported then
        pcall(function()
            if workspace:FindFirstChild("GameplayFolder") then
                info.supported = "Pressure"
            end
            local map = workspace:FindFirstChild("Map")
            if map and map:FindFirstChild("Ingame") then
                info.supported = "Forsaken"
            end
        end)
    end
    if info.supported then
        info.title = info.supported
    end
    info.icon = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"
    return info
end

-- ========== MAIN SCREEN CREATION ==========
local function createScreen()
    -- Create ScreenGui with high DisplayOrder to stay on top
    local gui = make("ScreenGui", {
        Name = "Dominant",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 2000,  -- High priority to stay on top of everything
    })
    placeGui(gui)

    -- Main container frame
    local main = make("Frame", {
        Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, gui)

    -- Responsive scaling
    local fit = make("UIScale", { Scale = 1 }, main)
    local function refit()
        local camera = workspace.CurrentCamera
        if camera then
            local view = camera.ViewportSize
            fit.Scale = math.clamp(math.min((view.X - 24) / FINAL_W, (view.Y - 24) / FINAL_H), 0.55, 1)
        end
    end
    refit()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
    end

    -- Shadow layers (multiple for depth effect) - FIXED: Now properly positioned within window bounds
    local shadow1 = shadow(main, 60, 60, -30, -30, PALETTE.shadow, 0.8)
    local shadow2 = shadow(main, 40, 40, -20, -20, PALETTE.shadow, 0.5)
    local shadow3 = shadow(main, 20, 20, -10, -10, PALETTE.shadow, 0.3)

    -- Canvas (main background)
    local canvas = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = PALETTE.bg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, main)
    corner(canvas, CORNER_RADIUS)

    -- Border stroke
    local border = make("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = PALETTE.accent,
        Transparency = 1,
    }, canvas)

    -- Decoration layer (for glow effects)
    local decor = make("CanvasGroup", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, canvas)
    corner(decor, CORNER_RADIUS)
    
    local decorFrame = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
        BackgroundTransparency = 1,
    }, decor)
    
    -- Multiple glow effects for depth and visual interest
    glow(decorFrame, 380, 140, 230, 266, 0.86, 270)
    glow(decorFrame, 100, 46, -8, 252, 0.75, 90)
    glow(decorFrame, 400, 184, 450, 8, 0.92, 90)
    glow(decorFrame, 70, 138, 5, -5, 0.78, 90)
    glow(decorFrame, 200, 100, -100, 130, 0.82, 45)
    glow(decorFrame, 150, 80, 480, -60, 0.75, 135)

    -- Lockup: DOMINANT letters + logo
    local lockup = make("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(0.5, math.floor(LOGO_W / 2), 0.5, math.floor(LOGO_H / 2)),
        Size = UDim2.new(0, 0, 0, LOGO_H),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, canvas)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, lockup)

    local letters = {}
    for index = 1, #WORD do
        letters[index] = make("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            FontFace = fontOf(Enum.FontWeight.Bold),
            TextSize = 16,
            TextColor3 = PALETTE.text,
            TextTransparency = 1,
            Text = string.sub(WORD, index, index),
            LayoutOrder = index,
        }, lockup)
    end
    make("Frame", {
        Size = UDim2.fromOffset(6, 1),
        BackgroundTransparency = 1,
        LayoutOrder = #WORD + 1,
    }, lockup)
    local logo = make("ImageLabel", {
        Size = UDim2.fromOffset(LOGO_W, LOGO_H),
        BackgroundTransparency = 1,
        Image = IMAGES.logo,
        ImageColor3 = Color3.new(1, 1, 1),
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        LayoutOrder = #WORD + 2,
    }, lockup)

    local gameInfo = describeGame()
    local labels = DETECTED[LANG] or DETECTED.en

    -- CanvasGroup + UICorner clips its contents to rounded corners
    local bannerHolder = make("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, BANNER_H),
        BackgroundColor3 = PALETTE.panel,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
    }, canvas)
    corner(bannerHolder, CORNER_RADIUS)
    local bannerScale = make("UIScale", { Scale = 1.08 }, bannerHolder)
    local banner = make("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = 0.25,
        ScaleType = Enum.ScaleType.Crop,
    }, bannerHolder)
    local shade = make("Frame", {
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundColor3 = PALETTE.bg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, bannerHolder)
    make("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.05),
        }),
    }, shade)

    local sideShade = make("Frame", {
        Size = UDim2.new(1, 0, 0, BANNER_H),
        BackgroundColor3 = PALETTE.bg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, bannerHolder)
    make("UIGradient", {
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.6, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, sideShade)

    local iconHolder = make("CanvasGroup", {
        Size = UDim2.fromOffset(76, 76),
        Position = UDim2.fromOffset(18, 110),
        BackgroundColor3 = PALETTE.button,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
    }, canvas)
    corner(iconHolder, 18)
    local iconStroke = make("UIStroke", { Color = PALETTE.accent, Thickness = 1.5, Transparency = 1 }, iconHolder)
    local iconScale = make("UIScale", { Scale = 0.6 }, iconHolder)
    local icon = make("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = gameInfo.icon,
        ScaleType = Enum.ScaleType.Crop,
    }, iconHolder)

    local function infoLine(y, text, size, color, bold)
        return make("TextLabel", {
            Size = UDim2.new(1, -124, 0, size + 8),
            Position = UDim2.fromOffset(106, y),
            BackgroundTransparency = 1,
            FontFace = fontOf(bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular),
            TextSize = size,
            TextColor3 = color,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = text,
        }, canvas)
    end
    local nameLabel = infoLine(124, tostring(gameInfo.title), 18, PALETTE.text, true)
    local idLabel = infoLine(152, labels.id .. " " .. tostring(gameInfo.gameId) .. "   \u00b7   " .. labels.place .. " " .. tostring(gameInfo.placeId), 12, PALETTE.muted, false)
    local stateText = gameInfo.supported and (labels.ok .. " \u00b7 " .. gameInfo.supported) or labels.no
    local stateLabel = infoLine(172, stateText, 12, gameInfo.supported and PALETTE.accent or PALETTE.error, false)

    -- The status pill at the bottom-left: the spinner and the status text sit inside it
    local statusPill = make("Frame", {
        Position = UDim2.new(0, 14, 1, -46),
        Size = UDim2.fromOffset(240, 32),
        BackgroundColor3 = PALETTE.panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, canvas)
    corner(statusPill, 14)
    make("UIStroke", { Color = PALETTE.accent, Transparency = 0.85, Thickness = 1 }, statusPill)

    local spinnerGroup = make("CanvasGroup", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, statusPill)
    local track = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, spinnerGroup)
    corner(track, 1000)
    make("UIStroke", { Thickness = 1.5, Color = PALETTE.muted, Transparency = 0.85, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, track)

    local ring = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, spinnerGroup)
    corner(ring, 1000)
    local ringStroke = make("UIStroke", { Thickness = 2, Color = PALETTE.accent, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ring)
    make("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.28, 0.2),
            NumberSequenceKeypoint.new(0.62, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, ringStroke)
    local spin = TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })

    local status = make("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 42, 0.5, 0),
        Size = UDim2.new(0, 186, 0, 16),
        BackgroundTransparency = 1,
        FontFace = fontOf(Enum.FontWeight.Regular),
        TextSize = 12,
        TextColor3 = PALETTE.muted,
        Text = T.modules,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, statusPill)

    -- Enhanced loading bar with gradient and rounded corners
    local shown = 0
    local barTrack = make("Frame", {
        Position = UDim2.new(0, 14, 1, -3),
        Size = UDim2.new(1, -28, 0, 3),
        BackgroundColor3 = PALETTE.panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, canvas)
    corner(barTrack, TINY_RADIUS)
    
    local barFill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, barTrack)
    corner(barFill, TINY_RADIUS)
    make("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(PALETTE.accent, PALETTE.accent_secondary),
    }, barFill)
    make("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(1, 0),
        }),
    }, barFill)

    -- Enhanced retry button with proper micro-interactions
    local retry = make("TextButton", {
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 18, 1, -46),
        Size = UDim2.new(0, 150, 0, 30),
        BackgroundColor3 = PALETTE.button,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        FontFace = fontOf(Enum.FontWeight.Bold),
        TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1),
        Text = T.retry,
        Visible = false,
        ZIndex = 102,
    }, canvas)
    corner(retry, SMALL_RADIUS)
    local retryScale = make("UIScale", { Scale = 1 }, retry)
    
    -- Micro-interactions: hover, press, release states
    retry.MouseEnter:Connect(function()
        tween(retry, 0.15, { BackgroundColor3 = PALETTE.buttonHover })
        tween(retryScale, 0.15, { Scale = 1.02 }, Enum.EasingStyle.Back)
    end)
    
    retry.MouseLeave:Connect(function()
        tween(retry, 0.2, { BackgroundColor3 = PALETTE.button })
        tween(retryScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
    end)
    
    retry.MouseButton1Down:Connect(function()
        tween(retry, 0.08, { BackgroundColor3 = PALETTE.buttonActive })
        tween(retryScale, 0.08, { Scale = 0.95 })
    end)
    
    retry.MouseButton1Up:Connect(function()
        tween(retry, 0.22, { BackgroundColor3 = PALETTE.buttonHover })
        tween(retryScale, 0.22, { Scale = 1.02 }, Enum.EasingStyle.Back)
    end)

    local function reveal()
        tween(bannerHolder, ANIM.reveal_duration, { GroupTransparency = 0 })
        tween(bannerScale, 1.6, { Scale = 1 }, Enum.EasingStyle.Quint)
        tween(shade, 0.9, { BackgroundTransparency = 0 })
        tween(sideShade, 0.9, { BackgroundTransparency = 0 })
        task.delay(0.2, function()
            tween(iconHolder, 0.5, { GroupTransparency = 0 })
            tween(iconScale, 0.7, { Scale = 1 }, Enum.EasingStyle.Back)
            tween(iconStroke, 0.6, { Transparency = 0.4 })
        end)
        task.delay(0.3, function()
            tween(nameLabel, 0.5, { TextTransparency = 0 })
        end)
        task.delay(0.45, function()
            tween(idLabel, 0.5, { TextTransparency = 0 })
        end)
        task.delay(0.6, function()
            tween(stateLabel, 0.5, { TextTransparency = 0 })
        end)
    end

    local function hideCard()
        tween(bannerHolder, ANIM.fade_standard, { GroupTransparency = 1 })
        tween(shade, ANIM.fade_standard, { BackgroundTransparency = 1 })
        tween(sideShade, ANIM.fade_standard, { BackgroundTransparency = 1 })
        tween(iconHolder, ANIM.fade_standard, { GroupTransparency = 1 })
        tween(nameLabel, ANIM.fade_standard, { TextTransparency = 1 })
        tween(idLabel, ANIM.fade_standard, { TextTransparency = 1 })
        tween(stateLabel, ANIM.fade_standard, { TextTransparency = 1 })
    end

    local function setLockup(transparency, time)
        tween(logo, time, { ImageTransparency = transparency })
        for _, letter in ipairs(letters) do
            tween(letter, time, { TextTransparency = transparency })
        end
    end

    local screen = { gui = gui, introDone = false, failed = false, onRetry = nil }
    local lastStep, lastChange = nil, os.clock()

    function screen.set(step, progress)
        if screen.failed then
            return
        end
        lastStep = step
        lastChange = os.clock()
        local text = T[step] or step
        if status.Text ~= text then
            status.Text = text
            -- a short fade in when the step changes, once the status text is visible
            if status.TextTransparency < 0.5 then
                status.TextTransparency = 0.7
                tween(status, ANIM.fade_standard, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
            end
        end
        status.TextColor3 = PALETTE.muted
        local target = type(progress) == "number" and progress or STEP_PROGRESS[step]
        if target and target > shown then
            shown = math.min(target, 0.95)
            tween(barFill, 0.6, { Size = UDim2.new(shown, 0, 1, 0) }, Enum.EasingStyle.Quint)
        end
    end

    function screen.stalled()
        local watched = lastStep == "modules" or lastStep == "game" or lastStep == "window"
        return watched and not screen.failed and os.clock() - lastChange > STALL_TIMEOUT
    end

    local function waitIntro()
        while not screen.introDone do
            task.wait()
        end
    end

    -- ========== INTRO ANIMATION ==========
    function screen.intro()
        task.spawn(function()
            main.Size = UDim2.new(0, INTRO_SIZE - 20, 0, INTRO_SIZE - 20)
            
            -- Initial grow with elastic easing
            local grow = tween(main, ANIM.intro_grow, { Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE) }, Enum.EasingStyle.Elastic)
            
            -- Fade in elements with proper timing
            tween(canvas, ANIM.fade_standard + 0.1, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
            tween(decor, ANIM.fade_standard + 0.1, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
            tween(logo, ANIM.fade_standard + 0.1, { ImageTransparency = 0 }, Enum.EasingStyle.Quint)
            tween(border, ANIM.fade_standard + 0.1, { Transparency = 0.55 }, Enum.EasingStyle.Quint)
            tween(shadow1, ANIM.fade_standard + 0.1, { ImageTransparency = 0.6 }, Enum.EasingStyle.Quint)
            tween(shadow2, ANIM.fade_standard + 0.1, { ImageTransparency = 0.4 }, Enum.EasingStyle.Quint)
            tween(shadow3, ANIM.fade_standard + 0.1, { ImageTransparency = 0.2 }, Enum.EasingStyle.Quint)
            
            grow.Completed:Wait()
            task.wait(SQUARE_TIME - ANIM.intro_grow)

            -- Border fade out
            tween(border, 0.7, { Transparency = 1 }, Enum.EasingStyle.Quint)
            
            -- Expand to final size with elastic easing
            local expand = tween(main, ANIM.intro_expand, { Size = UDim2.new(0, FINAL_W, 0, FINAL_H) }, Enum.EasingStyle.Elastic)
            
            -- Move lockup to corner
            tween(lockup, ANIM.intro_expand, { Position = UDim2.new(1, -24, 1, -24) }, Enum.EasingStyle.Elastic)
            
            -- Staggered letter animation
            for index, letter in ipairs(letters) do
                task.delay(0.2 + (index - 1) * ANIM.letter_stagger, function()
                    tween(letter, ANIM.letter_duration, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
                end)
            end
            
            expand.Completed:Wait()
            reveal()

            -- Show loading elements
            local show = tween(spinnerGroup, ANIM.fade_standard + 0.1, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
            tween(barTrack, ANIM.fade_standard + 0.1, { BackgroundTransparency = 0.6 }, Enum.EasingStyle.Quint)
            tween(barFill, ANIM.fade_standard + 0.1, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
            tween(status, ANIM.fade_standard + 0.1, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
            tween(statusPill, ANIM.fade_standard + 0.1, { BackgroundTransparency = 0.25 }, Enum.EasingStyle.Quint)
            
            show.Completed:Wait()
            spin:Play()
            screen.introDone = true
        end)
    end

    -- ========== READY STATE ==========
    function screen.ready()
        waitIntro()
        shown = 1
        tween(barFill, 0.5, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quint)
        task.wait(1.2)
    end

    -- ========== HIDE FUNCTION ==========
    function screen.hide()
        task.spawn(function()
            waitIntro()
            hideCard()
            setLockup(1, ANIM.fade_standard)
            tween(spinnerGroup, ANIM.fade_standard, { GroupTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(status, ANIM.fade_standard, { TextTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(statusPill, ANIM.fade_standard, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(barTrack, ANIM.fade_standard, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(barFill, ANIM.fade_standard, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
            task.wait(ANIM.fade_standard + 0.06)
            gui.Enabled = false
        end)
    end

    -- ========== SHOW FUNCTION ==========
    function screen.show()
        gui.Enabled = true
        tween(canvas, ANIM.fade_standard, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(decor, ANIM.fade_standard, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
        setLockup(0, ANIM.fade_standard)
        tween(spinnerGroup, ANIM.fade_standard, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(status, ANIM.fade_standard, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(statusPill, ANIM.fade_standard, { BackgroundTransparency = 0.25 }, Enum.EasingStyle.Quint)
        tween(barTrack, ANIM.fade_standard, { BackgroundTransparency = 0.6 }, Enum.EasingStyle.Quint)
        tween(barFill, ANIM.fade_standard, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        spin:Play()
    end

    -- ========== SET LOGO ==========
    function screen.setLogo(asset)
        if asset and asset ~= "" then
            logo.Image = asset
            screen.logoAsset = asset
        end
    end

    -- ========== SET BANNER ==========
    function screen.setBanner(asset, imageW, imageH)
        if not asset or asset == "" then
            return
        end
        banner.Image = asset
        screen.bannerAsset = asset
        if type(imageW) == "number" and type(imageH) == "number" and imageW > 0 and imageH > 0 then
            local scale = math.max(FINAL_W / imageW, BANNER_H / imageH)
            local regionW = FINAL_W / scale
            local regionH = BANNER_H / scale
            banner.ScaleType = Enum.ScaleType.Stretch
            banner.ImageRectSize = Vector2.new(math.floor(regionW), math.floor(regionH))
            banner.ImageRectOffset = Vector2.new(math.floor((imageW - regionW) / 2), math.floor((imageH - regionH) * 0.25))
        end
    end

    -- ========== FAIL STATE ==========
    function screen.fail(reason)
        task.spawn(function()
            waitIntro()
            screen.failed = true
            spin:Cancel()
            tween(spinnerGroup, ANIM.fade_standard, { GroupTransparency = 1 }, Enum.EasingStyle.Quint)
            local detail = reason and string.sub(tostring(reason), 1, 90) or T.check
            status.Text = T.failed .. ": " .. detail
            status.TextColor3 = PALETTE.error
            status.TextTransparency = 0
            barFill.BackgroundColor3 = PALETTE.error
            retry.Visible = true
        end)
    end

    -- ========== RESTART ==========
    function screen.restart()
        if not screen.failed then
            return
        end
        screen.failed = false
        retry.Visible = false
        shown = 0
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = PALETTE.accent
        status.Text = T.modules
        status.TextColor3 = PALETTE.muted
        tween(spinnerGroup, ANIM.fade_standard, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
        spin:Play()
    end

    -- ========== VIND CREATION OVERLAY (High ZIndex to stay on top) ==========
    local vindOverlay = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = PALETTE.overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 200,  -- Higher than loader to ensure it's on top
        Visible = false,
    }, gui)

    local vindCard = make("Frame", {
        Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = PALETTE.panel,
        BorderSizePixel = 0,
        ZIndex = 201,
    }, vindOverlay)
    corner(vindCard, CORNER_RADIUS)
    stroke(vindCard, 1, PALETTE.accent, 0.75)

    local vindTitle = make("TextLabel", {
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = T.creating or "Creating interface",
        TextSize = 16,
        TextColor3 = PALETTE.text,
        FontFace = fontOf(Enum.FontWeight.Bold),
        ZIndex = 202,
    }, vindCard)

    local vindSub = make("TextLabel", {
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = T.please or "Please wait...",
        TextSize = 13,
        TextColor3 = PALETTE.text_secondary,
        FontFace = fontOf(Enum.FontWeight.Regular),
        ZIndex = 202,
    }, vindCard)

    local vindBarBg = make("Frame", {
        Size = UDim2.new(0.72, 0, 0, 5),
        Position = UDim2.new(0.14, 0, 0, 100),
        BackgroundColor3 = PALETTE.panel_hover,
        BorderSizePixel = 0,
        ZIndex = 202,
    }, vindCard)
    corner(vindBarBg, TINY_RADIUS)

    local vindBar = make("Frame", {
        Size = UDim2.new(ANIM.pulse_min, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BorderSizePixel = 0,
        ZIndex = 203,
    }, vindBarBg)
    corner(vindBar, TINY_RADIUS)
    make("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(PALETTE.accent, PALETTE.accent_secondary),
    }, vindBar)

    local vindAnimating = false
    local function startVindBar()
        if vindAnimating then return end
        vindAnimating = true
        task.spawn(function()
            local going = true
            while vindOverlay.Visible and vindAnimating do
                if going then
                    elasticTween(vindBar, ANIM.pulse_speed, { Size = UDim2.new(ANIM.pulse_max, 0, 1, 0) })
                    task.wait(0.7)
                else
                    elasticTween(vindBar, ANIM.pulse_speed, { Size = UDim2.new(ANIM.pulse_min, 0, 1, 0) })
                    task.wait(0.7)
                end
                going = not going
            end
            vindAnimating = false
        end)
    end

    function screen.showVindCreation()
        vindOverlay.Visible = true
        vindOverlay.BackgroundTransparency = 1
        vindCard.Size = UDim2.new(0, FINAL_W - 40, 0, FINAL_H - 40)
        vindCard.BackgroundTransparency = 0.15
        vindTitle.TextTransparency = 1
        vindSub.TextTransparency = 1
        vindBarBg.BackgroundTransparency = 1
        vindBar.BackgroundTransparency = 1
        
        -- Smooth elastic entrance
        elasticTween(vindOverlay, 0.4, { BackgroundTransparency = 0.5 })
        elasticTween(vindCard, 0.5, { 
            Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
            BackgroundTransparency = 0,
        })
        tween(vindTitle, 0.4, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(vindSub, 0.4, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(vindBarBg, 0.4, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(vindBar, 0.4, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        startVindBar()
    end

    function screen.hideVindCreation()
        vindAnimating = false
        tween(vindTitle, ANIM.fade_fast, { TextTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindSub, ANIM.fade_fast, { TextTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindBarBg, ANIM.fade_fast, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindBar, ANIM.fade_fast, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindCard, ANIM.fade_standard, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, FINAL_W - 40, 0, FINAL_H - 40),
        }, Enum.EasingStyle.Quint)
        tween(vindOverlay, ANIM.fade_standard, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        task.delay(ANIM.fade_standard + 0.02, function()
            vindOverlay.Visible = false
        end)
    end

    -- ========== TRANSITION TO VIND (Seamless transition with matching size) ==========
    function screen.finish()
        task.spawn(function()
            waitIntro()
            spin:Cancel()
            
            -- Fade out loading elements first
            tween(spinnerGroup, ANIM.fade_fast, { GroupTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(status, ANIM.fade_fast, { TextTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(statusPill, ANIM.fade_fast, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(barTrack, ANIM.fade_fast, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(barFill, ANIM.fade_fast, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
            
            -- Resize main to match Vind window dimensions smoothly
            elasticTween(main, ANIM.transition_vind, { 
                Size = UDim2.new(0, FINAL_W, 0, FINAL_H) 
            })
            
            -- Show Vind creation overlay with matching size
            screen.showVindCreation()
            
            -- Fade out loader elements
            tween(canvas, ANIM.transition_vind, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(decor, ANIM.transition_vind, { GroupTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(shadow1, ANIM.transition_vind, { ImageTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(shadow2, ANIM.transition_vind, { ImageTransparency = 1 }, Enum.EasingStyle.Quint)
            tween(shadow3, ANIM.transition_vind, { ImageTransparency = 1 }, Enum.EasingStyle.Quint)
            
            -- Wait for Vind to load, then destroy
            task.wait(1.5)
            gui:Destroy()
        end)
    end

    -- ========== SHOW GAME (kept for compatibility) ==========
    function screen.showGame(_info)
    end

    -- ========== DESTRUCTOR ==========
    screen.destroy = screen.finish
    
    -- Connect retry button
    retry.MouseButton1Click:Connect(function()
        screen.restart()
        if screen.onRetry then
            task.spawn(screen.onRetry)
        end
    end)
    
    return screen
end

-- ========== ASSET LOADING ==========

local function assetGetter()
    if type(writefile) ~= "function" or type(isfolder) ~= "function" or type(makefolder) ~= "function" then
        return nil
    end
    return getcustomasset or getsynasset
end

local function isPng(body)
    return type(body) == "string" and #body > 100 and string.sub(body, 1, 4) == "\137PNG"
end

local function pngSize(body)
    local function u32(offset)
        local a, b, c, d = string.byte(body, offset, offset + 3)
        return ((a * 256 + b) * 256 + c) * 256 + d
    end
    return u32(17), u32(21)
end

local function downloadAsset(url, fileName)
    local getter = assetGetter()
    if type(getter) ~= "function" then
        return nil
    end
    if not isfolder("Dominant") then
        makefolder("Dominant")
    end
    if not isfolder(ASSET_FOLDER) then
        makefolder(ASSET_FOLDER)
    end
    local body = game:HttpGet(url)
    if not isPng(body) then
        return nil
    end
    local path = ASSET_FOLDER .. "/" .. fileName
    writefile(path, body)
    return getter(path), body
end

local function resolveLogo()
    local ok, asset = pcall(downloadAsset, BASE .. "assets/logo.png", "logo.png")
    if ok and type(asset) == "string" then
        return asset
    end
    warn("[Dominant] logo could not be loaded from the repository")
    return nil
end

local function resolveBanner(universeId)
    if type(universeId) ~= "number" or universeId <= 0 then
        return nil
    end
    for _ = 1, 4 do
        local ok, asset, body = pcall(function()
            local jsonBody = game:HttpGet(string.format(THUMBNAIL_API, tostring(universeId)))
            local decoded = HttpService:JSONDecode(jsonBody)
            local entry = decoded.data and decoded.data[1]
            local thumb = entry and entry.thumbnails and entry.thumbnails[1]
            local url = thumb and thumb.imageUrl
            if type(url) ~= "string" or url == "" then
                return nil
            end
            local bannerAsset, bannerBytes = downloadAsset(url, "banner_" .. tostring(universeId) .. ".png")
            return bannerAsset, bannerBytes
        end)
        if ok and type(asset) == "string" and type(body) == "string" then
            return asset, pngSize(body)
        end
        task.wait(1.5)
    end
    warn("[Dominant] banner could not be loaded for this game")
    return nil
end

-- ========== LANGUAGE SAVING ==========
local LANG = savedLanguage()
local T = TEXT[LANG]

-- ========== INITIALIZATION ==========

-- Clean up previous instance
local env = getgenv and getgenv() or _G
local previous = env.DominantInstance
if previous and type(previous.unload) == "function" then
    pcall(previous.unload)
    task.wait(0.3)
end

-- Create and initialize screen
local screen = createScreen()
screen.intro()

-- Load assets in background
task.spawn(function()
    screen.setLogo(resolveLogo())
end)
task.spawn(function()
    screen.setBanner(resolveBanner(game.GameId))
end)

-- ========== BOOTSTRAP ==========
local function bootstrap()
    local attempt = {}
    screen.attempt = attempt
    
    -- Stall watchdog
    task.spawn(function()
        for _ = 1, 600 do
            task.wait(1)
            if screen.attempt ~= attempt or screen.failed then
                return
            end
            if screen.stalled() then
                warn("[Dominant] loading step stalled")
                screen.fail(T.stall)
                return
            end
        end
    end)

    screen.set("modules")
    local ok, err = pcall(function()
        local Modules = loadstring(game:HttpGet(BASE .. "core/modules.lua"))()
        local modules = Modules.new(BASE)
        local config = modules:require("core/config")
        local app = modules:require("core/app")
        screen.ready()
        app.run(modules, config, screen)
    end)
    if not ok then
        warn("[Dominant] " .. tostring(err))
        screen.fail(err)
    end
end

screen.onRetry = bootstrap
task.spawn(bootstrap)
