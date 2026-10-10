local Modules = {}
Modules.__index = Modules

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local LOOKUP = {}
for i = 1, #B64 do
    LOOKUP[string.byte(B64, i)] = i - 1
end

local function decodeBase64(data)
    data = string.gsub(data, "[^%w%+/=]", "")
    local out = {}
    for i = 1, #data, 4 do
        local a, b, c, d = string.byte(data, i, i + 3)
        local n = (LOOKUP[a] or 0) * 262144 + (LOOKUP[b] or 0) * 4096 + (LOOKUP[c] or 0) * 64 + (LOOKUP[d] or 0)
        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        if c ~= 61 then
            out[#out + 1] = string.char(math.floor(n / 256) % 256)
        end
        if d ~= 61 then
            out[#out + 1] = string.char(n % 256)
        end
    end
    return table.concat(out)
end

Modules.decodeBase64 = decodeBase64

function Modules.new(baseUrl)
    return setmetatable({ base = baseUrl, cache = {} }, Modules)
end

function Modules:asset(file)
    local encoded = self.embeddedAssets and self.embeddedAssets[file]
    if type(encoded) ~= "string" then
        return nil
    end
    return decodeBase64(encoded)
end

function Modules:fetch(path)
    if self.embedded and self.embedded[path] then
        return self.embedded[path]
    end
    local url = self.base .. path .. ".lua"
    local ok, body = pcall(game.HttpGet, game, url)
    if not ok or type(body) ~= "string" or #body < 10 then
        error("could not download " .. url)
    end
    local chunk, compileError = loadstring(body)
    if not chunk then
        error("could not compile " .. path .. ": " .. tostring(compileError))
    end
    return chunk
end

function Modules:require(path)
    local cached = self.cache[path]
    if cached ~= nil then
        return cached
    end
    local result = self:fetch(path)()
    if result == nil then
        error("module " .. path .. " returned nothing")
    end
    self.cache[path] = result
    return result
end

return Modules
