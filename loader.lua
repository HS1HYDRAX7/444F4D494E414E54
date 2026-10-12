local BASE = "https://raw.githubusercontent.com/HS1HYDRAX7/DOMINANT/main/"
local ASSET_FOLDER = "Dominant/Assets"
local STALL_TIMEOUT = 25
local THUMBNAIL_API = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=%s&countPerUniverse=1&defaults=true&size=768x432&format=Png&isCircular=false"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local PALETTE = {
    bg = Color3.fromRGB(10, 10, 10),
    panel = Color3.fromRGB(26, 26, 26),
    accent = Color3.fromRGB(255, 255, 255),
    muted = Color3.fromRGB(150, 150, 150),
    text = Color3.fromRGB(255, 255, 255),
    error = Color3.fromRGB(240, 120, 120),
    glowFrom = Color3.fromRGB(255, 255, 255),
    glowTo = Color3.fromRGB(210, 210, 210),
    glowBase = Color3.fromRGB(255, 255, 255),
    button = Color3.fromRGB(66, 66, 66),
    buttonHover = Color3.fromRGB(90, 90, 90),
}

local IMAGES = {
    font = "rbxassetid://12187365364",
    glow = "rbxassetid://8992230677",
    shadow = "rbxassetid://6014261993",
    logo = "",
}

local FINAL_W, FINAL_H = 460, 260
local BANNER_H = 150
local INTRO_SIZE = 80
local SQUARE_TIME = 1.2
local LOGO_W, LOGO_H = 46, 42
local WORD = "DOMINANT"
-- How far the progress bar goes at each step, unless the app sends its own fraction
local STEP_PROGRESS = { interface = 0.04, modules = 0.2, game = 0.45, key = 0.6, window = 0.8 }

local TEXT = {
    en = { stall = "Step took too long", modules = "Loading modules", game = "Detecting game", key = "Waiting for key", window = "Building interface", ready = "Ready", failed = "Could not load Dominant", retry = "Retry", check = "Check your connection and retry" },
    pt = { stall = "Uma etapa demorou demais", modules = "Carregando módulos", game = "Detectando jogo", key = "Aguardando key", window = "Montando interface", ready = "Pronto", failed = "Não foi possível carregar o Dominant", retry = "Tentar de novo", check = "Verifique sua conexão e tente de novo" },
    es = { stall = "Un paso tardó demasiado", modules = "Cargando módulos", game = "Detectando juego", key = "Esperando key", window = "Construyendo interfaz", ready = "Listo", failed = "No se pudo cargar Dominant", retry = "Reintentar", check = "Revisa tu conexión e inténtalo de nuevo" },
    ru = { stall = "Этап выполняется слишком долго", modules = "Загрузка модулей", game = "Определение игры", key = "Ожидание ключа", window = "Сборка интерфейса", ready = "Готово", failed = "Не удалось загрузить Dominant", retry = "Повторить", check = "Проверьте соединение и повторите" },
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
        Size = UDim2.new(1, 50, 1, 50),
        Position = UDim2.new(0, -25, 0, -25),
        BackgroundTransparency = 1,
        Image = IMAGES.shadow,
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 1,
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
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = PALETTE.panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, canvas)
    local barFill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = PALETTE.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, barTrack)
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
            local grow = tween(main, 0.6, { Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE) }, Enum.EasingStyle.Quint)
            tween(canvas, 0.5, { BackgroundTransparency = 0 })
            tween(decor, 0.5, { GroupTransparency = 0 })
            tween(logo, 0.5, { ImageTransparency = 0 })
            tween(border, 0.5, { Transparency = 0.55 })
            tween(shadow, 0.5, { ImageTransparency = 0.6 })
            grow.Completed:Wait()
            task.wait(SQUARE_TIME - 0.6)

            tween(border, 0.7, { Transparency = 1 })
            local expand = tween(main, 0.85, { Size = UDim2.new(0, FINAL_W, 0, FINAL_H) }, Enum.EasingStyle.Quint)
            tween(lockup, 0.85, { Position = UDim2.new(1, -18, 1, -18) }, Enum.EasingStyle.Quint)
            for index, letter in ipairs(letters) do
                task.delay(0.15 + (index - 1) * 0.09, function()
                    tween(letter, 0.3, { TextTransparency = 0 })
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
            local detail = reason and string.sub(tostring(reason), 1, 90) or T.check
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
            hideCard()
            setLockup(1, 0.3)
            tween(spinnerGroup, 0.3, { GroupTransparency = 1 })
            tween(status, 0.3, { TextTransparency = 1 })
            tween(statusPill, 0.3, { BackgroundTransparency = 1 })
            tween(barTrack, 0.3, { BackgroundTransparency = 1 })
            tween(barFill, 0.3, { BackgroundTransparency = 1 })
            tween(shadow, 0.4, { ImageTransparency = 1 })
            tween(decor, 0.4, { GroupTransparency = 1 })
            local last = tween(canvas, 0.4, { BackgroundTransparency = 1 })
            last.Completed:Wait()
            gui:Destroy()
        end)
    end

    -- Kept so the game modules can call it; the card is built here, so nothing is needed.
    function screen.showGame(_info)
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
