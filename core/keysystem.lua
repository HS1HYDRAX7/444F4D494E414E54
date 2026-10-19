local M = {}

local HttpService = game:GetService("HttpService")

local LOCAL_LOGO = "Dominant/Assets/logo.png"

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

local function urlEncode(str)
    str = tostring(str or "")
    return (str:gsub("([^%w%-_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

--[[
  KeyAuth helper
  Credentials live in config.KeyAuth (Name, OwnerId, Version) — no "local name" in this file.
]]
local KeyAuthState = {
    sessionid = nil,
    initialized = false,
}

local function keyAuthInit(ka)
    if KeyAuthState.initialized and KeyAuthState.sessionid then
        return true
    end
    if type(ka) ~= "table" or not ka.Name or not ka.OwnerId then
        return false, "KeyAuth config missing"
    end

    local base = ka.ApiBase or "https://keyauth.win/api/1.1/"
    local url = base
        .. "?type=init"
        .. "&name=" .. urlEncode(ka.Name)
        .. "&ownerid=" .. urlEncode(ka.OwnerId)
        .. "&ver=" .. urlEncode(ka.Version or "1.0")

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(body) ~= "string" then
        return false, "init request failed"
    end
    if body == "KeyAuth_Invalid" then
        return false, "application not found"
    end

    local okJson, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not okJson or type(data) ~= "table" then
        return false, "bad init response"
    end
    if data.message == "invalidver" then
        return false, "invalid version"
    end
    if data.success ~= true then
        return false, tostring(data.message or "init failed")
    end

    KeyAuthState.sessionid = data.sessionid
    KeyAuthState.initialized = true
    return true
end

local function keyAuthLicense(ka, key)
    local okInit, initErr = keyAuthInit(ka)
    if not okInit then
        return false, initErr
    end

    local base = ka.ApiBase or "https://keyauth.win/api/1.1/"
    local url = base
        .. "?type=license"
        .. "&name=" .. urlEncode(ka.Name)
        .. "&ownerid=" .. urlEncode(ka.OwnerId)
        .. "&key=" .. urlEncode(key)
        .. "&ver=" .. urlEncode(ka.Version or "1.0")
        .. "&sessionid=" .. urlEncode(KeyAuthState.sessionid or "")

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(body) ~= "string" then
        return false, "license request failed"
    end

    local okJson, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not okJson or type(data) ~= "table" then
        return false, "bad license response"
    end
    if data.success == true then
        return true
    end
    return false, tostring(data.message or "invalid key")
end

local function isDefaultKey(config, key)
    if type(config.Keys) ~= "table" then
        return false
    end
    for _, k in ipairs(config.Keys) do
        if tostring(key) == tostring(k) then
            return true
        end
    end
    return false
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

    local getKeyLink = config.GetKeyLink or "https://keyauth.win/"
    local ka = config.KeyAuth

    -- Pre-init KeyAuth so first key check is faster
    if type(ka) == "table" then
        task.spawn(function()
            keyAuthInit(ka)
        end)
    end

    local attempt, attemptError = pcall(function()
        Ophyn.new({
            Title = config.Title,
            Description = config.Description or "Enter your key",
            Logo = localLogo() or config.Logo,
            Theme = config.KeyTheme or "Dominant",
            Folder = config.Folder,
            getkey = true,
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
                -- still listed so Ophyn can show them / save, but real check is custom
                Key = config.Keys or {},
                SaveKey = config.SaveKey ~= false,
                CheckKey = function(_, key)
                    if not key or key == "" then
                        return false
                    end
                    -- quick access defaults (owner/staff)
                    if isDefaultKey(config, key) then
                        return true
                    end
                    -- KeyAuth license
                    if type(ka) == "table" then
                        local okAuth, err = keyAuthLicense(ka, key)
                        if okAuth then
                            return true
                        end
                        -- optional: surface error once
                        if status and err then
                            pcall(status, "KeyAuth: " .. tostring(err))
                        end
                        return false
                    end
                    return false
                end,
                GetKeyLink = function()
                    return getKeyLink
                end,
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
