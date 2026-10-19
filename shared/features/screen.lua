local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local M = {}

function M.Register(ctx, data)
    local savedLight = nil
    local savedFog = nil
    local savedAtmospheres = {}
    local savedFov = nil
    local savedZoom = nil

    local function restoreProps(saved)
        if not saved then
            return
        end
        for key, value in pairs(saved) do
            pcall(function()
                Lighting[key] = value
            end)
        end
    end

    local function fullbrightStep()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(190, 190, 190)
        Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
    end

    local function noFogStep()
        Lighting.FogStart = 1e9
        Lighting.FogEnd = 1e9
        for _, atmosphere in ipairs(Lighting:GetChildren()) do
            if atmosphere:IsA("Atmosphere") then
                if savedAtmospheres[atmosphere] == nil then
                    savedAtmospheres[atmosphere] = atmosphere.Density
                end
                atmosphere.Density = 0
            end
        end
    end

    local function thirdPersonStep()
        local distance = math.max(0.5, tonumber(ctx.cfg.third_person_dist) or 10)
        pcall(function()
            LocalPlayer.CameraMaxZoomDistance = distance
            LocalPlayer.CameraMinZoomDistance = distance
        end)
    end

    ctx.addSetting("fullbright", false, function(value)
        if value then
            savedLight = savedLight or {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
            ctx.startLoop("fullbright", 0.25, fullbrightStep)
        else
            ctx.stopLoop("fullbright")
            restoreProps(savedLight)
            savedLight = nil
        end
    end)
    ctx.addSetting("no_fog", false, function(value)
        if value then
            savedFog = savedFog or { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd }
            ctx.startLoop("nofog", 0.5, noFogStep)
        else
            ctx.stopLoop("nofog")
            restoreProps(savedFog)
            savedFog = nil
            for atmosphere, density in pairs(savedAtmospheres) do
                pcall(function()
                    if atmosphere.Parent then
                        atmosphere.Density = density
                    end
                end)
            end
            savedAtmospheres = {}
        end
    end)
    ctx.addSetting("fov_on", false, function(value)
        if value then
            local camera = workspace.CurrentCamera
            if camera and savedFov == nil then
                savedFov = camera.FieldOfView
            end
            ctx.bind("fov", RunService.RenderStepped, function()
                local current = workspace.CurrentCamera
                if current then
                    current.FieldOfView = ctx.cfg.fov
                end
            end)
        else
            ctx.unbind("fov")
            local current = workspace.CurrentCamera
            if current and savedFov then
                current.FieldOfView = savedFov
            end
            savedFov = nil
        end
    end)
    ctx.addSetting("fov", 90)
    ctx.addSetting("third_person", false, function(value)
        if value then
            savedZoom = savedZoom or { min = LocalPlayer.CameraMinZoomDistance, max = LocalPlayer.CameraMaxZoomDistance }
            thirdPersonStep()
            ctx.startLoop("thirdperson", 0.5, thirdPersonStep)
        else
            ctx.stopLoop("thirdperson")
            if savedZoom then
                pcall(function()
                    LocalPlayer.CameraMaxZoomDistance = savedZoom.max
                    LocalPlayer.CameraMinZoomDistance = savedZoom.min
                end)
            end
            savedZoom = nil
        end
    end)
    ctx.addSetting("third_person_dist", 10, function()
        if ctx.cfg.third_person then
            thirdPersonStep()
        end
    end)

    -- Better first person (from the open-source FP + smooth cam script)
    local shakePower = 0
    local headAttachments = {
        HatAttachment = true,
        HairAttachment = true,
        FaceFrontAttachment = true,
        FaceCenterAttachment = true,
    }

    local function firstPersonStep(dt)
        local character = LocalPlayer.Character
        local camera = workspace.CurrentCamera
        if not character or not camera then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local head = character:FindFirstChild("Head")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not head or not hrp then
            return
        end

        local isFirstPerson = (head.Position - camera.CFrame.Position).Magnitude < 2
        if ctx.cfg.fp_hide_head then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.Name == "Head" then
                        part.LocalTransparencyModifier = isFirstPerson and 1 or 0
                    elseif part.Name == "Handle" then
                        local attachment = part:FindFirstChildOfClass("Attachment")
                        if attachment and headAttachments[attachment.Name] then
                            part.LocalTransparencyModifier = isFirstPerson and 1 or 0
                        end
                    end
                end
            end
        end

        if not ctx.cfg.fp_smooth then
            return
        end

        local bobAmount = tonumber(ctx.cfg.fp_bob) or 0.15
        local bobSpeed = 2
        local t = tick()
        local bob = Vector3.new(
            math.sin(t * bobSpeed) * bobAmount,
            math.abs(math.cos(t * bobSpeed)) * bobAmount * 0.6,
            0
        )
        local shake = Vector3.new(
            (math.random() * 2 - 1) * shakePower,
            (math.random() * 2 - 1) * shakePower,
            (math.random() * 2 - 1) * shakePower
        )
        shakePower = math.max(shakePower - 5 * (dt or 0.016), 0)

        local headRelative = hrp.CFrame:ToObjectSpace(head.CFrame).Position
        local baseY = tonumber(ctx.cfg.fp_offset_y) or -1.5
        local baseZ = tonumber(ctx.cfg.fp_offset_z) or -1
        humanoid.CameraOffset = headRelative + Vector3.new(0, baseY, baseZ) + bob + shake
    end

    ctx.addSetting("fp_smooth", false, function(value)
        if value then
            ctx.startLoop("fpsmooth", 0, firstPersonStep)
        else
            ctx.stopLoop("fpsmooth")
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.CameraOffset = Vector3.zero
            end
        end
    end)
    ctx.addSetting("fp_hide_head", true)
    ctx.addSetting("fp_bob", 0.15)
    ctx.addSetting("fp_offset_y", -1.5)
    ctx.addSetting("fp_offset_z", -1)

    -- light shake hooks when FP is on
    ctx.onCharacter(function(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthChanged:Connect(function(health)
                if ctx.cfg.fp_smooth and health < humanoid.MaxHealth then
                    shakePower += 0.5
                end
            end)
            humanoid.StateChanged:Connect(function(_, state)
                if ctx.cfg.fp_smooth and state == Enum.HumanoidStateType.Landed then
                    shakePower += 0.7
                end
            end)
        end
    end)

    ctx.onUnload(function()
        restoreProps(savedLight)
        restoreProps(savedFog)
        ctx.stopLoop("fpsmooth")
    end)
end

function M.Build(tab, ctx, data)
    local ui = ctx.ui
    ui.section(tab, "sec_lighting", "Lucide:sun")
    ui.toggle(tab, "fullbright", "Lucide:sun")
    ui.toggle(tab, "no_fog", "Lucide:cloud")

    ui.section(tab, "sec_camera", "Lucide:camera")
    ui.toggle(tab, "fov_on", "Lucide:scan")
    ui.slider(tab, "fov", 40, 120, 1, "Lucide:scan")
    ui.toggle(tab, "third_person", "Lucide:camera")
    ui.slider(tab, "third_person_dist", 2, 60, 1, "Lucide:ruler", " studs")

    ui.section(tab, "sec_firstperson", "Lucide:scan-eye")
    ui.toggle(tab, "fp_smooth", "Lucide:scan-eye")
    ui.toggle(tab, "fp_hide_head", "Lucide:user")
    ui.slider(tab, "fp_bob", 0, 0.5, 0.05, "Lucide:waves")
    ui.slider(tab, "fp_offset_y", -3, 1, 0.1, "Lucide:move-vertical")
    ui.slider(tab, "fp_offset_z", -3, 1, 0.1, "Lucide:move-horizontal")
end

return M
