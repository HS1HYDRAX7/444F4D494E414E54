local M = {}

function M.tab(window, ctx)
    local tab = window:AddTab({ Name = ctx.L("tab_tools"), Icon = "Lucide:wrench" })
    ctx.ui.section(tab, "sec_avatar", "Lucide:shirt")
    ctx.ui.button(tab, "btn_avatar_editor", "Lucide:shirt", function()
        ctx.modules:require("shared/features/avatar").open(ctx)
    end)
end

return M
