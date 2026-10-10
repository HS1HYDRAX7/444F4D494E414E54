local M = {}

local LOCAL_LOGO = "Dominant/Assets/logo.png"

-- The loader saves the GitHub logo here; the key window uses it so both look the same.
local function localLogo()
    local ok, asset = pcall(function()
        local getter = getcustomasset or getsynasset
        if type(getter) == "function" and type(isfile) == "function" and isfile(LOCAL_LOGO) then
            return getter(LOCAL_LOGO)
        end
        return nil
    end)
    if ok and type(asset) == "string" then
        return asset
    end
    return nil
end

function M.run(config, supportedIds, onSuccess, status, modules)
    local env = getgenv and getgenv() or _G
    if env.DominantSkipKey == true then
        onSuccess()
        return
    end

    local ok, Ophyn = false, nil
    if modules then
        ok, Ophyn = pcall(function()
            return modules:require("vendor/ophyn")
        end)
    end
    if not ok or type(Ophyn) ~= "table" or type(Ophyn.new) ~= "function" then
        ok, Ophyn = pcall(function()
            return loadstring(game:HttpGet(config.OphynUrl))()
        end)
    end
    if not ok or type(Ophyn) ~= "table" or type(Ophyn.new) ~= "function" then
        status("Key system unavailable")
        onSuccess()
        return
    end

    local supported = {}
    for _, id in ipairs(supportedIds) do
        supported[id] = true
    end
    supported[game.PlaceId] = true

    local started = false
    local function accept()
        if started then
            return
        end
        started = true
        onSuccess()
    end

    local attempt, attemptError = pcall(function()
        Ophyn.new({
            Title = config.Title,
            Description = config.Description,
            Logo = localLogo() or config.Logo,
            Theme = config.KeyTheme or "Dominant",
            Folder = config.Folder,
            getkey = false,
            Intro = "false",
            startintrosize = 80,
            squareintrotime = 1.2,
            squarecontorn = "true",
            Changelogocolor = false,
            Changeiconscolor = false,
            ChangeTheme = "true",
            discordlink = config.Discord,
            website_link = config.Website,
            Discord = "true",
            Website = "true",
            Informations = "true",
            Keyless = { enabled = false },
            NotifStyle = "1",
            TabsStyle = "1",
            SupportedGames = supported,
            KeySystem = {
                Key = config.Keys,
                SaveKey = config.SaveKey,
            },
            Callback = function()
                accept()
            end,
        })
    end)

    if not attempt then
        status("Key system failed: " .. tostring(attemptError))
        accept()
    end
end

return M
