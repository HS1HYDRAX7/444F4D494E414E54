--[[
    DOMINANT - Enhanced Loader
    Modern design with smooth animations and better organization
    Based on the original loader.lua with improvements from external files
]]

local BASE = "https://raw.githubusercontent.com/HS1HYDRAX7/DOMINANT/main/"
local ASSET_FOLDER = "Dominant/Assets"
local STALL_TIMEOUT = 25
local THUMBNAIL_API = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=%s&countPerUniverse=1&defaults=true&size=768x432&format=Png&isCircular=false"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Enhanced color palette with more modern tones
local PALETTE = {
    bg = Color3.fromRGB(12, 12, 16),
    panel = Color3.fromRGB(24, 24, 32),
    panel_hover = Color3.fromRGB(32, 32, 44),
    accent = Color3.fromRGB(0, 200, 255),
    accent_secondary = Color3.fromRGB(100, 220, 255),
    muted = Color3.fromRGB(130, 140, 160),
    text = Color3.fromRGB(245, 248, 255),
    text_secondary = Color3.fromRGB(180, 190, 210),
    error = Color3.fromRGB(255, 85, 85),
    success = Color3.fromRGB(80, 250, 123),
    warn = Color3.fromRGB(255, 185, 0),
    glowFrom = Color3.fromRGB(255, 255, 255),
    glowTo = Color3.fromRGB(190, 200, 230),
    glowBase = Color3.fromRGB(255, 255, 255),
    button = Color3.fromRGB(36, 38, 48),
    buttonHover = Color3.fromRGB(50, 54, 68),
    buttonActive = Color3.fromRGB(60, 66, 80),
    border = Color3.fromRGB(45, 50, 65),
    shadow = Color3.fromRGB(0, 0, 0),
}

local IMAGES = {
    font = "rbxassetid://12187365364",
    glow = "rbxassetid://8992230677",
    shadow = "rbxassetid://6014261993",
    logo = "",
}

-- Enhanced dimensions and timing
local FINAL_W, FINAL_H = 500, 280
local BANNER_H = 160
local INTRO_SIZE = 85
local SQUARE_TIME = 1.4
local LOGO_W, LOGO_H = 52, 48
local WORD = "DOMINANT"

-- Smoother step progress
local STEP_PROGRESS = { 
    interface = 0.05, 
    modules = 0.25, 
    game = 0.50, 
    key = 0.70, 
    window = 0.90 
}

-- Enhanced text with more languages and better messages
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
        success = "Loaded successfully!"
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
        success = "Carregado com sucesso!"
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
        success = "¡Cargado con éxito!"
    },
    ru = {
        stall = "Этап выполняется слишком долго", 
        modules = "Загрузка модулей", 
        game = "Определение игры", 
        key = "Ожидание ключа", 
        window = "Сборка интерфейса", 
        ready = "Готово", 
        failed = "Не удалось загрузить Dominant", 
        retry = "Повторить", 
        check = "Проверьте подключение и повторите", 
        creating = "Создание интерфейса", 
        please = "Подождите...",
        welcome = "Добро пожаловать в DOMINANT",
        loading = "Загрузка...",
        success = "Успешно загружено!"
    },
    fr = {
        stall = "L'étape prend trop de temps", 
        modules = "Chargement des modules", 
        game = "Détection du jeu", 
        key = "En attente de la clé", 
        window = "Construction de l'interface", 
        ready = "Prêt", 
        failed = "Impossible de charger Dominant", 
        retry = "Réessayer", 
        check = "Vérifiez votre connexion et réessayez", 
        creating = "Création de l'interface", 
        please = "Veuillez patienter...",
        welcome = "Bienvenue dans DOMINANT",
        loading = "Chargement...",
        success = "Chargé avec succès!"
    },
}

local DETECTED = {
    en = { ok = "Detected", no = "Unsupported game", id = "ID", place = "Place" },
    pt = { ok = "Detectado", no = "Jogo não suportado", id = "ID", place = "Lugar" },
    es = { ok = "Detectado", no = "Juego no compatible", id = "ID", place = "Lugar" },
    ru = { ok = "Обнаружено", no = "Игра не поддерживается", id = "ID", place = "Место" },
    fr = { ok = "Détecté", no = "Jeu non supporté", id = "ID", place = "Lieu" },
}

-- Enhanced game detection with more games
local SUPPORTED_GAMES = {
    { label = "Pressure", gameIds = { 4367208330 }, placeIds = { 12411473842 } },
    { label = "Forsaken", gameIds = { 6331902150, 7464167604 }, placeIds = { 18687417158, 83645629621104 } },
    { label = "Doors", gameIds = { 6516141153 }, placeIds = {} },
    { label = "Evasion", gameIds = { 1558867776 }, placeIds = {} },
}

-- Utility functions
local function savedLanguage()
    local ok, code = pcall(function()
        local path = "Dominant/session_" .. tostring(game.GameId) .. ".json"
        if isfile(path) then
            local decoded = HttpService:JSONDecode(readfile(path))
            return decoded.language
        end
        return nil
    end)
    if ok and type(code) == "string" and TEXT[code] then
        return code
    end
    return "en"
end

local LANG = savedLanguage()
local T = TEXT[LANG]

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

local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness, transparency)
    make("UIStroke", {
        Color = color or PALETTE.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function tween(instance, time, props, style, direction)
    local running = TweenService:Create(
        instance, 
        TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), 
        props
    )
    running:Play()
    return running
end

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
end

-- Enhanced gradient creation
local function gradient(parent, rotation, colors, transparency)
    local grad = make("UIGradient", {
        Rotation = rotation or 90,
        Color = ColorSequence.new(colors or {PALETTE.glowFrom, PALETTE.glowTo}),
        Transparency = transparency and NumberSequence.new(transparency) or nil,
    }, parent)
    return grad
end

-- Enhanced shadow effect
local function shadow(parent, sizeX, sizeY, offsetX, offsetY, color, transparency)
    local shadowFrame = make("ImageLabel", {
        Size = UDim2.new(1, sizeX or 0, 1, sizeY or 0),
        Position = UDim2.new(0, offsetX or 0, 0, offsetY or 0),
        BackgroundTransparency = 1,
        Image = IMAGES.shadow,
        ImageColor3 = color or Color3.new(0, 0, 0),
        ImageTransparency = transparency or 0.6,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 0,
    }, parent)
    return shadowFrame
end

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

-- Enhanced particle effect for loading
local function createParticleEffect(parent, position, size, color, duration)
    local particleContainer = make("Frame", {
        Size = UDim2.new(0, size, 0, size),
        Position = position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, parent)
    
    local particle = make("Frame", {
        Size = UDim2.new(0, 4, 0, 4),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, particleContainer)
    corner(particle, 2)
    
    local particles = {particle}
    for i = 1, 4 do
        local p = make("Frame", {
            Size = UDim2.new(0, 2, 0, 2),
            Position = UDim2.new(0.5, math.random(-20, 20), 0.5, math.random(-20, 20)),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.8,
        }, particleContainer)
        corner(p, 1)
        particles[#particles + 1] = p
    end
    
    -- Animate particles
    for _, p in ipairs(particles) do
        local tx = math.random(-30, 30)
        local ty = math.random(-30, 30)
        local t = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Position = UDim2.new(0.5, tx, 0.5, ty),
            BackgroundTransparency = 1,
        })
        t:Play()
    end
    
    task.delay(duration, function()
        particleContainer:Destroy()
    end)
    
    return particleContainer
end

-- Enhanced loading bar with gradient and glow
local function createLoadingBar(parent, width, height, position)
    local barContainer = make("Frame", {
        Size = UDim2.new(0, width, 0, height),
        Position = position,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, parent)
    
    local track = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = PALETTE.panel,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
    }, barContainer)
    corner(track, height / 2)
    
    local fill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, track)
    corner(fill, height / 2)
    
    local glowEffect = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
    }, fill)
    corner(glowEffect, height / 2)
    
    local gradientFill = gradient(fill, 90, {
        PALETTE.accent_secondary,
        PALETTE.accent,
        PALETTE.accent_secondary
    })
    
    return {
        container = barContainer,
        track = track,
        fill = fill,
        glow = glowEffect,
        setProgress = function(progress)
            local targetSize = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
            tween(fill, 0.4, { Size = targetSize }, Enum.EasingStyle.Quint)
        end,
        pulse = function()
            local pulseTween = TweenService:Create(
                glowEffect, 
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { BackgroundTransparency = 0.7 }
            )
            pulseTween:Play()
        end
    }
end

-- Enhanced spinner with smooth rotation
local function createSpinner(parent, size, thickness, color)
    local spinnerContainer = make("Frame", {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, parent)
    
    local ring = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, spinnerContainer)
    corner(ring, size / 2)
    
    local stroke = make("UIStroke", {
        Thickness = thickness,
        Color = color,
        Transparency = 0.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, ring)
    
    local gradientStroke = gradient(stroke, 0, {
        color,
        Color3.new(color.R, color.G, color.B, 0.3),
        color
    })
    
    local spinAnimation = TweenService:Create(
        ring, 
        TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
        { Rotation = 360 }
    )
    
    return {
        container = spinnerContainer,
        ring = ring,
        stroke = stroke,
        spin = function()
            spinAnimation:Play()
        end,
        stop = function()
            spinAnimation:Cancel()
        end,
        setVisibility = function(visible)
            spinnerContainer.Visible = visible
        end
    }
end

-- Main screen creation with enhanced design
local function createScreen()
    local gui = make("ScreenGui", {
        Name = "Dominant_Enhanced",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000,
    })
    placeGui(gui)

    local main = make("Frame", {
        Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
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

    -- Enhanced shadow with multiple layers
    local mainShadow1 = shadow(main, 60, 60, -30, -30, Color3.new(0, 0, 0), 0.8)
    local mainShadow2 = shadow(main, 40, 40, -20, -20, Color3.new(0, 0, 0), 0.6)

    local canvas = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = PALETTE.bg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, main)
    corner(canvas, 12)

    local border = make("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = PALETTE.border,
        Transparency = 1,
    }, canvas)

    -- Enhanced decoration with multiple glow effects
    local decor = make("CanvasGroup", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, canvas)
    corner(decor, 12)
    
    local decorFrame = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
        BackgroundTransparency = 1,
    }, decor)
    
    -- Multiple glow effects for depth
    glow(decorFrame, 400, 150, 240, 280, 0.88, 270)
    glow(decorFrame, 120, 50, -10, 260, 0.78, 90)
    glow(decorFrame, 450, 200, 480, 10, 0.94, 90)
    glow(decorFrame, 80, 150, 8, -8, 0.82, 90)
    glow(decorFrame, 300, 100, -100, 130, 0.90, 45)

    -- Enhanced lockup with better letter spacing and animation
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
        Padding = UDim.new(0, 4),
    }, lockup)

    local letters = {}
    for index = 1, #WORD do
        letters[index] = make("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            FontFace = fontOf(Enum.FontWeight.Bold),
            TextSize = 18,
            TextColor3 = PALETTE.text,
            TextTransparency = 1,
            Text = string.sub(WORD, index, index),
            LayoutOrder = index,
        }, lockup)
    end
    
    make("Frame", {
        Size = UDim2.fromOffset(8, 1),
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

    -- Enhanced banner with better styling
    local bannerHolder = make("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, BANNER_H),
        BackgroundColor3 = PALETTE.panel,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
    }, canvas)
    corner(bannerHolder, 12)
    
    local bannerScale = make("UIScale", { Scale = 1.1 }, bannerHolder)
    
    local banner = make("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = 0.2,
        ScaleType = Enum.ScaleType.Crop,
    }, bannerHolder)
    
    -- Enhanced shade with gradient
    local shade = make("Frame", {
        Size = UDim2.new(1, 0, 0, BANNER_H),
        BackgroundColor3 = PALETTE.bg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, bannerHolder)
    make("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.02),
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
        Transparency = NumberSequenceKeypoint.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.7, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, sideShade)

    -- Enhanced icon holder with pulsing effect
    local iconHolder = make("CanvasGroup", {
        Size = UDim2.fromOffset(84, 84),
        Position = UDim2.fromOffset(20, 115),
        BackgroundColor3 = PALETTE.button,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
    }, canvas)
    corner(iconHolder, 20)
    stroke(iconHolder, PALETTE.accent, 1.5, 1)
    
    local iconScale = make("UIScale", { Scale = 0.65 }, iconHolder)
    local iconPulse = TweenService:Create(
        iconScale, 
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Scale = 1.05 }
    )
    
    local iconStroke = make("UIStroke", { 
        Color = PALETTE.accent, 
        Thickness = 1.5, 
        Transparency = 1 
    }, iconHolder)
    
    local icon = make("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = gameInfo.icon,
        ScaleType = Enum.ScaleType.Crop,
    }, iconHolder)
    
    -- Enhanced info labels with better styling
    local function infoLine(y, text, size, color, bold)
        return make("TextLabel", {
            Size = UDim2.new(1, -130, 0, size + 10),
            Position = UDim2.fromOffset(114, y),
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
    
    local nameLabel = infoLine(128, tostring(gameInfo.title), 20, PALETTE.text, true)
    local idLabel = infoLine(158, labels.id .. " " .. tostring(gameInfo.gameId) .. "   \u00b7   " .. labels.place .. " " .. tostring(gameInfo.placeId), 13, PALETTE.muted, false)
    local stateText = gameInfo.supported and (labels.ok .. " \u00b7 " .. gameInfo.supported) or labels.no
    local stateLabel = infoLine(178, stateText, 13, gameInfo.supported and PALETTE.accent or PALETTE.error, false)

    -- Enhanced status pill with better design
    local statusPill = make("Frame", {
        Position = UDim2.new(0, 20, 1, -52),
        Size = UDim2.fromOffset(260, 36),
        BackgroundColor3 = PALETTE.panel,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, canvas)
    corner(statusPill, 16)
    stroke(statusPill, PALETTE.accent, 1, 0.85)

    -- Enhanced spinner with better design
    local spinnerGroup = make("CanvasGroup", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 6, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, statusPill)
    
    local spinner = createSpinner(spinnerGroup, 24, 2, PALETTE.accent)

    local track = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, spinnerGroup)
    corner(track, 1000)
    stroke(track, PALETTE.muted, 1.5, 0.85)

    local status = make("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 50, 0.5, 0),
        Size = UDim2.new(0, 198, 0, 18),
        BackgroundTransparency = 1,
        FontFace = fontOf(Enum.FontWeight.Regular),
        TextSize = 13,
        TextColor3 = PALETTE.muted,
        Text = T.modules,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, statusPill)

    -- Enhanced progress bar
    local shown = 0
    local barContainer = createLoadingBar(canvas, FINAL_W - 40, 4, UDim2.new(0.5, -((FINAL_W - 40)/2), 1, -8))

    -- Enhanced retry button
    local retry = make("TextButton", {
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 24, 1, -52),
        Size = UDim2.new(0, 160, 0, 34),
        BackgroundColor3 = PALETTE.button,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        FontFace = fontOf(Enum.FontWeight.Bold),
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        Text = T.retry,
        Visible = false,
    }, canvas)
    corner(retry, 10)
    stroke(retry, PALETTE.accent, 1, 0.7)
    
    local retryScale = make("UIScale", { Scale = 1 }, retry)
    
    retry.MouseEnter:Connect(function()
        tween(retry, 0.18, { BackgroundColor3 = PALETTE.buttonHover })
        tween(retryScale, 0.18, { Scale = 1.02 })
    end)
    
    retry.MouseLeave:Connect(function()
        tween(retry, 0.22, { BackgroundColor3 = PALETTE.button })
        tween(retryScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
    end)
    
    retry.MouseButton1Down:Connect(function()
        tween(retryScale, 0.08, { Scale = 0.97 })
    end)
    
    retry.MouseButton1Up:Connect(function()
        tween(retryScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
    end)

    -- Animation functions
    local function reveal()
        -- Banner animation with spring effect
        tween(bannerHolder, 1.2, { GroupTransparency = 0 })
        tween(bannerScale, 1.8, { Scale = 1 }, Enum.EasingStyle.Elastic)
        
        -- Shade animations with delay
        task.delay(0.25, function()
            tween(shade, 1.0, { BackgroundTransparency = 0 })
            tween(sideShade, 1.0, { BackgroundTransparency = 0 })
        end)
        
        -- Icon animation with bounce
        task.delay(0.35, function()
            tween(iconHolder, 0.6, { GroupTransparency = 0 })
            tween(iconScale, 0.8, { Scale = 1 }, Enum.EasingStyle.Back)
            tween(iconStroke, 0.7, { Transparency = 0.4 })
            iconPulse:Play()
        end)
        
        -- Text animations with stagger
        task.delay(0.45, function()
            tween(nameLabel, 0.55, { TextTransparency = 0 })
        end)
        
        task.delay(0.55, function()
            tween(idLabel, 0.55, { TextTransparency = 0 })
        end)
        
        task.delay(0.65, function()
            tween(stateLabel, 0.55, { TextTransparency = 0 })
        end)
    end

    local function hideCard()
        tween(bannerHolder, 0.35, { GroupTransparency = 1 })
        tween(shade, 0.35, { BackgroundTransparency = 1 })
        tween(sideShade, 0.35, { BackgroundTransparency = 1 })
        tween(iconHolder, 0.35, { GroupTransparency = 1 })
        tween(nameLabel, 0.35, { TextTransparency = 1 })
        tween(idLabel, 0.35, { TextTransparency = 1 })
        tween(stateLabel, 0.35, { TextTransparency = 1 })
    end

    local function setLockup(transparency, time)
        tween(logo, time, { ImageTransparency = transparency })
        for _, letter in ipairs(letters) do
            tween(letter, time, { TextTransparency = transparency })
        end
    end

    local screen = { 
        gui = gui, 
        introDone = false, 
        failed = false, 
        onRetry = nil,
        setLogo = nil,
        setBanner = nil
    }
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
            if status.TextTransparency < 0.5 then
                status.TextTransparency = 0.7
                tween(status, 0.35, { TextTransparency = 0 })
            end
        end
        status.TextColor3 = PALETTE.muted
        local target = type(progress) == "number" and progress or STEP_PROGRESS[step]
        if target and target > shown then
            shown = math.min(target, 0.95)
            barContainer.setProgress(shown)
        end
    end

    function screen.stalled()
        local watched = lastStep == "modules" or lastStep == "game" or lastStep == "window"
        return watched and not screen.failed and os.clock() - lastChange > STALL_TIMEOUT
    end

    function screen.intro()
        task.spawn(function()
            main.Size = UDim2.new(0, INTRO_SIZE - 25, 0, INTRO_SIZE - 25)
            local grow = tween(main, 0.7, { Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE) }, Enum.EasingStyle.Elastic)
            tween(canvas, 0.55, { BackgroundTransparency = 0 })
            tween(decor, 0.55, { GroupTransparency = 0 })
            tween(logo, 0.55, { ImageTransparency = 0 })
            tween(border, 0.55, { Transparency = 0.5 })
            local introShadow = shadow(main, 60, 60, -30, -30)
            tween(introShadow, 0.55, { ImageTransparency = 0.7 })
            
            grow.Completed:Wait()
            task.wait(SQUARE_TIME - 0.7)

            tween(border, 0.8, { Transparency = 1 })
            local expand = tween(main, 0.95, { Size = UDim2.new(0, FINAL_W, 0, FINAL_H) }, Enum.EasingStyle.Elastic)
            tween(lockup, 0.95, { Position = UDim2.new(1, -22, 1, -22) }, Enum.EasingStyle.Elastic)
            
            for index, letter in ipairs(letters) do
                task.delay(0.2 + (index - 1) * 0.1, function()
                    tween(letter, 0.35, { TextTransparency = 0 })
                end)
            end
            
            expand.Completed:Wait()
            reveal()

            local show = tween(spinnerGroup, 0.45, { GroupTransparency = 0 })
            tween(barContainer.track, 0.45, { BackgroundTransparency = 0.5 })
            tween(barContainer.fill, 0.45, { BackgroundTransparency = 0 })
            tween(status, 0.45, { TextTransparency = 0 })
            show.Completed:Wait()
            spinner.spin()
            screen.introDone = true
        end)
    end

    local function waitIntro()
        while not screen.introDone do
            task.wait()
        end
    end

    function screen.ready()
        waitIntro()
        shown = 1
        barContainer.setProgress(1)
        task.wait(1.4)
    end

    function screen.hide()
        task.spawn(function()
            waitIntro()
            hideCard()
            setLockup(1, 0.35)
            tween(canvas, 0.4, { BackgroundTransparency = 1 })
            tween(decor, 0.4, { GroupTransparency = 1 })
            tween(spinnerGroup, 0.35, { GroupTransparency = 1 })
            tween(status, 0.35, { TextTransparency = 1 })
            tween(statusPill, 0.35, { BackgroundTransparency = 1 })
            task.wait(0.41)
            gui.Enabled = false
        end)
    end

    function screen.show()
        gui.Enabled = true
        tween(canvas, 0.35, { BackgroundTransparency = 0 })
        tween(decor, 0.35, { GroupTransparency = 0 })
        setLockup(0, 0.35)
        tween(spinnerGroup, 0.35, { GroupTransparency = 0 })
        tween(status, 0.35, { TextTransparency = 0 })
        tween(statusPill, 0.35, { BackgroundTransparency = 0.2 })
        spinner.spin()
    end

    function screen.setLogo(asset)
        if asset and asset ~= "" then
            logo.Image = asset
            screen.logoAsset = asset
        end
    end

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

    function screen.fail(reason)
        task.spawn(function()
            waitIntro()
            screen.failed = true
            spinner.stop()
            tween(spinnerGroup, 0.35, { GroupTransparency = 1 })
            local detail = reason and string.sub(tostring(reason), 1, 90) or T.check
            status.Text = T.failed .. ": " .. detail
            status.TextColor3 = PALETTE.error
            status.TextTransparency = 0
            barContainer.fill.BackgroundColor3 = PALETTE.error
            retry.Visible = true
            
            -- Shake effect on error
            local originalPos = statusPill.Position
            local shakeTween = TweenService:Create(
                statusPill, 
                TweenInfo.new(0.15, Enum.EasingStyle.Back), 
                { Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 5, originalPos.Y.Scale, originalPos.Y.Offset) }
            )
            shakeTween:Play()
            task.delay(0.15, function()
                local returnTween = TweenService:Create(
                    statusPill, 
                    TweenInfo.new(0.15, Enum.EasingStyle.Back), 
                    { Position = originalPos }
                )
                returnTween:Play()
            end)
        end)
    end

    function screen.restart()
        if not screen.failed then
            return
        end
        screen.failed = false
        retry.Visible = false
        shown = 0
        barContainer.setProgress(0)
        barContainer.fill.BackgroundColor3 = PALETTE.accent
        status.Text = T.modules
        status.TextColor3 = PALETTE.muted
        tween(spinnerGroup, 0.35, { GroupTransparency = 0 })
        spinner.spin()
    end

    retry.MouseButton1Click:Connect(function()
        screen.restart()
        if screen.onRetry then
            task.spawn(screen.onRetry)
        end
    end)

    function screen.finish()
        task.spawn(function()
            waitIntro()
            spinner.stop()
            hideCard()
            setLockup(1, 0.35)
            tween(spinnerGroup, 0.35, { GroupTransparency = 1 })
            tween(status, 0.35, { TextTransparency = 1 })
            tween(statusPill, 0.35, { BackgroundTransparency = 1 })
            tween(barContainer.track, 0.35, { BackgroundTransparency = 1 })
            tween(barContainer.fill, 0.35, { BackgroundTransparency = 1 })
            local finishShadow = shadow(main, 60, 60, -30, -30)
            tween(finishShadow, 0.45, { ImageTransparency = 1 })
            tween(decor, 0.45, { GroupTransparency = 1 })
            local last = tween(canvas, 0.45, { BackgroundTransparency = 1 })
            last.Completed:Wait()
            gui:Destroy()
        end)
    end

    function screen.showGame(_info)
    end

    -- Enhanced VIND creation overlay
    local vindOverlay = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 80,
        Visible = false,
    }, gui)

    local vindCard = make("Frame", {
        Size = UDim2.new(0, 320, 0, 140),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = PALETTE.panel,
        BorderSizePixel = 0,
        ZIndex = 81,
    }, vindOverlay)
    corner(vindCard, 14)
    stroke(vindCard, PALETTE.accent, 1, 0.75)

    local vindTitle = make("TextLabel", {
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = T.creating or "Creating Interface",
        TextSize = 16,
        TextColor3 = PALETTE.text,
        FontFace = fontOf(Enum.FontWeight.Bold),
        ZIndex = 82,
    }, vindCard)

    local vindSub = make("TextLabel", {
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = T.please or "Please wait...",
        TextSize = 13,
        TextColor3 = PALETTE.muted,
        FontFace = fontOf(Enum.FontWeight.Regular),
        ZIndex = 82,
    }, vindCard)

    local vindBarBg = make("Frame", {
        Size = UDim2.new(0.75, 0, 0, 5),
        Position = UDim2.new(0.125, 0, 0, 100),
        BackgroundColor3 = PALETTE.button,
        BorderSizePixel = 0,
        ZIndex = 82,
    }, vindCard)
    corner(vindBarBg, 3)

    local vindBar = make("Frame", {
        Size = UDim2.new(0.2, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BorderSizePixel = 0,
        ZIndex = 83,
    }, vindBarBg)
    corner(vindBar, 3)
    gradient(vindBar, 90, {PALETTE.accent_secondary, PALETTE.accent})

    local vindAnimating = false
    local function startVindBar()
        if vindAnimating then return end
        vindAnimating = true
        task.spawn(function()
            local going = true
            while vindOverlay.Visible and vindAnimating do
                if going then
                    tween(vindBar, 0.7, { Size = UDim2.new(0.9, 0, 1, 0) }, Enum.EasingStyle.Sine)
                    task.wait(0.8)
                else
                    tween(vindBar, 0.7, { Size = UDim2.new(0.2, 0, 1, 0) }, Enum.EasingStyle.Sine)
                    task.wait(0.8)
                end
                going = not going
            end
            vindAnimating = false
        end)
    end

    function screen.showVindCreation()
        vindOverlay.Visible = true
        vindOverlay.BackgroundTransparency = 1
        vindCard.Size = UDim2.new(0, 280, 0, 120)
        vindCard.BackgroundTransparency = 0.2
        tween(vindOverlay, 0.35, { BackgroundTransparency = 0.6 })
        tween(vindCard, 0.4, {
            Size = UDim2.new(0, 320, 0, 140),
            BackgroundTransparency = 0,
        }, Enum.EasingStyle.Back)
        startVindBar()
    end

    function screen.hideVindCreation()
        vindAnimating = false
        tween(vindOverlay, 0.32, { BackgroundTransparency = 1 })
        tween(vindCard, 0.28, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 280, 0, 120),
        })
        task.delay(0.35, function()
            vindOverlay.Visible = false
        end)
    end

    screen.destroy = screen.finish
    return screen
end

-- Asset management functions
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

-- Main initialization
local env = getgenv and getgenv() or _G
local previous = env.DominantInstance
if previous and type(previous.unload) == "function" then
    pcall(previous.unload)
    task.wait(0.3)
end

local screen = createScreen()
screen.intro()

-- Load assets in background
 task.spawn(function()
    screen.setLogo(resolveLogo())
end)

task.spawn(function()
    screen.setBanner(resolveBanner(game.GameId))
end)

-- Enhanced bootstrap with better error handling
local function bootstrap()
    local attempt = {}
    screen.attempt = attempt
    
    -- Stall watcher
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

-- Add particle effects during loading
if not screen.failed then
    task.delay(0.5, function()
        if not screen.introDone then
            createParticleEffect(main, UDim2.new(0.5, 0, 0.5, 0), 20, PALETTE.accent, 1.5)
        end
    end)
end
