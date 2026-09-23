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
                and not center.no_collection
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

    -- Stable ordering keeps saved selections and pagination predictable.
    local function sort_entries(entries)
        table.sort(entries, function(a, b)
            local name_a = normalized(entry_name(a))
            local name_b = normalized(entry_name(b))

            if name_a == name_b then
                return a.key < b.key
            end

            return name_a < name_b
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
    -- Derive the sidebar categories from entries the player can actually select.
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

        table.sort(types, function(a, b)
            return normalized(a) < normalized(b)
        end)

        return types
    end


    mod.search_index = index
end