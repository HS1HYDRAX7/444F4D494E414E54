local features = {}

features["esp"] = (function()
local Players = game:GetService("Players")

local M = {}

function M.Register(ctx, data)
    local scan = ctx.modules:require("games/pressure/scan")
    local objects = {}
    local step, clear

    ctx.addSetting("esp", false, function(value)
        if value then
            ctx.startLoop("esp", 0.15, step)
        else
            ctx.stopLoop("esp")
            clear()
        end
    end)
    for _, key in ipairs({ "esp_monsters", "esp_players", "esp_items", "esp_currency", "esp_keycards", "esp_text", "esp_distance" }) do
        ctx.addSetting(key, true)
    end
    for _, key in ipairs({ "esp_doors", "esp_lockers", "esp_fake_doors", "esp_generators" }) do
        ctx.addSetting(key, false)
    end
    ctx.addSetting("esp_max_distance", 1000)
    ctx.addSetting("esp_fill", 0.6)
    ctx.addSetting("color_monster", Color3.fromRGB(200, 0, 0))
    ctx.addSetting("color_player", Color3.fromRGB(60, 255, 120))

    local function adorneePart(target)
        if target:IsA("BasePart") then
            return target
        end
        if target:IsA("Model") then
            return target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    local function create(target, label, color)
        local part = adorneePart(target)
        if not part then
            return nil
        end
        local highlight = Instance.new("Highlight")
        highlight.Name = "DominantHighlight"
        highlight.Adornee = target
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.OutlineColor = color
        highlight.Parent = target

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DominantLabel"
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.fromOffset(180, 32)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = part

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 13
        text.TextStrokeTransparency = 0.4
        text.TextColor3 = color
        text.Text = label
        text.Parent = billboard

        local entry = { highlight = highlight, billboard = billboard, label = text }
        objects[target] = entry
        return entry
    end

    local function destroy(target)
        local entry = objects[target]
        if not entry then
            return
        end
        pcall(function()
            entry.highlight:Destroy()
        end)
        pcall(function()
            entry.billboard:Destroy()
        end)
        objects[target] = nil
    end

    clear = function()
        for target in pairs(objects) do
            destroy(target)
        end
    end

    local function collect()
        local cfg = ctx.cfg
        local list = {}

        if cfg.esp_monsters then
            for _, child in ipairs(workspace:GetChildren()) do
                if data.Monsters[child.Name] and (child:IsA("Model") or child:IsA("BasePart")) then
                    table.insert(list, { target = child, label = child.Name, color = cfg.color_monster })
                end
            end
        end

        if cfg.esp_players then
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                if player ~= Players.LocalPlayer and character then
                    table.insert(list, { target = character, label = player.DisplayName, color = cfg.color_player })
                end
            end
        end

        for _, entry in ipairs(scan.items(data)) do
            local wanted = (entry.kind == "item" and cfg.esp_items)
                or (entry.kind == "currency" and cfg.esp_currency)
                or (entry.kind == "keycard" and cfg.esp_keycards)
            if wanted then
                table.insert(list, { target = entry.object, label = entry.label, color = entry.color })
            end
        end

        for _, entry in ipairs(scan.roomObjects(data)) do
            local object = entry.object
            if object.Parent then
                if entry.kind == "door" and cfg.esp_doors then
                    table.insert(list, { target = object, label = ctx.L("esp_exit_door"), color = data.Colors.ExitDoor })
                elseif entry.kind == "locker" and cfg.esp_lockers then
                    table.insert(list, { target = object, label = ctx.L("esp_locker"), color = data.Colors.Locker })
                elseif entry.kind == "fakedoor" and cfg.esp_fake_doors then
                    table.insert(list, { target = object, label = ctx.L("esp_fake_door"), color = data.Colors.FakeDoor })
                elseif entry.kind == "generator" and cfg.esp_generators then
                    local fixed = object:FindFirstChild("Fixed")
                    local value = fixed and fixed.Value
                    local pct = 0
                    if type(value) == "boolean" then
                        pct = value and 100 or 0
                    elseif type(value) == "number" then
                        pct = value
                    end
                    if pct < 100 then
                        local r = math.floor(255 * (1 - pct / 100))
                        local g = math.floor(255 * (pct / 100))
                        local target = object:FindFirstChild("ProxyPart") or object
                        table.insert(list, {
                            target = target,
                            label = ctx.L("esp_generator", tostring(math.floor(pct))),
                            color = Color3.fromRGB(r, g, 0),
                        })
                    end
                end
            end
        end

        return list
    end

    step = function()
        local cfg = ctx.cfg
        local root = ctx.state.root
        if not cfg.esp or not root then
            return
        end
        local seen = {}
        for _, item in ipairs(collect()) do
            local part = adorneePart(item.target)
            if part then
                local distance = (part.Position - root.Position).Magnitude
                if distance <= cfg.esp_max_distance then
                    local entry = objects[item.target] or create(item.target, item.label, item.color)
                    if entry then
                        seen[item.target] = true
                        entry.highlight.FillColor = item.color
                        entry.highlight.FillTransparency = 1 - cfg.esp_fill
                        entry.label.TextColor3 = item.color
                        entry.billboard.Enabled = cfg.esp_text
                        local text = item.label
                        if cfg.esp_distance then
                            text = text .. " [" .. tostring(math.floor(distance)) .. "m]"
                        end
                        entry.label.Text = text
                    end
                end
            end
        end
        for target in pairs(objects) do
            if not seen[target] or not target.Parent then
                destroy(target)
            end
        end
    end

    ctx.onUnload(clear)
end

function M.Build(tab, ctx, data)
    local ui = ctx.ui
    ui.section(tab, "sec_esp", "Lucide:eye")
    ui.toggle(tab, "esp", "Lucide:eye")
    ui.toggle(tab, "esp_monsters", "Lucide:skull")
    ui.toggle(tab, "esp_players", "Lucide:users")
    ui.toggle(tab, "esp_items", "Lucide:package")
    ui.toggle(tab, "esp_currency", "Lucide:coins")
    ui.toggle(tab, "esp_keycards", "Lucide:key-round")
    ui.toggle(tab, "esp_doors", "Lucide:door-open")
    ui.toggle(tab, "esp_lockers", "Lucide:lock")
    ui.toggle(tab, "esp_fake_doors", "Lucide:door-closed")
    ui.toggle(tab, "esp_generators", "Lucide:cog")
    ui.toggle(tab, "esp_text", "Lucide:type")
    ui.toggle(tab, "esp_distance", "Lucide:ruler")
    ui.slider(tab, "esp_max_distance", 100, 5000, 50, "Lucide:radar", " studs")
    ui.slider(tab, "esp_fill", 0, 1, 0.05, "Lucide:droplet")
    ui.section(tab, "sec_esp_colors", "Lucide:palette")
    ui.color(tab, "color_monster", "Lucide:skull")
    ui.color(tab, "color_player", "Lucide:users")
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
