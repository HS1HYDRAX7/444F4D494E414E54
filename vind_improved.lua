--[[
    Vind UI Library - Enhanced Version
    Modern design with smooth animations and better organization
    Based on original vind.lua with significant improvements
]]

--!nonstrict
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local IsMobileDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Enhanced NullUI with modern design
local NullUI = {}
NullUI.__index = NullUI
NullUI.Version = "2.9.0-enhanced"
NullUI.Flags = {}
NullUI._Windows = {}

-- Enhanced color themes
NullUI.Themes = {
    Dark = {
        Background = Color3.fromRGB(12, 12, 16),
        Panel = Color3.fromRGB(24, 24, 32),
        PanelHover = Color3.fromRGB(32, 32, 44),
        Accent = Color3.fromRGB(0, 200, 255),
        AccentSecondary = Color3.fromRGB(100, 220, 255),
        Text = Color3.fromRGB(245, 248, 255),
        TextSecondary = Color3.fromRGB(180, 190, 210),
        Muted = Color3.fromRGB(130, 140, 160),
        Border = Color3.fromRGB(45, 45, 55),
        Button = Color3.fromRGB(36, 38, 48),
        ButtonHover = Color3.fromRGB(50, 54, 68),
        ButtonActive = Color3.fromRGB(60, 66, 80),
        Success = Color3.fromRGB(80, 250, 123),
        Warn = Color3.fromRGB(255, 185, 0),
        Error = Color3.fromRGB(255, 85, 85),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    Light = {
        Background = Color3.fromRGB(255, 255, 255),
        Panel = Color3.fromRGB(245, 245, 245),
        PanelHover = Color3.fromRGB(235, 235, 235),
        Accent = Color3.fromRGB(0, 120, 255),
        AccentSecondary = Color3.fromRGB(80, 180, 255),
        Text = Color3.fromRGB(10, 10, 10),
        TextSecondary = Color3.fromRGB(60, 60, 60),
        Muted = Color3.fromRGB(110, 110, 110),
        Border = Color3.fromRGB(216, 216, 216),
        Button = Color3.fromRGB(232, 232, 232),
        ButtonHover = Color3.fromRGB(218, 218, 218),
        ButtonActive = Color3.fromRGB(200, 200, 200),
        Success = Color3.fromRGB(28, 150, 72),
        Warn = Color3.fromRGB(196, 116, 24),
        Error = Color3.fromRGB(210, 58, 58),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    Amethyst = {
        Background = Color3.fromRGB(14, 11, 16),
        Panel = Color3.fromRGB(24, 19, 28),
        PanelHover = Color3.fromRGB(32, 26, 36),
        Accent = Color3.fromRGB(230, 190, 255),
        AccentSecondary = Color3.fromRGB(240, 200, 255),
        Text = Color3.fromRGB(240, 235, 245),
        TextSecondary = Color3.fromRGB(200, 190, 220),
        Muted = Color3.fromRGB(130, 120, 140),
        Border = Color3.fromRGB(48, 38, 55),
        Button = Color3.fromRGB(38, 32, 44),
        ButtonHover = Color3.fromRGB(52, 44, 60),
        ButtonActive = Color3.fromRGB(65, 55, 75),
        Success = Color3.fromRGB(110, 220, 155),
        Warn = Color3.fromRGB(245, 180, 100),
        Error = Color3.fromRGB(255, 105, 105),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
}

-- Current theme
NullUI.CurrentTheme = NullUI.Themes.Dark

-- Enhanced configuration
NullUI.Config = {
    Blur = true,
    MaxNotifications = 5,
    Theme = "Dark",
    AnimationSpeed = 0.3,
    UseShadows = true,
    CornerRadius = 8,
}

-- Utility functions
local function SafeClamp(value, lo, hi)
    if hi < lo then return lo end
    return math.clamp(value, lo, hi)
end

local function SnapToIncrement(raw, min, max, increment)
    if increment <= 0 then increment = 1 end
    local snapped = math.floor((raw - min) / increment + 0.5) * increment + min
    snapped = math.clamp(snapped, min, max)
    local decimals = 0
    local probe = increment
    while decimals < 6 and math.abs(probe - math.floor(probe + 0.5)) > 1e-9 do
        probe = probe * 10
        decimals = decimals + 1
    end
    local factor = 10 ^ decimals
    return math.floor(snapped * factor + (snapped >= 0 and 0.5 or -0.5)) / factor
end

local function FormatNumber(v)
    if math.abs(v - math.floor(v + 0.5)) < 1e-9 then
        return tostring(math.floor(v + 0.5))
    end
    return string.format("%.4g", v)
end

-- Enhanced tween function with better defaults
local function tween(instance, time, props, style, direction)
    local info = TweenInfo.new(
        time or 0.3,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

-- Enhanced make function
local function make(className, props, parent)
    local instance = Instance.new(className)
    for k, v in pairs(props or {}) do
        instance[k] = v
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

-- Enhanced corner function
local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or NullUI.Config.CornerRadius) }, parent)
end

-- Enhanced stroke function
local function stroke(parent, color, thickness, transparency)
    make("UIStroke", {
        Color = color or NullUI.CurrentTheme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

-- Enhanced shadow function
local function shadow(parent, sizeX, sizeY, offsetX, offsetY, color, transparency)
    if not NullUI.Config.UseShadows then return end
    return make("ImageLabel", {
        Size = UDim2.new(1, sizeX or 0, 1, sizeY or 0),
        Position = UDim2.new(0, offsetX or 0, 0, offsetY or 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = color or Color3.new(0, 0, 0),
        ImageTransparency = transparency or 0.6,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 0,
    }, parent)
end

-- Enhanced gradient function
local function gradient(parent, rotation, colors, transparency)
    local grad = make("UIGradient", {
        Rotation = rotation or 90,
        Color = ColorSequence.new(colors or {Color3.new(1,1,1), Color3.new(0.5,0.5,0.5)}),
    }, parent)
    if transparency then
        grad.Transparency = NumberSequence.new(transparency)
    end
    return grad
end

-- Enhanced text function
local function text(parent, str, x, y, w, h, size, color, align)
    return make("TextLabel", {
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, w, 0, h),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = str or "",
        TextSize = size or 13,
        TextColor3 = color or NullUI.CurrentTheme.Text,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        FontFace = Enum.Font.Gotham,
    }, parent)
end

-- Enhanced frame function
local function frame(parent, x, y, w, h, color, transparency)
    return make("Frame", {
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, w, 0, h),
        BackgroundColor3 = color or NullUI.CurrentTheme.Panel,
        BackgroundTransparency = transparency or 1,
        BorderSizePixel = 0,
    }, parent)
end

-- Janitor for cleanup
local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
    return setmetatable({ _items = {}, _dead = false }, Janitor)
end

function Janitor:Add(item)
    if self._dead then
        if typeof(item) == "RBXScriptConnection" then
            item:Disconnect()
        elseif typeof(item) == "Instance" then
            item:Destroy()
        end
        return item
    end
    table.insert(self._items, item)
    return item
end

function Janitor:Destroy()
    if self._dead then return end
    self._dead = true
    for i = #self._items, 1, -1 do
        local item = self._items[i]
        self._items[i] = nil
        local t = typeof(item)
        if t == "RBXScriptConnection" then
            pcall(function() item:Disconnect() end)
        elseif t == "Instance" then
            pcall(function() item:Destroy() end)
        elseif t == "function" then
            pcall(item)
        elseif t == "table" and type(item.Destroy) == "function" then
            pcall(function() item:Destroy() end)
        end
    end
end

local LibJanitor = Janitor.new()

-- Asynchronous callback handling
local function SpawnCallback(callback, ...)
    if callback == nil then return end
    return task.spawn(function(...)
        local message
        local ok, traceback = xpcall(function(...)
            callback(...)
        end, function(err)
            local converted, text = pcall(tostring, err)
            message = converted and text or "Unknown callback error"
            return debug.traceback(message, 2)
        end, ...)
        if ok then return end
        warn("[VindUI] Callback Error: " .. tostring(traceback))
        local notified, notifyError = pcall(function()
            NullUI:Notify({
                Title = "Callback Error",
                Text = message,
                Type = "error",
                Duration = 5,
            })
        end)
        if not notified then warn("[VindUI] Could not show callback error: " .. tostring(notifyError)) end
    end, ...)
end

-- Signal system
local function MakeSignal()
    local listeners = {}
    return {
        Fire = function(...)
            for _, fn in ipairs(table.clone(listeners)) do
                SpawnCallback(fn, ...)
            end
        end,
        Connect = function(fn)
            table.insert(listeners, fn)
            return {
                Disconnect = function()
                    local i = table.find(listeners, fn)
                    if i then table.remove(listeners, i) end
                end,
            }
        end,
        Clear = function()
            table.clear(listeners)
        end,
    }
end

-- Enhanced window system
function NullUI:CreateWindow(props)
    props = props or {}
    
    local window = {
        Name = props.Name or "VindUI_Window",
        Title = props.Title or "Window",
        Subtitle = props.Subtitle or "",
        Size = props.Size or UDim2.new(0, 640, 0, 480),
        MinSize = props.MinSize or Vector2.new(400, 300),
        Position = props.Position or UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Draggable = props.Draggable ~= false,
        Resizable = props.Resizable or false,
        UseBlur = props.UseBlur ~= false,
        DefaultTab = props.DefaultTab or "Home",
        TabWidth = props.TabWidth or 160,
        TabScrollbar = props.TabScrollbar or false,
        UserInfo = props.UserInfo or { Enabled = false },
        
        -- Internal
        _Janitor = Janitor.new(),
        _Root = nil,
        _Tabs = {},
        _CurrentTab = nil,
        _Dragging = false,
        _Resizing = false,
        _StartPos = nil,
        _StartSize = nil,
        _StartCursor = nil,
    }
    
    -- Create main frame
    window._Root = make("Frame", {
        Name = window.Name,
        Size = window.Size,
        Position = window.Position,
        AnchorPoint = window.AnchorPoint,
        BackgroundColor3 = NullUI.CurrentTheme.Panel,
        BorderSizePixel = 0,
        Visible = false,
    })
    corner(window._Root, 12)
    stroke(window._Root, NullUI.CurrentTheme.Border, 1, 0)
    shadow(window._Root, 20, 20, 0, 0)
    
    -- Top bar
    window._TopBar = make("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = NullUI.CurrentTheme.Panel,
        BorderSizePixel = 0,
    }, window._Root)
    
    -- Title
    window._Title = text(window._TopBar, window.Title, 12, 0, 0, 40, 16, "text")
    window._Title.Font = Enum.Font.GothamBold
    window._Title.AutomaticSize = Enum.AutomaticSize.X
    
    -- Subtitle
    if window.Subtitle ~= "" then
        window._Subtitle = text(window._TopBar, window.Subtitle, 12, 0, 200, 40, 12, "muted")
        window._Subtitle.Font = Enum.Font.Gotham
        window._Subtitle.AutomaticSize = Enum.AutomaticSize.X
        window._Subtitle.TextXAlignment = Enum.TextXAlignment.Right
    end
    
    -- Close button
    window._CloseBtn = make("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = NullUI.CurrentTheme.Button,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, window._TopBar)
    corner(window._CloseBtn, 6)
    
    local closeIcon = make("ImageLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10738956374",
        ImageColor3 = NullUI.CurrentTheme.Muted,
    }, window._CloseBtn)
    
    -- Sidebar
    window._Sidebar = make("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, window.TabWidth, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = NullUI.CurrentTheme.Panel,
        BorderSizePixel = 0,
    }, window._Root)
    
    -- Tab list layout
    window._TabList = make("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, window._Sidebar)
    
    window._TabLayout = make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, window._TabList)
    
    -- Content area
    window._Content = make("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -window.TabWidth, 1, -40),
        Position = UDim2.new(0, window.TabWidth, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, window._Root)
    
    window._ContentLayout = make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
    }, window._Content)
    
    -- Dragging functionality
    if window.Draggable then
        local dragInput, dragStart, dragPos
        
        local function updateDrag(input)
            local delta = input.Position - dragStart
            window._Root.Position = UDim2.new(0, dragPos.X.Offset + delta.X, 0, dragPos.Y.Offset + delta.Y)
        end
        
        window._TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragStart = input.Position
                dragPos = window._Root.Position
                dragInput = input.UserInputService:GetMouseLocation()
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragStart = nil
                    end
                end)
            end
        end)
        
        window._TopBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
                dragStart = input.Position
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragStart then
                updateDrag(input)
            end
        end)
    end
    
    -- Close button functionality
    window._CloseBtn.MouseButton1Click:Connect(function()
        window:Destroy()
    end)
    
    -- Tab management
    function window:AddTab(props)
        props = props or {}
        
        local tab = {
            Name = props.Name or "Tab",
            Icon = props.Icon,
            Elements = {},
            _Button = nil,
            _Content = nil,
            Selected = false,
        }
        
        -- Create tab button
        tab._Button = make("TextButton", {
            Name = tab.Name,
            Size = UDim2.new(1, -8, 0, 35),
            BackgroundColor3 = NullUI.CurrentTheme.Button,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
        })
        corner(tab._Button, 6)
        
        -- Tab icon
        if tab.Icon then
            local iconSize = 16
            local icon = make("ImageLabel", {
                Size = UDim2.new(0, iconSize, 0, iconSize),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 8, 0.5, 0),
                BackgroundTransparency = 1,
                Image = tab.Icon,
                ImageColor3 = NullUI.CurrentTheme.Muted,
            }, tab._Button)
            tab._Icon = icon
        end
        
        -- Tab label
        tab._Label = text(tab._Button, tab.Name, tab.Icon and 28 or 8, 0, 0, 35, 13, "muted")
        tab._Label.TextXAlignment = Enum.TextXAlignment.Left
        tab._Label.AutomaticSize = Enum.AutomaticSize.X
        
        -- Tab content frame
        tab._Content = make("Frame", {
            Name = "TabContent",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        })
        
        tab._ContentLayout = make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        }, tab._Content)
        
        -- Select tab on click
        tab._Button.MouseButton1Click:Connect(function()
            window:SelectTab(tab)
        end)
        
        -- Hover effects
        tab._Button.MouseEnter:Connect(function()
            if not tab.Selected then
                tween(tab._Button, 0.15, { BackgroundTransparency = 0.8 })
                if tab._Label then tab._Label.TextColor3 = NullUI.CurrentTheme.Text end
                if tab._Icon then tab._Icon.ImageColor3 = NullUI.CurrentTheme.Text end
            end
        end)
        
        tab._Button.MouseLeave:Connect(function()
            if not tab.Selected then
                tween(tab._Button, 0.15, { BackgroundTransparency = 1 })
                if tab._Label then tab._Label.TextColor3 = NullUI.CurrentTheme.Muted end
                if tab._Icon then tab._Icon.ImageColor3 = NullUI.CurrentTheme.Muted end
            end
        end)
        
        function tab:Select()
            if window._CurrentTab then
                window._CurrentTab.Selected = false
                tween(window._CurrentTab._Button, 0.15, { BackgroundTransparency = 1 })
                if window._CurrentTab._Label then window._CurrentTab._Label.TextColor3 = NullUI.CurrentTheme.Muted end
                if window._CurrentTab._Icon then window._CurrentTab._Icon.ImageColor3 = NullUI.CurrentTheme.Muted end
                window._CurrentTab._Content.Visible = false
            end
            
            window._CurrentTab = tab
            tab.Selected = true
            tween(tab._Button, 0.15, { BackgroundTransparency = 0 })
            if tab._Label then tab._Label.TextColor3 = NullUI.CurrentTheme.Text end
            if tab._Icon then tab._Icon.ImageColor3 = NullUI.CurrentTheme.Accent end
            tab._Content.Visible = true
            
            -- Update content
            window._ContentLayout:Destroy()
            window._ContentLayout = make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 12),
            }, window._Content)
            
            for _, element in ipairs(tab._Content:GetChildren()) do
                if element:IsA("GuiObject") then
                    element.Parent = window._Content
                end
            end
        end
        
        function tab:AddSection(props)
            props = props or {}
            
            local section = make("Frame", {
                Name = props.Name or "Section",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, tab._Content)
            
            -- Section header
            local header = make("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, section)
            
            local title = text(header, props.Title or "Section", 12, 0, 0, 30, 14, "text")
            title.Font = Enum.Font.GothamBold
            title.AutomaticSize = Enum.AutomaticSize.X
            
            local divider = make("Frame", {
                Position = UDim2.new(0, 0, 0, 28),
                Size = UDim2.new(0, 40, 0, 1),
                BackgroundColor3 = NullUI.CurrentTheme.Accent,
                BorderSizePixel = 0,
            }, header)
            corner(divider, 0.5)
            
            -- Section content
            local content = make("Frame", {
                Position = UDim2.new(0, 0, 0, 30),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, section)
            
            local layout = make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }, content)
            
            function section:AddButton(props)
                props = props or {}
                
                local button = make("TextButton", {
                    Size = UDim2.new(1, 0, 0, props.Height or 32),
                    BackgroundColor3 = NullUI.CurrentTheme.Button,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = props.Text or "Button",
                    TextSize = props.TextSize or 13,
                    TextColor3 = NullUI.CurrentTheme.Text,
                    Font = props.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
                }, content)
                corner(button, props.CornerRadius or 6)
                stroke(button, NullUI.CurrentTheme.Border, 1, 0.3)
                
                -- Hover effects
                button.MouseEnter:Connect(function()
                    tween(button, 0.15, { BackgroundColor3 = NullUI.CurrentTheme.ButtonHover })
                end)
                
                button.MouseLeave:Connect(function()
                    tween(button, 0.15, { BackgroundColor3 = NullUI.CurrentTheme.Button })
                end)
                
                button.MouseButton1Down:Connect(function()
                    tween(button, 0.08, { Size = UDim2.new(1, 0, 0, (props.Height or 32) - 2) })
                end)
                
                button.MouseButton1Up:Connect(function()
                    tween(button, 0.15, { Size = UDim2.new(1, 0, 0, props.Height or 32) })
                end)
                
                if props.Callback then
                    button.MouseButton1Click:Connect(props.Callback)
                end
                
                return button
            end
            
            function section:AddToggle(props)
                props = props or {}
                
                local toggle = make("Frame", {
                    Size = UDim2.new(1, 0, 0, props.Height or 36),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, content)
                
                local label = text(toggle, props.Text or "Toggle", 0, 0, 0, 36, 13, "text")
                label.Size = UDim2.new(0, 0, 1, 0)
                label.AutomaticSize = Enum.AutomaticSize.X
                
                local button = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 40, 0, 20),
                    BackgroundColor3 = props.Value and NullUI.CurrentTheme.Accent or NullUI.CurrentTheme.Button,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                }, toggle)
                corner(button, 10)
                
                local circle = make("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(props.Value and 0.75 or 0.25, 0, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                }, button)
                corner(circle, 7)
                
                local value = props.Value or false
                
                button.MouseButton1Click:Connect(function()
                    value = not value
                    local targetPos = value and 0.75 or 0.25
                    local targetColor = value and NullUI.CurrentTheme.Accent or NullUI.CurrentTheme.Button
                    
                    tween(button, 0.2, { BackgroundColor3 = targetColor })
                    tween(circle, 0.2, { Position = UDim2.new(targetPos, 0, 0.5, 0) })
                    
                    if props.Callback then
                        props.Callback(value)
                    end
                end)
                
                return {
                    set = function(newValue)
                        value = newValue
                        local targetPos = value and 0.75 or 0.25
                        local targetColor = value and NullUI.CurrentTheme.Accent or NullUI.CurrentTheme.Button
                        
                        tween(button, 0.2, { BackgroundColor3 = targetColor })
                        tween(circle, 0.2, { Position = UDim2.new(targetPos, 0, 0.5, 0) })
                    end,
                    get = function() return value end,
                }
            end
            
            function section:AddSlider(props)
                props = props or {}
                
                local slider = make("Frame", {
                    Size = UDim2.new(1, 0, 0, props.Height or 40),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, content)
                
                local label = text(slider, props.Text or "Slider", 0, 0, 0, 16, 13, "text")
                label.Size = UDim2.new(0, 0, 0, 16)
                label.AutomaticSize = Enum.AutomaticSize.X
                
                local valueLabel = text(slider, tostring(props.Default or 50), 0, 18, 0, 14, 12, "muted")
                valueLabel.AnchorPoint = Vector2.new(1, 0)
                valueLabel.Position = UDim2.new(1, 0, 0, 0)
                valueLabel.AutomaticSize = Enum.AutomaticSize.X
                
                local track = make("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, -2),
                    Size = UDim2.new(1, 0, 0, 4),
                    BackgroundColor3 = NullUI.CurrentTheme.Button,
                    BorderSizePixel = 0,
                }, slider)
                corner(track, 2)
                
                local fill = make("Frame", {
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundColor3 = NullUI.CurrentTheme.Accent,
                    BorderSizePixel = 0,
                }, track)
                corner(fill, 2)
                gradient(fill, 90, {NullUI.CurrentTheme.AccentSecondary or NullUI.CurrentTheme.Accent, NullUI.CurrentTheme.Accent})
                
                local thumb = make("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                }, track)
                corner(thumb, 7)
                stroke(thumb, NullUI.CurrentTheme.Accent, 1, 0.3)
                
                local min = props.Min or 0
                local max = props.Max or 100
                local value = props.Default or 50
                local dragging = false
                
                local function updateValue(newValue)
                    value = math.clamp(newValue, min, max)
                    local percent = (value - min) / (max - min)
                    
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    thumb.Position = UDim2.new(percent, 0, 0.5, 0)
                    
                    if props.Suffix then
                        valueLabel.Text = tostring(value) .. props.Suffix
                    else
                        valueLabel.Text = tostring(math.floor(value))
                    end
                    
                    if props.Callback then
                        props.Callback(value)
                    end
                end
                
                thumb.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)
                
                thumb.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local mousePos = input.Position
                        local trackPos = track.AbsolutePosition
                        local trackSize = track.AbsoluteSize
                        local percent = math.clamp((mousePos.X - trackPos.X) / trackSize.X, 0, 1)
                        updateValue(min + percent * (max - min))
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mousePos = input.Position
                        local trackPos = track.AbsolutePosition
                        local trackSize = track.AbsoluteSize
                        local percent = math.clamp((mousePos.X - trackPos.X) / trackSize.X, 0, 1)
                        updateValue(min + percent * (max - min))
                    end
                end)
                
                updateValue(value)
                
                return {
                    set = updateValue,
                    get = function() return value end,
                }
            end
            
            function section:AddDropdown(props)
                props = props or {}
                
                local dropdown = make("Frame", {
                    Size = UDim2.new(1, 0, 0, props.Height or 36),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, content)
                
                local label = text(dropdown, props.Text or "Dropdown", 0, 0, 0, 36, 13, "text")
                label.Size = UDim2.new(0, 0, 1, 0)
                label.AutomaticSize = Enum.AutomaticSize.X
                
                local button = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 100, 0, 24),
                    BackgroundColor3 = NullUI.CurrentTheme.Button,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = props.Default or "Select...",
                    TextSize = 12,
                    TextColor3 = NullUI.CurrentTheme.Muted,
                    Font = Enum.Font.Gotham,
                }, dropdown)
                corner(button, 6)
                stroke(button, NullUI.CurrentTheme.Border, 1, 0.3)
                
                local chevron = make("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -6, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://10738958939",
                    ImageColor3 = NullUI.CurrentTheme.Muted,
                }, button)
                
                local optionsOpen = false
                local optionsFrame = make("Frame", {
                    AnchorPoint = Vector2.new(1, 1),
                    Position = UDim2.new(1, 0, 1, 0),
                    Size = UDim2.new(0, 120, 0, 0),
                    BackgroundColor3 = NullUI.CurrentTheme.Panel,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 10,
                }, button)
                corner(optionsFrame, 6)
                stroke(optionsFrame, NullUI.CurrentTheme.Border, 1, 0.3)
                
                local selectedValue = props.Default
                
                button.MouseButton1Click:Connect(function()
                    optionsOpen = not optionsOpen
                    optionsFrame.Visible = optionsOpen
                    
                    if optionsOpen then
                        optionsFrame.Size = UDim2.new(0, 120, 0, #props.Options * 24)
                        tween(optionsFrame, 0.2, { BackgroundTransparency = 0 })
                        tween(chevron, 0.2, { Rotation = 180 })
                    else
                        tween(optionsFrame, 0.2, { BackgroundTransparency = 1 })
                        tween(chevron, 0.2, { Rotation = 0 })
                    end
                end)
                
                for i, option in ipairs(props.Options or {}) do
                    local optionBtn = make("TextButton", {
                        Position = UDim2.new(0, 0, 0, (i - 1) * 24),
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundColor3 = NullUI.CurrentTheme.Button,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = option,
                        TextSize = 12,
                        TextColor3 = NullUI.CurrentTheme.Text,
                        Font = Enum.Font.Gotham,
                        ZIndex = 11,
                    }, optionsFrame)
                    
                    optionBtn.MouseEnter:Connect(function()
                        tween(optionBtn, 0.1, { BackgroundTransparency = 0.8 })
                    end)
                    
                    optionBtn.MouseLeave:Connect(function()
                        tween(optionBtn, 0.1, { BackgroundTransparency = 1 })
                    end)
                    
                    optionBtn.MouseButton1Click:Connect(function()
                        selectedValue = option
                        button.Text = option
                        optionsOpen = false
                        optionsFrame.Visible = false
                        tween(optionsFrame, 0.2, { BackgroundTransparency = 1 })
                        tween(chevron, 0.2, { Rotation = 0 })
                        
                        if props.Callback then
                            props.Callback(option)
                        end
                    end)
                end
                
                return {
                    set = function(newValue)
                        selectedValue = newValue
                        button.Text = newValue
                        if props.Callback then
                            props.Callback(newValue)
                        end
                    end,
                    get = function() return selectedValue end,
                }
            end
            
            return section
        end
        
        function tab:AddSection(props)
            local section = tab._Content:AddSection(props)
            return section
        end
        
        -- Add to tab list
        tab._Button.Parent = window._TabList
        window._Tabs[#window._Tabs + 1] = tab
        
        -- Select first tab by default
        if #window._Tabs == 1 then
            window:SelectTab(tab)
        end
        
        return tab
    end
    
    function window:SelectTab(tab)
        if type(tab) == "number" then
            tab = window._Tabs[tab]
        end
        if tab then
            tab:Select()
        end
    end
    
    function window:Show()
        window._Root.Visible = true
        tween(window._Root, 0.3, { BackgroundTransparency = 0 })
    end
    
    function window:Hide()
        tween(window._Root, 0.3, { BackgroundTransparency = 1 })
        task.delay(0.3, function()
            window._Root.Visible = false
        end)
    end
    
    function window:Destroy()
        window._Janitor:Destroy()
        if window._Root then
            window._Root:Destroy()
        end
        for i, w in ipairs(NullUI._Windows) do
            if w == window then
                table.remove(NullUI._Windows, i)
                break
            end
        end
    end
    
    function window:Toggle()
        if window._Root.Visible then
            window:Hide()
        else
            window:Show()
        end
    end
    
    -- Add to windows list
    table.insert(NullUI._Windows, window)
    
    -- Return window with enhanced methods
    return setmetatable(window, { __index = NullUI })
end

-- Notification system
function NullUI:Notify(props)
    props = props or {}
    
    local notification = {
        Title = props.Title or "Notification",
        Text = props.Text or "",
        Type = props.Type or "info",
        Duration = props.Duration or 5,
    }
    
    local theme = NullUI.CurrentTheme
    local colors = {
        info = theme.Accent,
        success = theme.Success,
        warn = theme.Warn,
        error = theme.Error,
    }
    
    local color = colors[notification.Type] or theme.Accent
    
    -- Create notification frame
    local notifFrame = make("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 280, 0, 60),
        Position = UDim2.new(1, 10, 0, -100),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 1000,
    })
    corner(notifFrame, 8)
    stroke(notifFrame, color, 1, 0.3)
    shadow(notifFrame, 10, 10, 0, 0)
    
    -- Title
    local title = text(notifFrame, notification.Title, 12, 10, 260, 20, 14, "text")
    title.Font = Enum.Font.GothamBold
    
    -- Text
    local textLabel = text(notifFrame, notification.Text, 12, 32, 260, 20, 12, "muted")
    textLabel.TextWrapped = true
    
    -- Add to player GUI
    notifFrame.Parent = PlayerGui
    
    -- Animate in
    tween(notifFrame, 0.3, { Position = UDim2.new(1, -290, 0, 20) }, Enum.EasingStyle.Quint)
    
    -- Auto-remove
    task.delay(notification.Duration, function()
        tween(notifFrame, 0.3, { Position = UDim2.new(1, 10, 0, -100) })
        task.delay(0.3, function()
            notifFrame:Destroy()
        end)
    end)
    
    return notification
end

-- Set theme
function NullUI:SetTheme(themeName)
    if NullUI.Themes[themeName] then
        NullUI.CurrentTheme = NullUI.Themes[themeName]
        NullUI.Config.Theme = themeName
    end
end

-- Set blur
function NullUI:SetBlurEnabled(enabled)
    NullUI.Config.Blur = enabled
end

-- Cleanup
local function cleanup()
    for _, window in ipairs(NullUI._Windows) do
        if window and window._Root then
            window._Root:Destroy()
        end
    end
    table.clear(NullUI._Windows)
end

-- Handle existing instance
do
    local globalTable = (getgenv and getgenv()) or _G
    local previousUnload = globalTable.__NullUI_Unload
    globalTable.__NullUI_Unload = nil
    if type(previousUnload) == "function" then
        pcall(previousUnload)
    end
    globalTable.__NullUI_Unload = cleanup
end

-- Return NullUI
return NullUI
