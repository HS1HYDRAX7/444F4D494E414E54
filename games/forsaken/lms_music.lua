-- LMS (Last Man Standing) songs.
-- confirmed = true means the ID was checked and the song can be chosen.
-- A song without a confirmed ID is kept in the list, so it can be filled in later.
-- status "discarded" or "removed" marks songs that are no longer used.
local M = {}

M.Songs = {
    { name = "A Grave Soul (Now, Run)", id = "77152471130613", confirmed = true },
    { name = "Plead", id = "136274352281439", confirmed = true },
    { name = "Creation of Hatred", id = "95305396196239", confirmed = false },
    { name = "Dead Ringer", id = nil, confirmed = false },
    { name = "Low Stock", id = nil, confirmed = false },
    { name = "Make A Cake", id = nil, confirmed = false },
    { name = "Made Just 4 U", id = nil, confirmed = false },
    { name = "Burnout", id = nil, confirmed = false },
    { name = "Through Patches of Violet (Hacklord)", id = "77579718926500", confirmed = true, note = "community version" },
    { name = "For Old Times Sake", id = nil, confirmed = false },
    { name = "You and I", id = nil, confirmed = false },
    { name = "Close to Me", id = "90022574613230", confirmed = false },
    { name = "Curiosity", id = "80712503354465", confirmed = true },
    { name = "Perpetuity", id = nil, confirmed = false },
    { name = "The Way It Ends", id = nil, confirmed = false },
    { name = "Survival For The Fittest", id = nil, confirmed = false },
    { name = "Faith's Answer", id = nil, confirmed = false },
    { name = "April Fools LMS", id = nil, confirmed = false },
    { name = "Hero", id = "121052332073884", confirmed = true },
    { name = "Debth", id = "91088104810072", confirmed = true },
    { name = "Metamorphosis", id = nil, confirmed = false, status = "discarded" },
    { name = "Your.Problem", id = nil, confirmed = false, status = "removed" },
}

-- The songs a player can choose: confirmed, with an ID, and not discarded or removed
function M.Selectable()
    local list = {}
    for _, song in ipairs(M.Songs) do
        if song.confirmed and song.id and song.status == nil then
            table.insert(list, song)
        end
    end
    return list
end

return M
