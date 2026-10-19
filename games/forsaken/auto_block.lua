--[[
    DOMINANT - Enhanced Auto Block for Forsaken
    Integrated from Guest1337, Hybrid-AB, Duck-Hub, and FishHub
    Modern design with better detection and performance
]]

local M = {}

local function hasFileApi()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function ensureFolder(path)
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local ok = pcall(function()
            if not isfolder(path) then
                makefolder(path)
            end
        end)
        return ok
    end
    return false
end

-- Enhanced Auto Block System
function M.Init(core)
    local Dominant = core.Dominant
    local Svc = core.Svc
    
    -- Default settings for Auto Block
    Dominant.Defaults.auto_block_enabled = false
    Dominant.Defaults.auto_block_mode = "Hybrid"  -- "Animation", "Sound", "Hitbox", "Hybrid"
    Dominant.Defaults.auto_block_range = 18
    Dominant.Defaults.auto_block_delay = 0
    Dominant.Defaults.auto_block_cooldown = 0.35
    Dominant.Defaults.auto_block_double = true
    Dominant.Defaults.auto_block_anti_bait = false
    Dominant.Defaults.auto_block_facing_check = true
    Dominant.Defaults.auto_block_facing_dot = 0.5
    
    -- Hitbox settings
    Dominant.Defaults.hitbox_enabled = true
    Dominant.Defaults.hitbox_size = Vector3.new(4.5, 6, 7.5)
    Dominant.Defaults.hitbox_margin = 0.05
    Dominant.Defaults.hitbox_range = 18
    
    -- Sound settings
    Dominant.Defaults.sound_block_enabled = true
    Dominant.Defaults.sound_block_delay = 0
    
    -- Animation settings
    Dominant.Defaults.anim_block_enabled = true
    Dominant.Defaults.anim_block_range = 18
    Dominant.Defaults.anim_block_delay = 0
    
    -- Enhanced sound IDs from multiple scripts
    local KILLER_SOUNDS = {
        ["94317217837143"] = true, ["105840448036441"] = true, ["99215225043220"] = true, ["108907358619313"] = true,
        ["107444859834748"] = true, ["124903763333174"] = true, ["123835423223220"] = true, ["112809109188560"] = true,
        ["123923371062204"] = true, ["137809737339569"] = true, ["131123355704017"] = true, ["98675142200448"] = true,
        ["109246041199659"] = true, ["140242176732868"] = true, ["105204810054381"] = true, ["80516583309685"] = true,
        ["128195973631079"] = true, ["84307400688050"] = true, ["98733709078792"] = true, ["124234993291213"] = true,
        ["82221759983649"] = true, ["75330693422988"] = true, ["117173212095661"] = true, ["74809026448465"] = true,
        ["119942598489800"] = true, ["88589682639517"] = true, ["121954639447247"] = true, ["128856426573270"] = true,
        ["85853080745515"] = true, ["109348678063422"] = true, ["80540530406270"] = true, ["131406927389838"] = true,
        ["128367348686124"] = true, ["89004992452376"] = true, ["108610718831698"] = true, ["109570290393196"] = true,
    }
    
    -- Enhanced trigger animation IDs from Hybrid-AB
    local TRIGGER_ANIMS = {
        ["114506382930939"]=true,["127245564598429"]=true,["99829427721752"]=true,
        ["138938529389204"]=true,["111647315359080"]=true,["92567970681901"]=true,
        ["124269076578545"]=true,["94958041603347"]=true,["109667959938617"]=true,
        ["130958529065375"]=true,["118298475669935"]=true,["126830014841198"]=true,
        ["126355327951215"]=true,["121086746534252"]=true,["18885909645"]=true,
        ["98456918873918"]=true,["105458270463374"]=true,["83829782357897"]=true,
        ["125403313786645"]=true,["82113744478546"]=true,["70371667919898"]=true,
        ["99135633258223"]=true,["7167027849946"]=true,["109230267448394"]=true,
        ["139835501033932"]=true,["126996426760253"]=true,["88451353906104"]=true,
        ["106538427162796"]=true,["122709416391891"]=true,["139309647473555"]=true,
        ["90620531468240"]=true,["91509234639766"]=true,["99824350842479"]=true,
        ["126171487400618"]=true,["101101433684051"]=true,["106860049270347"]=true,
        ["70483423693126"]=true,["126727756047566"]=true,["137642639873297"]=true,
        ["77375846492436"]=true,["126681776859538"]=true,["129976080405072"]=true,
        ["121293883585738"]=true,["81639435858902"]=true,["137314737492715"]=true,
    }
    
    -- State variables
    local blockLastTime = 0
    local BLOCK_CD = 0.1
    local cachedHRP = nil
    local animBlockConn = nil
    local hitboxConn = nil
    local hitboxHeartbeat = nil
    local soundBlockedUntil = {}
    local hookedSounds = {}
    
    -- Get character utilities
    local function getLocalCharacter()
        return Svc.Players.LocalPlayer.Character
    end
    
    local function getRoot(char)
        if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.RootPart then return humanoid.RootPart end
        return nil
    end
    
    local function getTeamFolder(char)
        local folder = Svc.Workspace:FindFirstChild("Players")
        if not folder then return nil end
        local killers = folder:FindFirstChild("Killers")
        local survivors = folder:FindFirstChild("Survivors")
        if killers and char and char:IsDescendantOf(killers) then
            return survivors
        end
        if survivors and char and char:IsDescendantOf(survivors) then
            return killers
        end
        return nil
    end
    
    -- Enhanced facing check
    local function isFacingTarget(root, targetHRP, dotThreshold)
        if not root or not targetHRP then return false end
        local look = root.CFrame.LookVector
        local toTarget = (targetHRP.Position - root.Position).Unit
        local dot = look:Dot(toTarget)
        return dot >= (dotThreshold or 0.5)
    end
    
    -- Sound blocking
    local function setupSoundBlocking()
        if not Dominant.Cfg.sound_block_enabled then return end
        
        local function onSoundPlayed(sound)
            if not sound:IsDescendantOf(game) then return end
            if sound.IsLoaded and sound.Playing then
                local soundId = tostring(sound.SoundId)
                if KILLER_SOUNDS[soundId] then
                    local character = getLocalCharacter()
                    if not character then return end
                    local root = getRoot(character)
                    if not root then return end
                    
                    local now = tick()
                    if soundBlockedUntil[soundId] and soundBlockedUntil[soundId] > now then
                        return
                    end
                    soundBlockedUntil[soundId] = now + (Dominant.Cfg.auto_block_cooldown or 0.35)
                    
                    -- Trigger block
                    triggerBlock(root, character)
                end
            end
        end
        
        -- Hook sound service
        local SoundService = Svc.SoundService
        if SoundService then
            local conn = SoundService.DescendantAdded:Connect(onSoundPlayed)
            table.insert(Dominant.Conns, conn)
        end
    end
    
    -- Animation blocking
    local function setupAnimationBlocking()
        if not Dominant.Cfg.anim_block_enabled then return end
        
        local function checkAnimation(animTrack)
            if not animTrack then return end
            local anim = animTrack.Animation
            if not anim then return end
            local animId = tostring(anim.AnimationId)
            if TRIGGER_ANIMS[animId] then
                local character = animTrack:IsPlaying() and animTrack.RobloxModel and animTrack.RobloxModel.Parent
                if character then
                    local root = getRoot(character)
                    if root then
                        triggerBlock(root, character)
                    end
                end
            end
        end
        
        -- Monitor animations
        local function onCharacterAdded(character)
            if animBlockConn then animBlockConn:Disconnect() end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                animBlockConn = humanoid.AnimationPlayed:Connect(function(animTrack)
                    checkAnimation(animTrack)
                end)
            end
        end
        
        local LocalPlayer = Svc.Players.LocalPlayer
        onCharacterAdded(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
        LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    end
    
    -- Hitbox blocking (Gaze V1.1 + LookVector)
    local function setupHitboxBlocking()
        if not Dominant.Cfg.hitbox_enabled then return end
        
        local boxSize = Dominant.Cfg.hitbox_size or Vector3.new(4.5, 6, 7.5)
        local margin = Dominant.Cfg.hitbox_margin or 0.05
        local range = Dominant.Cfg.hitbox_range or 18
        
        local function findNearestHumanoid(root)
            if not root then return nil, math.huge end
            local targetFolder = getTeamFolder(root.Parent)
            if not targetFolder then return nil, math.huge end
            
            local look = root.CFrame.LookVector
            local parts = Svc.Workspace:GetPartBoundsInBox(root.CFrame, boxSize)
            local closest, bestScore = nil, math.huge
            
            for _, part in ipairs(parts) do
                local model = part.Parent
                if model and model ~= root.Parent then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and hrp then
                        local offset = hrp.Position - root.Position
                        local dist = offset.Magnitude
                        if dist >= 0.5 and dist <= range then
                            local dir = offset.Unit
                            local facing = look:Dot(dir)
                            local preferred = model:IsDescendantOf(targetFolder)
                            local score = dist
                            if facing < 0 then
                                score = score + 50
                            elseif facing < 0.35 then
                                score = score + 18
                            end
                            if not preferred then
                                score = score + 30
                            end
                            if preferred and facing >= 0 then
                                if not closest or score < bestScore then
                                    bestScore = score
                                    closest = hrp
                                end
                            elseif not closest and score < bestScore then
                                bestScore = score
                                closest = hrp
                            end
                        end
                    end
                end
            end
            return closest, bestScore
        end
        
        local function setVelocityTarget(root, char)
            local target, _ = findNearestHumanoid(root)
            if not target then return end
            local dir = target.Position - root.Position
            if dir.Magnitude < 0.05 then return end
            dir = dir.Unit
            local forward = root.CFrame.LookVector
            if forward:Dot(dir) < 0.5 then
                dir = (dir * 1.35 + forward * 0.35)
                if dir.Magnitude > 0 then
                    dir = dir.Unit
                end
            end
            local dist = (target.Position - root.Position).Magnitude
            local shake = Vector3.new(math.random(-30, 30), math.random(-12, 12), math.random(-30, 30))
            local speed = 45 + dist * 5.5
            local current = root.Velocity
            root.Velocity = current * 0.25 + dir * speed + shake
        end
        
        -- Hook ability buttons
        local function setupHitboxHook()
            local playerGui = Svc.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if not playerGui then return end
            
            local ui = playerGui:FindFirstChild("MainUI")
            if not ui then return end
            
            local container = ui:FindFirstChild("AbilityContainer")
            if not container then return end
            
            local buttons = {}
            for _, btn in ipairs(container:GetChildren()) do
                if btn:IsA("TextButton") then
                    buttons[#buttons + 1] = btn
                end
            end
            
            local function isReady(cdLabel)
                if not cdLabel or cdLabel.Text == "" then return true end
                local n = tonumber(cdLabel.Text)
                return n ~= nil and n <= 0.1
            end
            
            for _, btn in ipairs(buttons) do
                local cd = btn:FindFirstChild("CooldownTime")
                if cd and cd:IsA("TextLabel") then
                    local conn = btn.MouseButton1Click:Connect(function()
                        if Dominant.Cfg.hitbox_enabled and isReady(cd) then
                            local character = getLocalCharacter()
                            if character then
                                local root = getRoot(character)
                                if root then
                                    setVelocityTarget(root, character)
                                end
                            end
                        end
                    end)
                    table.insert(Dominant.Conns, conn)
                end
            end
        end
        
        -- Setup hitbox hook with delay
        task.delay(2, setupHitboxHook)
    end
    
    -- Trigger block function
    local function triggerBlock(root, char)
        if not Dominant.Cfg.auto_block_enabled then return end
        
        local now = tick()
        if now - blockLastTime < BLOCK_CD then return end
        blockLastTime = now
        
        -- Check cooldown
        if Dominant.Cfg.auto_block_delay > 0 then
            task.wait(Dominant.Cfg.auto_block_delay)
        end
        
        -- Check facing if enabled
        if Dominant.Cfg.auto_block_facing_check then
            local targetFolder = getTeamFolder(char)
            if targetFolder then
                local closest = findNearestHumanoid(root)
                if closest and not isFacingTarget(root, closest, Dominant.Cfg.auto_block_facing_dot) then
                    return
                end
            end
        end
        
        -- Send block remote
        local RemoteEvent = core.RemoteEvent
        if RemoteEvent then
            local ok, err = pcall(function()
                -- Create block buffer
                local buffer = createBlockBuffer()
                if buffer then
                    RemoteEvent:FireServer("BlockState", { true, buffer })
                end
            end)
            if not ok then
                warn("[AutoBlock] Failed to send block: " .. tostring(err))
            end
        end
    end
    
    -- Create block buffer
    local cachedBlockBuffer = nil
    local function createBlockBuffer()
        if cachedBlockBuffer then return cachedBlockBuffer end
        
        local ok, buffer = pcall(function()
            if buffer and buffer.create then
                local blockBytes = { 3, 5, 0, 0, 0, 66, 108, 111, 99, 107 }
                local b = buffer.create(#blockBytes)
                for i = 1, #blockBytes do
                    buffer.writeu8(b, i - 1, blockBytes[i])
                end
                return b
            elseif buffer and buffer.fromstring then
                local str = "\3\5\0\0\0Block"
                return buffer.fromstring(str)
            end
            return nil
        end)
        
        if ok and buffer then
            cachedBlockBuffer = buffer
        end
        return buffer
    end
    
    -- Main initialization
    function M.InitAutoBlock()
        -- Setup all blocking methods
        setupSoundBlocking()
        setupAnimationBlocking()
        setupHitboxBlocking()
        
        -- Add settings to Dominant
        Dominant.Defaults.auto_block_priority = "Hybrid" -- "Sound", "Animation", "Hitbox"
        
        core.Log("Auto Block system initialized")
    end
    
    -- Build UI for Auto Block
    function M.BuildAutoBlock(tab, H, core)
        local Dominant = core.Dominant
        
        -- Auto Block section
        local autoBlockSection = tab:AddSection({
            Name = Dominant.L("auto_block"),
            Side = "Left",
        })
        
        -- Main toggle
        autoBlockSection:AddToggle({
            Name = Dominant.L("auto_block_enabled"),
            Flag = "auto_block_enabled",
            Default = Dominant.Cfg.auto_block_enabled,
            Callback = function(value)
                Dominant.Cfg.auto_block_enabled = value
                Dominant.QueueSave()
            end,
        })
        
        -- Mode selection
        autoBlockSection:AddDropdown({
            Name = Dominant.L("auto_block_mode"),
            Flag = "auto_block_mode",
            Options = { "Hybrid", "Animation", "Sound", "Hitbox" },
            Default = Dominant.Cfg.auto_block_mode,
            Callback = function(value)
                Dominant.Cfg.auto_block_mode = value
                Dominant.QueueSave()
            end,
        })
        
        -- Range slider
        autoBlockSection:AddSlider({
            Name = Dominant.L("auto_block_range"),
            Flag = "auto_block_range",
            Min = 5,
            Max = 30,
            Default = Dominant.Cfg.auto_block_range,
            Increment = 1,
            Suffix = " studs",
            Callback = function(value)
                Dominant.Cfg.auto_block_range = value
                Dominant.QueueSave()
            end,
        })
        
        -- Delay slider
        autoBlockSection:AddSlider({
            Name = Dominant.L("auto_block_delay"),
            Flag = "auto_block_delay",
            Min = 0,
            Max = 0.5,
            Default = Dominant.Cfg.auto_block_delay,
            Increment = 0.01,
            Suffix = "s",
            Callback = function(value)
                Dominant.Cfg.auto_block_delay = value
                Dominant.QueueSave()
            end,
        })
        
        -- Cooldown slider
        autoBlockSection:AddSlider({
            Name = Dominant.L("auto_block_cooldown"),
            Flag = "auto_block_cooldown",
            Min = 0,
            Max = 1,
            Default = Dominant.Cfg.auto_block_cooldown,
            Increment = 0.05,
            Suffix = "s",
            Callback = function(value)
                Dominant.Cfg.auto_block_cooldown = value
                Dominant.QueueSave()
            end,
        })
        
        -- Hitbox settings
        autoBlockSection:AddToggle({
            Name = Dominant.L("hitbox_enabled"),
            Flag = "hitbox_enabled",
            Default = Dominant.Cfg.hitbox_enabled,
            Callback = function(value)
                Dominant.Cfg.hitbox_enabled = value
                Dominant.QueueSave()
            end,
        })
        
        autoBlockSection:AddToggle({
            Name = Dominant.L("sound_block_enabled"),
            Flag = "sound_block_enabled",
            Default = Dominant.Cfg.sound_block_enabled,
            Callback = function(value)
                Dominant.Cfg.sound_block_enabled = value
                Dominant.QueueSave()
            end,
        })
        
        autoBlockSection:AddToggle({
            Name = Dominant.L("anim_block_enabled"),
            Flag = "anim_block_enabled",
            Default = Dominant.Cfg.anim_block_enabled,
            Callback = function(value)
                Dominant.Cfg.anim_block_enabled = value
                Dominant.QueueSave()
            end,
        })
        
        -- Facing check
        autoBlockSection:AddToggle({
            Name = Dominant.L("auto_block_facing_check"),
            Flag = "auto_block_facing_check",
            Default = Dominant.Cfg.auto_block_facing_check,
            Callback = function(value)
                Dominant.Cfg.auto_block_facing_check = value
                Dominant.QueueSave()
            end,
        })
        
        autoBlockSection:AddSlider({
            Name = Dominant.L("auto_block_facing_dot"),
            Flag = "auto_block_facing_dot",
            Min = -1,
            Max = 1,
            Default = Dominant.Cfg.auto_block_facing_dot,
            Increment = 0.05,
            Callback = function(value)
                Dominant.Cfg.auto_block_facing_dot = value
                Dominant.QueueSave()
            end,
        })
    end
    
    return M
end

return M
