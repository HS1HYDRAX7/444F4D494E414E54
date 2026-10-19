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

local function httpGet(url)
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" then
        return body
    end
    -- fallback request APIs
    local req = (syn and syn.request) or (http and http.request) or request or httprequest
    if type(req) == "function" then
        local ok2, res = pcall(req, { Url = url, Method = "GET" })
        if ok2 and type(res) == "table" then
            local b = res.Body or res.body
            if type(b) == "string" then
                return b
            end
        end
    end
    return nil
end

local KeyAuthState = {
    sessionid = nil,
    initialized = false,
    lastError = nil,
}

local function keyAuthInit(ka)
    if KeyAuthState.initialized and KeyAuthState.sessionid and KeyAuthState.sessionid ~= "" then
        return true
    end
    if type(ka) ~= "table" or not ka.Name or not ka.OwnerId then
        KeyAuthState.lastError = "KeyAuth config missing"
        return false, KeyAuthState.lastError
    end

    local base = ka.ApiBase or "https://keyauth.win/api/1.1/"
    local url = base
        .. "?type=init"
        .. "&name=" .. urlEncode(ka.Name)
        .. "&ownerid=" .. urlEncode(ka.OwnerId)
        .. "&ver=" .. urlEncode(ka.Version or "1.0")

    local body = httpGet(url)
    if not body then
        KeyAuthState.lastError = "init request failed"
        return false, KeyAuthState.lastError
    end
    if body == "KeyAuth_Invalid" then
        KeyAuthState.lastError = "application not found"
        return false, KeyAuthState.lastError
    end

    local okJson, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not okJson or type(data) ~= "table" then
        KeyAuthState.lastError = "bad init response"
        return false, KeyAuthState.lastError
    end
    if data.message == "invalidver" then
        KeyAuthState.lastError = "invalid version"
        return false, KeyAuthState.lastError
    end
    local success = data.success == true or data.success == "true" or data.success == 1
    if not success then
        KeyAuthState.lastError = tostring(data.message or "init failed")
        return false, KeyAuthState.lastError
    end

    KeyAuthState.sessionid = data.sessionid
    KeyAuthState.initialized = true
    KeyAuthState.lastError = nil
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

    local body = httpGet(url)
    if not body then
        return false, "license request failed"
    end

    local okJson, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not okJson or type(data) ~= "table" then
        return false, "bad license response"
    end
    local success = data.success == true or data.success == "true" or data.success == 1
    if success then
        return true
    end
    return false, tostring(data.message or "invalid key")
end

local function isDefaultKey(keys, key)
    if type(keys) ~= "table" then
        return false
    end
    local needle = tostring(key):match("^%s*(.-)%s*$") or ""
    for _, k in ipairs(keys) do
        if tostring(k) == needle then
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
        if status then status("Key system unavailable — skipping") end
        onSuccess()
        return
    end

    local supported = {}
    for _, id in ipairs(supportedIds or {}) do
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
    local defaultKeys = config.Keys or { "dominant", "J&T", "J&T Forever" }

    -- Pre-init KeyAuth (best effort)
    if type(ka) == "table" then
        task.spawn(function()
            local okInit, err = keyAuthInit(ka)
            if not okInit and status then
                pcall(status, "KeyAuth init: " .. tostring(err))
            end
        end)
    end

    -- Custom checker used by Ophyn KeySystem.API Type = "custom"
    local function customCheck(key /*, ctx */)
        key = tostring(key or ""):match("^%s*(.-)%s*$") or ""
        if key == "" then
            return false, "empty key"
        end
        if isDefaultKey(defaultKeys, key) then
            return true
        end
        if type(ka) == "table" then
            local okAuth, err = keyAuthLicense(ka, key)
            if okAuth then
                return true
            end
            return false, err or "invalid key"
        end
        return false, "no key provider"
    end

    local function customGetLink(/*, ctx */)
        return getKeyLink
    end

    local attempt, attemptError = pcall(function()
        Ophyn.new({
            Title = config.Title or "Dominant",
            Description = config.Description or "Enter your key or press Get Key",
            Logo = localLogo() or config.Logo,
            Theme = config.KeyTheme or "Dominant",
            Folder = config.Folder or "Dominant",
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
            -- style 2 as requested
            NotifStyle = "2",
            TabsStyle = "1",
            SupportedGames = supported,
            KeySystem = {
                -- static keys still work via KEYLIST
                Key = defaultKeys,
                SaveKey = config.SaveKey ~= false,
                -- THIS is what Get Key uses when no dynamic provider
                URL = getKeyLink,
                -- proper API entry so CheckKey + GetKeyLink are wired
                API = {
                    {
                        Type = "custom",
                        Title = "KeyAuth",
                        Icon = "key",
                        CheckKey = customCheck,
                        GetKeyLink = customGetLink,
                    },
                },
            },
            Callback = function()
                accept()
            end,
        })
    end)

    if not attempt then
        if status then
            status("Key system failed: " .. tostring(attemptError))
        end
        -- don't soft-lock the hub if UI fails
        accept()
    end
end

return M
