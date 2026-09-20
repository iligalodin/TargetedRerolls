local AKYRS_card_types = {
        {name= 'Umbral', label= 'UMBRAL'},
        {name='Alphabet',label='ALPHABET'},
        {name='Replicant',label='REPLICANT'},
    }

local function aikoyori_active()
    return _G.AKYRS ~= nil
        or (
            SMODS
            and SMODS.Mods
            and SMODS.Mods.aikoyorisshenanigans
            and SMODS.Mods.aikoyorisshenanigans.can_load == true
        )
end

return function(mod)
    if not aikoyori_active() then return end

    for _, card_type in ipairs(AKYRS_card_types) do
        table.insert(mod.card_types, card_type.name)
        table.insert(mod.card_type_labels, card_type.label)
    end
end
