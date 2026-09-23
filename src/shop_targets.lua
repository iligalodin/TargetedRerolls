return function(mod)
    local shop_targets = {}

    local entry_id = mod.entry_id


    -- Resolve indexed centers lazily because mods can register content later.
    local function center_for_entry(entry)
        return entry.center or (G.P_CENTERS and G.P_CENTERS[entry.key])
    end

    -- Selection reflects collection visibility, not the current vanilla pool.
    local function center_is_visible(center)
        return center
            and not center.hidden
            and not center.no_collection
            and not center.omit
            and center.unlocked ~= false
    end


    -- Use the same matching rules for every real shop card during a search.
    function shop_targets.is_selectable(entry)
        if not entry or not entry.searchable then return false end
        if entry.kind == 'playing_card' then return true end
        return center_is_visible(center_for_entry(entry))
    end

    -- Selection is read-only; vanilla rerolls decide what appears.

    local function card_center(card)
        return card and card.config and card.config.center
    end

    local function card_front_key(card)
        if not card or not card.config then return nil end
        return card.config.card_key
            or (card.config.card and card.config.card.key)
    end

    function shop_targets.card_matches_entry(card, entry)
        if not card or not entry then return false end

        local center = card_center(card)
        if entry.kind == 'playing_card' then
            local front = card.config and card.config.card
            return card_front_key(card) == entry.key
                and front
                and front.suit
                and front.value
                and center
                and (center.set == 'Default' or center.set == 'Enhanced')
        end

        return center
            and (center.key == entry.key or center.original_key == entry.key)
    end

    function shop_targets.selected_entries()
        local entries = {}
        for _, entry in ipairs(mod.search_index.all()) do
            if mod.selected_cards[entry_id(entry)] then
                entries[#entries + 1] = entry
            end
        end
        return entries
    end

    function shop_targets.shop_contains(entries)
        if not G.shop_jokers or not G.shop_jokers.cards then return false end

        for _, card in ipairs(G.shop_jokers.cards) do
            if not card.states or card.states.visible ~= false then
                for _, entry in ipairs(entries) do
                    if shop_targets.card_matches_entry(card, entry) then
                        return true
                    end
                end
            end
        end

        return false
    end

    -- Keep the count derived from the same filtered entry list as rerolling.
    function shop_targets.selected_count()
        return #shop_targets.selected_entries()
    end

    mod.shop_targets = shop_targets
end
