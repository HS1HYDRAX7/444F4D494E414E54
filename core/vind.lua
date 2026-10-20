--[[
    core/vind.lua
    Mantém a lógica original + chama a overlay de criação do loader quando disponível
]]

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

function M.load(config, uiTheme, modules, screen)
    -- screen é opcional (vindo do loader). Se existir, mostra overlay por cima.
    if screen and type(screen.showVindCreation) == "function" then
        pcall(screen.showVindCreation)
    end

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

    if screen and type(screen.hideVindCreation) == "function" then
        pcall(screen.hideVindCreation)
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
            Background = P.bg,
            Surface = P.input,
            Card = P.card,
            Text = P.text,
            TextDim = P.muted,
            Accent = P.accent,
            Outline = P.stroke,
            Border = P.stroke,
            Button = P.btn2,
            ButtonHover = P.btn2Hover,
            Input = P.input,
            Placeholder = P.muted,
            Stroke = P.stroke,
            Success = P.success,
            Error = P.error,
            Warning = P.warn,
            Primary = P.accent,
            Secondary = P.btn2,
        }
        for key, value in pairs(overrides) do
            if value ~= nil then
                library.Theme[key] = value
            end
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
