--[[
    DOMINANT - Enhanced ESP for Forsaken
    Integrated from multiple scripts with better performance and features
]]

local M = {}

local function hasFileApi()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

function M.Init(core)
    local Dominant = core.Dominant
    local Svc = core.Svc
    
    -- ESP Settings
    Dominant.Defaults.esp_enabled = false
    Dominant.Defaults.esp_killers = true
    Dominant.Defaults.esp_survivors = true
    Dominant.Defaults.esp_generators = true
    Dominant.Defaults.esp_items = true
    Dominant.Defaults.esp_traps = true
    Dominant.Defaults.esp_text = true
    Dominant.Defaults.esp_distance = true
    Dominant.Defaults.esp_health = true
    Dominant.Defaults.esp_max_distance = 2500
    Dominant.Defaults.esp_fill = 0.6
    Dominant.Defaults.esp_tracers = false
    Dominant.Defaults.esp_tracer_origin = "Bottom"
    Dominant.Defaults.esp_tracer_thickness = 1.5
    Dominant.Defaults.esp_outline_only = false
    Dominant.Defaults.esp_text_size = 14
    Dominant.Defaults.esp_show_fake = true
    Dominant.Defaults.esp_support = true
    
    -- Colors
    Dominant.Defaults.color_killer = Color3.fromRGB(255, 50, 50)
    Dominant.Defaults.color_survivor = Color3.fromRGB(60, 255, 120)
    Dominant.Defaults.color_generator = Color3.fromRGB(255, 230, 60)
    Dominant.Defaults.color_item = Color3.fromRGB(70, 170, 255)
    Dominant.Defaults.color_trap = Color3.fromRGB(255, 120, 40)
    Dominant.Defaults.color_fake = Color3.fromRGB(255, 165, 0)
    Dominant.Defaults.color_support = Color3.fromRGB(180, 0, 0)
    
    -- State
    local espObjects = {}
    local espConnections = {}
    local localPlayer = Svc.Players.LocalPlayer
    local camera = Svc.Workspace.CurrentCamera
    
    -- ESP utilities
    local function getTeamFolder(char)
        local folder = Svc.Workspace:FindFirstChild("Players")
        if not folder then return nil end
        local killers = folder:FindFirstChild("Killers")
        local survivors = folder:FindFirstChild("Survivors")
        if killers and char and char:IsDescendantOf(killers) then
            return survivors, "Killer"
        end
        if survivors and char and char:IsDescendantOf(survivors) then
            return killers, "Survivor"
        end
        return nil, "Unknown"
    end
    
    local function getCharacterType(char)
        local folder = Svc.Workspace:FindFirstChild("Players")
        if not folder then return "Unknown" end
        
        if char:IsDescendantOf(folder:FindFirstChild("Killers")) then
            return "Killer"
        elseif char:IsDescendantOf(folder:FindFirstChild("Survivors")) then
            return "Survivor"
        elseif char:IsDescendantOf(folder:FindFirstChild("Ragdolls")) then
            return "Ragdoll"
        end
        return "Unknown"
    end
    
    local function getCharacterColor(char)
        local charType = getCharacterType(char)
        local colors = {
            Killer = Dominant.Cfg.color_killer,
            Survivor = Dominant.Cfg.color_survivor,
            Ragdoll = Color3.fromRGB(150, 150, 150),
        }
        return colors[charType] or Color3.fromRGB(255, 255, 255)
    end
    
    local function isVisible(char, part)
        if not char or not part then return false end
        
        local localChar = localPlayer.Character
        if not localChar then return false end
        
        local localRoot = localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot then return false end
        
        local origin = localRoot.Position
        local target = part.Position
        local distance = (target - origin).Magnitude
        
        if distance > Dominant.Cfg.esp_max_distance then
            return false
        end
        
        -- Raycast check
        local ray = Ray.new(origin, (target - origin).Unit * distance)
        local hit, position = Svc.Workspace:FindPartOnRay(ray, localChar)
        
        if hit and hit:IsDescendantOf(char) then
            return true
        end
        
        return false
    end
    
    -- Create ESP for character
    local function createCharacterESP(char)
        if not Dominant.Cfg.esp_enabled then return end
        if espObjects[char] then return end
        
        local esp = {
            char = char,
            parts = {},
            text = nil,
            healthBar = nil,
        }
        
        -- Get humanoid and root
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then return end
        
        -- Character type and color
        local charType = getCharacterType(char)
        local color = getCharacterColor(char)
        
        -- Check if should show this character
        local showKiller = Dominant.Cfg.esp_killers and charType == "Killer"
        local showSurvivor = Dominant.Cfg.esp_survivors and charType == "Survivor"
        if not showKiller and not showSurvivor then return end
        
        -- Create box ESP
        if not Dominant.Cfg.esp_outline_only then
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = char
            box.Color3 = color
            box.Transparency = 0.6
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.LineThickness = 1
            box.Parent = char
            esp.parts.box = box
        end
        
        -- Create text ESP
        if Dominant.Cfg.esp_text then
            local gui = Instance.new("BillboardGui")
            gui.Adornee = root
            gui.AlwaysOnTop = true
            gui.Size = UDim2.new(0, 100, 0, 40)
            gui.StudsOffset = Vector3.new(0, 2.5, 0)
            gui.Parent = root
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundTransparency = 1
            frame.Parent = gui
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0, 14)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = charType
            nameLabel.TextColor3 = color
            nameLabel.TextSize = Dominant.Cfg.esp_text_size
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextStrokeTransparency = 0
            nameLabel.Parent = frame
            
            if Dominant.Cfg.esp_distance then
                local distLabel = Instance.new("TextLabel")
                distLabel.Size = UDim2.new(1, 0, 0, 12)
                distLabel.Position = UDim2.new(0, 0, 0, 16)
                distLabel.BackgroundTransparency = 1
                distLabel.Text = "0 studs"
                distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                distLabel.TextSize = Dominant.Cfg.esp_text_size - 2
                distLabel.Font = Enum.Font.Gotham
                distLabel.TextStrokeTransparency = 0
                distLabel.Parent = frame
                esp.parts.distLabel = distLabel
            end
            
            if Dominant.Cfg.esp_health and humanoid then
                local healthBar = Instance.new("Frame")
                healthBar.Size = UDim2.new(1, 0, 0, 4)
                healthBar.Position = UDim2.new(0, 0, 0, 32)
                healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                healthBar.BorderSizePixel = 0
                healthBar.Parent = frame
                
                local healthFill = Instance.new("Frame")
                healthFill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
                healthFill.BackgroundColor3 = color
                healthFill.BorderSizePixel = 0
                healthFill.Parent = healthBar
                esp.parts.healthBar = healthBar
                esp.parts.healthFill = healthFill
            end
            
            esp.text = gui
        end
        
        -- Update distance
        local function updateDistance()
            local localChar = localPlayer.Character
            if not localChar then return end
            
            local localRoot = localChar:FindFirstChild("HumanoidRootPart")
            if not localRoot or not root then return end
            
            local distance = math.floor((root.Position - localRoot.Position).Magnitude)
            if esp.parts.distLabel then
                esp.parts.distLabel.Text = distance .. " studs"
            end
        end
        
        -- Update health
        local function updateHealth()
            if not humanoid then return end
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            if esp.parts.healthFill then
                esp.parts.healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
            end
        end
        
        -- Connection for updates
        local conn = Svc.RunService.Heartbeat:Connect(function()
            if not char or not char.Parent then
                cleanupESP(esp)
                return
            end
            updateDistance()
            updateHealth()
        end)
        
        table.insert(espConnections, conn)
        
        -- Store ESP
        espObjects[char] = esp
    end
    
    -- Create ESP for generators
    local function createGeneratorESP(generator)
        if not Dominant.Cfg.esp_enabled or not Dominant.Cfg.esp_generators then return end
        if espObjects[generator] then return end
        
        local color = Dominant.Cfg.color_generator
        
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = generator
        box.Color3 = color
        box.Transparency = 0.6
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.LineThickness = 1
        box.Parent = generator
        
        espObjects[generator] = { parts = { box = box } }
    end
    
    -- Create ESP for items
    local function createItemESP(item)
        if not Dominant.Cfg.esp_enabled or not Dominant.Cfg.esp_items then return end
        if espObjects[item] then return end
        
        local color = Dominant.Cfg.color_item
        
        -- Check if it's a fake item
        if Dominant.Cfg.esp_show_fake then
            if item.Name == "Fake" or (item:FindFirstAttribute("Fake") ~= nil) then
                color = Dominant.Cfg.color_fake
            end
        end
        
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = item
        box.Color3 = color
        box.Transparency = 0.6
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.LineThickness = 1
        box.Parent = item
        
        espObjects[item] = { parts = { box = box } }
    end
    
    -- Create ESP for traps
    local function createTrapESP(trap)
        if not Dominant.Cfg.esp_enabled or not Dominant.Cfg.esp_traps then return end
        if espObjects[trap] then return end
        
        local color = Dominant.Cfg.color_trap
        
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = trap
        box.Color3 = color
        box.Transparency = 0.6
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.LineThickness = 1
        box.Parent = trap
        
        espObjects[trap] = { parts = { box = box } }
    end
    
    -- Cleanup ESP
    local function cleanupESP(esp)
        if not esp then return end
        
        for _, part in pairs(esp.parts) do
            if part and part.Parent then
                part:Destroy()
            end
        end
        
        if esp.text and esp.text.Parent then
            esp.text:Destroy()
        end
        
        if esp.char and espObjects[esp.char] then
            espObjects[esp.char] = nil
        end
    end
    
    -- Cleanup all ESP
    local function cleanupAllESP()
        for char, esp in pairs(espObjects) do
            cleanupESP(esp)
        end
        table.clear(espObjects)
        
        for _, conn in ipairs(espConnections) do
            conn:Disconnect()
        end
        table.clear(espConnections)
    end
    
    -- Toggle ESP
    function M.ToggleESP(enabled)
        Dominant.Cfg.esp_enabled = enabled
        if enabled then
            -- Recreate ESP for existing objects
            for _, player in ipairs(Svc.Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    createCharacterESP(player.Character)
                end
            end
            
            -- Generators
            local generators = Svc.Workspace:FindFirstChild("Generators")
            if generators then
                for _, gen in ipairs(generators:GetChildren()) do
                    createGeneratorESP(gen)
                end
            end
            
            -- Items
            local items = Svc.Workspace:FindFirstChild("Items")
            if items then
                for _, item in ipairs(items:GetChildren()) do
                    createItemESP(item)
                end
            end
            
            -- Traps
            local traps = Svc.Workspace:FindFirstChild("Traps")
            if traps then
                for _, trap in ipairs(traps:GetChildren()) do
                    createTrapESP(trap)
                end
            end
        else
            cleanupAllESP()
        end
    end
    
    -- Setup ESP listeners
    local function setupESP()
        -- Character added
        local function onCharacterAdded(character)
            if character ~= localPlayer.Character then
                createCharacterESP(character)
            end
        end
        
        -- Character removing
        local function onCharacterRemoving(character)
            cleanupESP(espObjects[character])
        end
        
        -- Players
        for _, player in ipairs(Svc.Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                createCharacterESP(player.Character)
            end
            player.CharacterAdded:Connect(function(char)
                onCharacterAdded(char)
            end)
        end
        
        Svc.Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(char)
                onCharacterAdded(char)
            end)
        end)
        
        -- Generators
        local generators = Svc.Workspace:FindFirstChild("Generators")
        if generators then
            generators.DescendantAdded:Connect(function(gen)
                createGeneratorESP(gen)
            end)
        end
        
        -- Items
        local items = Svc.Workspace:FindFirstChild("Items")
        if items then
            items.DescendantAdded:Connect(function(item)
                createItemESP(item)
            end)
        end
        
        -- Traps
        local traps = Svc.Workspace:FindFirstChild("Traps")
        if traps then
            traps.DescendantAdded:Connect(function(trap)
                createTrapESP(trap)
            end)
        end
    end
    
    -- Initialize ESP
    setupESP()
    
    -- Add to Dominant
    Dominant.ESP = {
        Toggle = M.ToggleESP,
        Cleanup = cleanupAllESP,
    }
    
    core.Log("ESP system initialized")
end

-- Build UI for ESP
function M.BuildESP(tab, H, core)
    local Dominant = core.Dominant
    
    local espSection = tab:AddSection({
        Name = Dominant.L("esp"),
        Side = "Left",
    })
    
    -- Main toggle
    espSection:AddToggle({
        Name = Dominant.L("esp_enabled"),
        Flag = "esp_enabled",
        Default = Dominant.Cfg.esp_enabled,
        Callback = function(value)
            Dominant.Cfg.esp_enabled = value
            M.ToggleESP(value)
            Dominant.QueueSave()
        end,
    })
    
    -- Entity toggles
    espSection:AddToggle({
        Name = Dominant.L("esp_killers"),
        Flag = "esp_killers",
        Default = Dominant.Cfg.esp_killers,
        Callback = function(value)
            Dominant.Cfg.esp_killers = value
            M.ToggleESP(Dominant.Cfg.esp_enabled)
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_survivors"),
        Flag = "esp_survivors",
        Default = Dominant.Cfg.esp_survivors,
        Callback = function(value)
            Dominant.Cfg.esp_survivors = value
            M.ToggleESP(Dominant.Cfg.esp_enabled)
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_generators"),
        Flag = "esp_generators",
        Default = Dominant.Cfg.esp_generators,
        Callback = function(value)
            Dominant.Cfg.esp_generators = value
            M.ToggleESP(Dominant.Cfg.esp_enabled)
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_items"),
        Flag = "esp_items",
        Default = Dominant.Cfg.esp_items,
        Callback = function(value)
            Dominant.Cfg.esp_items = value
            M.ToggleESP(Dominant.Cfg.esp_enabled)
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_traps"),
        Flag = "esp_traps",
        Default = Dominant.Cfg.esp_traps,
        Callback = function(value)
            Dominant.Cfg.esp_traps = value
            M.ToggleESP(Dominant.Cfg.esp_enabled)
            Dominant.QueueSave()
        end,
    })
    
    -- Display options
    espSection:AddToggle({
        Name = Dominant.L("esp_text"),
        Flag = "esp_text",
        Default = Dominant.Cfg.esp_text,
        Callback = function(value)
            Dominant.Cfg.esp_text = value
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_distance"),
        Flag = "esp_distance",
        Default = Dominant.Cfg.esp_distance,
        Callback = function(value)
            Dominant.Cfg.esp_distance = value
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_health"),
        Flag = "esp_health",
        Default = Dominant.Cfg.esp_health,
        Callback = function(value)
            Dominant.Cfg.esp_health = value
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_tracers"),
        Flag = "esp_tracers",
        Default = Dominant.Cfg.esp_tracers,
        Callback = function(value)
            Dominant.Cfg.esp_tracers = value
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddToggle({
        Name = Dominant.L("esp_outline_only"),
        Flag = "esp_outline_only",
        Default = Dominant.Cfg.esp_outline_only,
        Callback = function(value)
            Dominant.Cfg.esp_outline_only = value
            M.ToggleESP(Dominant.Cfg.esp_enabled)
            Dominant.QueueSave()
        end,
    })
    
    -- Range slider
    espSection:AddSlider({
        Name = Dominant.L("esp_max_distance"),
        Flag = "esp_max_distance",
        Min = 100,
        Max = 5000,
        Default = Dominant.Cfg.esp_max_distance,
        Increment = 100,
        Suffix = " studs",
        Callback = function(value)
            Dominant.Cfg.esp_max_distance = value
            Dominant.QueueSave()
        end,
    })
    
    -- Text size slider
    espSection:AddSlider({
        Name = Dominant.L("esp_text_size"),
        Flag = "esp_text_size",
        Min = 8,
        Max = 24,
        Default = Dominant.Cfg.esp_text_size,
        Increment = 1,
        Callback = function(value)
            Dominant.Cfg.esp_text_size = value
            Dominant.QueueSave()
        end,
    })
    
    -- Transparency slider
    espSection:AddSlider({
        Name = Dominant.L("esp_fill"),
        Flag = "esp_fill",
        Min = 0,
        Max = 1,
        Default = Dominant.Cfg.esp_fill,
        Increment = 0.05,
        Callback = function(value)
            Dominant.Cfg.esp_fill = value
            Dominant.QueueSave()
        end,
    })
    
    -- Color pickers
    espSection:AddColorPicker({
        Name = Dominant.L("color_killer"),
        Flag = "color_killer",
        Default = Dominant.Cfg.color_killer,
        Callback = function(color)
            Dominant.Cfg.color_killer = color
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddColorPicker({
        Name = Dominant.L("color_survivor"),
        Flag = "color_survivor",
        Default = Dominant.Cfg.color_survivor,
        Callback = function(color)
            Dominant.Cfg.color_survivor = color
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddColorPicker({
        Name = Dominant.L("color_generator"),
        Flag = "color_generator",
        Default = Dominant.Cfg.color_generator,
        Callback = function(color)
            Dominant.Cfg.color_generator = color
            Dominant.QueueSave()
        end,
    })
    
    espSection:AddColorPicker({
        Name = Dominant.L("color_item"),
        Flag = "color_item",
        Default = Dominant.Cfg.color_item,
        Callback = function(color)
            Dominant.Cfg.color_item = color
            Dominant.QueueSave()
        end,
    })
end

return M
