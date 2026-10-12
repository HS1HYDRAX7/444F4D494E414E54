local M = {}

M.Languages = {
    { Code = "en", Name = "English" },
    { Code = "pt", Name = "Português" },
    { Code = "es", Name = "Español" },
    { Code = "ru", Name = "Русский" },
}

function M.new(ctx)
    ctx.Languages = M.Languages
    local packs = { en = {}, pt = {}, es = {}, ru = {} }
    local current = "en"
    local hooks = {}

    function ctx.addStrings(code, strings)
        local pack = packs[code]
        if not pack then
            return
        end
        for key, value in pairs(strings) do
            pack[key] = value
        end
    end

    function ctx.L(key, ...)
        local pack = packs[current]
        local text = (pack and pack[key]) or packs.en[key] or key
        if select("#", ...) > 0 then
            local ok, formatted = pcall(string.format, text, ...)
            if ok then
                return formatted
            end
        end
        return text
    end

    function ctx.describe(key)
        local text = ctx.L(key .. "_d")
        if text == key .. "_d" then
            return nil
        end
        return text
    end

    -- Runs callback(oldCode, newCode) every time the language changes
    function ctx.onLanguageChange(callback)
        table.insert(hooks, callback)
    end

    function ctx.pack(code)
        return packs[code]
    end

    function ctx.setLanguage(code)
        if not packs[code] then
            return false
        end
        local from = current
        if from == code then
            return true
        end
        current = code
        for _, callback in ipairs(hooks) do
            pcall(callback, from, code)
        end
        return true
    end

    -- Changes the texts already drawn under root from one language to another. A drawn text is replaced only when it is
    -- exactly the text of a key in the old language, so values such as numbers and names are left as they are.
    function ctx.retranslate(root, fromCode, toCode, extraPairs)
        if not root or fromCode == toCode then
            return 0
        end
        local map = {}
        local function addPair(oldPack, newPack)
            if type(oldPack) ~= "table" or type(newPack) ~= "table" then
                return
            end
            for key, oldText in pairs(oldPack) do
                local newText = newPack[key]
                if type(oldText) == "string" and type(newText) == "string" and oldText ~= "" and oldText ~= newText then
                    map[oldText] = newText
                    map[string.upper(oldText)] = string.upper(newText)
                end
            end
        end
        addPair(packs[fromCode], packs[toCode])
        for _, pair in ipairs(extraPairs or {}) do
            addPair(pair[1], pair[2])
        end
        local changed = 0
        pcall(function()
            for _, object in ipairs(root:GetDescendants()) do
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    local replacement = map[object.Text]
                    if replacement then
                        object.Text = replacement
                        changed = changed + 1
                    end
                    if object:IsA("TextBox") then
                        local placeholder = map[object.PlaceholderText]
                        if placeholder then
                            object.PlaceholderText = placeholder
                        end
                    end
                end
            end
        end)
        return changed
    end

    function ctx.getLanguage()
        return current
    end
end

return M
