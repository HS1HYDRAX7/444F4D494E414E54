local M = {}

local function build(Dominant)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local okAES, AvatarEditorService = pcall(function()
	return game:GetService("AvatarEditorService")
end)
if not okAES then
	AvatarEditorService = nil
end


local getAsset = getcustomasset or getsynasset
local writeFile, readFile, delFile = writefile, readfile, delfile
local isFolder, makeFolder, listDir = isfolder, makefolder, listfiles
local canFiles = writeFile and readFile and isFolder and makeFolder and listDir

local ROOT = "AvatarStudio"
local CLOTHING_DIR = ROOT .. "/Clothing"
local OUTFIT_DIR = ROOT .. "/Outfits"
local TOGGLE_KEY = Enum.KeyCode.RightShift
local SKIN_PATH = "AvatarStudio/skin.json"

local COLS, ROWS = 5, 5
local CELL, GAP, PAD = 76, 6, 10
local TOP = 66
local GRID_H = ROWS * CELL + (ROWS - 1) * GAP
local WIN_W = PAD * 2 + COLS * CELL + (COLS - 1) * GAP
local WIN_H = TOP + 58 + GRID_H + 24 + PAD

local THEME = {
	Background = Dominant.OphynPalette.bg,
	Panel = Dominant.OphynPalette.input,
	Card = Dominant.OphynPalette.btn2,
	CardHover = Dominant.OphynPalette.btn2Hover,
	Stroke = Dominant.OphynPalette.stroke,
	Accent = Dominant.OphynPalette.submitBg,
	Text = Dominant.OphynPalette.text,
	SubText = Dominant.OphynPalette.muted,
	Danger = Dominant.OphynPalette.error,
	Success = Dominant.OphynPalette.success,
}

local BODY_PARTS = {"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3"}
local BODY_TARGETS = {
	All = BODY_PARTS,
	Head = {"HeadColor3"},
	Torso = {"TorsoColor3"},
	Arms = {"LeftArmColor3", "RightArmColor3"},
	Legs = {"LeftLegColor3", "RightLegColor3"},
}
local PALETTE = {
	"F5F5F5", "1F1F1F", "EF4444", "F97316", "FACC15", "22C55E", "14B8A6", "06B6D4",
	"3B82F6", "6366F1", "8B5CF6", "D946EF", "EC4899", "78716C", "A16207", "FDBCB4",
}
local CATEGORIES = {
	{"All", {}}, {"Hats", {"Hat"}}, {"Hair", {"HairAccessory"}}, {"Face", {"FaceAccessory"}},
	{"Neck", {"NeckAccessory"}}, {"Shoulders", {"ShoulderAccessory"}}, {"Front", {"FrontAccessory"}},
	{"Back", {"BackAccessory"}}, {"Waist", {"WaistAccessory"}},
}
local CLOTHING_KINDS = {"Shirt", "Pants", "Face"}
local TABS = {"Catalog", "Equipped", "Colors", "Wardrobe", "Outfits"}

local SINGLE_SLOT = {Hair = true, Face = true, Neck = true, Shoulder = true, Front = true, Back = true, Waist = true}

local function notify(text, color)
	local kind = color == THEME.Danger and "error" or "info"
	pcall(Dominant.Toast, text, kind, 3)
end
local connections = {}
local settings = {autoReapply = true}
local accessoryCache = {}
local originals = {}
local appliedClothing = {}
local sessionOutfit = nil
local clothingTarget = "Shirt"
local bodyTarget = "All"
local selectedCategory = 1
local catalogPages, catalogToken = nil, 0
local defaultStatus = "Search or pick a category to start."
local originalList = {}
local updateCards

local function new(className, props, children)
	local obj = Instance.new(className)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			obj[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	obj.Parent = parent
	if className == "TextLabel" or className == "TextButton" or className == "TextBox" then
		pcall(Dominant.StyleFont, obj, false)
	end
	return obj
end

local function corner(obj, radius)
	return new("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = obj})
end

local function stroke(obj, color, transparency)
	return new("UIStroke", {Color = color or THEME.Stroke, Transparency = transparency or 0.4, Parent = obj})
end

local function tween(obj, duration, goal)
	TweenService:Create(obj, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goal):Play()
end

local function setBase(btn, color)
	btn:SetAttribute("Base", color)
	tween(btn, 0.2, {BackgroundColor3 = color})
end

local function button(text, parent, size, color)
	color = color or THEME.Card
	local btn = new("TextButton", {
		Size = size or UDim2.fromOffset(80, 22), BackgroundColor3 = color, Text = text,
		TextColor3 = THEME.Text, Font = Enum.Font.GothamMedium, TextSize = 12,
		AutoButtonColor = false, Parent = parent,
	})
	corner(btn, 7)
	btn:SetAttribute("Base", color)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.12, {BackgroundColor3 = btn:GetAttribute("Base"):Lerp(Color3.new(1, 1, 1), 0.1)})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.12, {BackgroundColor3 = btn:GetAttribute("Base")})
	end)
	return btn
end

local function highlight(map, active)
	for key, btn in pairs(map) do
		local on = key == active
		setBase(btn, on and THEME.Accent or THEME.Card)
		btn.TextColor3 = on and THEME.Text or THEME.SubText
	end
end

local function clearChildren(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function hexColor(hex)
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end

local function ensureFolders()
	if not canFiles then
		return false
	end
	for _, dir in ipairs({ROOT, CLOTHING_DIR, OUTFIT_DIR}) do
		if not isFolder(dir) then
			makeFolder(dir)
		end
	end
	return true
end

local function scanFiles(dir, filter)
	local found = {}
	if not canFiles or not isFolder(dir) then
		return found
	end
	local ok, paths = pcall(listDir, dir)
	if not ok or type(paths) ~= "table" then
		return found
	end
	for _, path in ipairs(paths) do
		local name = path:match("([^/\\]+)$") or path
		if filter(name:lower()) then
			table.insert(found, {name = name, path = dir .. "/" .. name})
		end
	end
	return found
end

local function getCharacter()
	local char = LocalPlayer.Character
	return char, char and char:FindFirstChildOfClass("Humanoid")
end

local function resolveAssetTypes(names)
	local list = {}
	for _, name in ipairs(names) do
		local ok, value = pcall(function()
			return Enum.AvatarAssetType[name]
		end)
		if ok and value then
			table.insert(list, value)
		end
	end
	return list
end

local function loadAccessoryTemplate(assetId)
	if accessoryCache[assetId] then
		return accessoryCache[assetId]
	end
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. assetId)
	end)
	if not ok or type(objects) ~= "table" or #objects == 0 then
		return nil, "Could not load asset " .. assetId .. ". Check the ID or your connection."
	end
	local root = objects[1]
	local accessory = root:IsA("Accessory") and root or root:FindFirstChildWhichIsA("Accessory", true)
	if accessory then
		accessoryCache[assetId] = accessory:Clone()
	end
	for _, obj in ipairs(objects) do
		obj:Destroy()
	end
	if not accessory then
		return nil, "Asset " .. assetId .. " is not an accessory."
	end
	return accessoryCache[assetId]
end

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

local function equipAccessory(assetId, displayName, silent)
	local char, hum = getCharacter()
	if not hum then
		if not silent then notify("No character loaded yet.", THEME.Danger) end
		return false
	end
	for _, existing in ipairs(char:GetChildren()) do
		if existing:IsA("Accessory") and existing:GetAttribute("CatalogId") == assetId then
			if not silent then notify("Already equipped.", THEME.SubText) end
			return true
		end
	end

	local template, err = loadAccessoryTemplate(assetId)
	if not template then
		if not silent then notify(err, THEME.Danger) end
		return false
	end

	local accessory = template:Clone()
	for _, d in ipairs(accessory:GetDescendants()) do
		if d:IsA("Weld") or d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	local typeName = (tostring(accessory.AccessoryType):gsub("^.*%.", ""))
	accessory:SetAttribute("CatalogId", assetId)
	accessory:SetAttribute("CatalogName", displayName or ("Asset " .. assetId))

	local ok, attached = pcall(attachAccessory, char, accessory)
	if not ok or not attached then
		accessory:Destroy()
		if not silent then
			notify("Failed on " .. (displayName or assetId) .. ": " .. (ok and "no Handle or body part found" or tostring(attached)), THEME.Danger)
		end
		return false
	end

	if SINGLE_SLOT[typeName] then
		for _, existing in ipairs(char:GetChildren()) do
			if existing ~= accessory and existing:IsA("Accessory") and (tostring(existing.AccessoryType):gsub("^.*%.", "")) == typeName then
				existing:Destroy()
			end
		end
	end

	if not silent then
		notify("Equipped " .. (displayName or assetId), THEME.Accent)
	end
	return true
end

local function clearAccessories()
	local char = LocalPlayer.Character
	if not char then return end
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
		end
	end
end

local function setBodyColors(props, colorFor)
	local char = LocalPlayer.Character
	local bc = char and char:FindFirstChildOfClass("BodyColors")
	if not bc then
		notify("BodyColors not found on your character.", THEME.Danger)
		return false
	end
	for _, prop in ipairs(props) do
		pcall(function()
			bc[prop] = colorFor(prop)
		end)
	end
	return true
end

local function remember(key, value)
	if originals[key] == nil then
		originals[key] = value
	end
end

local function applyClothing(kind, path)
	local char = LocalPlayer.Character
	if not char then
		notify("No character loaded yet.", THEME.Danger)
		return false
	end
	if not getAsset then
		notify("Your executor does not support getcustomasset.", THEME.Danger)
		return false
	end
	local ok, url = pcall(getAsset, path)
	if not ok or not url then
		notify("Could not load " .. path, THEME.Danger)
		return false
	end

	if kind == "Face" then
		local head = char:FindFirstChild("Head")
		local face = head and head:FindFirstChild("face")
		if not face then
			notify("No face decal on this avatar.", THEME.Danger)
			return false
		end
		remember("Face", face.Texture)
		face.Texture = url
	else
		local item = char:FindFirstChildOfClass(kind) or Instance.new(kind)
		item.Parent = char
		if kind == "Shirt" then
			remember("Shirt", item.ShirtTemplate)
			item.ShirtTemplate = url
		else
			remember("Pants", item.PantsTemplate)
			item.PantsTemplate = url
		end
	end
	appliedClothing[kind] = path
	return true
end

local function restoreClothing()
	local char = LocalPlayer.Character
	if char then
		local shirt = char:FindFirstChildOfClass("Shirt")
		if shirt and originals.Shirt then shirt.ShirtTemplate = originals.Shirt end
		local pants = char:FindFirstChildOfClass("Pants")
		if pants and originals.Pants then pants.PantsTemplate = originals.Pants end
		local head = char:FindFirstChild("Head")
		local face = head and head:FindFirstChild("face")
		if face and originals.Face then face.Texture = originals.Face end
	end
	originals, appliedClothing = {}, {}
end

local function accessoryKey(acc)
	return acc.Name .. "|" .. (tostring(acc.AccessoryType):gsub("^.*%.", ""))
end

local function waitForAppearance(char)
	char:WaitForChild("Humanoid", 10)
	local last, stable, start = -1, 0, os.clock()
	while stable < 0.6 and os.clock() - start < 6 do
		local count = 0
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Accessory") then
				count += 1
			end
		end
		if count == last then
			stable += 0.1
		else
			stable, last = 0, count
		end
		task.wait(0.1)
	end
end

local function snapshotOriginals()
	originalList = {}
	local char = LocalPlayer.Character
	if not char then return end
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") and not child:GetAttribute("CatalogId") then
			local typeName = (tostring(child.AccessoryType):gsub("^.*%.", ""))
			table.insert(originalList, {name = child.Name, type = typeName})
		end
	end
end

local function buildOutfit()
	local outfit = {
		accessories = {},
		removed = {},
		colors = {},
		shirt = appliedClothing.Shirt,
		pants = appliedClothing.Pants,
		face = appliedClothing.Face,
	}
	local char = LocalPlayer.Character
	if not char then return outfit end
	local present = {}
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local id = child:GetAttribute("CatalogId")
			if id then
				table.insert(outfit.accessories, {
					id = id,
					name = child:GetAttribute("CatalogName"),
					type = (tostring(child.AccessoryType):gsub("^.*%.", "")),
				})
			else
				present[accessoryKey(child)] = true
			end
		end
	end
	for _, entry in ipairs(originalList) do
		if not present[entry.name .. "|" .. entry.type] then
			table.insert(outfit.removed, entry)
		end
	end
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then
		for _, prop in ipairs(BODY_PARTS) do
			local c = bc[prop]
			outfit.colors[prop] = {c.R, c.G, c.B}
		end
	end
	return outfit
end

local function commit()
	sessionOutfit = buildOutfit()
end

local function isEquipped(assetId)
	local char = LocalPlayer.Character
	if not char then return false end
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute("CatalogId") == assetId then
			return true
		end
	end
	return false
end

local function toggleAccessory(assetId, name)
	if isEquipped(assetId) then
		local char = LocalPlayer.Character
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Accessory") and child:GetAttribute("CatalogId") == assetId then
				child:Destroy()
			end
		end
		notify("Removed " .. (name or ("Asset " .. assetId)), THEME.SubText)
	else
		equipAccessory(assetId, name)
	end
	commit()
	updateCards()
end

local function removeOriginal(key)
	local char = LocalPlayer.Character
	if not char then return end
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") and not child:GetAttribute("CatalogId") and accessoryKey(child) == key then
			child:Destroy()
		end
	end
end

local function applyOutfit(data)
	task.spawn(function()
		local char = LocalPlayer.Character
		for _, child in ipairs(char and char:GetChildren() or {}) do
			if child:IsA("Accessory") and child:GetAttribute("CatalogId") then
				child:Destroy()
			end
		end
		for _, entry in ipairs(data.removed or {}) do
			removeOriginal(entry.name .. "|" .. entry.type)
		end
		for _, item in ipairs(data.accessories or {}) do
			local isTable = type(item) == "table"
			equipAccessory(tonumber(isTable and item.id or item), isTable and item.name or nil, true)
		end
		local char = LocalPlayer.Character
		local bc = char and char:FindFirstChildOfClass("BodyColors")
		if bc and data.colors then
			for prop, c in pairs(data.colors) do
				pcall(function()
					bc[prop] = Color3.new(c[1], c[2], c[3])
				end)
			end
		end
		if data.shirt then applyClothing("Shirt", data.shirt) end
		if data.pants then applyClothing("Pants", data.pants) end
		if data.face then applyClothing("Face", data.face) end
		commit()
	end)
end

local function saveOutfit(name)
	if not ensureFolders() then
		notify("Your executor does not support file functions.", THEME.Danger)
		return
	end
	name = (name:gsub("[^%w _%-]", ""))
	if name == "" then
		name = "outfit_" .. os.time()
	end
	name = name:sub(1, 32)
	writeFile(OUTFIT_DIR .. "/" .. name .. ".json", HttpService:JSONEncode(buildOutfit()))
	notify("Saved outfit: " .. name, THEME.Accent)
end

local function exportSkin()
	if not ensureFolders() then
		notify("Your executor does not support file functions.", THEME.Danger)
		return
	end
	local dir = SKIN_PATH:match("^(.*)/[^/]+$")
	if dir and not isFolder(dir) then
		makeFolder(dir)
	end
	writeFile(SKIN_PATH, HttpService:JSONEncode(buildOutfit()))
	notify("Skin saved to " .. SKIN_PATH, THEME.Accent)
end

local function loadOutfit(path)
	local okRead, raw = pcall(readFile, path)
	local okParse, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not okRead or not okParse or type(data) ~= "table" then
		notify("That outfit file is invalid.", THEME.Danger)
		return
	end
	applyOutfit(data)
	notify("Loading outfit...", THEME.Accent)
end


local grid, statusLabel, moreBtn, searchBox, equippedHeader, equippedList, wardrobeGrid, wardrobeInfo, outfitList, pages, tabButtons

local function makeCard(item)
	local id = tonumber(item.Id)
	if not id then return end
	local name = item.Name or "Unnamed"
	local price = (tonumber(item.Price) or 0) > 0 and ("R$ " .. item.Price) or "Free"

	local card = new("TextButton", {
		Size = UDim2.fromOffset(CELL, CELL), BackgroundColor3 = THEME.Card, AutoButtonColor = false, Text = "", Parent = grid,
	})
	corner(card, 8)
	card:SetAttribute("AssetId", id)
	stroke(card, THEME.Accent, isEquipped(id) and 0 or 1)
	new("ImageLabel", {
		Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit, Image = ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(id), Parent = card,
	})
	card.MouseEnter:Connect(function()
		tween(card, 0.12, {BackgroundColor3 = THEME.CardHover})
		statusLabel.Text = name .. "  |  " .. price
	end)
	card.MouseLeave:Connect(function()
		tween(card, 0.12, {BackgroundColor3 = THEME.Card})
		statusLabel.Text = defaultStatus
	end)
	card.MouseButton1Click:Connect(function()
		toggleAccessory(id, name)
	end)
end

local function fetchCatalog(reset)
	if not AvatarEditorService then
		defaultStatus = "Catalog search is not available here. Paste an asset ID instead."
		statusLabel.Text = defaultStatus
		return
	end
	local token = catalogToken
	if reset then
		catalogToken += 1
		token = catalogToken
		clearChildren(grid)
		moreBtn.Visible = false
		statusLabel.Text = "Searching..."
		local okParams, params = pcall(function()
			local p = CatalogSearchParams.new()
			p.SearchKeyword = searchBox.Text
			return p
		end)
		if not okParams then
			statusLabel.Text = "Search is not supported by this executor."
			return
		end
		local types = resolveAssetTypes(CATEGORIES[selectedCategory][2])
		if #types > 0 then
			pcall(function() params.AssetTypes = types end)
		end
		local okSearch, resultPages = pcall(function()
			return AvatarEditorService:SearchCatalog(params)
		end)
		if token ~= catalogToken then return end
		if not okSearch or not resultPages then
			statusLabel.Text = "Search failed. Try again in a moment."
			return
		end
		catalogPages = resultPages
	else
		if not catalogPages or catalogPages.IsFinished then return end
		statusLabel.Text = "Loading more..."
		local okNext = pcall(function()
			catalogPages:AdvanceToNextPageAsync()
		end)
		if token ~= catalogToken then return end
		if not okNext then
			statusLabel.Text = "Could not load more results."
			return
		end
	end

	local okItems, items = pcall(function()
		return catalogPages:GetCurrentPage()
	end)
	if not okItems or type(items) ~= "table" then
		statusLabel.Text = "No results for this search."
		return
	end
	local shown = 0
	for _, item in ipairs(items) do
		if not tostring(item.ItemType):find("Bundle") then
			makeCard(item)
			shown += 1
		end
	end
	moreBtn.Visible = not catalogPages.IsFinished
	defaultStatus = shown > 0 and "Click an item to try it on." or "Nothing on this page. Try another search."
	statusLabel.Text = defaultStatus
end

updateCards = function()
	for _, card in ipairs(grid:GetChildren()) do
		local id = card:GetAttribute("AssetId")
		local outline = card:FindFirstChildOfClass("UIStroke")
		if id and outline then
			outline.Transparency = isEquipped(id) and 0 or 1
		end
	end
end

local function refreshEquipped()
	clearChildren(equippedList)
	local char = LocalPlayer.Character
	local count = 0
	if char then
		for _, acc in ipairs(char:GetChildren()) do
			if acc:IsA("Accessory") then
				count += 1
				local row = new("Frame", {Size = UDim2.new(1, -6, 0, 30), BackgroundColor3 = THEME.Card, Parent = equippedList})
				corner(row, 7)
				local typeName = (tostring(acc.AccessoryType):gsub("^.*%.", ""))
				new("TextLabel", {
					Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
					Text = (acc:GetAttribute("CatalogName") or acc.Name) .. "  (" .. typeName .. ")",
					TextColor3 = THEME.Text, Font = Enum.Font.Gotham, TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
				})
				local removeBtn = button("Remove", row, UDim2.fromOffset(62, 20), THEME.Danger)
				removeBtn.Position = UDim2.new(1, -68, 0.5, -10)
				removeBtn.TextSize = 11
				removeBtn.MouseButton1Click:Connect(function()
					acc:Destroy()
					commit()
					updateCards()
					refreshEquipped()
				end)
			end
		end
	end
	equippedHeader.Text = count .. " accessories equipped"
end

local function refreshWardrobe()
	clearChildren(wardrobeGrid)
	if not canFiles then
		wardrobeInfo.Text = "Your executor does not support file functions."
		return
	end
	ensureFolders()
	local files = scanFiles(CLOTHING_DIR, function(n)
		return n:match("%.png$") or n:match("%.jpe?g$")
	end)
	for _, file in ipairs(files) do
		local card = new("TextButton", {
			Size = UDim2.fromOffset(CELL, CELL), BackgroundColor3 = THEME.Card, AutoButtonColor = false, Text = "", Parent = wardrobeGrid,
		})
		corner(card, 8)
		local thumb = new("ImageLabel", {
			Size = UDim2.new(1, -8, 1, -18), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = THEME.Panel,
			ScaleType = Enum.ScaleType.Fit, Parent = card,
		})
		corner(thumb, 6)
		if getAsset then
			local okThumb, url = pcall(getAsset, file.path)
			if okThumb then thumb.Image = url end
		end
		new("TextLabel", {
			Size = UDim2.new(1, -6, 0, 12), Position = UDim2.new(0, 3, 1, -14), BackgroundTransparency = 1,
			Text = file.name, TextColor3 = THEME.SubText, Font = Enum.Font.Gotham, TextSize = 8,
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
		})
		card.MouseButton1Click:Connect(function()
			if applyClothing(clothingTarget, file.path) then
				commit()
				notify("Applied " .. file.name .. " to " .. clothingTarget, THEME.Accent)
			end
		end)
	end
	if #files > 0 then
		wardrobeInfo.Text = #files .. " images. Tap one to apply it to " .. clothingTarget .. "."
	else
		wardrobeInfo.Text = "No PNG or JPG yet. Add files to " .. CLOTHING_DIR .. " and press Refresh."
	end
end

local function refreshOutfits()
	clearChildren(outfitList)
	if not canFiles then
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Your executor does not support file functions.",
			TextColor3 = THEME.SubText, Font = Enum.Font.Gotham, TextSize = 11, Parent = outfitList,
		})
		return
	end
	ensureFolders()
	local files = scanFiles(OUTFIT_DIR, function(n)
		return n:match("%.json$")
	end)
	if #files == 0 then
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "No saved outfits yet. Name one above and press Save.",
			TextColor3 = THEME.SubText, Font = Enum.Font.Gotham, TextSize = 11, Parent = outfitList,
		})
		return
	end
	for _, file in ipairs(files) do
		local row = new("Frame", {Size = UDim2.new(1, -6, 0, 30), BackgroundColor3 = THEME.Card, Parent = outfitList})
		corner(row, 7)
		new("TextLabel", {
			Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
			Text = (file.name:gsub("%.json$", "")), TextColor3 = THEME.Text, Font = Enum.Font.GothamMedium, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
		})
		local loadBtn = button("Load", row, UDim2.fromOffset(56, 20), THEME.Accent)
		loadBtn.Position = UDim2.new(1, -124, 0.5, -10)
		loadBtn.TextSize = 11
		loadBtn.MouseButton1Click:Connect(function()
			loadOutfit(file.path)
		end)
		local deleteBtn = button("Delete", row, UDim2.fromOffset(56, 20), THEME.Danger)
		deleteBtn.Position = UDim2.new(1, -62, 0.5, -10)
		deleteBtn.TextSize = 11
		deleteBtn.MouseButton1Click:Connect(function()
			if delFile then
				delFile(file.path)
				refreshOutfits()
				notify("Outfit deleted.", THEME.Danger)
			else
				notify("Your executor does not support delfile.", THEME.Danger)
			end
		end)
	end
end

local function showTab(name)
	for pageName, page in pairs(pages) do
		page.Visible = pageName == name
	end
	highlight(tabButtons, name)
	if name == "Equipped" then
		refreshEquipped()
	elseif name == "Wardrobe" then
		refreshWardrobe()
	elseif name == "Outfits" then
		refreshOutfits()
	end
end


local ui = {}
local PANEL_W, PANEL_H = 560, 548
local SIDEBAR_W = 118
local CONTENT_W = PANEL_W - SIDEBAR_W - 28
local CONTENT_H = PANEL_H - 58

local guiParent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
local oldGui = guiParent:FindFirstChild("DominantAvatarEditor")
if oldGui then
	oldGui:Destroy()
end

local screen = new("ScreenGui", {
	Name = "DominantAvatarEditor",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 10060,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = guiParent,
})
Dominant.Objects["avatar_editor_gui"] = screen

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local fitScale = math.min(1, (viewport.X - 24) / PANEL_W, (viewport.Y - 24) / PANEL_H)

local main = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(PANEL_W, PANEL_H),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = THEME.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = screen,
})
corner(main, 14)
stroke(main, THEME.Stroke, 0.2)
local mainScale = new("UIScale", {Scale = fitScale, Parent = main})

local topbar = new("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = main})
new("TextLabel", {
	Size = UDim2.new(1, -60, 1, 0),
	Position = UDim2.fromOffset(16, 0),
	BackgroundTransparency = 1,
	Text = "Avatar editor",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = THEME.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topbar,
})
local closeBtn = button("X", topbar, UDim2.fromOffset(30, 26), THEME.Card)
closeBtn.Position = UDim2.new(1, -40, 0, 9)

local sidebar = new("Frame", {
	Size = UDim2.new(0, SIDEBAR_W, 0, CONTENT_H),
	Position = UDim2.fromOffset(10, 48),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
	Parent = main,
})
corner(sidebar, 12)
new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = sidebar})
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar})
tabButtons = {}
for index, name in ipairs(TABS) do
	local btn = button(name, sidebar, UDim2.new(1, 0, 0, 32), THEME.Card)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = index
	new("UIPadding", {PaddingLeft = UDim.new(0, 12), Parent = btn})
	tabButtons[name] = btn
end

local content = new("Frame", {
	Size = UDim2.new(0, CONTENT_W, 0, CONTENT_H),
	Position = UDim2.fromOffset(SIDEBAR_W + 18, 48),
	BackgroundTransparency = 1,
	Parent = main,
})
pages = {}
local function newPage(name)
	local page = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content})
	pages[name] = page
	return page
end

local catalogPage = newPage("Catalog")
searchBox = new("TextBox", {
	Size = UDim2.new(1, -62, 0, 26),
	BackgroundColor3 = THEME.Panel,
	Text = "",
	PlaceholderText = "Search or paste an asset ID",
	PlaceholderColor3 = THEME.SubText,
	TextColor3 = THEME.Text,
	TextSize = 12,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = catalogPage,
})
corner(searchBox, 8)
new("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = searchBox})
local searchBtn = button("Search", catalogPage, UDim2.fromOffset(56, 26), THEME.Accent)
searchBtn.Position = UDim2.new(1, -56, 0, 0)

local catRow = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.fromOffset(0, 32),
	BackgroundTransparency = 1,
	ScrollBarThickness = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.X,
	Parent = catalogPage,
})
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = catRow})
local categoryButtons = {}
for index, cat in ipairs(CATEGORIES) do
	local btn = button(cat[1], catRow, UDim2.fromOffset(74, 24), THEME.Card)
	btn.TextSize = 11
	btn.LayoutOrder = index
	categoryButtons[index] = btn
end
highlight(categoryButtons, selectedCategory)

grid = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, GRID_H),
	Position = UDim2.fromOffset(0, 62),
	BackgroundTransparency = 1,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.SubText,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = catalogPage,
})
new("UIGridLayout", {
	CellSize = UDim2.fromOffset(CELL, CELL),
	CellPadding = UDim2.fromOffset(GAP, GAP),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = grid,
})
statusLabel = new("TextLabel", {
	Size = UDim2.new(1, -64, 0, 16),
	Position = UDim2.fromOffset(0, 62 + GRID_H + 6),
	BackgroundTransparency = 1,
	Text = defaultStatus,
	TextColor3 = THEME.SubText,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Parent = catalogPage,
})
moreBtn = button("More", catalogPage, UDim2.fromOffset(56, 18), THEME.Card)
moreBtn.Position = UDim2.new(1, -56, 0, 62 + GRID_H + 5)
moreBtn.TextSize = 11
moreBtn.Visible = false

local equippedPage = newPage("Equipped")
equippedHeader = new("TextLabel", {
	Size = UDim2.new(1, -100, 0, 22),
	BackgroundTransparency = 1,
	Text = "0 accessories equipped",
	TextColor3 = THEME.SubText,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = equippedPage,
})
ui.clearAllBtn = button("Clear all", equippedPage, UDim2.fromOffset(88, 22), THEME.Danger)
ui.clearAllBtn.Position = UDim2.new(1, -88, 0, 0)
equippedList = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -30),
	Position = UDim2.fromOffset(0, 30),
	BackgroundTransparency = 1,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.SubText,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = equippedPage,
})
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = equippedList})

local colorsPage = newPage("Colors")
local bodyRow = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = colorsPage})
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = bodyRow})
ui.bodyButtons = {}
for _, name in ipairs({"All", "Head", "Torso", "Arms", "Legs"}) do
	local btn = button(name, bodyRow, UDim2.new(0.2, -4, 1, 0), THEME.Card)
	btn.TextSize = 11
	ui.bodyButtons[name] = btn
end
highlight(ui.bodyButtons, bodyTarget)
local palette = new("Frame", {Size = UDim2.new(1, 0, 0, 84), Position = UDim2.fromOffset(0, 36), BackgroundTransparency = 1, Parent = colorsPage})
new("UIGridLayout", {CellSize = UDim2.fromOffset(36, 36), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = palette})
for _, hex in ipairs(PALETTE) do
	local swatch = new("TextButton", {BackgroundColor3 = hexColor(hex), Text = "", AutoButtonColor = false, Parent = palette})
	corner(swatch, 9)
	stroke(swatch, THEME.Text, 0.8)
	swatch.MouseButton1Click:Connect(function()
		if setBodyColors(BODY_TARGETS[bodyTarget], function() return hexColor(hex) end) then
			commit()
		end
	end)
end
ui.randomBtn = button("Randomize", colorsPage, UDim2.fromOffset(120, 28), THEME.Accent)
ui.randomBtn.Position = UDim2.fromOffset(0, 130)
new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.fromOffset(0, 166),
	BackgroundTransparency = 1,
	Text = "Changes only show on your screen.",
	TextColor3 = THEME.SubText,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = colorsPage,
})

local wardrobePage = newPage("Wardrobe")
ui.kindButtons = {}
for index, kind in ipairs(CLOTHING_KINDS) do
	local btn = button(kind, wardrobePage, UDim2.fromOffset(70, 24), THEME.Card)
	btn.Position = UDim2.fromOffset((index - 1) * 76, 0)
	btn.TextSize = 11
	ui.kindButtons[kind] = btn
end
highlight(ui.kindButtons, clothingTarget)
ui.refreshBtn = button("Refresh", wardrobePage, UDim2.fromOffset(70, 24), THEME.Card)
ui.refreshBtn.Position = UDim2.new(1, -150, 0, 0)
ui.refreshBtn.TextSize = 11
ui.restoreBtn = button("Restore", wardrobePage, UDim2.fromOffset(74, 24), THEME.Danger)
ui.restoreBtn.Position = UDim2.new(1, -74, 0, 0)
ui.restoreBtn.TextSize = 11
wardrobeInfo = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.fromOffset(0, 30),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.SubText,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Parent = wardrobePage,
})
wardrobeGrid = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -52),
	Position = UDim2.fromOffset(0, 52),
	BackgroundTransparency = 1,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.SubText,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = wardrobePage,
})
new("UIGridLayout", {CellSize = UDim2.fromOffset(CELL, CELL), CellPadding = UDim2.fromOffset(GAP, GAP), Parent = wardrobeGrid})

local outfitsPage = newPage("Outfits")
ui.nameBox = new("TextBox", {
	Size = UDim2.new(1, -62, 0, 26),
	BackgroundColor3 = THEME.Panel,
	Text = "",
	PlaceholderText = "Outfit name",
	PlaceholderColor3 = THEME.SubText,
	TextColor3 = THEME.Text,
	TextSize = 12,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = outfitsPage,
})
corner(ui.nameBox, 8)
new("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = ui.nameBox})
ui.saveBtn = button("Save", outfitsPage, UDim2.fromOffset(56, 26), THEME.Accent)
ui.saveBtn.Position = UDim2.new(1, -56, 0, 0)
outfitList = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -124),
	Position = UDim2.fromOffset(0, 34),
	BackgroundTransparency = 1,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.SubText,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = outfitsPage,
})
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = outfitList})
local settingsCard = new("Frame", {
	Size = UDim2.new(1, 0, 0, 84),
	Position = UDim2.new(0, 0, 1, -84),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
	Parent = outfitsPage,
})
corner(settingsCard, 10)
new("TextLabel", {
	Size = UDim2.new(1, -70, 0, 20),
	Position = UDim2.fromOffset(12, 8),
	BackgroundTransparency = 1,
	Text = "Re-apply the last outfit after respawn",
	TextColor3 = THEME.Text,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = settingsCard,
})
ui.toggleBg = new("TextButton", {
	Size = UDim2.fromOffset(38, 20),
	Position = UDim2.new(1, -50, 0, 8),
	BackgroundColor3 = THEME.Card,
	Text = "",
	AutoButtonColor = false,
	Parent = settingsCard,
})
corner(ui.toggleBg, 10)
ui.knob = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = THEME.Text, BorderSizePixel = 0, Parent = ui.toggleBg})
corner(ui.knob, 8)
ui.exportBtn = button("Export skin JSON", settingsCard, UDim2.fromOffset(140, 24), THEME.Accent)
ui.exportBtn.Position = UDim2.fromOffset(12, 42)
ui.exportBtn.TextSize = 11
ui.closeBtn2 = button("Close", settingsCard, UDim2.fromOffset(80, 24), THEME.Card)
ui.closeBtn2.Position = UDim2.fromOffset(160, 42)
ui.closeBtn2.TextSize = 11

local visible = false
local function setVisible(state)
	visible = state
	if state then
		main.Visible = true
		tween(mainScale, 0.25, {Scale = fitScale})
	else
		tween(mainScale, 0.18, {Scale = fitScale * 0.9})
		task.delay(0.18, function()
			if not visible then
				main.Visible = false
			end
		end)
	end
end

local dragging, dragStart, startPos = false, nil, nil
topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
Dominant.Connect(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
Dominant.Connect(UserInputService.InputChanged, function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local function runSearch()
	local typed = searchBox.Text
	if typed:match("^%d+$") then
		toggleAccessory(tonumber(typed), "Asset " .. typed)
		return
	end
	fetchCatalog(true)
end
searchBtn.MouseButton1Click:Connect(runSearch)
searchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		runSearch()
	end
end)
moreBtn.MouseButton1Click:Connect(function()
	fetchCatalog(false)
end)
for index, btn in ipairs(categoryButtons) do
	btn.MouseButton1Click:Connect(function()
		selectedCategory = index
		highlight(categoryButtons, index)
		fetchCatalog(true)
	end)
end
for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		showTab(name)
	end)
end
for name, btn in pairs(ui.bodyButtons) do
	btn.MouseButton1Click:Connect(function()
		bodyTarget = name
		highlight(ui.bodyButtons, name)
	end)
end
ui.randomBtn.MouseButton1Click:Connect(function()
	setBodyColors(BODY_TARGETS[bodyTarget], function()
		return Color3.fromHSV(math.random(), 0.5, 0.95)
	end)
	commit()
end)
for kind, btn in pairs(ui.kindButtons) do
	btn.MouseButton1Click:Connect(function()
		clothingTarget = kind
		highlight(ui.kindButtons, kind)
		refreshWardrobe()
	end)
end
ui.refreshBtn.MouseButton1Click:Connect(function()
	refreshWardrobe()
end)
ui.restoreBtn.MouseButton1Click:Connect(function()
	restoreClothing()
	commit()
	refreshWardrobe()
	notify("Default clothing restored.", THEME.Accent)
end)
ui.clearAllBtn.MouseButton1Click:Connect(function()
	clearAccessories()
	commit()
	updateCards()
	refreshEquipped()
	notify("Removed all accessories.", THEME.Danger)
end)
ui.saveBtn.MouseButton1Click:Connect(function()
	saveOutfit(ui.nameBox.Text)
	refreshOutfits()
end)
local function paintToggle()
	tween(ui.toggleBg, 0.2, {BackgroundColor3 = settings.autoReapply and THEME.Success or THEME.Card})
	tween(ui.knob, 0.2, {Position = settings.autoReapply and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)})
end
ui.toggleBg.MouseButton1Click:Connect(function()
	settings.autoReapply = not settings.autoReapply
	paintToggle()
end)
paintToggle()
ui.exportBtn.MouseButton1Click:Connect(function()
	exportSkin()
end)
closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
end)
ui.closeBtn2.MouseButton1Click:Connect(function()
	setVisible(false)
end)

local function onCharacter(char)
	originals, appliedClothing = {}, {}
	task.spawn(function()
		waitForAppearance(char)
		snapshotOriginals()
		if settings.autoReapply and sessionOutfit then
			applyOutfit(sessionOutfit)
		end
		updateCards()
	end)
end
Dominant.Connect(LocalPlayer.CharacterAdded, onCharacter)
if LocalPlayer.Character then
	onCharacter(LocalPlayer.Character)
end

showTab("Catalog")
task.spawn(fetchCatalog, true)

return {
	open = function()
		updateCards()
		setVisible(true)
	end,
	toggle = function()
		if visible then
			setVisible(false)
		else
			updateCards()
			setVisible(true)
		end
	end,
}
end

local instance

function M.open(ctx)
    if not instance then
        local dominant = ctx.modules:require("shared/ui_theme").make(ctx)
        local ok, result = pcall(build, dominant)
        if not ok then
            ctx.warn("[Dominant] Avatar editor failed: " .. tostring(result))
            ctx.notify("Avatar editor failed to start", "error", 4)
            return
        end
        instance = result
    end
    instance.open()
end

return M
