-- Chooses the window library the hub opens with. Vind keeps its own path; WindUI and Rayfield are wrapped by
-- shared/ui_adapter, so the games and the shared features make the same calls whichever library is chosen.
local M = {}

-- The loader shows these same choices on its own screen (loader.lua, INTERFACE_CHOICES)
M.choices = {
    { id = "vind", label = "Vind UI", note = "Original interface" },
    { id = "windui", label = "WindUI", note = "Rounded panels and Lucide icons" },
    { id = "rayfield", label = "Rayfield", note = "Rayfield Gen2" },
    { id = "cascade", label = "Cascade", note = "macOS Sequoia style" },
}

function M.isValid(id)
    for _, choice in ipairs(M.choices) do
        if choice.id == id then
            return true
        end
    end
    return false
end

local function fetchChunk(url)
    local ok, body = pcall(game.HttpGet, game, url)
    if not ok or type(body) ~= "string" or #body < 100 then
        return nil, "could not download " .. tostring(url)
    end
    local chunk, compileError = loadstring(body)
    if not chunk then
        return nil, compileError
    end
    local okRun, result = pcall(chunk)
    if not okRun or type(result) ~= "table" then
        return nil, result
    end
    return result
end

-- The library from the repository (vendor/<id>.lua) when it is there, otherwise from its URL in the config
local function loadLibrary(id, config, modules)
    -- WindUI is the official build, loaded from its URL like the WindUI example does; the repository keeps no copy
    if id == "windui" then
        return fetchChunk(config.WindUIUrl)
    end
    local okRepo, value = pcall(function()
        return modules:require("vendor/" .. id)
    end)
    if okRepo and type(value) == "table" then
        return value
    end
    if id == "windui" then
        return fetchChunk(config.WindUIUrl)
    end
    if id == "rayfield" then
        return fetchChunk(config.RayfieldUrl)
    end
    return nil, "vendor/" .. id .. ".lua is missing"
end

-- Same return values as core/vind.load: the library, or nil and the reason it could not load
function M.load(id, config, uiTheme, modules)
    if not M.isValid(id) then
        id = "vind"
    end
    if id == "vind" then
        return modules:require("core/vind").load(config, uiTheme, modules)
    end
    local library, loadError = loadLibrary(id, config, modules)
    if library then
        return modules:require("shared/ui_adapter").wrap(id, library, uiTheme and uiTheme.palette)
    end
    warn("[Dominant] " .. id .. " did not load, using Vind UI instead: " .. tostring(loadError))
    return modules:require("core/vind").load(config, uiTheme, modules)
end

return M
