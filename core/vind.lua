local M = {}

local function fetchRemote(config)
    local ok, body = pcall(game.HttpGet, game, config.VindUrl)
    if not ok or type(body) ~= "string" or #body < 100 then
        return nil, "could not download Vind UI"
    end
    local chunk, compileError = loadstring(body)
    if not chunk then
        return nil, compileError
    end
    local okRun, library = pcall(chunk)
    if not okRun or type(library) ~= "table" then
        return nil, library
    end
    return library
end

function M.load(config, uiTheme, modules)
    local library, loadError = nil, nil
    if modules then
        local okEmbedded, embedded = pcall(function()
            return modules:require("vendor/vind")
        end)
        if okEmbedded and type(embedded) == "table" then
            library = embedded
        else
            loadError = embedded
        end
    end
    if not library then
        library, loadError = fetchRemote(config)
    end
    if not library then
        return nil, loadError
    end
    pcall(function()
        library:SetTheme(config.Theme)
    end)
    if type(uiTheme) == "table" and type(library.Theme) == "table" then
        local P = uiTheme.palette
        local overrides = {
            Background = P.bg, Surface = P.input, Card = P.card, Text = P.text,
            TextDim = P.muted, Accent = P.accent, Outline = P.stroke, Border = P.stroke,
            Button = P.btn2, ButtonHover = P.btn2Hover, Input = P.input,
            Placeholder = P.muted, Stroke = P.stroke,
        }
        for key, value in pairs(overrides) do
            library.Theme[key] = value
        end
    end
    pcall(function()
        library:PreloadIcons({ "Lucide", "Material", "Phosphor", "SF" })
    end)
    pcall(function()
        library:SetScaleRange(0.75, 1.35)
    end)
    return library
end

return M
