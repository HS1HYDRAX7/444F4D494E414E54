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

local KEY_CACHE_SECONDS = 120
local keyCache = {}

local function remoteKeyStatus(validateUrl, key)
    if type(validateUrl) ~= "string" or validateUrl == "" then
        return nil, nil
    end
    local now = os.time()
    local cached = keyCache[key]
    if cached and now - cached.at < KEY_CACHE_SECONDS then
        return cached.valid, cached.reason
    end
    local body = httpGet(validateUrl .. urlEncode(key))
    if type(body) ~= "string" then
        return nil, nil
    end
    local okJson, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not okJson or type(data) ~= "table" or type(data.valid) ~= "boolean" then
        return nil, nil
    end
    local reason = type(data.reason) == "string" and data.reason or (data.valid and "ok" or "invalid")
    if data.valid then
        keyCache[key] = { valid = true, reason = reason, at = now }
    end
    return data.valid, reason
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
    if needle == "" then
        return false
    end
    for _, k in ipairs(keys) do
        if tostring(k) == needle then
            return true
        end
    end
    return false
end

function M.run(config, supportedIds, onSuccess, status, modules)
    local env = getgenv and getgenv() or _G
    -- Explicit opt-in skip only (dev flag). Never auto-authorize on errors.
    if env.DominantSkipKey == true then
        if status then
            pcall(status, "Key skipped (DominantSkipKey)")
        end
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
        if status then
            status("Key system unavailable — access blocked")
        end
        -- FIX: do NOT call onSuccess() here. That was the free-pass bug.
        warn("[Dominant] Ophyn failed to load: " .. tostring(Ophyn))
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
    -- Static keys only work if you intentionally put them in config.Keys.
    -- They still must be typed / saved — never auto-pass empty keys.
    local defaultKeys = config.Keys
    if type(defaultKeys) ~= "table" then
        defaultKeys = {}
    end

    if type(ka) == "table" then
        task.spawn(function()
            local okInit, err = keyAuthInit(ka)
            if not okInit and status then
                pcall(status, "KeyAuth init: " .. tostring(err))
            end
        end)
    end

    local function customCheck(key)
        key = tostring(key or ""):match("^%s*(.-)%s*$") or ""
        if key == "" then
            return false, "Enter a key"
        end
        if isDefaultKey(defaultKeys, key) then
            return true
        end

        local remoteValid, remoteReason = remoteKeyStatus(config.KeyValidateUrl, key)
        if remoteValid then
            return true
        end
        if remoteReason == "revoked" then
            return false, "This key was revoked"
        end
        if remoteReason == "expired" then
            return false, "This key has expired"
        end

        if type(ka) == "table" then
            local okAuth, err = keyAuthLicense(ka, key)
            if okAuth then
                return true
            end
            return false, err or "Invalid key"
        end
        return false, "Invalid key"
    end

    local function customGetLink()
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
            -- Force key required. Never keyless.
            Keyless = {
                enabled = false,
                disabletextbox = false,
                disablegetkey = false,
                showcard = false,
                autoconfirm = false,
            },

            NotifStyle = "2",
            TabsStyle = "1",
            SupportedGames = supported,
            KeySystem = {
                -- Do NOT put static keys here as the primary gate when API exists.
                -- Empty list forces every key through CheckKey (KeyAuth / remote).
                -- Optional local allowlist still works via customCheck above.
                Key = {},
                SaveKey = config.SaveKey ~= false,
                URL = getKeyLink,
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
        warn("[Dominant] Ophyn.new error: " .. tostring(attemptError))
        -- FIX: do NOT call accept() on error. That was authorizing without a key.
        return
    end
end

return M
