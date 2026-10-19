local BASE = "https://raw.githubusercontent.com/HS1HYDRAX7/DOMINANT/main/"
local ASSET_FOLDER = "Dominant/Assets"
local STALL_TIMEOUT = 45
local THUMBNAIL_API = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=%s&countPerUniverse=1&defaults=true&size=768x432&format=Png&isCircular=false"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local PALETTE = {
    bg = Color3.fromRGB(8, 8, 10),
    panel = Color3.fromRGB(20, 20, 24),
    panel_hover = Color3.fromRGB(28, 28, 36),
    accent = Color3.fromRGB(230, 45, 55),
    accent_secondary = Color3.fromRGB(255, 100, 140),
    muted = Color3.fromRGB(130, 140, 160),
    text = Color3.fromRGB(245, 248, 255),
    text_secondary = Color3.fromRGB(180, 190, 210),
    error = Color3.fromRGB(255, 85, 85),
    success = Color3.fromRGB(80, 250, 123),
    warn = Color3.fromRGB(255, 185, 0),
    glowFrom = Color3.fromRGB(255, 120, 120),
    glowTo = Color3.fromRGB(200, 20, 35),
    glowBase = Color3.fromRGB(255, 255, 255),
    button = Color3.fromRGB(42, 42, 50),
    buttonHover = Color3.fromRGB(58, 58, 68),
    buttonActive = Color3.fromRGB(70, 74, 88),
    border = Color3.fromRGB(45, 50, 65),
    shadow = Color3.fromRGB(0, 0, 0),
}

local IMAGES = {
    font = "rbxassetid://12187365364",
    glow = "rbxassetid://8992230677",
    shadow = "rbxassetid://6014261993",
    logo = "",
}

local FINAL_W, FINAL_H = 500, 280
local BANNER_H = 160
local INTRO_SIZE = 85
local SQUARE_TIME = 1.4
local LOGO_W, LOGO_H = 52, 48
local WORD = "DOMINANT"
-- How far the progress bar goes at each step, unless the app sends its own fraction
local STEP_PROGRESS = { interface = 0.05, modules = 0.20, game = 0.40, key = 0.65, window = 0.88, ready = 1 }

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
    pt = { stall = "Uma etapa demorou demais", modules = "Carregando módulos", game = "Detectando jogo", key = "Aguardando key", window = "Montando interface", ready = "Pronto", failed = "Não foi possível carregar o Dominant", retry = "Tentar de novo", check = "Verifique sua conexão e tente de novo", creating = "Criando interface", please = "Aguarde..." },
    es = { stall = "Un paso tardó demasiado", modules = "Cargando módulos", game = "Detectando juego", key = "Esperando key", window = "Construyendo interfaz", ready = "Listo", failed = "No se pudo cargar Dominant", retry = "Reintentar", check = "Revisa tu conexión e inténtalo de nuevo", creating = "Creando interfaz", please = "Espere..." },
    ru = { stall = "Этап выполняется слишком долго", modules = "Загрузка модулей", game = "Определение игры", key = "Ожидание ключа", window = "Сборка интерфейса", ready = "Готово", failed = "Не удалось загрузить Dominant", retry = "Повторить", check = "Проверьте соединение и повторите", creating = "Создание интерфейса Vind", please = "Подождите..." },
}

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


local DETECTED = {
    en = { ok = "Detected game", no = "Unsupported game", id = "ID", place = "Place" },
    pt = { ok = "Jogo detectado", no = "Jogo não suportado", id = "ID", place = "Lugar" },
    es = { ok = "Juego detectado", no = "Juego no compatible", id = "ID", place = "Lugar" },
    ru = { ok = "Игра определена", no = "Игра не поддерживается", id = "ID", place = "Место" },
}

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

local function tween(instance, time, props, style)
    local running = TweenService:Create(instance, TweenInfo.new(time, style or Enum.EasingStyle.Quad), props)
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

local function createScreen()
    local gui = make("ScreenGui", {
        Name = "Dominant",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 2000,
    })
    placeGui(gui)

    local main = make("Frame", {
        Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, gui)

    -- On small screens the whole card is scaled down so it is never cut off
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

    local shadow = make("ImageLabel", {
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.new(0, -30, 0, -30),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = IMAGES.shadow,
        ImageColor3 = PALETTE.shadow,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 0,
    }, main)
    
    -- Second shadow layer for better depth
    local shadow2 = make("ImageLabel", {
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = IMAGES.shadow,
        ImageColor3 = PALETTE.shadow,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 0,
    }, main)


    local canvas = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = PALETTE.bg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, main)
    corner(canvas, 10)

    local border = make("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = PALETTE.accent,
        Transparency = 1,
    }, canvas)

    local decor = make("CanvasGroup", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, canvas)
    corner(decor, 10)
    local decorFrame = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
        BackgroundTransparency = 1,
    }, decor)
    glow(decorFrame, 380, 140, 230, 266, 0.86, 270)
    glow(decorFrame, 100, 46, -8, 252, 0.75, 90)
    glow(decorFrame, 400, 184, 450, 8, 0.92, 90)
    glow(decorFrame, 70, 138, 5, -5, 0.78, 90)
    glow(decorFrame, 200, 100, -100, 130, 0.82, 45)
    glow(decorFrame, 150, 80, 480, -60, 0.75, 135)

    -- Lockup: the DOMINANT letters followed by the logo. It starts centred on the
    -- logo and travels to the bottom-right corner while the letters appear behind it.
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

    -- CanvasGroup + UICorner clips its contents to rounded corners; a plain
    -- ImageLabel with UICorner keeps square corners.
    local bannerHolder = make("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, BANNER_H),
        BackgroundColor3 = PALETTE.panel,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
    }, canvas)
    corner(bannerHolder, 10)
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
    local idLabel = infoLine(152, labels.id .. " " .. tostring(gameInfo.gameId) .. "   ·   " .. labels.place .. " " .. tostring(gameInfo.placeId), 12, PALETTE.muted, false)
    local stateText = gameInfo.supported and (labels.ok .. " · " .. gameInfo.supported) or labels.no
    local stateLabel = infoLine(172, stateText, 12, gameInfo.supported and PALETTE.accent or PALETTE.error, false)

    -- The status pill at the bottom-left: the spinner and the status text sit inside it
    local statusPill = make("Frame", {
        Position = UDim2.new(0, 14, 1, -46),
        Size = UDim2.fromOffset(240, 32),
        BackgroundColor3 = PALETTE.panel,
        BackgroundTransparency = 0.25,
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

    -- Thin progress bar along the bottom edge of the card
    local shown = 0
    local barTrack = make("Frame", {
        Position = UDim2.new(0, 14, 1, -3),
        Size = UDim2.new(1, -28, 0, 3),
        BackgroundColor3 = PALETTE.panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, canvas)
    corner(barTrack, 1.5)
    
    local barFill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, barTrack)
    corner(barFill, 1.5)
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
    }, canvas)
    corner(retry, 8)
    local retryScale = make("UIScale", { Scale = 1 }, retry)
    retry.MouseEnter:Connect(function()
        tween(retry, 0.15, { BackgroundColor3 = PALETTE.buttonHover })
    end)
    retry.MouseLeave:Connect(function()
        tween(retry, 0.2, { BackgroundColor3 = PALETTE.button })
        tween(retryScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
    end)
    retry.MouseButton1Down:Connect(function()
        tween(retryScale, 0.08, { Scale = 0.95 })
    end)
    retry.MouseButton1Up:Connect(function()
        tween(retryScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
    end)

    local function reveal()
        tween(bannerHolder, 1.1, { GroupTransparency = 0 })
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
        tween(bannerHolder, 0.3, { GroupTransparency = 1 })
        tween(shade, 0.3, { BackgroundTransparency = 1 })
        tween(sideShade, 0.3, { BackgroundTransparency = 1 })
        tween(iconHolder, 0.3, { GroupTransparency = 1 })
        tween(nameLabel, 0.3, { TextTransparency = 1 })
        tween(idLabel, 0.3, { TextTransparency = 1 })
        tween(stateLabel, 0.3, { TextTransparency = 1 })
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
                tween(status, 0.3, { TextTransparency = 0 })
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

    function screen.intro()
        task.spawn(function()
            main.Size = UDim2.new(0, INTRO_SIZE - 20, 0, INTRO_SIZE - 20)
            local grow = tween(main, 0.7, { Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE) }, Enum.EasingStyle.Elastic)
            tween(canvas, 0.5, { BackgroundTransparency = 0 })
            tween(decor, 0.5, { GroupTransparency = 0 })
            tween(logo, 0.5, { ImageTransparency = 0 })
            tween(border, 0.5, { Transparency = 0.55 })
            tween(shadow, 0.5, { ImageTransparency = 0.6 })
            tween(shadow2, 0.5, { ImageTransparency = 0.4 })
            grow.Completed:Wait()
            task.wait(SQUARE_TIME - 0.6)

            tween(border, 0.7, { Transparency = 1 })
            local expand = tween(main, 0.95, { Size = UDim2.new(0, FINAL_W, 0, FINAL_H) }, Enum.EasingStyle.Elastic)
            tween(lockup, 0.95, { Position = UDim2.new(1, -22, 1, -22) }, Enum.EasingStyle.Elastic)
            for index, letter in ipairs(letters) do
                task.delay(0.2 + (index - 1) * 0.1, function()
                    tween(letter, 0.35, { TextTransparency = 0 })
                end)
            end
            expand.Completed:Wait()
            reveal()

            local show = tween(spinnerGroup, 0.4, { GroupTransparency = 0 })
            tween(barTrack, 0.4, { BackgroundTransparency = 0.6 })
            tween(barFill, 0.4, { BackgroundTransparency = 0 })
            tween(status, 0.4, { TextTransparency = 0 })
            show.Completed:Wait()
            spin:Play()
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
        tween(barFill, 0.5, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quint)
        task.wait(1.2)
    end

    function screen.hide()
        task.spawn(function()
            waitIntro()
            hideCard()
            setLockup(1, 0.3)
            tween(canvas, 0.35, { BackgroundTransparency = 1 })
            tween(decor, 0.35, { GroupTransparency = 1 })
            tween(spinnerGroup, 0.3, { GroupTransparency = 1 })
            tween(status, 0.3, { TextTransparency = 1 })
            tween(statusPill, 0.3, { BackgroundTransparency = 1 })
            tween(barTrack, 0.3, { BackgroundTransparency = 1 })
            tween(barFill, 0.3, { BackgroundTransparency = 1 })
            task.wait(0.36)
            gui.Enabled = false
        end)
    end

    function screen.show()
        gui.Enabled = true
        tween(canvas, 0.3, { BackgroundTransparency = 0 })
        tween(decor, 0.3, { GroupTransparency = 0 })
        setLockup(0, 0.3)
        tween(spinnerGroup, 0.3, { GroupTransparency = 0 })
        tween(status, 0.3, { TextTransparency = 0 })
        tween(statusPill, 0.3, { BackgroundTransparency = 0.25 })
        tween(barTrack, 0.3, { BackgroundTransparency = 0.6 })
        tween(barFill, 0.3, { BackgroundTransparency = 0 })
        spin:Play()
    end

    function screen.setLogo(asset)
        if asset and asset ~= "" then
            logo.Image = asset
            screen.logoAsset = asset
        end
    end

    -- Crops the banner from the real image size so the aspect ratio is kept and the
    -- upper part of the artwork (the characters) stays in view instead of being cut.
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
            spin:Cancel()
            tween(spinnerGroup, 0.3, { GroupTransparency = 1 })
            local detail = reason and string.sub(tostring(reason), 1, 140) or T.check
            status.Text = T.failed .. ": " .. detail
            status.TextColor3 = PALETTE.error
            status.TextTransparency = 0
            barFill.BackgroundColor3 = PALETTE.error
            retry.Visible = true
        end)
    end

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
        tween(spinnerGroup, 0.3, { GroupTransparency = 0 })
        spin:Play()
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
            spin:Cancel()
            
            -- Smooth transition: resize main to match Vind window size
            -- Vind typically uses ~400-500 width, so we'll animate to that
            local targetSize = UDim2.new(0, FINAL_W, 0, FINAL_H)
            
            -- First, fade out the loading elements
            tween(spinnerGroup, 0.2, { GroupTransparency = 1 })
            tween(status, 0.2, { TextTransparency = 1 })
            tween(statusPill, 0.2, { BackgroundTransparency = 1 })
            tween(barTrack, 0.2, { BackgroundTransparency = 1 })
            tween(barFill, 0.2, { BackgroundTransparency = 1 })
            
            -- Then resize the main frame to Vind dimensions smoothly
            tween(main, 0.4, { Size = targetSize }, Enum.EasingStyle.Quint)
            
            -- Show Vind creation overlay with matching size
            screen.showVindCreation()
            
            -- Fade out the entire loader while Vind loads
            tween(canvas, 0.5, { BackgroundTransparency = 1 })
            tween(decor, 0.5, { GroupTransparency = 1 })
            tween(shadow, 0.5, { ImageTransparency = 1 })
            
            -- Wait for Vind to fully load, then destroy loader
            task.wait(1.5)
            gui:Destroy()
        end)
    end

    -- Kept so the game modules can call it; the card is built here, so nothing is needed.
    function screen.showGame(_info)
    end

    -- ========== VIND CREATION OVERLAY (fica por cima de tudo) ==========
    local vindOverlay = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 90,
        Visible = false,
    }, gui)

    local vindCard = make("Frame", {
        Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = PALETTE.panel,
        BorderSizePixel = 0,
        ZIndex = 91,
    }, vindOverlay)
    corner(vindCard, 12)
    make("UIStroke", {
        Color = PALETTE.accent,
        Thickness = 1,
        Transparency = 0.75,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, vindCard)

    local vindTitle = make("TextLabel", {
        Position = UDim2.new(0, 0, 0, 28),
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = T.creating or "Creating interface",
        TextSize = 15,
        TextColor3 = PALETTE.text,
        FontFace = fontOf(Enum.FontWeight.Bold),
        ZIndex = 92,
    }, vindCard)

    local vindSub = make("TextLabel", {
        Position = UDim2.new(0, 0, 0, 54),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = T.please or "Please wait...",
        TextSize = 12,
        TextColor3 = PALETTE.muted,
        FontFace = fontOf(Enum.FontWeight.Regular),
        ZIndex = 92,
    }, vindCard)

    local vindBarBg = make("Frame", {
        Size = UDim2.new(0.72, 0, 0, 4),
        Position = UDim2.new(0.14, 0, 0, 92),
        BackgroundColor3 = PALETTE.panel_hover,
        BorderSizePixel = 0,
        ZIndex = 92,
    }, vindCard)
    corner(vindBarBg, 2)

    local vindBar = make("Frame", {
        Size = UDim2.new(0.18, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BorderSizePixel = 0,
        ZIndex = 93,
    }, vindBarBg)
    corner(vindBar, 2)
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
                    tween(vindBar, 0.65, { Size = UDim2.new(0.82, 0, 1, 0) }, Enum.EasingStyle.Sine)
                    task.wait(0.7)
                else
                    tween(vindBar, 0.65, { Size = UDim2.new(0.18, 0, 1, 0) }, Enum.EasingStyle.Sine)
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
        
        -- Smooth fade in with elastic easing
        tween(vindOverlay, 0.4, { BackgroundTransparency = 0.5 }, Enum.EasingStyle.Quint)
        tween(vindCard, 0.5, {
            Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
            BackgroundTransparency = 0,
        }, Enum.EasingStyle.Elastic)
        tween(vindTitle, 0.4, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(vindSub, 0.4, { TextTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(vindBarBg, 0.4, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        tween(vindBar, 0.4, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        startVindBar()
    end

    function screen.hideVindCreation()
        vindAnimating = false
        tween(vindTitle, 0.2, { TextTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindSub, 0.2, { TextTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindBarBg, 0.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindBar, 0.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        tween(vindCard, 0.25, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, FINAL_W - 40, 0, FINAL_H - 40),
        }, Enum.EasingStyle.Quint)
        tween(vindOverlay, 0.28, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        task.delay(0.32, function()
            vindOverlay.Visible = false
        end)
    end

    screen.destroy = screen.finish
    return screen
end

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

local env = getgenv and getgenv() or _G
local previous = env.DominantInstance
if previous and type(previous.unload) == "function" then
    pcall(previous.unload)
    task.wait(0.3)
end

local screen = createScreen()
screen.intro()
task.spawn(function()
    screen.setLogo(resolveLogo())
end)
task.spawn(function()
    screen.setBanner(resolveBanner(game.GameId))
end)

local function bootstrap()
    local attempt = {}
    screen.attempt = attempt
    task.spawn(function()
        for _ = 1, 900 do
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

    local function safeHttp(url)
        local ok, body = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(body) == "string" and #body > 20 then
            return body
        end
        local req = (syn and syn.request) or (http and http.request) or request or httprequest
        if type(req) == "function" then
            local ok2, res = pcall(req, { Url = url, Method = "GET" })
            if ok2 and type(res) == "table" then
                local b = res.Body or res.body
                if type(b) == "string" and #b > 20 then
                    return b
                end
            end
        end
        return nil
    end

    screen.set("modules", 0.15)
    local ok, err = pcall(function()
        local modulesBody = safeHttp(BASE .. "core/modules.lua")
        if not modulesBody then
            error("failed to download core/modules.lua")
        end
        local ModulesChunk, compileErr = loadstring(modulesBody)
        if not ModulesChunk then
            error("modules compile: " .. tostring(compileErr))
        end
        local Modules = ModulesChunk()
        if type(Modules) ~= "table" or type(Modules.new) ~= "function" then
            error("invalid modules module")
        end
        local modules = Modules.new(BASE)
        screen.set("modules", 0.28)

        local config = modules:require("core/config")
        if type(config) ~= "table" then
            error("config failed to load")
        end
        screen.set("game", 0.42)

        local app = modules:require("core/app")
        if type(app) ~= "table" or type(app.run) ~= "function" then
            error("app module invalid")
        end
        screen.set("key", 0.62)
        if type(screen.ready) == "function" then
            screen.ready()
        end
        app.run(modules, config, screen)
    end)
    if not ok then
        warn("[Dominant] " .. tostring(err))
        screen.fail(err)
    end
end

screen.onRetry = bootstrap
task.spawn(bootstrap)
