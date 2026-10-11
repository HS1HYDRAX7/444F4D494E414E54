local features = {}

features["player"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildPlayer(tab, H)
    end
    return M
end)()

features["auto"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildAutomation(tab, H)
    end
    return M
end)()

features["combat"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildCombat(tab, H)
    end
    return M
end)()

features["visuals"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildVisuals(tab, H)
    end
    return M
end)()

features["world"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildWorld(tab, H)
    end
    return M
end)()

-- Skin changer (Fun tab). Each skin is a folder under Assets.Skins.Killers or Assets.Skins.Survivors.
-- Only the skin's visual is applied (accessories, shirt, pants, face and body colors), using the same
-- logic as the avatar editor. Animations inside a skin are never read or applied. Guest 666 is skipped.
local SkinChanger = (function()
    local Skins = {}

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local ORIGINAL_KEY = "skin_original"
    local GUEST_MARK = "666"
    local OWNED = "DominantSkin"
    local CATEGORIES = { "Killers", "Survivors" }
    local CARDS = {
        Killers = { label = "skin_killer", describe = "skin_killer_d", icon = "Lucide:skull" },
        Survivors = { label = "skin_survivor", describe = "skin_survivor_d", icon = "Lucide:user" },
    }
    local BLOCK_NOTICE = {
        Killers = "skin_block_killer",
        Survivors = "skin_block_survivor",
    }
    local BODY_PARTS = { "HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3" }
    -- Accessory types that can only be worn once; a new one replaces the old one (same as the avatar editor).
    local SINGLE_SLOT = { Hair = true, Face = true, Neck = true, Shoulder = true, Front = true, Back = true, Waist = true }

    local STRINGS = {
        en = {
            sec_skins = "Skins",
            skin_killer = "Killer skin",
            skin_killer_d = "Changes the killer's look (accessories, clothes, face and colors)",
            skin_survivor = "Survivor skin",
            skin_survivor_d = "Changes the survivor's look (accessories, clothes, face and colors)",
            skin_original = "Original",
            skin_block_killer = "Set the killer skin to Original first to use a survivor skin",
            skin_block_survivor = "Set the survivor skin to Original first to use a killer skin",
        },
        pt = {
            sec_skins = "Skins",
            skin_killer = "Skin de killer",
            skin_killer_d = "Muda a aparência do killer (acessórios, roupas, rosto e cores)",
            skin_survivor = "Skin de sobrevivente",
            skin_survivor_d = "Muda a aparência do sobrevivente (acessórios, roupas, rosto e cores)",
            skin_original = "Original",
            skin_block_killer = "Desative a skin de killer (deixe em Original) para usar uma skin de sobrevivente",
            skin_block_survivor = "Desative a skin de sobrevivente (deixe em Original) para usar uma skin de killer",
        },
        es = {
            sec_skins = "Skins",
            skin_killer = "Skin de asesino",
            skin_killer_d = "Cambia la apariencia del asesino (accesorios, ropa, cara y colores)",
            skin_survivor = "Skin de superviviente",
            skin_survivor_d = "Cambia la apariencia del superviviente (accesorios, ropa, cara y colores)",
            skin_original = "Original",
            skin_block_killer = "Pon primero la skin de asesino en Original para usar una skin de superviviente",
            skin_block_survivor = "Pon primero la skin de superviviente en Original para usar una skin de asesino",
        },
        ru = {
            sec_skins = "Скины",
            skin_killer = "Скин убийцы",
            skin_killer_d = "Меняет внешность убийцы (аксессуары, одежда, лицо и цвета)",
            skin_survivor = "Скин выжившего",
            skin_survivor_d = "Меняет внешность выжившего (аксессуары, одежда, лицо и цвета)",
            skin_original = "Оригинал",
            skin_block_killer = "Сначала поставьте скин убийцы на Оригинал, чтобы использовать скин выжившего",
            skin_block_survivor = "Сначала поставьте скин выжившего на Оригинал, чтобы использовать скин убийцы",
        },
    }

    local Dominant, L, tabRef
    local hooked = false
    local lists = { Killers = {}, Survivors = {} }
    local selected = { Killers = nil, Survivors = nil }
    local cards = {}
    local snapshot, snapshotChar = nil, nil
    local addCard

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

    local function typeName(accessory)
        return (tostring(accessory.AccessoryType):gsub("^.*%.", ""))
    end

    -- True when the object lives inside an "Animations" folder under root. Those are never used.
    local function insideAnimations(object, root)
        local node = object.Parent
        while node and node ~= root do
            if node.Name == "Animations" then
                return true
            end
            node = node.Parent
        end
        return false
    end

    local function isGuest(folder, source)
        return string.find(folder.Name, GUEST_MARK, 1, true) ~= nil
            or string.find(source.Name, GUEST_MARK, 1, true) ~= nil
    end

    -- The model that holds the skin's look. A folder without a model is read directly.
    local function findSource(folder)
        if folder:IsA("Model") then
            return folder
        end
        for _, object in ipairs(folder:GetDescendants()) do
            if object:IsA("Model") and not insideAnimations(object, folder) then
                return object
            end
        end
        return folder
    end

    local function readVisual(source)
        local visual = { accessories = {}, colors = nil, shirt = nil, pants = nil, face = nil }
        for _, object in ipairs(source:GetDescendants()) do
            if object:IsA("Accessory") and not insideAnimations(object, source) and object:FindFirstChild("Handle") then
                table.insert(visual.accessories, object)
            end
        end
        local shirt = source:FindFirstChildWhichIsA("Shirt", true)
        if shirt and not insideAnimations(shirt, source) and shirt.ShirtTemplate ~= "" then
            visual.shirt = shirt.ShirtTemplate
        end
        local pants = source:FindFirstChildWhichIsA("Pants", true)
        if pants and not insideAnimations(pants, source) and pants.PantsTemplate ~= "" then
            visual.pants = pants.PantsTemplate
        end
        local head = source:FindFirstChild("Head", true)
        local face = head and head:FindFirstChild("face")
        if face and face:IsA("Decal") and face.Texture ~= "" then
            visual.face = face.Texture
        end
        local bc = source:FindFirstChildWhichIsA("BodyColors", true)
        if bc and not insideAnimations(bc, source) then
            visual.colors = {}
            for _, prop in ipairs(BODY_PARTS) do
                local ok, color = pcall(function()
                    return bc[prop]
                end)
                if ok and color ~= nil then
                    visual.colors[prop] = color
                end
            end
        end
        return visual
    end

    local function hasVisual(visual)
        return #visual.accessories > 0 or visual.shirt ~= nil or visual.pants ~= nil or visual.face ~= nil or visual.colors ~= nil
    end

    local function scan(folder)
        local list = {}
        if not folder then
            return list
        end
        for _, child in ipairs(folder:GetChildren()) do
            local source = findSource(child)
            if not isGuest(child, source) then
                local visual = readVisual(source)
                if hasVisual(visual) then
                    table.insert(list, { name = child.Name, visual = visual })
                end
            end
        end
        table.sort(list, function(a, b)
            return a.name < b.name
        end)
        return list
    end

    local function entryNamed(category, name)
        for _, entry in ipairs(lists[category]) do
            if entry.name == name then
                return entry
            end
        end
        return nil
    end

    local function activeEntry()
        return selected.Killers or selected.Survivors
    end

    local function stripWelds(object)
        for _, descendant in ipairs(object:GetDescendants()) do
            if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
                descendant:Destroy()
            end
        end
    end

    -- Attachment logic copied from the avatar editor: the accessory's Handle is welded to the
    -- matching body part, falling back to the head or torso.
    local function findCharAttachment(char, name)
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local att = part:FindFirstChild(name)
                if att and att:IsA("Attachment") then
                    return att
                end
            end
        end
        return nil
    end

    local function fallbackPart(char, attachmentName)
        local name = attachmentName:lower()
        if name:find("shoulder") or name:find("back") or name:find("front") or name:find("waist") then
            return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        end
        return char:FindFirstChild("Head") or char:FindFirstChild("Torso")
    end

    local function attachAccessory(char, accessory)
        local handle = accessory:FindFirstChild("Handle")
        if not handle then
            return false
        end
        handle.Anchored = false
        handle.CanCollide = false
        handle.CanTouch = false
        handle.CanQuery = false
        handle.Massless = true

        local handleAt, charAt
        for _, att in ipairs(handle:GetChildren()) do
            if att:IsA("Attachment") then
                local match = findCharAttachment(char, att.Name)
                if match then
                    handleAt, charAt = att, match
                    break
                end
            end
        end

        local part
        if handleAt then
            part = charAt.Parent
            handle.CFrame = charAt.WorldCFrame * handleAt.CFrame:Inverse()
        else
            local firstAt = handle:FindFirstChildWhichIsA("Attachment")
            part = fallbackPart(char, firstAt and firstAt.Name or "")
            if part then
                handle.CFrame = part.CFrame
            end
        end
        if not part or not part:IsA("BasePart") then
            return false
        end

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = part
        weld.Parent = handle

        for _, desc in ipairs(accessory:GetDescendants()) do
            if desc:IsA("BasePart") and desc ~= handle then
                desc.CanCollide = false
                desc.CanTouch = false
                desc.CanQuery = false
                desc.Massless = true
                local w = Instance.new("WeldConstraint")
                w.Part0 = desc
                w.Part1 = handle
                w.Parent = desc
            end
        end

        accessory.Parent = char
        return true
    end

    -- Waits until the character's accessories stop changing, so the snapshot is the real original look.
    local function waitForAppearance(char)
        char:WaitForChild("Humanoid", 10)
        local last, stable, start = -1, 0, os.clock()
        while stable < 0.6 and os.clock() - start < 6 do
            local count = 0
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Accessory") then
                    count = count + 1
                end
            end
            if count == last then
                stable = stable + 0.1
            else
                stable, last = 0, count
            end
            task.wait(0.1)
        end
    end

    -- The player's look before any skin. Skin pieces are skipped so they never end up in the snapshot.
    local function takeSnapshot(char)
        local snap = { accessories = {}, shirt = nil, pants = nil, face = nil, colors = nil }
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Accessory") and not child:GetAttribute(OWNED) then
                local copy = child:Clone()
                stripWelds(copy)
                table.insert(snap.accessories, copy)
            end
        end
        local shirt = char:FindFirstChildOfClass("Shirt")
        snap.shirt = shirt and shirt.ShirtTemplate or nil
        local pants = char:FindFirstChildOfClass("Pants")
        snap.pants = pants and pants.PantsTemplate or nil
        local head = char:FindFirstChild("Head")
        local face = head and head:FindFirstChild("face")
        snap.face = face and face.Texture or nil
        local bc = char:FindFirstChildOfClass("BodyColors")
        if bc then
            snap.colors = {}
            for _, prop in ipairs(BODY_PARTS) do
                local ok, color = pcall(function()
                    return bc[prop]
                end)
                if ok and color ~= nil then
                    snap.colors[prop] = color
                end
            end
        end
        return snap
    end

    local function ensureSnapshot(char)
        if snapshot and snapshotChar == char then
            return snapshot
        end
        waitForAppearance(char)
        snapshot = takeSnapshot(char)
        snapshotChar = char
        return snapshot
    end

    -- Puts the character back to the snapshot: removes skin pieces, re-adds originals that a skin replaced,
    -- and restores colors, shirt, pants and face.
    local function restoreSnapshot(char, snap)
        for _, child in ipairs(char:GetChildren()) do
            if child:GetAttribute(OWNED) then
                child:Destroy()
            end
        end
        for _, original in ipairs(snap.accessories) do
            local kind = typeName(original)
            local present = false
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Accessory") and child.Name == original.Name and typeName(child) == kind then
                    present = true
                    break
                end
            end
            if not present then
                local copy = original:Clone()
                stripWelds(copy)
                local ok, attached = pcall(attachAccessory, char, copy)
                if not (ok and attached) then
                    copy:Destroy()
                end
            end
        end
        if snap.colors then
            local bc = char:FindFirstChildOfClass("BodyColors")
            if bc then
                for prop, color in pairs(snap.colors) do
                    pcall(function()
                        bc[prop] = color
                    end)
                end
            end
        end
        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt and snap.shirt ~= nil then
            shirt.ShirtTemplate = snap.shirt
        end
        local pants = char:FindFirstChildOfClass("Pants")
        if pants and snap.pants ~= nil then
            pants.PantsTemplate = snap.pants
        end
        local head = char:FindFirstChild("Head")
        local face = head and head:FindFirstChild("face")
        if face and snap.face ~= nil then
            face.Texture = snap.face
        end
    end

    local function removeSlot(char, kind, except)
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Accessory") and child ~= except and typeName(child) == kind then
                child:Destroy()
            end
        end
    end

    local function ownedClothing(char, className)
        local item = char:FindFirstChildOfClass(className)
        if not item then
            item = Instance.new(className)
            item:SetAttribute(OWNED, true)
            item.Parent = char
        end
        return item
    end

    local function applyVisual(char, visual)
        local bc = char:FindFirstChildOfClass("BodyColors")
        if bc and visual.colors then
            for prop, color in pairs(visual.colors) do
                pcall(function()
                    bc[prop] = color
                end)
            end
        end
        if visual.shirt then
            ownedClothing(char, "Shirt").ShirtTemplate = visual.shirt
        end
        if visual.pants then
            ownedClothing(char, "Pants").PantsTemplate = visual.pants
        end
        if visual.face then
            local head = char:FindFirstChild("Head")
            local face = head and head:FindFirstChild("face")
            if face then
                face.Texture = visual.face
            end
        end
        for _, template in ipairs(visual.accessories) do
            local accessory = template:Clone()
            stripWelds(accessory)
            accessory:SetAttribute(OWNED, true)
            local kind = typeName(accessory)
            local ok, attached = pcall(attachAccessory, char, accessory)
            if ok and attached then
                if SINGLE_SLOT[kind] then
                    removeSlot(char, kind, accessory)
                end
            else
                accessory:Destroy()
            end
        end
    end

    local function applySelected()
        local char = LocalPlayer.Character
        if not char then
            return
        end
        task.spawn(function()
            local snap = ensureSnapshot(char)
            restoreSnapshot(char, snap)
            local entry = activeEntry()
            if entry then
                applyVisual(char, entry.visual)
            end
        end)
    end

    local function onCharacter(char)
        snapshot, snapshotChar = nil, nil
        if activeEntry() then
            task.spawn(function()
                ensureSnapshot(char)
                applySelected()
            end)
        end
    end

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
            selected[category] = nil
        elseif selected[other] then
            Dominant.Notify(L(BLOCK_NOTICE[other]), "warning", 4)
            rebuildCards()
            return
        else
            local entry = entryNamed(category, value)
            if not entry then
                return
            end
            selected[category] = entry
        end
        applySelected()
    end

    addCard = function(category)
        local spec = CARDS[category]
        local original = L(ORIGINAL_KEY)
        local choices = { original }
        for _, entry in ipairs(lists[category]) do
            table.insert(choices, entry.name)
        end
        local current = selected[category] and selected[category].name or original
        cards[category] = tabRef:AddDropdown({
            Text = L(spec.label),
            Description = L(spec.describe),
            Icon = spec.icon,
            Options = choices,
            Default = current,
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

        local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
        local skinRoot = assets and assets:FindFirstChild("Skins")
        for _, category in ipairs(CATEGORIES) do
            lists[category] = scan(skinRoot and skinRoot:FindFirstChild(category))
        end

        if not hooked then
            hooked = true
            Dominant.OnCharacter(onCharacter)
        end

        helpers.Section(tab, "sec_skins", "Lucide:sparkles")
        addCard("Killers")
        addCard("Survivors")
    end

    return Skins
end)()

features["fun"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        -- Skins go first, so the section sits at the top of the tab, right above the animation changer.
        local ok, err = pcall(SkinChanger.Build, tab, H, core)
        if not ok then
            core.Dominant.Notify("Skins failed: " .. tostring(err), "error", 8)
        end
        core.UI.BuildFun(tab, H)
    end
    return M
end)()

features["misc"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildMisc(tab, H)
            core.ctx.modules:require("shared/features/scripts").Build(tab, core.ctx)
    end
    return M
end)()

features["debug"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildDebug(tab, H)
    end
    return M
end)()

features["settings"] = (function()
    local M = {}
    function M.Build(tab, H, core, window)
        core.UI.BuildSettings(window, tab, H)
    end
    return M
end)()

return features
