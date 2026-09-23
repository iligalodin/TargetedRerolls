return function(mod)
    local blacklist = {}
    local blocked_keys = {}
    local blocked_types = {}

    -- Static entries apply on every load; runtime entries use the API below.

    -- Add individual center keys here.
    local configured_keys = {
        -- 'j_example',
    }

    -- Add center.set values here, for example 'FakeCenter' or 'Edition'.
    local configured_types = {
        'Edition',
        'Default',
        'Enhanced',
        'DescriptionDummy',
        'Center',
        'Back',
        'Content Set',

        'FakeCenter',
    }

    for _, key in ipairs(configured_keys) do
        blocked_keys[key] = true
    end

    for _, center_type in ipairs(configured_types) do
        blocked_types[center_type] = true
    end

    local function center_key(center_or_key)
        if type(center_or_key) == 'table' then
            return center_or_key.key
        end

        return center_or_key
    end

    local function center_type(center_or_type)
        if type(center_or_type) == 'table' then
            return center_or_type.set or center_or_type.object_type or 'Center'
        end

        return center_or_type
    end


    -- Every mutation refreshes the grid so external mods take effect immediately.
    local function refresh_index()
        if mod.search_index then
            mod.search_index.refresh()
        end
    end

    local function update_blocklist(blocked, value, should_block)
        if value == nil then return false end

        value = tostring(value)
        if (blocked[value] == true) == should_block then return false end

        blocked[value] = should_block or nil
        refresh_index()
        return true
    end

    -- Add or remove one registered center key.
    function blacklist.add(center_or_key)
        return update_blocklist(blocked_keys, center_key(center_or_key), true)
    end

    function blacklist.remove(center_or_key)
        return update_blocklist(blocked_keys, center_key(center_or_key), false)
    end

    -- Add or remove a complete center set, such as a custom consumable type.
    function blacklist.add_type(center_or_type)
        return update_blocklist(blocked_types, center_type(center_or_type), true)
    end

    function blacklist.remove_type(center_or_type)
        return update_blocklist(blocked_types, center_type(center_or_type), false)
    end


    -- A center object matches either its own key or its registered type.
    function blacklist.contains(center_or_key)
        local key = center_key(center_or_key)
        if key and blocked_keys[tostring(key)] then return true end

        if type(center_or_key) == 'table' then
            local type_name = center_type(center_or_key)
            return type_name and blocked_types[tostring(type_name)] == true or false
        end

        return false
    end

    function blacklist.type_contains(center_or_type)
        local type_name = center_type(center_or_type)
        return type_name ~= nil and blocked_types[tostring(type_name)] == true
    end

    function blacklist.all()
        local keys = {}
        for key in pairs(blocked_keys) do
            keys[#keys + 1] = key
        end
        table.sort(keys)
        return keys
    end

    function blacklist.all_types()
        local types = {}
        for type_name in pairs(blocked_types) do
            types[#types + 1] = type_name
        end
        table.sort(types)
        return types
    end


    -- Clear only runtime state; static configured entries return after reload.
    function blacklist.clear()
        blocked_keys = {}
        blocked_types = {}
        refresh_index()
    end

    blacklist.blacklist = blacklist.add
    blacklist.unblacklist = blacklist.remove
    blacklist.blacklist_type = blacklist.add_type
    blacklist.unblacklist_type = blacklist.remove_type
    blacklist.is_blacklisted = blacklist.contains
    blacklist.is_type_blacklisted = blacklist.type_contains

    mod.blacklist = blacklist
    mod.blacklist_center = blacklist.add
    mod.blacklist_center_type = blacklist.add_type
    mod.is_center_blacklisted = blacklist.contains
    mod.is_center_type_blacklisted = blacklist.type_contains
end
