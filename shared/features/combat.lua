--[[
  Universal Combat — ESP no estilo Pressure/Forsaken (Highlight + painel Billboard)
  + Aimbot com FOV circle.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local M = {}

local ESP = {
    Objects = {},
    Folder = nil,
}

local Tracers = {
    Lines = {},
    Gui = nil,
}

local aimbotConn = nil
local fovCircle = nil

local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function getFolder()
    if ESP.Folder and ESP.Folder.Parent then
        return ESP.Folder
    end
    local folder = Instance.new("Folder")
    folder.Name = "DominantESP"
    local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    local ok = pcall(function()
        folder.Parent = parent
    end)
    if not ok then
        folder.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    ESP.Folder = folder
    return folder
end

local function getTracerGui()
    if Tracers.Gui and Tracers.Gui.Parent then
        return Tracers.Gui
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "DominantTracers"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    local ok = pcall(function()
        gui.Parent = parent
    end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    Tracers.Gui = gui
    return gui
end

local function playerColor(player, cfg)
    if cfg.esp_teamcheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return cfg.color_team or Color3.fromRGB(80, 180, 255)
    end
    return cfg.color_player or Color3.fromRGB(255, 90, 90)
end

local function adorneePart(target)
    if target:IsA("BasePart") then
        return target
    end
    if target:IsA("Model") then
        return target.PrimaryPart
            or target:FindFirstChild("HumanoidRootPart")
            or target:FindFirstChild("UpperTorso")
            or target:FindFirstChild("Torso")
            or target:FindFirstChildWhichIsA("BasePart", true)
    end
    return target:FindFirstChildWhichIsA("BasePart", true)
end

local function destroy(target)
    local entry = ESP.Objects[target]
    if not entry then
        return
    end
    pcall(function()
        if entry.Highlight then entry.Highlight:Destroy() end
        if entry.Billboard then entry.Billboard:Destroy() end
    end)
    ESP.Objects[target] = nil
    local line = Tracers.Lines[target]
    if line then
        pcall(function() line:Destroy() end)
        Tracers.Lines[target] = nil
    end
end

local function clear()
    for target in pairs(ESP.Objects) do
        destroy(target)
    end
    if ESP.Folder then
        pcall(function()
            ESP.Folder:ClearAllChildren()
        end)
    end
    for target, line in pairs(Tracers.Lines) do
        pcall(function() line:Destroy() end)
        Tracers.Lines[target] = nil
    end
end

-- Same panel style as Pressure / Forsaken
local function create(target, label, color, cfg)
    cfg = cfg or {}
    local folder = getFolder()
    local fill = cfg.esp_outline_only and 1 or (1 - (tonumber(cfg.esp_fill) or 0.6))
    local textSize = tonumber(cfg.esp_text_size) or 13
    local maxDist = tonumber(cfg.esp_max_distance) or 2000

    local highlight = Instance.new("Highlight")
    highlight.Name = "DominantHighlight"
    highlight.Adornee = target
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = fill
    highlight.OutlineTransparency = 0
    highlight.Parent = folder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DominantLabel"
    billboard.Adornee = adorneePart(target)
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(200, 46)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.MaxDistance = maxDist
    billboard.Parent = folder

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    panel.BackgroundTransparency = 0.45
    panel.BorderSizePixel = 0
    panel.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = panel
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Transparency = 0.35
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(8, 4)
    title.Size = UDim2.new(1, -16, 0, 20)
    title.Font = Enum.Font.GothamBold
    title.TextSize = textSize
    title.TextColor3 = color
    title.TextStrokeTransparency = 0.4
    pcall(function()
        title.TextTruncate = Enum.TextTruncate.AtEnd
    end)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = label or target.Name
    title.Parent = panel

    local detail = Instance.new("TextLabel")
    detail.Name = "Detail"
    detail.BackgroundTransparency = 1
    detail.Position = UDim2.fromOffset(8, 22)
    detail.Size = UDim2.new(1, -16, 0, 14)
    detail.Font = Enum.Font.Gotham
    detail.TextSize = 11
    detail.TextColor3 = Color3.fromRGB(205, 205, 205)
    detail.TextStrokeTransparency = 0.6
    pcall(function()
        detail.TextTruncate = Enum.TextTruncate.AtEnd
    end)
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.Text = ""
    detail.Parent = panel

    local entry = {
        Target = target,
        Highlight = highlight,
        Billboard = billboard,
        Panel = panel,
        Stroke = stroke,
        Title = title,
        Detail = detail,
        Last = {},
    }
    ESP.Objects[target] = entry
    return entry
end

local function ensureTracer(target, color)
    local line = Tracers.Lines[target]
    if line and line.Parent then
        return line
    end
    local gui = getTracerGui()
    line = Instance.new("Frame")
    line.Name = "Tracer"
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = color
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 0.25
    line.Parent = gui
    Tracers.Lines[target] = line
    return line
end

local function updateTracer(target, from, to, color, thickness)
    local line = ensureTracer(target, color)
    local mid = (from + to) / 2
    local delta = to - from
    local length = delta.Magnitude
    local angle = math.atan2(delta.Y, delta.X)
    line.BackgroundColor3 = color
    line.Size = UDim2.fromOffset(length, thickness or 1.5)
    line.Position = UDim2.fromOffset(mid.X, mid.Y)
    line.Rotation = math.deg(angle)
    line.Visible = true
end

local function ensureFovCircle()
    if fovCircle then return fovCircle end
    local ok, c = pcall(Drawing.new, "Circle")
    if ok and c then
        c.Filled = false
        c.Thickness = 1.5
        c.NumSides = 64
        c.Visible = false
        c.Color = Color3.fromRGB(255, 255, 255)
        fovCircle = c
    end
    return fovCircle
end

local function destroyFovCircle()
    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end
end

local function getRoot(character)
    return character and (
        character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
    )
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    local char = player.Character
    local hum = getHumanoid(char)
    return char and hum and hum.Health > 0
end

local function worldToScreen(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function getClosestInFOV(cfg)
    local mouse = UserInputService:GetMouseLocation()
    local best, bestDist = nil, cfg.aimbot_fov or 120
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            if cfg.aimbot_teamcheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                -- skip teammates
            else
                local root = getRoot(player.Character)
                if root then
                    local screen, onScreen = worldToScreen(root.Position)
                    if onScreen then
                        local dist = (screen - mouse).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            best = player
                        end
                    end
                end
            end
        end
    end
    return best
end

function M.Register(ctx)
    -- ESP settings (same keys style as Pressure/Forsaken)
    ctx.addSetting("esp", false, function(value)
        if not value then
            clear()
            ctx.stopLoop("universal_esp")
        else
            ctx.startLoop("universal_esp", 0.05, function()
                M.espStep(ctx)
            end)
        end
    end)
    ctx.addSetting("esp_name", true)
    ctx.addSetting("esp_distance", true)
    ctx.addSetting("esp_health", true)
    ctx.addSetting("esp_tracers", false)
    ctx.addSetting("esp_teamcheck", false)
    ctx.addSetting("esp_outline_only", false)
    ctx.addSetting("esp_fill", 0.6)
    ctx.addSetting("esp_max_distance", 2000)
    ctx.addSetting("esp_text_size", 13)
    ctx.addSetting("esp_tracer_thickness", 1.5)
    ctx.addSetting("color_player", Color3.fromRGB(255, 90, 90))
    ctx.addSetting("color_team", Color3.fromRGB(80, 180, 255))

    -- Aimbot
    ctx.addSetting("aimbot", false, function(value)
        if value then
            if aimbotConn then aimbotConn:Disconnect() end
            aimbotConn = RunService.RenderStepped:Connect(function()
                M.aimbotStep(ctx)
            end)
            ctx.objects["bind_aimbot"] = aimbotConn
        else
            if aimbotConn then
                aimbotConn:Disconnect()
                aimbotConn = nil
            end
            ctx.unbind("aimbot")
            destroyFovCircle()
        end
    end)
    ctx.addSetting("aimbot_fov", 120)
    ctx.addSetting("aimbot_smooth", 0.35)
    ctx.addSetting("aimbot_teamcheck", true)
    ctx.addSetting("aimbot_part", "Head")
    ctx.addSetting("aimbot_wallcheck", false)
    ctx.addSetting("aimbot_show_fov", false)

    ctx.addHotkey("key_esp", "hotkey_esp", function()
        ctx.set("esp", not ctx.cfg.esp)
    end)
    ctx.addHotkey("key_aimbot", "hotkey_aimbot", function()
        ctx.set("aimbot", not ctx.cfg.aimbot)
    end)

    ctx.onUnload(function()
        clear()
        destroyFovCircle()
        if aimbotConn then
            aimbotConn:Disconnect()
            aimbotConn = nil
        end
        if ESP.Folder then
            pcall(function() ESP.Folder:Destroy() end)
            ESP.Folder = nil
        end
        if Tracers.Gui then
            pcall(function() Tracers.Gui:Destroy() end)
            Tracers.Gui = nil
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            destroy(player.Character)
        end
    end)
end

function M.espStep(ctx)
    local cfg = ctx.cfg
    if not cfg.esp then
        clear()
        return
    end

    local maxDist = tonumber(cfg.esp_max_distance) or 2000
    local textSize = tonumber(cfg.esp_text_size) or 13
    local fill = cfg.esp_outline_only and 1 or (1 - (tonumber(cfg.esp_fill) or 0.6))
    local myRoot = getRoot(LocalPlayer.Character)
    local myPos = myRoot and myRoot.Position
    local seen = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            -- skip
        elseif not isAlive(player) then
            if player.Character then destroy(player.Character) end
        elseif cfg.esp_teamcheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            if player.Character then destroy(player.Character) end
        else
            local char = player.Character
            local root = getRoot(char)
            local hum = getHumanoid(char)
            if not root or not hum then
                if char then destroy(char) end
            else
                local dist = myPos and (root.Position - myPos).Magnitude or 0
                if dist > maxDist then
                    destroy(char)
                else
                    seen[char] = true
                    local color = playerColor(player, cfg)
                    local entry = ESP.Objects[char]
                    if not entry then
                        entry = create(char, player.DisplayName or player.Name, color, cfg)
                    end

                    -- update highlight / panel (same as Pressure)
                    local last = entry.Last
                    if last.color ~= color then
                        last.color = color
                        entry.Highlight.FillColor = color
                        entry.Highlight.OutlineColor = color
                        entry.Title.TextColor3 = color
                        entry.Stroke.Color = color
                    end
                    if last.fill ~= fill then
                        last.fill = fill
                        entry.Highlight.FillTransparency = fill
                    end
                    if last.textSize ~= textSize then
                        last.textSize = textSize
                        entry.Title.TextSize = textSize
                    end
                    if last.maxDistance ~= maxDist then
                        last.maxDistance = maxDist
                        entry.Billboard.MaxDistance = maxDist
                    end
                    if not entry.Billboard.Adornee or not entry.Billboard.Adornee.Parent then
                        entry.Billboard.Adornee = adorneePart(char)
                    end

                    if cfg.esp_name ~= false then
                        entry.Title.Text = player.DisplayName or player.Name
                        entry.Title.Visible = true
                    else
                        entry.Title.Text = ""
                    end

                    local details = {}
                    if cfg.esp_health and hum.MaxHealth > 0 then
                        table.insert(details, string.format("HP %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)))
                    end
                    if cfg.esp_distance then
                        table.insert(details, string.format("%dm", math.floor(dist)))
                    end
                    entry.Detail.Text = table.concat(details, "  ·  ")
                    entry.Panel.Visible = (cfg.esp_name ~= false) or (cfg.esp_distance == true) or (cfg.esp_health == true)

                    -- tracers (ScreenGui line, same idea as Pressure)
                    if cfg.esp_tracers then
                        local screen, onScreen = worldToScreen(root.Position)
                        if onScreen then
                            local origin
                            local originMode = cfg.esp_tracer_origin or "Bottom"
                            local vp = Camera.ViewportSize
                            if originMode == "Center" then
                                origin = Vector2.new(vp.X / 2, vp.Y / 2)
                            elseif originMode == "Mouse" then
                                origin = UserInputService:GetMouseLocation()
                            else
                                origin = Vector2.new(vp.X / 2, vp.Y)
                            end
                            updateTracer(char, origin, screen, color, cfg.esp_tracer_thickness or 1.5)
                        else
                            local line = Tracers.Lines[char]
                            if line then line.Visible = false end
                        end
                    else
                        local line = Tracers.Lines[char]
                        if line then line.Visible = false end
                    end
                end
            end
        end
    end

    for target in pairs(ESP.Objects) do
        if not seen[target] then
            destroy(target)
        end
    end
end

function M.aimbotStep(ctx)
    local cfg = ctx.cfg
    if not cfg.aimbot then return end

    if cfg.aimbot_show_fov then
        local circle = ensureFovCircle()
        if circle then
            local mouse = UserInputService:GetMouseLocation()
            circle.Position = mouse
            circle.Radius = tonumber(cfg.aimbot_fov) or 120
            circle.Visible = true
            circle.Color = Color3.fromRGB(255, 255, 255)
            circle.Transparency = 0.3
        end
    elseif fovCircle then
        fovCircle.Visible = false
    end

    local holding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        or UserInputService:IsKeyDown(Enum.KeyCode.E)
    if not holding then return end

    local target = getClosestInFOV(cfg)
    if not target then return end

    local char = target.Character
    local partName = cfg.aimbot_part or "Head"
    local part = char and (char:FindFirstChild(partName) or getRoot(char))
    if not part then return end

    if cfg.aimbot_wallcheck then
        local origin = Camera.CFrame.Position
        local dir = part.Position - origin
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LocalPlayer.Character, char }
        local hit = Workspace:Raycast(origin, dir, params)
        if hit then return end
    end

    local smooth = math.clamp(tonumber(cfg.aimbot_smooth) or 0.35, 0.05, 1)
    local goal = CFrame.new(Camera.CFrame.Position, part.Position)
    Camera.CFrame = Camera.CFrame:Lerp(goal, smooth)
end

function M.BuildESP(tab, ctx)
    local ui = ctx.ui

    ui.section(tab, "sec_esp", "Lucide:eye")
    ui.toggle(tab, "esp", "Lucide:eye")
    ui.toggle(tab, "esp_name", "Lucide:type")
    ui.toggle(tab, "esp_distance", "Lucide:ruler")
    ui.toggle(tab, "esp_health", "Lucide:heart")
    ui.toggle(tab, "esp_tracers", "Lucide:move-diagonal")
    ui.toggle(tab, "esp_teamcheck", "Lucide:users")
    ui.toggle(tab, "esp_outline_only", "Lucide:square")
    ui.slider(tab, "esp_fill", 0, 1, 0.05, "Lucide:droplet")
    ui.slider(tab, "esp_max_distance", 100, 5000, 50, "Lucide:radar", " studs")
    ui.slider(tab, "esp_text_size", 10, 20, 1, "Lucide:type")
    ui.slider(tab, "esp_tracer_thickness", 0.5, 4, 0.1, "Lucide:minus")
end

function M.BuildAimbot(tab, ctx)
    local ui = ctx.ui

    ui.section(tab, "sec_aimbot", "Lucide:crosshair")
    ui.toggle(tab, "aimbot", "Lucide:crosshair")
    ui.slider(tab, "aimbot_fov", 20, 400, 5, "Lucide:circle", " px")
    ui.slider(tab, "aimbot_smooth", 0.05, 1, 0.05, "Lucide:gauge")
    ui.toggle(tab, "aimbot_teamcheck", "Lucide:users")
    ui.toggle(tab, "aimbot_wallcheck", "Lucide:brick-wall")
    ui.toggle(tab, "aimbot_show_fov", "Lucide:circle")
    ui.dropdown(tab, "aimbot_part", { "Head", "HumanoidRootPart" }, "Lucide:user", ctx.cfg.aimbot_part)
end

function M.Build(tab, ctx)
    M.BuildESP(tab, ctx)
    M.BuildAimbot(tab, ctx)
end

return M
