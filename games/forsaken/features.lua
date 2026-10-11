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
    local APPLIED = "DominantSkinApplied"
    local CATEGORIES = { "Killers", "Survivors", "Premade" }
    local CARDS = {
        Killers = { label = "skin_killer", describe = "skin_killer_d", icon = "Lucide:skull" },
        Survivors = { label = "skin_survivor", describe = "skin_survivor_d", icon = "Lucide:user" },
        Premade = { label = "skin_premade", describe = "skin_premade_d", icon = "Lucide:crown" },
    }
    local NO_PARTS_NOTICE = "skin_no_parts"
    local BLOCK_NOTICE = {
        Killers = "skin_block_killer",
        Survivors = "skin_block_survivor",
        Premade = "skin_block_premade",
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

    -- Premade skins, by asset id (the same models the R6 Manager loads)
    local PREMADE_SKINS = {
        { "KJ", "130841968435483" },
        { "Veeronica", "114811939755612" },
        { "Noli", "83685503729863" },
        { "C00lkidd", "102799527809391" },
        { "Old Noli", "83707814406417" },
        { "MS3 Guest 1337", "91317685801943" },
        { "Squid Game Gaurd", "81040214366473" },
        { "Jason (Not Slasher)", "76056443707772" },
        { "67 Slasher", "78724952767173" },
        { "Yeslo", "87325125748010" },
        { "JX1DX1 (Testing Port Over CAN BE BROKEN)", "133147021648397" },
        { "M4 Slasher", "96844924618989" },
        { "1x1x1x1 Jason (Rework)", "93690666816685" },
        { "The Commander (NOLI)", "129043207944984" },
    }

    local PREMADE_STRINGS = {
        en = { skin_premade = "Premade skin", skin_premade_d = "Premade skins loaded by asset ID", skin_block_premade = "Set the premade skin to Original first", skin_custom = "Custom model (asset ID)", skin_custom_d = "Paste an asset ID to load any R6 model", skin_load_failed = "Could not load that model" },
        pt = { skin_premade = "Skin pronta", skin_premade_d = "Skins prontas carregadas pelo ID do asset", skin_block_premade = "Coloque primeiro a skin pronta em Original", skin_custom = "Modelo customizado (ID do asset)", skin_custom_d = "Cole um ID de asset para carregar qualquer modelo R6", skin_load_failed = "Não foi possível carregar esse modelo" },
        es = { skin_premade = "Skin preparada", skin_premade_d = "Skins preparadas cargadas por ID de asset", skin_block_premade = "Pon primero la skin preparada en Original", skin_custom = "Modelo personalizado (ID de asset)", skin_custom_d = "Pega un ID de asset para cargar cualquier modelo R6", skin_load_failed = "No se pudo cargar ese modelo" },
        ru = { skin_premade = "Готовый скин", skin_premade_d = "Готовые скины, загружаемые по ID ассета", skin_block_premade = "Сначала поставьте готовый скин на Оригинал", skin_custom = "Своя модель (ID ассета)", skin_custom_d = "Вставьте ID ассета, чтобы загрузить любую модель R6", skin_load_failed = "Не удалось загрузить эту модель" },
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
        for _, source in ipairs({ STRINGS, EXTRA_STRINGS, PREMADE_STRINGS }) do
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
        local visual = { model = source, accessories = {}, accessoryAnchors = {}, colors = nil, shirt = nil, pants = nil, face = nil }
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
        local head = source:FindFirstChild("Head") or source:FindFirstChild("Head", true)
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
            local skinFolders = {}
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("Folder") and modelOf(sub) then
                    table.insert(skinFolders, sub)
                end
            end
            if #skinFolders > 0 then
                for _, sub in ipairs(skinFolders) do
                    local model = modelOf(sub)
                    if not isGuest(child, model) and not string.find(sub.Name, GUEST_MARK, 1, true) then
                        addSkin(list, child.Name .. " · " .. sub.Name, model)
                    end
                end
            else
                local source = modelOf(child) or child
                if not isGuest(child, source) then
                    addSkin(list, child.Name, source)
                end
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
        return selected.Killers or selected.Survivors or selected.Premade
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
        for part, value in pairs(hiddenParts) do
            if part.Parent then
                pcall(function()
                    part.Transparency = value
                end)
            end
        end
        hiddenParts = {}
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

    -- Copies the skin's whole rig as one model and welds it to the character the way the R6 Manager does.
    -- Each of the six body parts is placed on the matching part of the character and welded to it (a legacy Weld,
    -- with C0 = old.CFrame:Inverse() * new.CFrame). The skin's own welds keep the rest of the rig attached, so
    -- accessories and decorations follow the body. Scripts, humanoids and animations are left out.
    local function applyOverlay(char, model)
        if not model then
            return 0
        end
        local rig = model:Clone()
        rig.Name = "DominantSkinOverlay"
        rig:SetAttribute(OWNED, true)
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Humanoid") or desc:IsA("Animator")
                or desc:IsA("AnimationController") or desc:IsA("Animation") then
                desc:Destroy()
            end
        end

        local bodySet = {}
        for _, name in ipairs(OVERLAY_PARTS) do
            local skinBody = rig:FindFirstChild(name) or rig:FindFirstChild(name, true)
            if skinBody and skinBody:IsA("BasePart") then
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
                desc.Anchored = false
                desc.CanCollide = false
                desc.CanTouch = false
                desc.CanQuery = false
                desc.Massless = true
                desc.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                if not isVisualPart(desc) then
                    -- plain blocks (hitboxes, collision boxes) stay in the rig but are not shown
                    desc.Transparency = 1
                end
                table.insert(parts, desc)
            end
        end

        -- Where each part sits relative to the rig's torso, for parts that end up without any joint
        local skinTorso = rig:FindFirstChild("Torso") or rig:FindFirstChild("Torso", true)
        local charTorso = char:FindFirstChild("Torso")
        local relative = {}
        if skinTorso and skinTorso:IsA("BasePart") then
            for _, part in ipairs(parts) do
                relative[part] = skinTorso.CFrame:ToObjectSpace(part.CFrame)
            end
        end

        -- The rig's own joints, so every part knows what it is attached to
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
            local newPart = rig:FindFirstChild(name) or rig:FindFirstChild(name, true)
            local oldPart = char:FindFirstChild(name)
            if newPart and oldPart and newPart:IsA("BasePart") and oldPart:IsA("BasePart") then
                newPart.Anchored = false
                newPart.CFrame = oldPart.CFrame
                local weld = Instance.new("Weld")
                weld.Part0 = oldPart
                weld.Part1 = newPart
                weld.C0 = oldPart.CFrame:Inverse() * newPart.CFrame
                weld.Parent = newPart
                reached[newPart] = true
                table.insert(queue, newPart)
                placed = placed + 1
            else
                table.insert(lastMissing, name .. (newPart and "" or " (skin)") .. (oldPart and "" or " (player)"))
            end
        end

        -- Everything joined, directly or through other parts, to a placed body part follows it
        while #queue > 0 do
            local current = table.remove(queue, 1)
            for _, other in ipairs(partners[current] or {}) do
                if other:IsA("BasePart") and not reached[other] then
                    reached[other] = true
                    table.insert(queue, other)
                end
            end
        end

        -- Parts with no joint at all go to the torso, keeping their place in the skin
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
        return placed
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
        -- Hide the player's own body, like the R6 Manager does. The hiding is local (LocalTransparencyModifier),
        -- so other players keep seeing the normal character. Accessories stay visible when "keep items" is on.
        hideBody(char)
        local placed = applyOverlay(char, visual.model)
        if not keepItems then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Accessory") and not child:GetAttribute(OWNED) then
                    child:Destroy()
                end
            end
        end
        -- The player's clothes clip into the skin, so they are cleared while a skin is on (restored on Original)
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

    local function updateWatch()
        if activeEntry() then
            Dominant.StartLoop("skinwatch", 1, watch)
        else
            Dominant.StopLoop("skinwatch")
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

    local premadeCache = {}
    local function loadAssetModel(id)
        if premadeCache[id] then
            return premadeCache[id]
        end
        local ok, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)[1]
        end)
        if ok and result then
            premadeCache[id] = result
            return result
        end
        return nil
    end

    local function entryFromModel(name, model)
        local visual = readVisual(model)
        if hasVisual(visual) then
            return { name = name, visual = visual }
        end
        return nil
    end

    local function loadPremade(name)
        for _, item in ipairs(lists.Premade) do
            if item.name == name then
                local model = loadAssetModel(item.id)
                if model then
                    return entryFromModel(name, model)
                end
                return nil
            end
        end
        return nil
    end

    local function loadCustom(text)
        local id = tostring(text or ""):match("%d+")
        if not id then
            return nil
        end
        local model = loadAssetModel(id)
        if not model then
            return nil
        end
        local entry = entryFromModel("Custom " .. id, model)
        if entry then
            local known = false
            for _, item in ipairs(lists.Premade) do
                if item.id == id then
                    known = true
                end
            end
            if not known then
                table.insert(lists.Premade, { name = "Custom " .. id, id = id })
            end
        end
        return entry
    end

    local LOAD_FAILED_KEY = "skin_load_failed"
    local CUSTOM_KEY = "skin_custom"

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
        if category == "Premade" then
            task.spawn(function()
                local entry = loadPremade(value)
                if entry then
                    commit("Premade", entry)
                else
                    Dominant.Notify(L(LOAD_FAILED_KEY), "error", 5)
                    rebuildCards()
                end
            end)
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
        lists.Premade = {}
        for _, item in ipairs(PREMADE_SKINS) do
            table.insert(lists.Premade, { name = item[1], id = item[2] })
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
        addCard("Premade")
        tab:AddTextbox({
            Text = L(CUSTOM_KEY),
            Placeholder = "rbxassetid",
            Default = "",
            Callback = function(text)
                task.spawn(function()
                    local blocking = otherActive("Premade")
                    if blocking then
                        Dominant.Notify(L(BLOCK_NOTICE[blocking]), "warning", 4)
                        return
                    end
                    local entry = loadCustom(text)
                    if entry then
                        commit("Premade", entry)
                        rebuildCards()
                    else
                        Dominant.Notify(L(LOAD_FAILED_KEY), "error", 5)
                    end
                end)
            end,
        })
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
