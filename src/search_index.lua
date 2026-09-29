return function(mod)
    local index = {}

    -- The index is a read-only catalog; it never changes vanilla card pools.

    -- Normalize once for deterministic case-insensitive sorting and searching.
    local function normalized(value)
        return tostring(value or ''):lower()
    end

    local function entry_name(entry)
        return entry.name or entry.key
    end
    -- Only Joker and consumable centers can appear in the normal shop catalog.
    local function is_shop_card_center(center)
        return center.set == 'Joker' or center.consumeable
    end


    -- Store every registry entry, but mark unavailable entries as unsearchable.
    local function add_center(entries, seen, pool_name, center, registry_key)
        if type(center) ~= 'table' then return end
        local key = center.key or registry_key
        if not key or seen[key] then return end

        seen[key] = true
        entries[#entries + 1] = {
            kind = 'center',
            key = key,
            name = center.name or key,
            pool = pool_name,
            set = center.set or pool_name,
            searchable = is_shop_card_center(center)
                and not center.omit
                and (not center.no_collection
                    or (type(center.no_collection) == 'function' and not center.no_collection()))
                and not (mod.blacklist and mod.blacklist.contains(center)),
            center = center,
        }
    end

    local function collect_centers(entries, seen)
        -- P_CENTERS is the canonical registry: every injected center lives here.
        for registry_key, center in pairs(G.P_CENTERS or {}) do
            if type(center) == 'table' then
                local center_type = center.set or center.object_type or 'Center'
                add_center(entries, seen, center_type, center, registry_key)
            end
        end
    end

    -- Playing-card fronts live in a separate registry from center objects.
    local function collect_playing_cards(entries)
        for key, front in pairs(G.P_CARDS or {}) do
            if key ~= 'empty' and type(front) == 'table' then
                entries[#entries + 1] = {
                    kind = 'playing_card',
                    key = key,
                    name = front.name or key,
                    pool = 'Playing Card',
                    set = 'Playing Card',
                    searchable = true,
                    front = front,
                }
            end
        end
    end

    -- Type, origin/bundle, rarity, then name; compute keys once per refresh.
    local function sort_entries(entries)
        local rarity_order = {Common = 1, Uncommon = 2, Rare = 3, Legendary = 4}
        local next_rarity = 4
        for _, key in ipairs((SMODS and SMODS.Rarity and SMODS.Rarity.obj_buffer) or {}) do
            if not rarity_order[key] then
                next_rarity = next_rarity + 1
                rarity_order[key] = next_rarity
            end
        end

        for _, entry in ipairs(entries) do
            local center = entry.center or entry.front
            local card_type = entry.set or entry.pool
            local type_order = card_type == 'Joker' and 1
                or (center.consumeable and 2 or 3)
            local type_name = card_type == 'Playing Card' and 'Cards' or card_type
            -- Taking ownership does not turn a base-game card into mod content.
            local owner = center.original_mod or (not center.taken_ownership and center.mod)
            local bundle = type(center.bundle) == 'table' and center.bundle[1] or center.bundle
            local source = owner and (bundle or owner.display_name or owner.name or owner.id) or ''
            local rarity = center.rarity
            local rarity_rank = type(rarity) == 'number' and rarity
                or rarity_order[rarity] or (rarity == nil and 0 or math.huge)
            local descriptions = G.localization and G.localization.descriptions
            local text = descriptions and descriptions[card_type] and descriptions[card_type][entry.key]
            local name = text and type(text.name) == 'string' and text.name or entry_name(entry)
            entry.sort_key = {
                type_order, normalized(type_name), owner and 1 or 0, normalized(source),
                rarity_rank, rarity_rank == math.huge and normalized(rarity) or '',
                normalized(name), entry.key, entry.kind,
            }
        end

        table.sort(entries, function(a, b)
            for i = 1, #a.sort_key do
                if a.sort_key[i] ~= b.sort_key[i] then
                    return a.sort_key[i] < b.sort_key[i]
                end
            end
            return false
        end)
    end

    -- Refresh after a blacklist mutation or when another mod registers content.
    function index.refresh()
        local entries = {}
        local seen_centers = {}

        collect_centers(entries, seen_centers)
        collect_playing_cards(entries)
        sort_entries(entries)

        index.entries = entries
        return entries
    end

    function index.all()
        return index.entries or index.refresh()
    end

    -- Search names, keys, pools, and sets without interpreting pattern syntax.
    function index.search(query, pool)
        query = normalized(query)
        local matches = {}

        for _, entry in ipairs(index.all()) do
            local in_pool = not pool
                or pool == ''
                or (
                    entry.kind == 'center'
                    and (entry.set == pool or entry.pool == pool)
                )
                or (
                    entry.kind == 'playing_card'
                    and pool == 'Playing Card'
                )

            if in_pool and entry.searchable then
                local haystack = table.concat({
                    normalized(entry_name(entry)),
                    normalized(entry.key),
                    normalized(entry.pool),
                    normalized(entry.set),
                }, ' ')

                if query == '' or haystack:find(query, 1, true) then
                    matches[#matches + 1] = entry
                end
            end
        end

        return matches
    end
    -- First appearances in the sorted catalog give the sidebar See All's order.
    function index.center_types()
        local types = {}
        local seen = {}

        for _, entry in ipairs(index.all()) do
            if entry.searchable
                and (entry.kind == 'center' or entry.kind == 'playing_card') then
                local center_type = entry.kind == 'playing_card'
                    and 'Playing Card'
                    or (entry.set or entry.pool)
                if not seen[center_type] then
                    seen[center_type] = true
                    types[#types + 1] = center_type
                end
            end
        end

        return types
    end


    mod.search_index = index
end