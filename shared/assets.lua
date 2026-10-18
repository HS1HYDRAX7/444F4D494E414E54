local M = {}

function M.new(ctx)
    local manifest = ctx.modules:require("assets/index")
    local cache = {}
    local assets = {}

    local function ensureDirs(path)
        local current = ""
        for segment in string.gmatch(path, "([^/]+)/") do
            current = current == "" and segment or (current .. "/" .. segment)
            pcall(function()
                if not isfolder(current) then
                    makefolder(current)
                end
            end)
        end
    end

    local function assetFolder()
        return ctx.config.Folder .. "/Assets"
    end

    local function ensureFolders()
        pcall(function()
            if not isfolder(ctx.config.Folder) then
                makefolder(ctx.config.Folder)
            end
            if not isfolder(assetFolder()) then
                makefolder(assetFolder())
            end
        end)
    end

    function assets.resolve(path)
        if not path or path == "" then
            return nil
        end
        path = tostring(path):gsub("\\", "/")
        if path:match("^%d+$") then
            return "rbxassetid://" .. path
        end
        if path:find("rbxassetid://", 1, true) or path:find("rbxthumb://", 1, true) or path:find("rbxasset://", 1, true) then
            return path
        end
        local getters = {}
        if type(getcustomasset) == "function" then
            table.insert(getters, getcustomasset)
        end
        if type(getsynasset) == "function" then
            table.insert(getters, getsynasset)
        end
        local tries = { path, "workspace/" .. path, "Workspace/" .. path }
        for _, get in ipairs(getters) do
            for _, try in ipairs(tries) do
                local ok, asset = pcall(get, try)
                if ok and type(asset) == "string" and asset ~= "" then
                    return asset
                end
            end
        end
        return nil
    end

    function assets.get(key)
        local cached = cache[key]
        if cached ~= nil then
            return cached or nil
        end
        local file = manifest[key]
        if not file or not ctx.caps.files then
            cache[key] = false
            return nil
        end
        local path = assetFolder() .. "/" .. file
        local okExists, exists = pcall(isfile, path)
        if not (okExists and exists) then
            local okDownload, body = pcall(function()
                -- Encode path segments so spaces / () ! work on GitHub raw
                local encoded = tostring(file):gsub("([^/]+)", function(seg)
                    return (seg:gsub("([^%w%-%._~])", function(c)
                        return string.format("%%%02X", string.byte(c))
                    end))
                end)
                local url = ctx.modules.base .. "assets/" .. encoded
                local fromModule = nil
                if type(ctx.modules.asset) == "function" then
                    fromModule = ctx.modules:asset(file)
                end
                return fromModule or game:HttpGet(url)
            end)
            if not okDownload or type(body) ~= "string" or #body == 0 then
                ctx.warn("could not download asset " .. tostring(file))
                cache[key] = false
                return nil
            end
            ensureFolders()
            ensureDirs(path)
            -- Local path: replace problematic chars so writefile is happier on all executors
            local safePath = path
            pcall(writefile, safePath, body)
            -- If write with spaces fails, try underscore fallback and update resolve path
            local okExists2, exists2 = pcall(isfile, path)
            if not (okExists2 and exists2) then
                local safeFile = tostring(file):gsub("[^%w%._%-/]", "_")
                local safeFull = assetFolder() .. "/" .. safeFile
                ensureDirs(safeFull)
                pcall(writefile, safeFull, body)
                path = safeFull
            end
        end
        local asset = assets.resolve(path)
        cache[key] = asset or false
        return asset
    end

    function assets.add(key, file)
        manifest[key] = file
        cache[key] = nil
    end

    ctx.assets = assets
    return assets
end

return M
