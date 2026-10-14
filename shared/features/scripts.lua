local M = {}

local function localFolder(ctx)
    return ctx.config.Folder .. "/misc"
end

local function ensureFolders(ctx)
    pcall(function()
        if not isfolder(ctx.config.Folder) then
            makefolder(ctx.config.Folder)
        end
        if not isfolder(localFolder(ctx)) then
            makefolder(localFolder(ctx))
        end
    end)
end

local function fetchIndex(ctx)
    local ok, body = pcall(game.HttpGet, game, ctx.modules.base .. "scripts/index.lua")
    if not ok or type(body) ~= "string" or #body < 5 then
        return nil
    end
    local chunk = loadstring(body)
    if not chunk then
        return nil
    end
    local okRun, index = pcall(chunk)
    if okRun and type(index) == "table" then
        return index
    end
    return nil
end

local function runSource(ctx, source, name)
    local chunk, compileError = loadstring(source, "=" .. name)
    if not chunk then
        ctx.warn(tostring(compileError))
        ctx.notify(ctx.L("script_failed") .. " " .. name, "error", 5)
        return
    end
    local ok, err = pcall(chunk)
    if ok then
        ctx.notify(ctx.L("script_ran") .. " " .. name, "success", 3)
    else
        ctx.warn(tostring(err))
        ctx.notify(ctx.L("script_failed") .. " " .. name, "error", 5)
    end
end

local function listLocal(ctx)
    local files = {}
    if not ctx.caps.files or type(listfiles) ~= "function" then
        return files
    end
    local ok, entries = pcall(listfiles, localFolder(ctx))
    if not ok or type(entries) ~= "table" then
        return files
    end
    for _, entry in ipairs(entries) do
        local name = tostring(entry):gsub("\\", "/"):match("([^/]+)$") or tostring(entry)
        local lower = name:lower()
        if lower:match("%.lua$") or lower:match("%.txt$") then
            table.insert(files, { name = name, path = localFolder(ctx) .. "/" .. name })
        end
    end
    table.sort(files, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    return files
end

-- Each tool gets its own tab: the logo, the description and the actions for that tool
local toolTabs = {}

local function sourceUrl(ctx, entry)
    return ctx.modules.base .. "scripts/" .. tostring(entry.file)
end

local function localPath(ctx, entry)
    return localFolder(ctx) .. "/" .. tostring(entry.file)
end

local function copyText(ctx, text)
    if ctx.copy then
        ctx.copy(text)
    elseif type(setclipboard) == "function" then
        pcall(setclipboard, text)
    end
    ctx.notify(text, "success", 2)
end

local function runEntry(ctx, entry)
    local okGet, source = pcall(game.HttpGet, game, sourceUrl(ctx, entry))
    if not okGet or type(source) ~= "string" then
        ctx.notify(ctx.L("script_failed") .. " " .. tostring(entry.name), "error", 4)
        return
    end
    pcall(writefile, localPath(ctx, entry), source)
    runSource(ctx, source, tostring(entry.name))
end

local function openToolTab(ctx, window, entry)
    local existing = toolTabs[entry.file]
    if existing then
        window:SelectTab(existing)
        return
    end
    local tool = window:AddTab({ Name = tostring(entry.name), Icon = "Lucide:package" })
    local cover = (ctx.assets and entry.logo and ctx.assets.get(entry.logo)) or "Lucide:package"
    tool:AddShowcase({
        Title = tostring(entry.name),
        Subtitle = tostring(entry.desc or ""),
        Cover = cover,
        Sections = {
            {
                Title = "Actions",
                Items = {
                    {
                        Title = "Run",
                        Subtitle = "Download the latest version and open it",
                        Cover = "Lucide:play",
                        Callback = function() runEntry(ctx, entry) end,
                    },
                    {
                        Title = "Copy source URL",
                        Subtitle = sourceUrl(ctx, entry),
                        Cover = "Lucide:link",
                        Callback = function() copyText(ctx, sourceUrl(ctx, entry)) end,
                    },
                    {
                        Title = "Copy local path",
                        Subtitle = localPath(ctx, entry),
                        Cover = "Lucide:folder-open",
                        Callback = function() copyText(ctx, localPath(ctx, entry)) end,
                    },
                },
            },
        },
    })
    toolTabs[entry.file] = tool
    window:SelectTab(tool)
end

function M.Build(tab, ctx)
    ctx.ui.section(tab, "sec_scripts", "Lucide:file-code")
    ensureFolders(ctx)

    local index = fetchIndex(ctx)
    if index then
        for _, entry in ipairs(index) do
            tab:AddButton({
                Text = tostring(entry.name or entry.file),
                Description = tostring(entry.desc or ctx.L("btn_run_script")),
                Icon = "Lucide:package",
                Callback = function()
                    local window = tab._window
                    if window then
                        openToolTab(ctx, window, entry)
                    else
                        runEntry(ctx, entry)
                    end
                end,
            })
        end
    else
        tab:AddParagraph({ Title = ctx.L("scripts_offline"), Icon = "Lucide:wifi-off", Text = ctx.L("scripts_hint") })
    end

    -- Tools from the list already have their own tab, so their saved copies are not listed a second time
    local listed = {}
    if index then
        for _, entry in ipairs(index) do
            listed[tostring(entry.file)] = true
        end
    end
    for _, file in ipairs(listLocal(ctx)) do
        if not listed[file.name] then
            tab:AddButton({
                Text = file.name,
                Description = ctx.L("scripts_local"),
                Icon = "Lucide:play",
                Callback = function()
                    local okRead, source = pcall(readfile, file.path)
                    if okRead and type(source) == "string" then
                        runSource(ctx, source, file.name)
                    end
                end,
            })
        end
    end
end

return M
