features["esp"] = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local M = {}

function M.Register(ctx, data)
    local scan = ctx.modules:require("games/pressure/scan")

    local ESP = {
        Objects = {},
        Folder = nil,
    }

    local Tracers = {
        Lines = {},
        Gui = nil,
    }

    local function clamp01(value)
        if value < 0 then
            return 0
        elseif value > 1 then
            return 1
        end
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

    local function kindColor(kind, fallback)
        local cfg = ctx.cfg
        local map = {
            monster = cfg.color_monster,
            player = cfg.color_player,
            item = cfg.color_item,
            currency = cfg.color_currency,
            keycard = cfg.color_keycard,
            door = cfg.color_door,
            locker = cfg.color_locker,
            fakedoor = cfg.color_fakedoor,
            generator = cfg.color_generator,
        }
        return map[kind] or fallback or Color3.new(1, 1, 1)
    end

    local function adorneePart(target)
        if target:IsA("BasePart") then
            return target
        end
        if target:IsA("Model") then
            return target.PrimaryPart
                or target:FindFirstChild("HumanoidRootPart")
                or target:FindFirstChild("RootPart")
                or target:FindFirstChild("RootPosition")
                or target:FindFirstChildWhichIsA("BasePart", true)
        end
        return target:FindFirstChildWhichIsA("BasePart", true)
    end

    local function positionOf(target)
        local part = adorneePart(target)
        return part and part.Position or nil
    end

    local function create(target, kind, label)
        local folder = getFolder()
        local cfg = ctx.cfg
        local color = kindColor(kind)

        local highlight = Instance.new("Highlight")
        highlight.Name = "DominantHighlight"
        highlight.Adornee = target
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = cfg.esp_outline_only and 1 or (1 - (cfg.esp_fill or 0.6))
        highlight.OutlineTransparency = 0
        highlight.Parent = folder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DominantLabel"
        billboard.Adornee = adorneePart(target)
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.fromOffset(200, 46)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.MaxDistance = cfg.esp_max_distance or 1000
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
        title.TextSize = cfg.esp_text_size or 13
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
            Kind = kind,
            BaseLabel = label or target.Name,
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

    local function destroy(target)
        local entry = ESP.Objects[target]
        if not entry then
            return
        end
        pcall(function()
            entry.Highlight:Destroy()
            entry.Billboard:Destroy()
        end)
        ESP.Objects[target] = nil
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
            pcall(function()
                line:Destroy()
            end)
            Tracers.Lines[target] = nil
        end
    end

    local function describe(entry, distance)
        local cfg = ctx.cfg
        local title = entry.BaseLabel or entry.Target.Name
        local details = {}
        if entry.Kind == "player" then
            local player = Players:GetPlayerFromCharacter(entry.Target)
            if player then
                title = player.DisplayName
            end
            local humanoid = entry.Target:FindFirstChildOfClass("Humanoid")
            if cfg.esp_health and humanoid and humanoid.MaxHealth > 0 then
                table.insert(details, string.format("HP %d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)))
            end
        elseif entry.Kind == "generator" and entry.Extra then
            title = ctx.L("esp_generator", tostring(entry.Extra))
        end
        if cfg.esp_distance then
            table.insert(details, string.format("%dm", math.floor(distance)))
        end
        return title, table.concat(details, "  ·  ")
    end

    local function update(entry, distance, maxDistance)
        local cfg = ctx.cfg
        local last = entry.Last
        local color = kindColor(entry.Kind)
        if last.color ~= color then
            last.color = color
            entry.Highlight.FillColor = color
            entry.Highlight.OutlineColor = color
            entry.Title.TextColor3 = color
            entry.Stroke.Color = color
        end
        local fill = cfg.esp_outline_only and 1 or (1 - (cfg.esp_fill or 0.6))
        if last.fill ~= fill then
            last.fill = fill
            entry.Highlight.FillTransparency = fill
        end
        local textSize = cfg.esp_text_size or 13
        if last.textSize ~= textSize then
            last.textSize = textSize
            entry.Title.TextSize = textSize
        end
        if last.maxDistance ~= maxDistance then
            last.maxDistance = maxDistance
            entry.Billboard.MaxDistance = maxDistance
        end
        -- Refresh adornee if the original part was destroyed
        if not entry.Billboard.Adornee or not entry.Billboard.Adornee.Parent then
            entry.Billboard.Adornee = adorneePart(entry.Target)
        end
        entry.Highlight.Enabled = true
        entry.Billboard.Enabled = cfg.esp_text ~= false
        if not cfg.esp_text then
            return
        end

        local fade = clamp01((distance - maxDistance * 0.6) / (maxDistance * 0.4))
        local fadeStep = math.floor(fade * 20 + 0.5) / 20
        if last.fade ~= fadeStep then
            last.fade = fadeStep
            entry.Panel.BackgroundTransparency = 0.45 + fadeStep * 0.45
            entry.Title.TextTransparency = fadeStep * 0.85
            entry.Detail.TextTransparency = fadeStep * 0.85
            entry.Stroke.Transparency = 0.35 + fadeStep * 0.6
        end

        local title, detail = describe(entry, distance)
        if last.title ~= title then
            last.title = title
            entry.Title.Text = title
        end
        if last.detail ~= detail then
            last.detail = detail
            entry.Detail.Text = detail
        end
    end

    local function stack(placed)
        local used = {}
        for i, item in ipairs(placed) do
            if not used[i] then
                used[i] = true
                local group = { item }
                for j = i + 1, #placed do
                    if not used[j] and (placed[j].position - item.position).Magnitude < 5 then
                        used[j] = true
                        table.insert(group, placed[j])
                    end
                end
                table.sort(group, function(a, b)
                    return tostring(a.entry.Kind) < tostring(b.entry.Kind)
                end)
                for index, member in ipairs(group) do
                    local offset = 3 + (index - 1) * 2.4
                    local last = member.entry.Last
                    if last.offset ~= offset then
                        last.offset = offset
                        member.entry.Billboard.StudsOffset = Vector3.new(0, offset, 0)
                    end
                end
            end
        end
    end

    local function monsterContainers()
        local list = { workspace }
        local gf = workspace:FindFirstChild("GameplayFolder")
        if gf then
            local monsters = gf:FindFirstChild("Monsters")
            if monsters then
                table.insert(list, monsters)
            end
            local entities = gf:FindFirstChild("Entities")
            if entities then
                table.insert(list, entities)
            end
        end
        local monstersTop = workspace:FindFirstChild("Monsters")
        if monstersTop then
            table.insert(list, monstersTop)
        end
        local entitiesTop = workspace:FindFirstChild("Entities")
        if entitiesTop then
            table.insert(list, entitiesTop)
        end
        return list
    end

    local function collect()
        local cfg = ctx.cfg
        local list = {}

        if cfg.esp_monsters then
            local seenMonster = {}
            for _, container in ipairs(monsterContainers()) do
                for _, child in ipairs(container:GetChildren()) do
                    if not seenMonster[child] and data.Monsters[child.Name] and (child:IsA("Model") or child:IsA("BasePart")) then
                        seenMonster[child] = true
                        table.insert(list, {
                            target = child,
                            kind = "monster",
                            label = child.Name,
                            color = kindColor("monster"),
                        })
                    end
                end
            end
        end

        if cfg.esp_players then
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                if player ~= LocalPlayer and character then
                    table.insert(list, {
                        target = character,
                        kind = "player",
                        label = player.DisplayName,
                        color = kindColor("player"),
                    })
                end
            end
        end

        for _, entry in ipairs(scan.items(data)) do
            local wanted = (entry.kind == "item" and cfg.esp_items)
                or (entry.kind == "currency" and cfg.esp_currency)
                or (entry.kind == "keycard" and cfg.esp_keycards)
            if wanted then
                table.insert(list, {
                    target = entry.object,
                    kind = entry.kind,
                    label = entry.label,
                    color = entry.color or kindColor(entry.kind),
                })
            end
        end

        for _, entry in ipairs(scan.roomObjects(data)) do
            local object = entry.object
            if object.Parent then
                if entry.kind == "door" and cfg.esp_doors then
                    table.insert(list, {
                        target = object,
                        kind = "door",
                        label = ctx.L("esp_exit_door"),
                        color = kindColor("door", data.Colors.ExitDoor),
                    })
                elseif entry.kind == "locker" and cfg.esp_lockers then
                    table.insert(list, {
                        target = object,
                        kind = "locker",
                        label = ctx.L("esp_locker"),
                        color = kindColor("locker", data.Colors.Locker),
                    })
                elseif entry.kind == "fakedoor" and cfg.esp_fake_doors then
                    table.insert(list, {
                        target = object,
                        kind = "fakedoor",
                        label = ctx.L("esp_fake_door"),
                        color = kindColor("fakedoor", data.Colors.FakeDoor),
                    })
                elseif entry.kind == "generator" and cfg.esp_generators then
                    local fixed = object:FindFirstChild("Fixed")
                    local value = fixed and fixed.Value
                    local pct = 0
                    if type(value) == "boolean" then
                        pct = value and 100 or 0
                    elseif type(value) == "number" then
                        pct = value
                    end
                    if pct < 100 or not cfg.esp_hide_done then
                        local target = object:FindFirstChild("ProxyPart") or object
                        table.insert(list, {
                            target = target,
                            kind = "generator",
                            label = ctx.L("esp_generator", tostring(math.floor(pct))),
                            color = kindColor("generator"),
                            extra = math.floor(pct),
                        })
                    end
                end
            end
        end

        return list
    end

    local function tracersBackend()
        if Tracers.Gui and Tracers.Gui.Parent then
            return Tracers.Gui
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = "DominantTracers"
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 50
        gui.ResetOnSpawn = false
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

    local function newTracerLine()
        local frame = Instance.new("Frame")
        frame.Name = "Tracer"
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BorderSizePixel = 0
        frame.BackgroundColor3 = Color3.new(1, 1, 1)
        frame.BackgroundTransparency = 0.15
        frame.Visible = false
        frame.Parent = tracersBackend()
        return frame
    end

    local function tracerOrigin(camera)
        local cfg = ctx.cfg
        local size = camera.ViewportSize
        local originMode = cfg.esp_tracer_origin or "Bottom"
        if originMode == "Center" then
            return Vector2.new(size.X * 0.5, size.Y * 0.5)
        elseif originMode == "Top" then
            return Vector2.new(size.X * 0.5, 8)
        elseif originMode == "Mouse" then
            local mouse = LocalPlayer:GetMouse()
            return Vector2.new(mouse.X, mouse.Y)
        end
        return Vector2.new(size.X * 0.5, size.Y - 8)
    end

    local function tracersStep(placed)
        local cfg = ctx.cfg
        if not cfg.esp_tracers then
            for target, line in pairs(Tracers.Lines) do
                line.Visible = false
            end
            return
        end
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local origin = tracerOrigin(camera)
        local thickness = math.clamp(tonumber(cfg.esp_tracer_thickness) or 1.5, 0.5, 6)
        local seen = {}
        for _, item in ipairs(placed) do
            local entry = item.entry
            local target = entry.Target
            local screen, onScreen = camera:WorldToViewportPoint(item.position)
            if onScreen and screen.Z > 0 then
                seen[target] = true
                local line = Tracers.Lines[target]
                if not line then
                    line = newTracerLine()
                    Tracers.Lines[target] = line
                end
                local to = Vector2.new(screen.X, screen.Y)
                local delta = to - origin
                local length = delta.Magnitude
                if length > 1 then
                    line.Size = UDim2.fromOffset(length, thickness)
                    line.Position = UDim2.fromOffset((origin.X + to.X) * 0.5, (origin.Y + to.Y) * 0.5)
                    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                    line.BackgroundColor3 = kindColor(entry.Kind)
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        end
        for target, line in pairs(Tracers.Lines) do
            if not seen[target] then
                line.Visible = false
            end
        end
    end

    local function step()
        local cfg = ctx.cfg
        local root = ctx.state.root
        if not cfg.esp or not root then
            return
        end
        local maxDistance = cfg.esp_max_distance or 1000
        local seen = {}
        local placed = {}
        for _, item in ipairs(collect()) do
            local target = item.target
            local pos = positionOf(target)
            if pos and target.Parent then
                local distance = (pos - root.Position).Magnitude
                if distance <= maxDistance then
                    seen[target] = true
                    local entry = ESP.Objects[target]
                    if not entry then
                        entry = create(target, item.kind, item.label)
                    else
                        entry.Kind = item.kind
                        entry.BaseLabel = item.label
                    end
                    if item.extra then
                        entry.Extra = item.extra
                    end
                    if entry then
                        update(entry, distance, maxDistance)
                        table.insert(placed, { entry = entry, position = pos })
                    end
                end
            end
        end
        stack(placed)
        tracersStep(placed)
        for target in pairs(ESP.Objects) do
            if not seen[target] or not target.Parent then
                destroy(target)
            end
        end
    end

    ctx.addSetting("esp", false, function(value)
        if value then
            ctx.startLoop("esp", 0.1, step)
        else
            ctx.stopLoop("esp")
            clear()
        end
    end)

    for _, key in ipairs({
        "esp_monsters", "esp_players", "esp_items", "esp_currency", "esp_keycards",
        "esp_text", "esp_distance", "esp_health",
    }) do
        ctx.addSetting(key, true)
    end
    for _, key in ipairs({
        "esp_doors", "esp_lockers", "esp_fake_doors", "esp_generators",
        "esp_hide_done", "esp_outline_only", "esp_tracers",
    }) do
        ctx.addSetting(key, false)
    end
    ctx.addSetting("esp_max_distance", 1000)
    ctx.addSetting("esp_fill", 0.6)
    ctx.addSetting("esp_text_size", 13)
    ctx.addSetting("esp_tracer_thickness", 1.5)
    ctx.addSetting("esp_tracer_origin", "Bottom")
    ctx.addSetting("color_monster", Color3.fromRGB(200, 0, 0))
    ctx.addSetting("color_player", Color3.fromRGB(60, 255, 120))
    ctx.addSetting("color_item", Color3.fromRGB(135, 206, 250))
    ctx.addSetting("color_currency", Color3.fromRGB(60, 179, 113))
    ctx.addSetting("color_keycard", Color3.fromRGB(0, 200, 255))
    ctx.addSetting("color_door", Color3.fromRGB(0, 200, 100))
    ctx.addSetting("color_locker", Color3.fromRGB(0, 255, 0))
    ctx.addSetting("color_fakedoor", Color3.fromRGB(180, 0, 0))
    ctx.addSetting("color_generator", Color3.fromRGB(255, 180, 0))

    ctx.onUnload(clear)
end

function M.Build(tab, ctx, data)
    local ui = ctx.ui
    local function safe(fn)
        local ok, err = pcall(fn)
        if not ok then
            ctx.warn("esp ui: " .. tostring(err))
        end
    end

    -- Ensure color defaults exist even if Register partially failed
    local colorDefaults = {
        color_monster = Color3.fromRGB(200, 0, 0),
        color_player = Color3.fromRGB(60, 255, 120),
        color_item = Color3.fromRGB(135, 206, 250),
        color_currency = Color3.fromRGB(60, 179, 113),
        color_keycard = Color3.fromRGB(0, 200, 255),
        color_door = Color3.fromRGB(0, 200, 100),
        color_locker = Color3.fromRGB(0, 255, 0),
        color_fakedoor = Color3.fromRGB(180, 0, 0),
        color_generator = Color3.fromRGB(255, 180, 0),
    }
    for key, value in pairs(colorDefaults) do
        if ctx.cfg[key] == nil then
            ctx.cfg[key] = value
            if ctx.defaults[key] == nil then
                ctx.defaults[key] = value
            end
        end
    end

    safe(function() ui.section(tab, "sec_esp", "Lucide:eye") end)
    for _, key in ipairs({
        "esp", "esp_monsters", "esp_players", "esp_items", "esp_currency", "esp_keycards",
        "esp_doors", "esp_lockers", "esp_fake_doors", "esp_generators", "esp_hide_done",
        "esp_text", "esp_distance", "esp_health", "esp_outline_only", "esp_tracers",
    }) do
        local icon = "Lucide:eye"
        if key:find("monster") then icon = "Lucide:skull"
        elseif key:find("player") then icon = "Lucide:users"
        elseif key:find("item") then icon = "Lucide:package"
        elseif key:find("currency") then icon = "Lucide:coins"
        elseif key:find("keycard") then icon = "Lucide:key"
        elseif key:find("door") and key:find("fake") then icon = "Lucide:door-closed"
        elseif key:find("door") then icon = "Lucide:door-open"
        elseif key:find("locker") then icon = "Lucide:lock"
        elseif key:find("generator") or key:find("hide") then icon = "Lucide:cog"
        elseif key:find("text") then icon = "Lucide:type"
        elseif key:find("distance") then icon = "Lucide:ruler"
        elseif key:find("health") then icon = "Lucide:heart"
        elseif key:find("outline") then icon = "Lucide:square"
        elseif key:find("tracer") then icon = "Lucide:move"
        end
        safe(function() ui.toggle(tab, key, icon) end)
    end
    safe(function() ui.slider(tab, "esp_max_distance", 100, 5000, 50, "Lucide:radar", " studs") end)
    safe(function() ui.slider(tab, "esp_fill", 0, 1, 0.05, "Lucide:droplet") end)
    safe(function() ui.slider(tab, "esp_text_size", 10, 22, 1, "Lucide:type") end)
    safe(function() ui.slider(tab, "esp_tracer_thickness", 0.5, 6, 0.25, "Lucide:minus") end)
    safe(function()
        ui.dropdown(tab, "esp_tracer_origin", { "Bottom", "Center", "Top", "Mouse" }, "Lucide:crosshair")
    end)
    safe(function() ui.section(tab, "sec_esp_colors", "Lucide:palette") end)
    for _, key in ipairs({
        "color_monster", "color_player", "color_item", "color_currency", "color_keycard",
        "color_door", "color_locker", "color_fakedoor", "color_generator",
    }) do
        safe(function() ui.color(tab, key, "Lucide:palette") end)
    end
end

return M
end)()

features["anti"] = (function()
local Players = game:GetService("Players")

local M = {}

local function nameSet(...)
    local set = {}
    for _, name in ipairs({ ... }) do
        set[name] = true
    end
    return set
end

local function byName(names)
    return function(object)
        if names[object.Name] then
            return object
        end
        return nil
    end
end

local function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local LIST = {
    { key = "eyefestation", group = "monsters", match = byName(nameSet("EyefestHurt", "EyefestationCameraEffect")) },
    { key = "pandemonium", group = "monsters", match = function(data) return byName(data.Pandemonium) end },
    { key = "pipsqueak", group = "monsters", match = function(object)
        if string.find(object.Name, "Pipsqueak", 1, true) or string.find(object.Name, "Pipsqeuak", 1, true) then
            return object
        end
        return nil
    end },
    { key = "a200", group = "monsters", match = function(object)
        if string.find(object.Name, "A200", 1, true) or string.find(object.Name, "A-200", 1, true) then
            return object
        end
        return nil
    end },
    { key = "walldweller", group = "monsters", match = byName(nameSet("WallDweller", "MeatWallDweller", "RottenWallDweller", "DwellerModel")) },
    { key = "bouncer", group = "monsters", match = byName(nameSet("Bouncer", "Bouncers")) },
    { key = "skeletonhead", group = "monsters", match = byName(nameSet("SkeletonHead")) },
    { key = "statue", group = "monsters", match = byName(nameSet("StatueRoot", "StatueHead")) },
    { key = "nogood", group = "monsters", match = byName(nameSet("NoGood")) },
    { key = "skinless", group = "monsters", match = byName(nameSet("SkinlessCorpse")) },
    { key = "witchinghour", group = "monsters", match = function(object)
        if object.Name:lower() == "witchinghour" then
            return object
        end
        return nil
    end },
    { key = "divine", group = "monsters", match = byName(nameSet("DiVine", "DiVineRoot", "Divineroot")) },
    { key = "searchlights", group = "monsters", match = byName(nameSet("Searchlights")) },
    { key = "monsterlocker", group = "monsters", match = byName(nameSet("MonsterLocker")) },
    { key = "squiddles", group = "monsters", match = function(object)
        if object.Name == "SquiddleBuildup" and object.Parent and object.Parent.Name == "Face" and object.Parent.Parent then
            return object.Parent.Parent
        end
        if object.Name == "Squiddle" or object.Name == "SquiddleBase" then
            return object
        end
        return nil
    end },
    { key = "coagulate", group = "monsters", match = function(object)
        local current = object
        while current and current ~= workspace and current ~= game do
            local lower = current.Name:lower()
            if string.find(lower, "coagulate", 1, true) or string.find(lower, "coagulant", 1, true) then
                return current
            end
            current = current.Parent
        end
        return nil
    end },
    { key = "edentrees", group = "monsters", match = function(object)
        if object:IsA("Model") and not isPlayerCharacter(object) and string.match(object.Name, "^%l%l%l%l$") and object:FindFirstChild("RootPart") then
            return object
        end
        local parent = object.Parent
        if parent and parent:IsA("Model") and not isPlayerCharacter(parent) and string.match(parent.Name, "^%l%l%l%l$") and parent:FindFirstChild("RootPart") then
            return parent
        end
        return nil
    end },
    { key = "cement", group = "spawns", match = function(object)
        if string.find(object.Name:lower(), "cement", 1, true) then
            return object
        end
        return nil
    end },
    { key = "turrets", group = "spawns", match = function(object)
        if object.Name == "Turret" or string.match(object.Name, "^TurretSpawn") then
            return object
        end
        return nil
    end },
    { key = "tripwires", group = "spawns", match = byName(nameSet("Tripwire", "TripwireSpawn")) },
    { key = "landmines", group = "spawns", match = byName(nameSet("Landmine", "LandmineSpawn", "DrawerLandmine")) },
    { key = "damageparts", group = "encounters", match = function(object)
        local lower = object.Name:lower()
        if lower == "damagepart" or lower == "electricity" or lower == "damageparts" then
            return object
        end
        return nil
    end },
    { key = "firewall", group = "encounters", match = byName(nameSet("Firewall")) },
}

function M.Register(ctx, data)
    local connections = {}

    local function disconnect(key)
        local list = connections[key]
        if list then
            for _, connection in ipairs(list) do
                connection:Disconnect()
            end
        end
        connections[key] = nil
    end

    local function run(object, matcher)
        if not object.Parent then
            return
        end
        local ok, target = pcall(matcher, object)
        if ok and target and target.Parent then
            pcall(function()
                target:Destroy()
            end)
        end
    end

    local function enable(key, matcher)
        disconnect(key)
        local list = {}
        connections[key] = list
        for _, object in ipairs(workspace:GetDescendants()) do
            run(object, matcher)
        end
        table.insert(list, workspace.DescendantAdded:Connect(function(object)
            task.defer(run, object, matcher)
        end))
    end

    for _, entry in ipairs(LIST) do
        local key = "anti_" .. entry.key
        local matcher = entry.match

        if type(matcher) == "function" and entry.key == "pandemonium" then
            matcher = matcher(data)
        end
        ctx.addSetting(key, false, function(value)
            if value then
                enable(key, matcher)
            else
                disconnect(key)
            end
        end)
    end

    ctx.onUnload(function()
        for key in pairs(connections) do
            disconnect(key)
        end
    end)
end

function M.Build(tab, ctx, data)
    local ui = ctx.ui
    local sections = {
        monsters = "sec_anti_monsters",
        spawns = "sec_anti_spawns",
        encounters = "sec_anti_encounters",
    }
    local shown = {}
    for _, entry in ipairs(LIST) do
        if not shown[entry.group] then
            shown[entry.group] = true
            ui.section(tab, sections[entry.group], "Lucide:shield")
        end
        ui.labelToggle(tab, "anti_" .. entry.key, ctx.L("anti_" .. entry.key), nil, "Lucide:shield")
    end
end

return M
end)()

features["automation"] = (function()
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local M = {}

function M.Register(ctx, data)
    local scan = ctx.modules:require("games/pressure/scan")
    local originalHold = {}
    local originalCollide = {}
    local lastAlert = {}

    local function adorneePart(target)
        if target:IsA("BasePart") then
            return target
        end
        if target:IsA("Model") then
            return target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    local function lootStep()
        local root = ctx.state.root
        if not root then
            return
        end
        local radius = math.clamp(tonumber(ctx.cfg.loot_radius) or 5, 1, 30)
        for _, entry in ipairs(scan.items(data)) do
            local object = entry.object
            if entry.kind ~= "item" and object.Parent then
                local part = adorneePart(object)
                if part and (part.Position - root.Position).Magnitude <= radius then
                    local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        pcall(function()
                            if ctx.caps.fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                local hold = prompt.HoldDuration
                                prompt.HoldDuration = 0
                                prompt:InputHoldBegin()
                                task.wait()
                                prompt:InputHoldEnd()
                                prompt.HoldDuration = hold
                            end
                        end)
                    end
                end
            end
        end
    end

    local function instantPrompt(prompt)
        if ctx.cfg.instant_prompts and originalHold[prompt] == nil and prompt.HoldDuration > 0 then
            originalHold[prompt] = prompt.HoldDuration
            prompt.HoldDuration = 0
        end
    end

    local function phaseDoor(part)
        if not part:IsA("BasePart") or not data.PhaseDoorNames[part.Name] then
            return
        end
        if originalCollide[part] == nil then
            originalCollide[part] = part.CanCollide
        end
        part.CanCollide = false
    end

    ctx.addSetting("loot_aura", false, function(value)
        if value then
            ctx.startLoop("loot", 0.15, lootStep)
        else
            ctx.stopLoop("loot")
        end
    end)
    ctx.addSetting("loot_radius", 5)
    ctx.addSetting("instant_prompts", false, function(value)
        ctx.unbind("prompts")
        if value then
            ctx.bind("prompts", ProximityPromptService.PromptShown, instantPrompt)
        else
            for prompt, hold in pairs(originalHold) do
                if prompt.Parent then
                    prompt.HoldDuration = hold
                end
            end
            originalHold = {}
        end
    end)
    ctx.addSetting("open_sesame", false, function(value)
        ctx.unbind("phasedoors")
        if value then
            local rooms = scan.rooms()
            if not rooms then
                ctx.notify(ctx.L("n_rooms_missing"), "warning", 3)
                return
            end
            for _, object in ipairs(rooms:GetDescendants()) do
                phaseDoor(object)
            end
            ctx.bind("phasedoors", rooms.DescendantAdded, function(object)
                task.defer(phaseDoor, object)
            end)
            ctx.notify(ctx.L("n_open_sesame"), "info", 4)
        else
            for part, original in pairs(originalCollide) do
                if part.Parent then
                    part.CanCollide = original
                end
            end
            originalCollide = {}
        end
    end)
    ctx.addSetting("entity_alert", false, function(value)
        ctx.unbind("entityalert")
        if value then
            ctx.bind("entityalert", workspace.ChildAdded, function(child)
                if data.Monsters[child.Name] then
                    local now = os.clock()
                    if not lastAlert[child.Name] or now - lastAlert[child.Name] > 8 then
                        lastAlert[child.Name] = now
                        ctx.notify(ctx.L("n_spawned", child.Name), "warning", 5)
                    end
                end
            end)
        end
    end)

    ctx.onUnload(function()
        for prompt, hold in pairs(originalHold) do
            if prompt.Parent then
                prompt.HoldDuration = hold
            end
        end
        for part, original in pairs(originalCollide) do
            if part.Parent then
                part.CanCollide = original
            end
        end
    end)

    M.doorYeet = function()
        local root = ctx.state.root
        local rooms = scan.rooms()
        if not root or not rooms then
            return
        end
        local done = {}
        for _, prompt in ipairs(rooms:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local door = prompt:FindFirstAncestorOfClass("Model")
                if door and not done[door] and string.find(door.Name:lower(), "door", 1, true) then
                    local parts = door:GetDescendants()
                    local near = false
                    for _, descendant in ipairs(parts) do
                        if descendant:IsA("BasePart") and (root.Position - descendant.Position).Magnitude <= 10 then
                            near = true
                            break
                        end
                    end
                    if near then
                        done[door] = true
                        for _, descendant in ipairs(parts) do
                            if descendant:IsA("BasePart") then
                                descendant.LocalTransparencyModifier = 1
                                descendant.CanCollide = false
                            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                                descendant.Transparency = 1
                            elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
                                descendant.Enabled = false
                            end
                        end
                    end
                end
            end
        end
    end
end

function M.Build(tab, ctx, data)
    local ui = ctx.ui
    ui.section(tab, "sec_collect", "Lucide:hand")
    ui.toggle(tab, "loot_aura", "Lucide:package")
    ui.slider(tab, "loot_radius", 1, 30, 1, "Lucide:ruler", " studs")
    ui.toggle(tab, "instant_prompts", "Lucide:zap")

    ui.section(tab, "sec_doors", "Lucide:door-open")
    ui.toggle(tab, "open_sesame", "Lucide:door-open")
    ui.button(tab, "btn_door_yeet", "Lucide:door-closed", function()
        M.doorYeet()
    end)

    ui.section(tab, "sec_alerts", "Lucide:bell")
    ui.toggle(tab, "entity_alert", "Lucide:triangle-alert")
end

return M
end)()

return features
