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

-- Skin changer (Fun tab). Hybrid overlay:
--   * skins with Config.Animations (and John Doe) use root weld + own Idle/Walk/Run
--   * every other skin uses limb weld so the player's animations drive the look
-- Props (skate, ExtraModels) are stripped; 1x1x1x1 swords are kept. Premade removed. Guest 666 skipped.
local SkinChanger = (function()
    local Skins = {}

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local ORIGINAL_KEY = "skin_original"
    local GUEST_MARK = "666"
    local OWNED = "DominantSkin"
    local APPLIED = "DominantSkinApplied"
    local CATEGORIES = { "Killers", "Survivors" }
    local CARDS = {
        Killers = { label = "skin_killer", describe = "skin_killer_d", icon = "Lucide:skull" },
        Survivors = { label = "skin_survivor", describe = "skin_survivor_d", icon = "Lucide:user" },
    }
    local NO_PARTS_NOTICE = "skin_no_parts"
    local BLOCK_NOTICE = {
        Killers = "skin_block_killer",
        Survivors = "skin_block_survivor",
    }
    local BODY_PARTS = { "HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3" }
    -- Accessory types that can only be worn once; a new one replaces the old one (same as the avatar editor).
    local OVERLAY_PARTS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
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

    local EXTRA_STRINGS = {
        en = { skin_missing_parts = "Body parts not matched: %s", skin_no_parts = "This skin has no parts that match your character", skin_keep_items = "Keep my items", skin_keep_items_d = "Keeps your accessories on while a skin is active" },
        pt = { skin_missing_parts = "Partes do corpo sem encaixe: %s", skin_no_parts = "Esta skin não tem partes compatíveis com o seu personagem", skin_keep_items = "Manter meus itens", skin_keep_items_d = "Mantém seus acessórios enquanto uma skin estiver ativa" },
        es = { skin_missing_parts = "Partes del cuerpo sin encaje: %s", skin_no_parts = "Esta skin no tiene partes compatibles con tu personaje", skin_keep_items = "Mantener mis objetos", skin_keep_items_d = "Mantiene tus accesorios mientras una skin esté activa" },
        ru = { skin_missing_parts = "Части тела без совпадения: %s", skin_no_parts = "У этого скина нет частей, совместимых с вашим персонажем", skin_keep_items = "Оставить мои предметы", skin_keep_items_d = "Сохраняет ваши аксессуары, пока скин активен" },
    }



    local Dominant, L, tabRef
    local hooked = false
    local lists = { Killers = {}, Survivors = {} }
    local selected = { Killers = nil, Survivors = nil }
    local cards = {}
    local snapshot, snapshotChar = nil, nil
    local hiddenParts = {}
    local lastMissing = {}
    local MISSING_KEY = "skin_missing_parts"
    local keepItems = true
    local KEEP_ITEMS_KEY = "skin_keep_items"
    local addCard

    local function registerStrings(dominant)
        for _, source in ipairs({ STRINGS, EXTRA_STRINGS }) do
            for code, pack in pairs(source) do
                dominant.Strings[code] = dominant.Strings[code] or {}
                for key, text in pairs(pack) do
                    if dominant.Strings[code][key] == nil then
                        dominant.Strings[code][key] = text
                    end
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

    -- Body part names used by different skins (the 1x1x1x1 skins use leftA, leftL, rightA, rightL...).
    -- Names are compared without case, spaces, underscores or dashes.
    local LIMB_ALIASES = {
        ["Head"] = { "head" },
        ["Torso"] = { "torso", "uppertorso" },
        ["Left Arm"] = { "leftarm", "lefta", "larm", "leftupperarm" },
        ["Right Arm"] = { "rightarm", "righta", "rarm", "rightupperarm" },
        ["Left Leg"] = { "leftleg", "leftl", "lleg", "leftlowerleg" },
        ["Right Leg"] = { "rightleg", "rightl", "rleg", "rightlowerleg" },
    }
    local LIMB_NAMES = { "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

    local function aliasMatches(name, charName)
        local key = string.lower(tostring(name)):gsub("[%s_%-]", "")
        if key == string.lower(charName):gsub("[%s_%-]", "") then
            return true
        end
        for _, alias in ipairs(LIMB_ALIASES[charName] or {}) do
            if key == alias then
                return true
            end
        end
        return false
    end

    local function isLimbName(name)
        for _, limb in ipairs(LIMB_NAMES) do
            if aliasMatches(name, limb) then
                return true
            end
        end
        return false
    end

    -- A body part of a rig: its direct children first, then anywhere under the rig
    local function findLimb(rig, charName)
        for _, child in ipairs(rig:GetChildren()) do
            if child:IsA("BasePart") and aliasMatches(child.Name, charName) then
                return child
            end
        end
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("BasePart") and aliasMatches(desc.Name, charName) then
                return desc
            end
        end
        return nil
    end

    -- A Model whose own children include a torso and at least one limb. This is the body; a loose Head next to it is not.
    local function hasBodyParts(model)
        local torso = false
        local limbs = 0
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("BasePart") then
                if aliasMatches(child.Name, "Torso") then
                    torso = true
                end
                if isLimbName(child.Name) then
                    limbs = limbs + 1
                end
            end
        end
        return torso or limbs >= 2
    end

    -- Models/folders that must never ride the body overlay (props, cameras, emotes...).
    -- ExtraModels often holds skateboards etc. Whitelist keeps known weapon visuals (1x1x1x1 swords).
    local NOT_THE_BODY = {
        Config = true, Behavior = true, ExtraModels = true, CameraRig = true,
        VictoryCameraRig = true, Animations = true, Emotes = true, Sounds = true,
    }
    local PROP_NAMES = {
        skate = true, skateboard = true, board = true, hoverboard = true,
        vehicle = true, bike = true, car = true, camera = true,
    }
    local KEEP_EXTRA = {
        haxxedswordleft = true, haxxedswordright = true,
        swordleft = true, swordright = true, sword = true,
    }

    local function insideNotBody(object, root)
        local node = object.Parent
        while node and node ~= root do
            if NOT_THE_BODY[node.Name] then
                return true
            end
            node = node.Parent
        end
        return false
    end

    -- Two objects are related when one is the other or sits inside it
    local function isRelated(a, b)
        local node = a
        while node do
            if node == b then
                return true
            end
            node = node.Parent
        end
        node = b
        while node do
            if node == a then
                return true
            end
            node = node.Parent
        end
        return false
    end

    local function bodyGroupOf(object)
        local candidates = {}
        if object:IsA("Model") and hasBodyParts(object) then
            table.insert(candidates, object)
        end
        for _, desc in ipairs(object:GetDescendants()) do
            if desc:IsA("Model") and not insideAnimations(desc, object) and not insideNotBody(desc, object) and hasBodyParts(desc) then
                table.insert(candidates, desc)
            end
        end
        local best, bestScore = nil, nil
        for _, model in ipairs(candidates) do
            local depth = 0
            local node = model.Parent
            while node and node ~= object do
                depth = depth + 1
                node = node.Parent
            end
            -- a model named Rig wins, then the shallowest one
            local score = (model.Name == "Rig" and 0 or 1000) + depth
            if best == nil or score < bestScore then
                best, bestScore = model, score
            end
        end
        return best
    end

    -- The skin's own animations, from its Config module (Animations: Idle, Walk, Run)
    local function animationsOf(source)
        if not (Dominant.Caps and Dominant.Caps.require) then
            return nil
        end
        for _, object in ipairs(source:GetDescendants()) do
            if object:IsA("ModuleScript") and object.Name == "Config" and not insideAnimations(object, source) then
                local ok, data = pcall(require, object)
                if ok and type(data) == "table" and type(data.Animations) == "table" then
                    local set = data.Animations
                    local idle, walk, run = tostring(set.Idle or ""):match("%d+"), tostring(set.Walk or ""):match("%d+"), tostring(set.Run or ""):match("%d+")
                    if idle and walk and run then
                        return { Idle = idle, Walk = walk, Run = run }
                    end
                end
            end
        end
        return nil
    end

    -- For a skin accessory: the rig part it is welded to in the skin, and its position relative to that part.
    -- Using this keeps the accessory where the skin puts it, instead of guessing from attachment names.
    local function anchorFor(accessory, source)
        local handle = accessory:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then
            return nil
        end
        local partner = nil
        for _, joint in ipairs(source:GetDescendants()) do
            if joint:IsA("WeldConstraint") or joint:IsA("Weld") then
                local other = nil
                if joint.Part0 == handle then
                    other = joint.Part1
                elseif joint.Part1 == handle then
                    other = joint.Part0
                end
                if other and other:IsA("BasePart") and other ~= handle then
                    local inside = false
                    local node = other.Parent
                    while node and node ~= source do
                        if node == accessory then
                            inside = true
                            break
                        end
                        node = node.Parent
                    end
                    if not inside then
                        partner = other
                        break
                    end
                end
            end
        end
        if not partner then
            return nil
        end
        local rels = {}
        for index, desc in ipairs(accessory:GetDescendants()) do
            if desc:IsA("BasePart") and desc ~= handle then
                rels[index] = handle.CFrame:ToObjectSpace(desc.CFrame)
            end
        end
        return { name = partner.Name, offset = partner.CFrame:ToObjectSpace(handle.CFrame), rels = rels }
    end

    local function readVisual(source)
        local visual = { model = source, anims = animationsOf(source), accessories = {}, accessoryAnchors = {}, colors = nil, shirt = nil, pants = nil, face = nil }
        for _, object in ipairs(source:GetDescendants()) do
            if object:IsA("Accessory") and not insideAnimations(object, source) and object:FindFirstChild("Handle") then
                table.insert(visual.accessories, object)
                visual.accessoryAnchors[object] = anchorFor(object, source)
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
        local head = findLimb(bodyGroupOf(source) or source, "Head")
        local face = head and head:FindFirstChild("face")
        if face and face:IsA("Decal") and face.Texture ~= "" then
            visual.face = face.Texture
        end
        local bc = source:FindFirstChildOfClass("BodyColors") or source:FindFirstChildWhichIsA("BodyColors", true)
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
            or #visual.model:GetDescendants() > 0 and visual.model:FindFirstChildWhichIsA("BasePart", true) ~= nil
    end

    -- The Model that holds a skin's look, ignoring anything inside an "Animations" folder.
    local function modelOf(object)
        if object:IsA("Model") then
            return object
        end
        for _, desc in ipairs(object:GetDescendants()) do
            if desc:IsA("Model") and not insideAnimations(desc, object) then
                return desc
            end
        end
        return nil
    end

    local function addSkin(list, name, source)
        local visual = readVisual(source)
        if hasVisual(visual) then
            table.insert(list, { name = name, visual = visual })
        end
    end

    -- Assets.Skins.<Category> holds either one folder per skin, or one folder per killer with a folder per skin
    -- inside. The killer's own base model is never listed as a skin, and Guest 666 is always skipped.
    local function scan(root)
        local list = {}
        if not root then
            return list
        end
        for _, child in ipairs(root:GetChildren()) do
            local subs = {}
            if child:IsA("Folder") then
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("Folder") and bodyGroupOf(sub) then
                        table.insert(subs, sub)
                    end
                end
            end
            if #subs > 0 then
                for _, sub in ipairs(subs) do
                    if not isGuest(child, sub) then
                        addSkin(list, child.Name .. " · " .. sub.Name, sub)
                    end
                end
            elseif bodyGroupOf(child) and not isGuest(child, child) then
                addSkin(list, child.Name, child)
            end
        end
        table.sort(list, function(x, y)
            return x.name < y.name
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
            if part:IsA("BasePart") and not part:GetAttribute(OWNED) then
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
        -- Destroy overlay first so the real body can show again
        for _, child in ipairs(char:GetChildren()) do
            if child:GetAttribute(OWNED) or child.Name == "DominantSkinOverlay" then
                pcall(function() child:Destroy() end)
            end
        end
        for part, value in pairs(hiddenParts) do
            if part and part.Parent then
                pcall(function()
                    part.Transparency = value
                end)
            end
        end
        hiddenParts = {}
        -- Safety: force body parts visible if something was missed
        for _, name in ipairs(OVERLAY_PARTS) do
            local part = char:FindFirstChild(name)
            if part and part:IsA("BasePart") and part.Transparency >= 0.99 then
                part.Transparency = 0
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face")
            if face and face:IsA("Decal") and face.Transparency >= 0.99 then
                face.Transparency = 0
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
                    pcall(function() copy:Destroy() end)
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
        head = char:FindFirstChild("Head")
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

    -- A part is worth copying only if it shows something: a mesh, or a texture/decal on it.
    -- Plain blocks (collision boxes, hitboxes) would show up as white boxes around the character.
    local function isVisualPart(part)
        if not part:IsA("BasePart") or (part.Transparency or 0) >= 0.99 then
            return false
        end
        if part:IsA("MeshPart") then
            return true
        end
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("SpecialMesh") or child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance")
                or child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
                return true
            end
        end
        return false
    end

    local function cleanCopy(copy)
        for _, d in ipairs(copy:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Animator") or d:IsA("AnimationController")
                or d:IsA("Animation") or d:IsA("Motor6D") or d:IsA("Weld") or d:IsA("WeldConstraint") then
                d:Destroy()
            end
        end
    end

    local function insideAccessory(object, root)
        local node = object.Parent
        while node and node ~= root do
            if node:IsA("Accessory") then
                return true
            end
            node = node.Parent
        end
        return false
    end

    local function isJohnSkin(model)
        local n = string.lower(tostring(model and model.Name or ""))
        if n:find("john", 1, true) or n:find("doe", 1, true) then
            return true
        end
        local parent = model and model.Parent
        while parent do
            local pn = string.lower(tostring(parent.Name or ""))
            if pn:find("john", 1, true) or pn:find("doe", 1, true) then
                return true
            end
            parent = parent.Parent
        end
        return false
    end

    -- Drop ExtraModels/props (skate etc.). Keep only whitelisted weapons (1x1x1x1 swords).
    local function stripNonBody(rig, body)
        local toDestroy = {}
        for _, child in ipairs(rig:GetDescendants()) do
            local key = string.lower(tostring(child.Name or "")):gsub("[%s_%-]", "")
            if NOT_THE_BODY[child.Name] then
                if child.Name == "ExtraModels" then
                    for _, extra in ipairs(child:GetChildren()) do
                        local ek = string.lower(tostring(extra.Name or "")):gsub("[%s_%-]", "")
                        if KEEP_EXTRA[ek] and body and body.Parent then
                            extra.Parent = body
                        else
                            table.insert(toDestroy, extra)
                        end
                    end
                    table.insert(toDestroy, child)
                else
                    table.insert(toDestroy, child)
                end
            elseif PROP_NAMES[key] and child ~= body and not isRelated(child, body) then
                table.insert(toDestroy, child)
            end
        end
        for _, obj in ipairs(toDestroy) do
            pcall(function() obj:Destroy() end)
        end
    end

    local function zeroPhysics(parts)
        for _, part in ipairs(parts) do
            if part.Parent then
                part.Anchored = false
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Massless = true
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end
        end
    end

    -- Root weld (features-2 style): whole rig follows one joint. Used when the skin has its own
    -- animations (John Doe, etc.) so spikes/extra limbs stay as one piece and play Config anims.
    local function applyOverlayRoot(char, model)
        local rig = model:Clone()
        rig.Name = "DominantSkinOverlay"
        rig:SetAttribute(OWNED, true)
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("Script") or desc:IsA("LocalScript") then
                desc:Destroy()
            end
        end
        local controller = Instance.new("AnimationController")
        local humanoid = rig:FindFirstChildWhichIsA("Humanoid", true)
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator") or rig:FindFirstChildWhichIsA("Animator", true)
        if not animator then
            animator = Instance.new("Animator")
        end
        animator.Parent = controller
        if humanoid then
            humanoid:Destroy()
        end
        controller.Parent = rig

        local body = bodyGroupOf(rig) or rig
        stripNonBody(rig, body)
        local others = {}
        for _, candidate in ipairs(rig:GetDescendants()) do
            if candidate:IsA("Model") and candidate ~= body and hasBodyParts(candidate) and not isRelated(candidate, body) then
                table.insert(others, candidate)
            end
        end
        for _, other in ipairs(others) do
            other:Destroy()
        end

        local parts = {}
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("BasePart") then
                if not isVisualPart(desc) then
                    desc.Transparency = 1
                end
                table.insert(parts, desc)
            end
        end
        zeroPhysics(parts)

        local found = 0
        lastMissing = {}
        for _, name in ipairs(OVERLAY_PARTS) do
            local skinPart = findLimb(body, name)
            local charPart = char:FindFirstChild(name)
            if skinPart and charPart then
                found = found + 1
            else
                table.insert(lastMissing, name .. (skinPart and "" or " (skin)") .. (charPart and "" or " (player)"))
            end
        end

        local skinTorso = findLimb(body, "Torso")
        local charTorso = char:FindFirstChild("Torso")
        local charRoot = char:FindFirstChild("HumanoidRootPart") or charTorso
        local skinRoot = body:FindFirstChild("HumanoidRootPart", true) or skinTorso
        if not (skinTorso and charTorso and charRoot and skinRoot) then
            return 0
        end

        local move = charTorso.CFrame * skinTorso.CFrame:Inverse()
        for _, part in ipairs(parts) do
            part.CFrame = move * part.CFrame
        end
        -- glue any floating parts to the skin root so nothing falls off
        local links = {}
        for _, joint in ipairs(rig:GetDescendants()) do
            if (joint:IsA("Motor6D") or joint:IsA("Weld") or joint:IsA("WeldConstraint")) and joint.Part0 and joint.Part1 then
                links[joint.Part0] = links[joint.Part0] or {}
                table.insert(links[joint.Part0], joint.Part1)
                links[joint.Part1] = links[joint.Part1] or {}
                table.insert(links[joint.Part1], joint.Part0)
            end
        end
        local reached = { [skinRoot] = true }
        local queue = { skinRoot }
        while #queue > 0 do
            local current = table.remove(queue)
            for _, other in ipairs(links[current] or {}) do
                if not reached[other] then
                    reached[other] = true
                    table.insert(queue, other)
                end
            end
        end
        for _, part in ipairs(parts) do
            if not reached[part] then
                local loose = Instance.new("Weld")
                loose.Part0 = skinRoot
                loose.Part1 = part
                loose.C0 = skinRoot.CFrame:Inverse() * part.CFrame
                loose.Parent = skinRoot
            end
        end
        rig.Parent = char
        local weld = Instance.new("Weld")
        weld.Part0 = charRoot
        weld.Part1 = skinRoot
        weld.C0 = charRoot.CFrame:Inverse() * skinRoot.CFrame
        weld.Parent = skinRoot
        zeroPhysics(parts)
        return found
    end

    -- Limb weld: each body part is pinned to the matching character limb so the player's own
    -- animations drive the look. Used when the skin has no Config animations.
    local function applyOverlayLimbs(char, model)
        local rig = model:Clone()
        rig.Name = "DominantSkinOverlay"
        rig:SetAttribute(OWNED, true)
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Humanoid") or desc:IsA("Animator")
                or desc:IsA("AnimationController") or desc:IsA("Animation") then
                desc:Destroy()
            end
        end
        local hrp = rig:FindFirstChild("HumanoidRootPart", true)
        if hrp then
            hrp:Destroy()
        end

        local body = bodyGroupOf(rig) or rig
        stripNonBody(rig, body)
        local others = {}
        for _, m in ipairs(rig:GetDescendants()) do
            if m:IsA("Model") and m ~= body and hasBodyParts(m) and not isRelated(m, body) then
                table.insert(others, m)
            end
        end
        for _, m in ipairs(others) do
            m:Destroy()
        end

        local bodySet = {}
        for _, name in ipairs(OVERLAY_PARTS) do
            local skinBody = findLimb(body, name)
            if skinBody then
                bodySet[skinBody] = true
            end
        end
        for _, joint in ipairs(rig:GetDescendants()) do
            if joint:IsA("WeldConstraint") or joint:IsA("Weld") or joint:IsA("Motor6D") then
                local first, second = joint.Part0, joint.Part1
                if first and second and bodySet[first] and bodySet[second] then
                    joint:Destroy()
                elseif joint:IsA("Motor6D") and first and second then
                    local weld = Instance.new("Weld")
                    weld.Part0 = first
                    weld.Part1 = second
                    weld.C0 = joint.C0
                    weld.C1 = joint.C1
                    weld.Parent = joint.Parent
                    joint:Destroy()
                end
            end
        end

        local parts = {}
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("BasePart") then
                if not isVisualPart(desc) then
                    desc.Transparency = 1
                end
                table.insert(parts, desc)
            end
        end
        zeroPhysics(parts)

        local skinTorso = findLimb(body, "Torso")
        local charTorso = char:FindFirstChild("Torso")
        local relative = {}
        if skinTorso and skinTorso:IsA("BasePart") then
            for _, part in ipairs(parts) do
                relative[part] = skinTorso.CFrame:ToObjectSpace(part.CFrame)
            end
        end

        local partners = {}
        for _, joint in ipairs(rig:GetDescendants()) do
            if joint:IsA("WeldConstraint") or joint:IsA("Weld") or joint:IsA("Motor6D") then
                local first, second = joint.Part0, joint.Part1
                if first and second then
                    partners[first] = partners[first] or {}
                    table.insert(partners[first], second)
                    partners[second] = partners[second] or {}
                    table.insert(partners[second], first)
                end
            end
        end

        rig.Parent = char
        lastMissing = {}
        local placed = 0
        local reached = {}
        local queue = {}
        for _, name in ipairs(OVERLAY_PARTS) do
            local newPart = findLimb(body, name)
            local oldPart = char:FindFirstChild(name)
            if newPart and oldPart and newPart:IsA("BasePart") and oldPart:IsA("BasePart") then
                newPart.CFrame = oldPart.CFrame
                local weld = Instance.new("Weld")
                weld.Part0 = oldPart
                weld.Part1 = newPart
                weld.C0 = CFrame.new()
                weld.C1 = CFrame.new()
                weld.Parent = newPart
                reached[newPart] = true
                table.insert(queue, newPart)
                placed = placed + 1
            else
                table.insert(lastMissing, name .. (newPart and "" or " (skin)") .. (oldPart and "" or " (player)"))
            end
        end
        while #queue > 0 do
            local current = table.remove(queue, 1)
            for _, other in ipairs(partners[current] or {}) do
                if other:IsA("BasePart") and not reached[other] then
                    reached[other] = true
                    table.insert(queue, other)
                end
            end
        end
        if charTorso and charTorso:IsA("BasePart") then
            for _, part in ipairs(parts) do
                if not reached[part] and relative[part] then
                    part.CFrame = charTorso.CFrame * relative[part]
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = charTorso
                    weld.Part1 = part
                    weld.Parent = part
                end
            end
        end
        zeroPhysics(parts)
        return placed
    end

    -- Hybrid: John Doe / skins with Config.Animations use root weld + own anims (features-2 path).
    -- Everything else uses limb weld so the player animations drive the look (no stiffness).
    local function applyOverlay(char, model, useRoot)
        if not model then
            return 0
        end
        if useRoot or isJohnSkin(model) then
            return applyOverlayRoot(char, model)
        end
        return applyOverlayLimbs(char, model)
    end

    local function insideOwned(object, root)
        local node = object
        while node and node ~= root do
            if node:GetAttribute(OWNED) then
                return true
            end
            node = node.Parent
        end
        return false
    end

    -- Hides the player's own body and face with Transparency, like the R6 Manager. The original values are kept, so
    -- Original can put them back. Accessories stay visible when "keep items" is on. The skin's parts are never hidden.
    local function hideBody(char)
        for _, desc in ipairs(char:GetDescendants()) do
            if (desc:IsA("BasePart") or desc:IsA("Decal")) and not insideOwned(desc, char) and not (keepItems and insideAccessory(desc, char)) then
                if hiddenParts[desc] == nil then
                    hiddenParts[desc] = desc.Transparency
                end
                desc.Transparency = 1
            end
        end
    end

    local function applyVisual(char, visual)
        -- Hide real body, then place the skin overlay.
        -- Root path (own anims / John) keeps the whole model as one piece.
        -- Limb path follows the player's animations so the skin never freezes.
        hideBody(char)
        local useRoot = visual.anims ~= nil or isJohnSkin(visual.model)
        local placed = applyOverlay(char, visual.model, useRoot)
        if not keepItems then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Accessory") and not child:GetAttribute(OWNED) then
                    child:Destroy()
                end
            end
        end
        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt then
            shirt.ShirtTemplate = visual.shirt or ""
        end
        local pants = char:FindFirstChildOfClass("Pants")
        if pants then
            pants.PantsTemplate = visual.pants or ""
        end
        return placed
    end

    local busy, queued = false, false

    local function applySelected()
        if busy then
            queued = true
            return
        end
        busy = true
        task.spawn(function()
            repeat
                queued = false
                local char = LocalPlayer.Character
                if char then
                    local snap = ensureSnapshot(char)
                    restoreSnapshot(char, snap)
                    local entry = activeEntry()
                    if entry then
                        local placed = applyVisual(char, entry.visual)
                        char:SetAttribute(APPLIED, entry.name)
                        if #lastMissing > 0 then
                            Dominant.Notify(L(MISSING_KEY, table.concat(lastMissing, ", ")), "warning", 8)
                        end
                        if placed == 0 and entry.visual.model and entry.visual.model:FindFirstChildWhichIsA("BasePart", true) then
                            Dominant.Notify(L(NO_PARTS_NOTICE), "warning", 5)
                        end
                    else
                        char:SetAttribute(APPLIED, nil)
                    end
                end
            until not queued
            busy = false
        end)
    end

    -- Checks every second that the active skin is on the current character. Covers respawns and
    -- killers whose character is replaced after the round starts, when no CharacterAdded is fired.
    local function watch()
        local char = LocalPlayer.Character
        local entry = activeEntry()
        if not (char and entry) then
            return
        end
        if char:GetAttribute(APPLIED) ~= entry.name then
            applySelected()
        else
            local head = char:FindFirstChild("Head")
            if head and head.Transparency ~= 1 then
                hideBody(char)
            end
        end
    end

    local animTracks = {}
    local animNow = nil
    local animRig = nil

    local function stopAnimations()
        for _, track in pairs(animTracks) do
            pcall(function()
                track:Stop(0.2)
            end)
        end
        animTracks = {}
        animNow = nil
    end

    local function animStep()
        local entry = activeEntry()
        local char = LocalPlayer.Character
        local rig = char and char:FindFirstChild("DominantSkinOverlay")
        if rig ~= animRig then
            stopAnimations()
            animRig = rig
        end
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local controller = rig and rig:FindFirstChildOfClass("AnimationController")
        local animator = controller and controller:FindFirstChildOfClass("Animator")
        if not (entry and entry.visual.anims and animator and humanoid) then
            return
        end
        local direction = humanoid.MoveDirection
        local moving = direction and direction.Magnitude and direction.Magnitude > 0.1
        local kind = "Idle"
        if moving then
            kind = (humanoid.WalkSpeed or 16) >= 20 and "Run" or "Walk"
        end
        local id = entry.visual.anims[kind]
        if id == animNow then
            return
        end
        animNow = id
        for key, track in pairs(animTracks) do
            if key ~= id then
                pcall(function()
                    track:Stop(0.2)
                end)
            end
        end
        local track = animTracks[id]
        if not track then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. id
            local ok, loaded = pcall(function()
                return animator:LoadAnimation(anim)
            end)
            if not ok or not loaded then
                return
            end
            loaded.Looped = true
            loaded.Priority = Enum.AnimationPriority.Movement
            animTracks[id] = loaded
            track = loaded
        end
        pcall(function()
            track:Play(0.2)
        end)
    end

    local function updateWatch()
        local entry = activeEntry()
        if entry then
            Dominant.StartLoop("skinwatch", 1, watch)
        else
            Dominant.StopLoop("skinwatch")
        end
        if entry and entry.visual.anims then
            Dominant.StartLoop("skinanim", 0.1, animStep)
        else
            Dominant.StopLoop("skinanim")
            stopAnimations()
        end
    end

    local function onCharacter(char)
        snapshot, snapshotChar = nil, nil
        hiddenParts = {}
        if activeEntry() then
            updateWatch()
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

    local function otherActive(category)
        for _, name in ipairs(CATEGORIES) do
            if name ~= category and selected[name] then
                return name
            end
        end
        return nil
    end

    local function commit(category, entry)
        selected[category] = entry
        applySelected()
        updateWatch()
    end

    local function selectSkin(category, value)
        local original = L(ORIGINAL_KEY)
        if value == nil or value == original then
            selected[category] = nil
            applySelected()
            updateWatch()
            return
        end
        local blocking = otherActive(category)
        if blocking then
            Dominant.Notify(L(BLOCK_NOTICE[blocking]), "warning", 4)
            rebuildCards()
            return
        end
        local entry = entryNamed(category, value)
        if entry then
            commit(category, entry)
        end
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
        for _, category in ipairs({ "Killers", "Survivors" }) do
            lists[category] = scan(skinRoot and skinRoot:FindFirstChild(category))
        end

        if not hooked then
            hooked = true
            Dominant.OnCharacter(onCharacter)
        end

        helpers.Section(tab, "sec_skins", "Lucide:sparkles")
        tab:AddToggle({
            Text = L(KEEP_ITEMS_KEY),
            Default = keepItems,
            Callback = function(value)
                keepItems = value == true
                if activeEntry() then
                    applySelected()
                end
            end,
        })
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
