local CRYPTID_card_types = {
        {name= 'Code', label= 'CODE'},
    }

local function cryptid_active()
    return _G.Cryptid ~=nil
    and SMODS.Mods
    and SMODS.Mods.aikoyorisshenanigans
    and SMODS.Mods.aikoyorisshenanigans.can_load == true
end

local function cryptid_type_active(card_type)
    return cryptid_active()
        and G
        and G.P_CENTER_POOLS
        and G.P_CENTER_POOLS[card_type]
        and next(G.P_CENTER_POOLS[card_type]) ~= nil
end

return function(mod)
    if not cryptid_active() then return end

    for _, card_type in ipairs(CRYPTID_card_types) do
        if cryptid_type_active(card_type.name) then
            table.insert(mod.card_types, card_type.name)
            table.insert(mod.card_type_labels, card_type.label)
        end
    end
end
