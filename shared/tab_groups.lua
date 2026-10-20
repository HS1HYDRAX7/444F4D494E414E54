local M = {}

function M.addTab(window, groups, groupName, options)
    if type(groupName) == "string" and groupName ~= "" then
        local group = groups[groupName]
        if group == nil then
            local okGroup, created = pcall(function()
                return window:AddTabGroup({ Name = groupName })
            end)
            group = okGroup and created or false
            groups[groupName] = group
        end
        if group then
            local okTab, tab = pcall(function()
                return group:AddTab(options)
            end)
            if okTab and tab then
                return tab
            end
        end
    end
    return window:AddTab(options)
end

return M
