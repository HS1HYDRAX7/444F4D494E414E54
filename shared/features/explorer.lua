local M = {}

function M.open(ctx, Feat, Dominant)
    local function L(key)
        return ctx.L(key)
    end
    Feat.Background.Ensure()
    Feat.Background.CloseBrowser()

    local TweenService = game:GetService("TweenService")
    local P = Dominant.OphynPalette
    local parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local W = math.floor(math.min(560, viewport.X - 32))
    local H = math.floor(math.min(430, viewport.Y - 32))
    local state = {
        folder = Feat.Background.Root,
        selected = nil,
        query = "",
        cards = {},
        lastClick = { path = nil, time = 0 },
    }
    local refreshGrid

    local function make(class, props, target)
        local obj = Instance.new(class)
        for key, value in pairs(props or {}) do
            obj[key] = value
        end
        if target then
            obj.Parent = target
        end
        return obj
    end

    local function round(obj, radius, color, transparency)
        make("UICorner", { CornerRadius = UDim.new(0, radius) }, obj)
        if color then
            return make("UIStroke", { Color = color, Transparency = transparency or 0, Thickness = 1 }, obj)
        end
    end

    local function label(target, text, size, color, bold, props)
        local lbl = make("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            TextSize = size,
            TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, target)
        Dominant.StyleFont(lbl, bold)
        for key, value in pairs(props or {}) do
            lbl[key] = value
        end
        return lbl
    end

    local function button(text, target, size, primary)
        local base = primary and P.submitBg or P.btn2
        local btn = make("TextButton", {
            AutoButtonColor = false,
            Text = text,
            TextSize = 12,
            Size = size,
            TextColor3 = primary and P.submitText or P.text,
            BackgroundColor3 = base,
        }, target)
        Dominant.StyleFont(btn, true)
        round(btn, 8, P.stroke, primary and 1 or 0.4)
        btn.MouseEnter:Connect(function()
            local hover = primary and base:Lerp(Color3.new(1, 1, 1), 0.1) or P.btn2Hover
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hover }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
        end)
        return btn
    end

    local gui = make("ScreenGui", {
        Name = "DominantBackgroundExplorer",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 10050,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)
    Feat.Background.Gui = gui

    local dim = make("TextButton", {
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        Size = UDim2.fromScale(1, 1),
    }, gui)

    local win = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H),
        BackgroundColor3 = P.card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    round(win, 14, P.stroke, 0)
    local scale = make("UIScale", { Scale = 0.94 }, win)
    TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    label(win, L("bg_browse"), 15, P.text, true, {
        Position = UDim2.fromOffset(16, 12),
        Size = UDim2.new(1, -64, 0, 20),
    })
    local subtitle = label(win, Feat.Background.Root, 11, P.muted, false, {
        Position = UDim2.fromOffset(16, 32),
        Size = UDim2.new(1, -64, 0, 14),
    })
    local closeBtn = button("×", win, UDim2.fromOffset(30, 30), false)
    closeBtn.Position = UDim2.new(1, -44, 0, 12)
    closeBtn.TextSize = 18

    local backBtn = button(L("bg_back"), win, UDim2.fromOffset(72, 30), false)
    backBtn.Position = UDim2.fromOffset(16, 56)
    local search = make("TextBox", {
        PlaceholderText = L("bg_search"),
        PlaceholderColor3 = P.muted,
        Text = "",
        TextColor3 = P.text,
        TextSize = 12,
        ClearTextOnFocus = false,
        BackgroundColor3 = P.input,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(96, 56),
        Size = UDim2.new(1, -204, 0, 30),
    }, win)
    Dominant.StyleFont(search, false)
    round(search, 8, P.stroke, 0.2)
    make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, search)
    local refreshBtn = button(L("bg_refresh"), win, UDim2.fromOffset(84, 30), false)
    refreshBtn.Position = UDim2.new(1, -100, 0, 56)

    local grid = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 96),
        Size = UDim2.new(1, -24, 1, -152),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = P.muted,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
    }, win)
    make("UIGridLayout", {
        CellSize = UDim2.fromOffset(120, 104),
        CellPadding = UDim2.fromOffset(10, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }, grid)

    local selectedLabel = label(win, L("bg_folder_hint"), 12, P.muted, false, {
        Position = UDim2.new(0, 16, 1, -38),
        Size = UDim2.new(1, -228, 0, 24),
    })
    local clearBtn = button(L("bg_clear"), win, UDim2.fromOffset(84, 30), false)
    clearBtn.Position = UDim2.new(1, -196, 1, -42)
    local applyBtn = button(L("bg_apply"), win, UDim2.fromOffset(96, 30), true)
    applyBtn.Position = UDim2.new(1, -106, 1, -42)

    local function collect()
        local nodes = {}
        local query = string.lower(state.query)
        if query ~= "" then
            for _, node in ipairs(Feat.Background.Tree(Feat.Background.Root, 0)) do
                if node.Kind == "file" and string.find(string.lower(node.Name), query, 1, true) then
                    table.insert(nodes, node)
                end
            end
            return nodes
        end
        local folders, files = {}, {}
        if type(listfiles) == "function" then
            local ok, entries = pcall(listfiles, state.folder)
            if ok and type(entries) == "table" then
                for _, entry in ipairs(entries) do
                    local name = Feat.Background.Basename(entry)
                    local isDir = false
                    if type(isfolder) == "function" then
                        local okDir, result = pcall(isfolder, entry)
                        isDir = okDir and result == true
                    end
                    if isDir then
                        table.insert(folders, { Path = entry, Name = name, Kind = "folder" })
                    elseif Feat.Background.IsImage(entry) then
                        table.insert(files, {
                            Path = entry,
                            Name = name,
                            Kind = "file",
                            Gif = Feat.Background.IsGif(entry),
                        })
                    end
                end
            end
        end
        local function byName(a, b)
            return a.Name:lower() < b.Name:lower()
        end
        table.sort(folders, byName)
        table.sort(files, byName)
        for _, node in ipairs(folders) do
            table.insert(nodes, node)
        end
        for _, node in ipairs(files) do
            table.insert(nodes, node)
        end
        return nodes
    end

    local function setSelectedVisual()
        for path, entry in pairs(state.cards) do
            local on = state.selected ~= nil and state.selected.Path == path
            entry.stroke.Color = on and P.accent or P.stroke
            entry.stroke.Transparency = on and 0 or 0.3
            entry.stroke.Thickness = on and 2 or 1
        end
    end

    local function setSelection(node)
        state.selected = node
        Feat.Background.Selected = node and node.Path or nil
        setSelectedVisual()
        if node and node.Kind == "file" then
            selectedLabel.Text = node.Name .. (node.Gif and "  · GIF" or "")
            selectedLabel.TextColor3 = P.text
        else
            selectedLabel.Text = L("bg_folder_hint")
            selectedLabel.TextColor3 = P.muted
        end
    end

    local function applyNode(node)
        if Feat.Background.Apply(node.Path) then
            Dominant.Notify(L("bg_applied"), "success", 3)
            Feat.Background.CloseBrowser()
        else
            Dominant.Notify(L("bg_failed"), "error", 3)
        end
    end

    local function addCard(node, order)
        local isFolder = node.Kind == "folder"
        local item = make("TextButton", {
            AutoButtonColor = false,
            Text = "",
            BackgroundColor3 = P.input,
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, grid)
        local outline = round(item, 10, P.stroke, 0.3)
        if isFolder then
            label(item, "▸", 26, P.muted, true, {
                Position = UDim2.fromOffset(0, 10),
                Size = UDim2.new(1, 0, 0, 56),
                TextXAlignment = Enum.TextXAlignment.Center,
            })
        else
            local thumb = make("ImageLabel", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(4, 4),
                Size = UDim2.new(1, -8, 0, 70),
                ScaleType = Enum.ScaleType.Crop,
                Image = Feat.Background.Resolve(node.Path) or "",
            }, item)
            round(thumb, 8)
            if node.Gif then
                local badge = label(item, "GIF", 9, P.submitText, true, {
                    BackgroundColor3 = P.submitBg,
                    BackgroundTransparency = 0,
                    Position = UDim2.new(1, -38, 0, 8),
                    Size = UDim2.fromOffset(30, 16),
                    TextXAlignment = Enum.TextXAlignment.Center,
                })
                round(badge, 5)
            end
        end
        label(item, node.Name, 11, isFolder and P.muted or P.text, false, {
            Position = UDim2.new(0, 8, 1, -26),
            Size = UDim2.new(1, -16, 0, 20),
        })
        state.cards[node.Path] = { frame = item, stroke = outline }
        item.MouseEnter:Connect(function()
            TweenService:Create(item, TweenInfo.new(0.12), { BackgroundColor3 = P.btn2 }):Play()
        end)
        item.MouseLeave:Connect(function()
            TweenService:Create(item, TweenInfo.new(0.12), { BackgroundColor3 = P.input }):Play()
        end)
        item.MouseButton1Click:Connect(function()
            if isFolder then
                state.folder = node.Path
                state.query = ""
                search.Text = ""
                setSelection(nil)
                refreshGrid()
                return
            end
            local now = os.clock()
            if state.lastClick.path == node.Path and now - state.lastClick.time < 0.4 then
                applyNode(node)
                return
            end
            state.lastClick = { path = node.Path, time = now }
            setSelection(node)
        end)
    end

    refreshGrid = function()
        for _, child in ipairs(grid:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        state.cards = {}
        local nodes = collect()
        subtitle.Text = state.query ~= "" and (L("bg_search") .. ": " .. state.query) or state.folder
        local atRoot = state.folder == Feat.Background.Root and state.query == ""
        backBtn.TextTransparency = atRoot and 0.55 or 0
        if #nodes == 0 then
            label(grid, L("bg_no_files"), 12, P.muted, false, {
                Size = UDim2.new(1, -8, 0, 40),
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
            })
        else
            for index, node in ipairs(nodes) do
                addCard(node, index)
            end
        end
        setSelectedVisual()
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        if search.Text ~= state.query then
            state.query = search.Text
            refreshGrid()
        end
    end)

    backBtn.MouseButton1Click:Connect(function()
        if state.query ~= "" then
            state.query = ""
            search.Text = ""
        elseif state.folder ~= Feat.Background.Root then
            local up = state.folder:match("^(.*)/[^/]+$")
            state.folder = (up and #up >= #Feat.Background.Root) and up or Feat.Background.Root
        else
            return
        end
        refreshGrid()
    end)

    refreshBtn.MouseButton1Click:Connect(function()
        Feat.Background.Ensure()
        refreshGrid()
        Dominant.Notify(L("bg_refresh"), "info", 2)
    end)

    clearBtn.MouseButton1Click:Connect(function()
        Feat.Background.Apply("")
        setSelection(nil)
        Dominant.Notify(L("bg_clear"), "info", 2)
    end)

    applyBtn.MouseButton1Click:Connect(function()
        if not state.selected or state.selected.Kind ~= "file" then
            Dominant.Notify(L("bg_no_files"), "warning", 3)
            return
        end
        applyNode(state.selected)
    end)

    dim.MouseButton1Click:Connect(Feat.Background.CloseBrowser)
    closeBtn.MouseButton1Click:Connect(Feat.Background.CloseBrowser)

    local preset = Feat.Background.Selected
    if preset then
        local presetFolder = preset:match("^(.*)/[^/]+$")
        if presetFolder and #presetFolder >= #Feat.Background.Root then
            state.folder = presetFolder
        end
    end
    refreshGrid()
    if preset then
        for _, node in ipairs(collect()) do
            if node.Path == preset then
                setSelection(node)
                break
            end
        end
    end
end

return M
