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

function M.Build(tab, ctx)
    ctx.ui.section(tab, "sec_scripts", "Lucide:file-code")
    ensureFolders(ctx)

    local index = fetchIndex(ctx)
    if index then
        for _, entry in ipairs(index) do
            tab:AddButton({
                Text = tostring(entry.name or entry.file),
                Description = tostring(entry.desc or ctx.L("btn_run_script")),
                Icon = "Lucide:download",
                Callback = function()
                    local okGet, source = pcall(game.HttpGet, game, ctx.modules.base .. "scripts/" .. tostring(entry.file))
                    if not okGet or type(source) ~= "string" then
                        ctx.notify(ctx.L("script_failed") .. " " .. tostring(entry.name), "error", 4)
                        return
                    end
                    pcall(writefile, localFolder(ctx) .. "/" .. tostring(entry.file), source)
                    runSource(ctx, source, tostring(entry.name))
                end,
            })
        end
    else
        tab:AddParagraph({ Title = ctx.L("scripts_offline"), Icon = "Lucide:wifi-off", Text = ctx.L("scripts_hint") })
    end

    for _, file in ipairs(listLocal(ctx)) do
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

return M
