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
end

