local CRYPTID_card_types = {
    {name = 'Code', label = 'CODE'},
}

local function cryptid_active()
    return _G.Cryptid ~= nil
        or (
            SMODS
            and SMODS.Mods
            and SMODS.Mods.Cryptid
            and SMODS.Mods.Cryptid.can_load == true
        )
end

return function(mod)
    if not cryptid_active() then
        return
    end

    -- G.P_CENTER_POOLS is not guaranteed to be populated while mod
    -- initialization runs. The catalog checks the pool when it opens.
    for _, card_type in ipairs(CRYPTID_card_types) do
        table.insert(mod.card_types, card_type.name)
        table.insert(mod.card_type_labels, card_type.label)
    end
end

