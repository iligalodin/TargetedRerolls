local function aikoyori_active()
    return SMODS
    and SMODS.Mods
        and SMODS.Mods.aikoyorisshenanigans
        and SMODS.Mods.aikoyorisshenanigans.can_load == true
end

local function aiko_type_active(card_type)
    return aikoyori_active()
        and G
        and G.P_CENTER_POOLS
        and G.P_CENTER_POOLS[card_type]
        and next(G.P_CENTER_POOLS[card_type]) ~= nil
end

local function add_aiko_card_types_to_reroll(mod)
    for _, card_type in ipairs({'Umbral', 'Alphabet', 'Replicant'}) do
        if aiko_type_active(card_type) then
            table.insert(mod.card_types, card_type)
            table.insert(mod.card_type_labels, string.upper(card_type))
        end
    end
end


return function(mod)
    local current_mod = SMODS and SMODS.current_mod
    local stored_targets = current_mod and current_mod.config and current_mod.config.targets
    local selected_targets = {}
    local selected_target_order = {}

    if type(stored_targets) == 'table' then
        for _, target in ipairs(stored_targets) do
            if type(target) == 'table' and target.type and target.key then
                local id = target.type..':'..target.key
                if not selected_targets[id] then
                    selected_targets[id] = {type = target.type, key = target.key}
                    selected_target_order[#selected_target_order + 1] = id
                end
            end
        end
    end

    mod.state = {
        current_mod = current_mod,
        selected_targets = selected_targets,
        selected_target_order = selected_target_order,
        search = {
            active = false,
            button_label = 'Targeted Reroll',
            targets = {},
            reserve = 0,
            rolls = 0,
            total_spent = 0,
        },
        catalog = {
            reserve_text = '0',
            initialized = false,
            card_type = 'Joker',
            entry_meta = {},
            button_states = {},
            start_state = {text = 'REROLL (0)'},
        },
        debug = {
            money_text = '0',
        },
    }

    mod.card_types = {
        'Joker',
        'Tarot',
        'Planet',
        'Spectral',
        'Playing Card'}
    mod.card_type_labels = {
        'JOKERS',
        'TAROT',
        'PLANET',
        'SPECTRAL',
        'PLAYING CARDS'
    }

    add_aiko_card_types_to_reroll(mod)


end

