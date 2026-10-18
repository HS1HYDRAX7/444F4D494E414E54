--[[
    LMS Music reference module
    -------------------------
    O sistema REAL de LMS do Dominant NÃO usa os rbxassetid daqui na maioria das faixas.
    Ele usa:
      1) Feat.Audio.Songs em games/forsaken/core.lua  (chave -> "lms_xxx" ou rbxassetid)
      2) assets/index.lua                             (lms_xxx -> arquivo em assets/sounds/lms/)
      3) shared/assets.lua                            (baixa o mp3 do GitHub + getcustomasset)

    Os MP3 que você subiu no repo (com espaços no nome) são a fonte.
    O index ANTIGO usava underscore e dava 404. Isso foi corrigido.

    Link exemplo que você mandou (blob = página, não serve):
      https://github.com/HS1HYDRAX7/DOMINANT/blob/main/assets/sounds/lms/And%20The%20Seraphim%20Wept.mp3

    Raw que o downloader usa (depois de encode):
      https://raw.githubusercontent.com/HS1HYDRAX7/DOMINANT/main/assets/sounds/lms/And%20The%20Seraphim%20Wept.mp3
]]

local M = {}

-- name = o que aparece no dropdown / cfg.lms_song
-- key  = chave no assets/index (ou rbxassetid direto)
M.Songs = {
    { name = "A Grave Soul (Now, Run)",          key = "rbxassetid://77152471130613", source = "roblox" },
    { name = "Hero",                             key = "rbxassetid://121052332073884", source = "roblox" },
    { name = "Debth",                            key = "rbxassetid://91088104810072", source = "roblox" },
    { name = "Burnout",                          key = "rbxassetid://130101085745481", source = "roblox" },
    { name = "Compass",                          key = "rbxassetid://127298326178102", source = "roblox" },
    { name = "Vanity",                           key = "rbxassetid://137266220091579", source = "roblox" },

    -- Arquivos do repositório (assets/sounds/lms/)
    { name = "Plead",                            key = "lms_plead", file = "Plead.mp3" },
    { name = "Creation of Hatred",               key = "lms_creation_of_hatred", file = "Creation of Hatred.mp3" },
    { name = "Close to Me",                      key = "lms_close_to_me", file = "Close to Me.mp3" },
    { name = "Through Patches of Violet (Hacklord)", key = "lms_through_patches", file = "THROUGH PATCHES OF VIOLET.mp3" },
    { name = "Curiosity",                        key = "lms_curiosity", file = "Curiosity.mp3" },
    { name = "And The Seraphim Wept",            key = "lms_and_the_seraphim_wept", file = "And The Seraphim Wept.mp3" },
    { name = "Escape The Necrobloxians",         key = "lms_escape_necrobloxians", file = "Escape The Necrobloxians!.mp3" },
    { name = "Low Stock",                        key = "lms_low_stock", file = "LOW STOCK (NEW Vanity LMS).mp3" },
    { name = "Made Just 4 U",                    key = "lms_made_just_4_u", file = "MADE JUST 4 U.mp3" },
    { name = "Meet Your Making",                 key = "lms_meet_your_making", file = "Meet Your Making.mp3" },
    { name = "Old Vanity",                       key = "lms_old_vanity", file = "OLD Vanity LMS.mp3" },
    { name = "Perpetuity",                       key = "lms_perpetuity", file = "Perpetuity.mp3" },
    { name = "Receading Lifespan",               key = "lms_receading_lifespan", file = "Receading Lifespan.mp3" },
    { name = "Smile",                            key = "lms_smile", file = "Smile.mp3" },
    { name = "The Darkness In Your Heart",       key = "lms_darkness_in_your_heart", file = "The Darkness In Your Heart.mp3" },
}

function M.Selectable()
    local list = {}
    for _, song in ipairs(M.Songs) do
        table.insert(list, song)
    end
    return list
end

return M
