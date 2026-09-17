return function(mod)
    local utils = mod.utils
    local state = mod.state
    local catalog = state.catalog
    local targets = {}

    local function showman_allows_duplicate(key)
        return SMODS and SMODS.showman and SMODS.showman(key)
    end

    function targets.center_is_visible(center)
        return center
            and not center.hidden
            and not center.no_collection
            and not center.omit
            and center.unlocked ~= false
    end

    local function target_rate(target_type)
        local rate_key = target_type == 'Playing Card' and 'playing_card_rate' or target_type:lower()..'_rate'
        return utils.number(G.GAME[rate_key] or 0)
    end

    local function pool_contains(target_type, key)
        if target_type == 'Playing Card' then
            return target_rate(target_type) > 0
        end

        local pool = get_current_pool(target_type, nil, nil, 'targeted_reroll')
        for _, pool_key in ipairs(pool or {}) do
            if pool_key == key then return true end
        end
        return false
    end

    local function joker_is_valid(key)
        local center = G.P_CENTERS[key]
        if not center or center.set ~= 'Joker' or not targets.center_is_visible(center) then return false end
        if center.rarity == 4 or center.rarity == 'Legendary' then return false end

        local pool_flags = G.GAME and G.GAME.pool_flags or {}
        if center.no_pool_flag and pool_flags[center.no_pool_flag] then return false end
        if center.yes_pool_flag and not pool_flags[center.yes_pool_flag] then return false end

        if SMODS and SMODS.add_to_pool and not SMODS.add_to_pool(center, {source = 'targeted-reroll'}) then
            return false
        end
        if G.GAME.banned_keys and G.GAME.banned_keys[key] then return false end
        if G.GAME.used_jokers and G.GAME.used_jokers[key] and not showman_allows_duplicate(key) then
            return false
        end
        return true
    end

    function targets.can_appear(target_type, key)
        if target_type == 'Joker' then
            return target_rate(target_type) > 0 and joker_is_valid(key)
        end
        if target_type == 'Playing Card' then
            local front = G.P_CARDS[key]
            return front and front.suit and front.value and target_rate(target_type) > 0
        end

        local center = G.P_CENTERS[key]
        return targets.center_is_visible(center)
            and target_rate(target_type) > 0
            and pool_contains(target_type, key)
    end

    function targets.card_matches(card, target)
        if not card or not target then return false end
        if target.type == 'Playing Card' then
            local card_config = card.config or {}
            local center = card_config.center
            local is_playing_card = card_config.card_key == target.key
                and card_config.card
                and card_config.card.suit
                and card_config.card.value
            return is_playing_card and center and (center.set == 'Default' or center.set == 'Enhanced')
        end

        local center = card.config and card.config.center
        return center and (center.key == target.key or center.original_key == target.key)
    end

    function targets.shop_contains(target_list)
        if not G.shop_jokers or not G.shop_jokers.cards then return false end
        for _, target in ipairs(target_list or {}) do
            for _, card in ipairs(G.shop_jokers.cards) do
                if targets.card_matches(card, target) then return true end
            end
        end
        return false
    end

    local function playing_card_entries()
        local result = {}
        for key, front in pairs(G.P_CARDS or {}) do
            if key ~= 'empty' and front.suit and front.value then
                local entry = copy_table(G.P_CENTERS.c_base)
                entry.key = 'targeted_playing_'..key
                entry.name = front.name or key
                entry.label = front.name or key
                entry.targeted_front = front
                entry.discovered = true
                entry.unlocked = true
                catalog.entry_meta[entry] = {
                    type = 'Playing Card',
                    key = key,
                    possible = targets.can_appear('Playing Card', key),
                }
                result[#result + 1] = entry
            end
        end

        table.sort(result, function(a, b)
            return (a.targeted_front.suit..a.targeted_front.value) < (b.targeted_front.suit..b.targeted_front.value)
        end)
        return result
    end

    function targets.available(card_type)
        local result = {}
        catalog.entry_meta = {}

        if card_type == 'Playing Card' then
            return playing_card_entries()
        end

        for _, center in ipairs(G.P_CENTER_POOLS[card_type] or {}) do
            local key = center.key
            if key and targets.center_is_visible(center)
                and (card_type ~= 'Joker' or joker_is_valid(key)) then
                catalog.entry_meta[center] = {
                    type = card_type,
                    key = key,
                    possible = targets.can_appear(card_type, key),
                }
                result[#result + 1] = center
            end
        end

        table.sort(result, function(a, b)
            local a_order = a.order or 0
            local b_order = b.order or 0
            if a_order == b_order then return (a.name or a.key) < (b.name or b.key) end
            return a_order < b_order
        end)
        return result
    end

    function targets.selected()
        local result = {}
        for _, id in ipairs(state.selected_target_order) do
            local target = state.selected_targets[id]
            if target and targets.can_appear(target.type, target.key) then
                result[#result + 1] = {type = target.type, key = target.key}
            end
        end
        return result
    end

    mod.targets = targets
end
