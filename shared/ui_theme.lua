local M = {}

local THEMES = {
	Amethyst = {
		bg = Color3.fromRGB(20, 16, 20),
		input = Color3.fromRGB(24, 19, 24),
		card = Color3.fromRGB(28, 22, 28),
		stroke = Color3.fromRGB(40, 32, 41),
		btn2 = Color3.fromRGB(42, 36, 43),
		btn2Hover = Color3.fromRGB(54, 47, 55),
		text = Color3.fromRGB(233, 229, 234),
		muted = Color3.fromRGB(125, 115, 126),
		accent = Color3.fromRGB(235, 199, 246),
		warn = Color3.fromRGB(240, 176, 108),
		success = Color3.fromRGB(120, 210, 140),
		error = Color3.fromRGB(240, 120, 120),

		submitBg = Color3.fromRGB(235, 199, 246),
		submitText = Color3.fromRGB(24, 18, 26),

		glowBase = Color3.fromRGB(226, 218, 230),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(235, 199, 246),

		confetti = {
			Color3.fromRGB(235, 199, 246),
			Color3.fromRGB(120, 210, 140),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(240, 176, 108),
			Color3.fromRGB(150, 190, 255),
		},
	},

	Carmim = {
		bg = Color3.fromRGB(10, 10, 14),
		input = Color3.fromRGB(16, 14, 16),
		card = Color3.fromRGB(22, 18, 20),
		stroke = Color3.fromRGB(48, 38, 42),
		btn2 = Color3.fromRGB(36, 30, 32),
		btn2Hover = Color3.fromRGB(52, 42, 46),
		text = Color3.fromRGB(248, 244, 246),
		muted = Color3.fromRGB(130, 122, 128),
		accent = Color3.fromRGB(230, 45, 55),
		warn = Color3.fromRGB(255, 190, 60),
		success = Color3.fromRGB(80, 250, 140),
		error = Color3.fromRGB(255, 90, 100),

		submitBg = Color3.fromRGB(230, 45, 55),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 120, 130),
		glowFrom = Color3.fromRGB(255, 90, 110),
		glowTo = Color3.fromRGB(180, 15, 40),

		confetti = {
			Color3.fromRGB(230, 45, 55),
			Color3.fromRGB(255, 120, 130),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 190, 60),
			Color3.fromRGB(80, 250, 140),
		},
	},

	Plant = {
		bg = Color3.fromRGB(28, 94, 56),
		input = Color3.fromRGB(23, 78, 46),
		card = Color3.fromRGB(34, 108, 65),
		stroke = Color3.fromRGB(58, 140, 92),
		btn2 = Color3.fromRGB(44, 122, 74),
		btn2Hover = Color3.fromRGB(56, 140, 88),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(188, 226, 202),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 214, 140),
		success = Color3.fromRGB(200, 255, 210),
		error = Color3.fromRGB(255, 150, 150),

		submitBg = Color3.fromRGB(96, 205, 122),
		submitText = Color3.fromRGB(14, 66, 36),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(235, 255, 240),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(150, 235, 170),
			Color3.fromRGB(96, 205, 122),
			Color3.fromRGB(255, 214, 140),
			Color3.fromRGB(210, 255, 220),
		},
	},

	["Plant-Dark"] = {
		bg = Color3.fromRGB(10, 10, 10),
		input = Color3.fromRGB(14, 16, 14),
		card = Color3.fromRGB(18, 22, 19),
		stroke = Color3.fromRGB(34, 42, 36),
		btn2 = Color3.fromRGB(28, 34, 29),
		btn2Hover = Color3.fromRGB(40, 48, 42),
		text = Color3.fromRGB(238, 242, 238),
		muted = Color3.fromRGB(122, 132, 124),
		accent = Color3.fromRGB(70, 214, 110),
		warn = Color3.fromRGB(240, 176, 108),
		success = Color3.fromRGB(120, 220, 150),
		error = Color3.fromRGB(240, 120, 120),

		submitBg = Color3.fromRGB(22, 101, 52),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(110, 255, 150),
		glowFrom = Color3.fromRGB(90, 240, 130),
		glowTo = Color3.fromRGB(30, 170, 70),

		confetti = {
			Color3.fromRGB(70, 214, 110),
			Color3.fromRGB(150, 245, 175),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(240, 176, 108),
			Color3.fromRGB(22, 101, 52),
		},
	},

	Dark = {
		bg = Color3.fromRGB(10, 10, 10),
		input = Color3.fromRGB(18, 18, 18),
		card = Color3.fromRGB(23, 23, 23),
		stroke = Color3.fromRGB(46, 46, 46),
		btn2 = Color3.fromRGB(34, 34, 34),
		btn2Hover = Color3.fromRGB(48, 48, 48),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(150, 150, 150),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(240, 176, 108),
		success = Color3.fromRGB(120, 210, 140),
		error = Color3.fromRGB(240, 120, 120),

		submitBg = Color3.fromRGB(66, 66, 66),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(210, 210, 210),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(200, 200, 200),
			Color3.fromRGB(140, 140, 140),
			Color3.fromRGB(240, 176, 108),
			Color3.fromRGB(120, 210, 140),
		},
	},

	Light = {
		bg = Color3.fromRGB(255, 255, 255),
		input = Color3.fromRGB(240, 240, 240),
		card = Color3.fromRGB(245, 245, 245),
		stroke = Color3.fromRGB(216, 216, 216),
		btn2 = Color3.fromRGB(232, 232, 232),
		btn2Hover = Color3.fromRGB(218, 218, 218),
		text = Color3.fromRGB(10, 10, 10),
		muted = Color3.fromRGB(110, 110, 110),
		accent = Color3.fromRGB(10, 10, 10),
		warn = Color3.fromRGB(196, 116, 24),
		success = Color3.fromRGB(28, 150, 72),
		error = Color3.fromRGB(210, 58, 58),

		submitBg = Color3.fromRGB(20, 20, 20),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(30, 30, 30),
		glowFrom = Color3.fromRGB(60, 60, 60),
		glowTo = Color3.fromRGB(0, 0, 0),

		confetti = {
			Color3.fromRGB(10, 10, 10),
			Color3.fromRGB(90, 90, 90),
			Color3.fromRGB(160, 160, 160),
			Color3.fromRGB(230, 150, 50),
			Color3.fromRGB(50, 170, 100),
		},
	},

	Violet = {
		bg = Color3.fromRGB(94, 64, 162),
		input = Color3.fromRGB(78, 52, 140),
		card = Color3.fromRGB(108, 78, 180),
		stroke = Color3.fromRGB(136, 108, 204),
		btn2 = Color3.fromRGB(120, 90, 192),
		btn2Hover = Color3.fromRGB(136, 106, 208),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(214, 202, 242),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 214, 140),
		success = Color3.fromRGB(200, 255, 210),
		error = Color3.fromRGB(255, 160, 170),

		submitBg = Color3.fromRGB(58, 32, 112),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(240, 232, 255),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(214, 190, 255),
			Color3.fromRGB(170, 130, 255),
			Color3.fromRGB(255, 214, 140),
			Color3.fromRGB(58, 32, 112),
		},
	},

	Midnight = {
		bg = Color3.fromRGB(26, 44, 104),
		input = Color3.fromRGB(18, 32, 80),
		card = Color3.fromRGB(34, 56, 124),
		stroke = Color3.fromRGB(62, 88, 158),
		btn2 = Color3.fromRGB(44, 70, 142),
		btn2Hover = Color3.fromRGB(58, 86, 164),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(190, 204, 240),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 214, 140),
		success = Color3.fromRGB(190, 255, 215),
		error = Color3.fromRGB(255, 150, 160),

		submitBg = Color3.fromRGB(52, 92, 196),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(226, 236, 255),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(170, 200, 255),
			Color3.fromRGB(100, 150, 255),
			Color3.fromRGB(255, 214, 140),
			Color3.fromRGB(52, 92, 196),
		},
	},

	Amber = {
		bg = Color3.fromRGB(160, 84, 16),
		input = Color3.fromRGB(132, 68, 10),
		card = Color3.fromRGB(176, 98, 28),
		stroke = Color3.fromRGB(206, 132, 62),
		btn2 = Color3.fromRGB(186, 108, 38),
		btn2Hover = Color3.fromRGB(200, 122, 52),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(255, 228, 196),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 240, 170),
		success = Color3.fromRGB(215, 255, 205),
		error = Color3.fromRGB(110, 18, 18),

		submitBg = Color3.fromRGB(110, 50, 6),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(255, 240, 220),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 220, 160),
			Color3.fromRGB(255, 180, 90),
			Color3.fromRGB(255, 240, 170),
			Color3.fromRGB(110, 50, 6),
		},
	},

	Indigo = {
		bg = Color3.fromRGB(20, 14, 58),
		input = Color3.fromRGB(15, 10, 46),
		card = Color3.fromRGB(28, 20, 76),
		stroke = Color3.fromRGB(50, 40, 112),
		btn2 = Color3.fromRGB(38, 29, 96),
		btn2Hover = Color3.fromRGB(52, 42, 122),
		text = Color3.fromRGB(240, 238, 255),
		muted = Color3.fromRGB(150, 142, 204),
		accent = Color3.fromRGB(150, 132, 255),
		warn = Color3.fromRGB(240, 190, 120),
		success = Color3.fromRGB(120, 220, 160),
		error = Color3.fromRGB(255, 120, 140),

		submitBg = Color3.fromRGB(84, 64, 210),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(160, 140, 255),
		glowFrom = Color3.fromRGB(140, 120, 255),
		glowTo = Color3.fromRGB(90, 70, 230),

		confetti = {
			Color3.fromRGB(150, 132, 255),
			Color3.fromRGB(200, 190, 255),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(240, 190, 120),
			Color3.fromRGB(84, 64, 210),
		},
	},
}

M.themes = THEMES
M.palette = THEMES.Dark
M.font = "rbxassetid://12187365364"

function M.make(ctx)
    local P = M.palette
    local connections = {}
    local objects = {}
    local dominant = {
        OphynPalette = P,
        OphynFont = M.font,
        Objects = objects,
        Conns = connections,
    }
    function dominant.Toast(text, kind, duration)
        ctx.notify(tostring(text), kind or "info", duration or 3)
    end
    function dominant.Notify(text, kind, duration)
        ctx.notify(tostring(text), kind or "info", duration or 3)
    end
    function dominant.Warn(text)
        ctx.warn(tostring(text))
    end
    function dominant.Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end
    function dominant.StyleFont(obj, bold)
        local ok = pcall(function()
            obj.FontFace = Font.new(M.font, bold and Enum.FontWeight.Bold or Enum.FontWeight.Medium, Enum.FontStyle.Normal)
        end)
        if not ok then
            obj.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        end
        return obj
    end
    ctx.onUnload(function()
        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        for _, obj in pairs(objects) do
            pcall(function()
                obj:Destroy()
            end)
        end
    end)
    return dominant
end

return M
