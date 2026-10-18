--[[
    LMS Music Module - Cleaned & Fixed
    ---------------------------------
    Problema original: links do GitHub blob não funcionam em Sound.SoundId.
    
    Link que você mandou (blob - NÃO usar):
    https://github.com/HS1HYDRAX7/DOMINANT/blob/main/assets/sounds/lms/And%20The%20Seraphim%20Wept.mp3

    Raw correto (ainda assim Roblox bloqueia sons externos na maioria dos casos):
    https://raw.githubusercontent.com/HS1HYDRAX7/DOMINANT/main/assets/sounds/lms/And%20The%20Seraphim%20Wept.mp3

    Solução profissional: faça upload dos .mp3 no Roblox Creator Dashboard
    e coloque o Asset ID (rbxassetid://...) abaixo.
]]

local M = {}

M.Songs = {
    -- Confirmados (funcionam)
    { name = "A Grave Soul (Now, Run)",          id = "77152471130613", confirmed = true },
    { name = "Plead",                            id = "136274352281439", confirmed = true },
    { name = "Curiosity",                        id = "80712503354465", confirmed = true },
    { name = "Through Patches of Violet (Hacklord)", id = "77579718926500", confirmed = true, note = "community version" },
    { name = "Hero",                             id = "121052332073884", confirmed = true },
    { name = "Debth",                            id = "91088104810072", confirmed = true },

    -- Pendentes de Asset ID (faça upload e preencha)
    { name = "Creation of Hatred",               id = "95305396196239", confirmed = false },
    { name = "Close to Me",                      id = "90022574613230", confirmed = false },
    { name = "And The Seraphim Wept",            id = nil, confirmed = false, note = "precisa de asset ID" },
    { name = "LOW STOCK (NEW Vanity LMS)",       id = nil, confirmed = false },
    { name = "MADE JUST 4 U",                    id = nil, confirmed = false },
    { name = "Perpetuity",                       id = nil, confirmed = false },
    { name = "Smile",                            id = nil, confirmed = false },
    { name = "The Darkness In Your Heart",       id = nil, confirmed = false },
    { name = "Meet Your Making",                 id = nil, confirmed = false },
    { name = "Receading Lifespan",               id = nil, confirmed = false },
    { name = "Escape The Necrobloxians!",        id = nil, confirmed = false },

    -- Removidos / descartados
    { name = "Metamorphosis",                    id = nil, confirmed = false, status = "discarded" },
    { name = "Your.Problem",                     id = nil, confirmed = false, status = "removed" },
}

-- Apenas músicas confirmadas e com ID válido
function M.Selectable()
    local list = {}
    for _, song in ipairs(M.Songs) do
        if song.confirmed and song.id and song.status == nil then
            table.insert(list, song)
        end
    end
    return list
end

function M.GetByName(name)
    name = tostring(name or ""):lower()
    for _, song in ipairs(M.Songs) do
        if song.name:lower() == name then
            return song
        end
    end
    return nil
end

function M.GetId(name)
    local song = M.GetByName(name)
    return song and song.id or nil
end

-- Helper para criar o Sound corretamente
function M.CreateSound(songName, parent)
    local id = M.GetId(songName)
    if not id then
        warn("[LMS] Song sem Asset ID:", songName)
        return nil
    end
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = parent or workspace
    return sound
end

return M
