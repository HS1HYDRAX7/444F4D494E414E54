-- Skin changer for Forsaken: one dropdown for killer skins and one for survivor skins.
-- Like the animation changer, a skin swaps the idle, walk and run animations.
-- Guest 666 is allowed (animations work on his model).
-- Only one skin can be active at a time. Picking a skin in the other category shows a
-- notice and puts both dropdowns back in sync with the active skin.

local Skins = {}

local ORIGINAL_KEY = "skin_original"
local GUEST_MARK = "666"
local CATEGORIES = { "Killers", "Survivors" }
local CARDS = {
    Killers = { label = "skin_killer", describe = "skin_killer_d", icon = "Lucide:skull" },
    Survivors = { label = "skin_survivor", describe = "skin_survivor_d", icon = "Lucide:user" },
}
-- Shown when the player tries to use a skin from one category while the other one is active.
local BLOCK_NOTICE = {
    Killers = "skin_block_killer",
    Survivors = "skin_block_survivor",
}

local STRINGS = {
    en = {
        sec_skins = "Skins",
        skin_killer = "Killer skin",
        skin_killer_d = "Changes the killer's idle, walk and run animations",
        skin_survivor = "Survivor skin",
        skin_survivor_d = "Changes the survivor's idle, walk and run animations",
        skin_original = "Original",
        skin_block_killer = "Set the killer skin to Original first to use a survivor skin",
        skin_block_survivor = "Set the survivor skin to Original first to use a killer skin",
    },
    pt = {
        sec_skins = "Skins",
        skin_killer = "Skin de killer",
        skin_killer_d = "Troca as animações de parado, andar e correr do killer",
        skin_survivor = "Skin de sobrevivente",
        skin_survivor_d = "Troca as animações de parado, andar e correr do sobrevivente",
        skin_original = "Original",
        skin_block_killer = "Desative a skin de killer (deixe em Original) para usar uma skin de sobrevivente",
        skin_block_survivor = "Desative a skin de sobrevivente (deixe em Original) para usar uma skin de killer",
    },
    es = {
        sec_skins = "Skins",
        skin_killer = "Skin de asesino",
        skin_killer_d = "Cambia las animaciones de reposo, caminar y correr del asesino",
        skin_survivor = "Skin de superviviente",
        skin_survivor_d = "Cambia las animaciones de reposo, caminar y correr del superviviente",
        skin_original = "Original",
        skin_block_killer = "Pon primero la skin de asesino en Original para usar una skin de superviviente",
        skin_block_survivor = "Pon primero la skin de superviviente en Original para usar una skin de asesino",
    },
    ru = {
        sec_skins = "Скины",
        skin_killer = "Скин убийцы",
        skin_killer_d = "Меняет анимации покоя, ходьбы и бега убийцы",
        skin_survivor = "Скин выжившего",
        skin_survivor_d = "Меняет анимации покоя, ходьбы и бега выжившего",
        skin_original = "Оригинал",
        skin_block_killer = "Сначала поставьте скин убийцы на Оригинал, чтобы использовать скин выжившего",
        skin_block_survivor = "Сначала поставьте скин выжившего на Оригинал, чтобы использовать скин убийцы",
    },
}

local Dominant = nil
local L = nil
local tabRef = nil
local hooked = false

local state = { Killers = nil, Survivors = nil }
local sets = { Killers = {}, Survivors = {} }
local names = { Killers = {}, Survivors = {} }
local index = {}
local cache = {}
local cards = {}

local function registerStrings(dominant)
    for code, pack in pairs(STRINGS) do
        dominant.Strings[code] = dominant.Strings[code] or {}
        for key, text in pairs(pack) do
            if dominant.Strings[code][key] == nil then
                dominant.Strings[code][key] = text
            end
        end
    end
end

local function digits(id)
    return tostring(id or ""):match("%d+")
end

-- Guest 666 animations enabled (user confirmed the model works with overrides).
local function isGuest(node, root, displayName)
    return false
end

local function scan(folder, category)
    sets[category] = {}
    names[category] = {}
    if not folder then
        return
    end
    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("ModuleScript") and object.Name == "Config" and object.Parent and not object.Parent:IsA("Model") then
            local ok, data = pcall(require, object)
            local animations = ok and type(data) == "table" and data.Animations
            if type(animations) == "table" then
                local rawName = (type(data.DisplayName) == "string" and data.DisplayName) or object.Parent.Name
                -- Partial sets OK: Guest 666 often has a single shared animation id.
                local idle = digits(animations.Idle or animations.idle)
                local walk = digits(animations.Walk or animations.walk or animations.Moving)
                local run = digits(animations.Run or animations.run or animations.Sprint)
                local any = idle or walk or run or digits(animations.Animation) or digits(animations.Default)
                if not any then
                    local parent = object.Parent
                    if parent then
                        for _, inst in ipairs(parent:GetDescendants()) do
                            if inst:IsA("Animation") then
                                any = digits(inst.AnimationId)
                                if any then
                                    break
                                end
                            end
                        end
                    end
                end
                if any then
                    idle = idle or any
                    walk = walk or any
                    run = run or walk or any
                    local name = rawName
                    if tostring(name):find("Milestone") and object.Parent and object.Parent.Parent then
                        name = object.Parent.Parent.Name .. " " .. (tostring(name):gsub("Milestone ", ""))
                    end
                    if not sets[category][name] then
                        sets[category][name] = { Idle = idle, Walk = walk, Run = run }
                        table.insert(names[category], name)
                        index[idle] = "Idle"
                        index[walk] = "Walk"
                        index[run] = "Run"
                    end
                end
            end
        end
    end
    table.sort(names[category])
end

local function activeCategory()
    if state.Killers then
        return "Killers"
    end
    if state.Survivors then
        return "Survivors"
    end
    return nil
end

local function activeSet()
    local category = activeCategory()
    if not category then
        return nil
    end
    return sets[category][state[category]]
end

local function stopOverrides()
    for id, track in pairs(cache) do
        pcall(function()
            track:Stop(0.2)
        end)
        cache[id] = nil
    end
end

local function trackFor(animator, id)
    local cached = cache[id]
    if cached then
        return cached
    end
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. id
    animation:SetAttribute("DominantSkinOverride", true)
    local ok, loaded = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if ok and loaded then
        loaded.Looped = true
        loaded.Priority = Enum.AnimationPriority.Movement
        cache[id] = loaded
        return loaded
    end
    return nil
end

function Skins.Step()
    local set = activeSet()
    local animator = Dominant.State.Animator
    local humanoid = Dominant.State.Humanoid
    if not set or not animator or not humanoid or not animator.Parent then
        return
    end
    local sprint = Dominant.Objects.sprintModule
    local kind = "Idle"
    if humanoid.MoveDirection ~= Vector3.zero then
        kind = (sprint and sprint.IsSprinting) and "Run" or "Walk"
    end
    local wanted = set[kind]
    if not wanted then
        return
    end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local animation = track.Animation
        local id = animation and digits(animation.AnimationId)
        if animation and animation:GetAttribute("DominantSkinOverride") then
            if id ~= wanted then
                track:Stop(0.2)
            end
        elseif id and index[id] then
            track:Stop(0.2)
        end
    end
    local override = trackFor(animator, wanted)
    if override and not override.IsPlaying then
        override:Play(0.15)
    end
end

local function applyState()
    if activeCategory() then
        Dominant.StartLoop("skinchanger", 0.1, Skins.Step)
    else
        Dominant.StopLoop("skinchanger")
        stopOverrides()
    end
end

local addCard

local function rebuildCards()
    for _, category in ipairs(CATEGORIES) do
        local card = cards[category]
        cards[category] = nil
        if card then
            pcall(function()
                card:Destroy()
            end)
        end
    end
    for _, category in ipairs(CATEGORIES) do
        addCard(category)
    end
end

local function selectSkin(category, value)
    local original = L(ORIGINAL_KEY)
    local other = category == "Killers" and "Survivors" or "Killers"
    if value == nil or value == original then
        state[category] = nil
    elseif state[other] then
        Dominant.Notify(L(BLOCK_NOTICE[other]), "warning", 4)
        rebuildCards()
        return
    else
        state[category] = value
    end
    applyState()
end

addCard = function(category)
    local spec = CARDS[category]
    local original = L(ORIGINAL_KEY)
    local choices = { original }
    for _, name in ipairs(names[category]) do
        table.insert(choices, name)
    end
    cards[category] = tabRef:AddDropdown({
        Text = L(spec.label),
        Description = L(spec.describe),
        Icon = spec.icon,
        Options = choices,
        Default = state[category] or original,
        Callback = function(value)
            if type(value) == "table" then
                value = value[1]
            end
            selectSkin(category, value)
        end,
    })
end

function Skins.Build(tab, helpers, core)
    Dominant = core.Dominant
    L = core.L
    tabRef = tab
    cards = {}
    registerStrings(Dominant)

    index = {}
    local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
    local skins = assets and assets:FindFirstChild("Skins")
    for _, category in ipairs(CATEGORIES) do
        if Dominant.Caps.require then
            scan(skins and skins:FindFirstChild(category), category)
        else
            sets[category] = {}
            names[category] = {}
        end
    end

    if not hooked then
        hooked = true
        Dominant.OnCharacter(function()
            cache = {}
        end)
    end

    helpers.Section(tab, "sec_skins", "Lucide:sparkles")
    addCard("Killers")
    addCard("Survivors")
    applyState()
end

return Skins
