return function(mod)
    local debug_money = 9000000

    -- Debug controls are available only while a run owns G.GAME.current_round.

    local function in_run()
        return G and G.GAME and G.GAME.current_round
    end

    local catalog_file_name = 'TargetedRerolls-card-catalog.json'

    -- JSON cannot represent callbacks, userdata, cyclic graphs, or non-finite
    -- numbers. Keep every readable attribute while making the snapshot writable.
    local function export_value(value, seen, depth)
        local value_type = type(value)
        if value_type == 'string' or value_type == 'boolean' then return value end
        if value_type == 'number' then
            if value ~= value or value == math.huge or value == -math.huge then
                return tostring(value)
            end
            return value
        end
        if value_type ~= 'table' then return '<'..value_type..'>' end
        if seen[value] then return '<cycle>' end
        if depth >= 16 then return '<max depth>' end

        seen[value] = true
        local snapshot = {}
        for key, child in pairs(value) do
            snapshot[tostring(key)] = export_value(child, seen, depth + 1)
        end
        seen[value] = nil
        return snapshot
    end

    local function snapshot_registry(registry)
        local snapshot, count = {}, 0
        for key, value in pairs(registry or {}) do
            snapshot[tostring(key)] = export_value(value, {}, 0)
            count = count + 1
        end
        return snapshot, count
    end

    -- Build the same pools used when a card is created in G.shop_jokers.
    -- `sho` is the key_append passed by create_card_for_shop, so Steamodded
    -- gives every in_pool callback its real shop context.
    local function sorted_keys(values)
        local keys = {}
        for key in pairs(values) do keys[#keys + 1] = key end
        table.sort(keys)
        return keys
    end

    local function non_legendary_rarities(card_type)
        local object_type = SMODS
            and SMODS.ObjectTypes
            and SMODS.ObjectTypes[card_type]
        local rarities = object_type and object_type.rarities
        local keys, seen = {}, {}

        for _, rarity in ipairs(rarities or {}) do
            local key = type(rarity) == 'table' and rarity.key or rarity
            if key and key ~= 'Legendary' and key ~= 4 and not seen[key] then
                seen[key] = true
                keys[#keys + 1] = key
            end
        end

        if card_type == 'Joker' and #keys == 0 then
            keys = {'Common', 'Uncommon', 'Rare'}
        end
        return keys
    end

    local function drawer_pool(card_type, rarity)
        local ok, pool, pool_key = pcall(
            get_current_pool,
            card_type,
            rarity,
            nil,
            'sho'
        )
        if not ok then
            return nil, tostring(pool)
        end

        local keys = {}
        for _, key in ipairs(pool or {}) do
            if key ~= 'UNAVAILABLE' then keys[key] = true end
        end
        return {
            pool_key = pool_key,
            keys = sorted_keys(keys),
        }
    end

    local function drawer_pools(card_type)
        local rarities = non_legendary_rarities(card_type)
        if #rarities == 0 then
            local pool, err = drawer_pool(card_type)
            return pool and {default = pool} or nil, err
        end

        local pools = {}
        for _, rarity in ipairs(rarities) do
            local pool, err = drawer_pool(card_type, rarity)
            if not pool then return nil, err end
            pools[tostring(rarity)] = pool
        end
        return pools
    end

    local function drawer_playing_cards()
        local keys = {}
        for key, front in pairs(G.P_CARDS or {}) do
            local suit = front and SMODS.Suits and SMODS.Suits[front.suit]
            local rank = front and SMODS.Ranks and SMODS.Ranks[front.value]
            if suit and rank then
                local rank_ok = SMODS.add_to_pool(rank, {
                    initial_deck = false,
                    suit = front.suit,
                })
                local suit_ok = SMODS.add_to_pool(suit, {
                    initial_deck = false,
                    rank = front.value,
                })
                if rank_ok and suit_ok then keys[key] = true end
            end
        end
        return sorted_keys(keys)
    end
    local function effective_shop_rate(card_type)
        local rate = G.GAME[card_type:lower()..'_rate'] or 0
        local percrate = G.GAME.cry_percrate
        if percrate and card_type ~= 'Joker' and card_type ~= 'Spectral' then
            rate = rate * ((percrate[card_type:lower()] or 100) / 100)
        end
        return rate
    end

    local function scheduled_joker_drawer_centers()
        local keys = {}
        for _, saved_card in ipairs(G.GAME.next_shop_cards or {}) do
            local area = saved_card.cry_from_shop
            local key = saved_card.save_fields and saved_card.save_fields.center
            if (area == nil or area == 'shop_jokers') and key then
                keys[key] = true
            end
        end
        return sorted_keys(keys)
    end

    local function cryptid_equilibrium_snapshot()
        local cryptid = rawget(_G, 'Cryptid')
        if not (
            G.GAME.modifiers
            and G.GAME.modifiers.cry_equilibrium
            and cryptid
            and type(cryptid.can_spawn_equilibrium) == 'function'
        ) then
            return nil
        end

        local keys = {}
        for _, pool_name in ipairs({'Joker', 'Consumeables', 'Voucher', 'Booster'}) do
            for _, center in ipairs(G.P_CENTER_POOLS[pool_name] or {}) do
                local ok, can_spawn = pcall(cryptid.can_spawn_equilibrium, center)
                if ok and can_spawn then keys[center.key] = true end
            end
        end

        local base_ok, can_spawn_base = false, false
        if G.P_CENTERS.c_base then
            base_ok, can_spawn_base = pcall(
                cryptid.can_spawn_equilibrium,
                G.P_CENTERS.c_base
            )
        end
        return {
            centers = sorted_keys(keys),
            card_fronts = base_ok and can_spawn_base and drawer_playing_cards() or {},
        }
    end


    local function drawer_types()
        local types, seen = {}, {}
        local function add(card_type)
            if seen[card_type] then return end
            seen[card_type] = true
            local rate = effective_shop_rate(card_type)
            if rate > 0 then
                types[#types + 1] = {key = card_type, rate = rate}
            end
        end

        add('Joker')
        add('Tarot')
        add('Planet')
        add('Spectral')
        if (G.GAME.playing_card_rate or 0) > 0 then
            local is_enhanced = (G.GAME.used_vouchers or {})['v_illusion']
                and pseudorandom(pseudoseed('illusion')) > 0.6
            types[#types + 1] = {
                key = is_enhanced and 'Enhanced' or 'Base',
                rate = G.GAME.playing_card_rate,
            }
        end
        for _, card_type in ipairs(
            (SMODS.ConsumableType and SMODS.ConsumableType.obj_buffer) or {}
        ) do
            add(card_type)
        end
        return types
    end

    function mod.snapshot_joker_drawer()
        if not (G and G.GAME) then
            return nil, 'a run must be active'
        end
        if type(get_current_pool) ~= 'function' then
            return nil, 'get_current_pool is unavailable'
        end
        if not (SMODS and SMODS.add_to_pool and SMODS.Suits and SMODS.Ranks) then
            return nil, 'Steamodded pool helpers are unavailable'
        end

        local centers, card_fronts = {}, {}
        local by_type = {}
        for _, entry in ipairs(drawer_types()) do
            local type_key = entry.key
            local type_snapshot = {rate = entry.rate}
            if type_key == 'Base' then
                type_snapshot.centers = {'c_base'}
                type_snapshot.card_fronts = drawer_playing_cards()
            else
                local pools, err = drawer_pools(type_key)
                if not pools then return nil, err end
                type_snapshot.pools = pools
                if type_key == 'Enhanced' then
                    type_snapshot.card_fronts = drawer_playing_cards()
                end
            end
            by_type[type_key] = type_snapshot
        end
        local scheduled = scheduled_joker_drawer_centers()
        if #scheduled > 0 then
            by_type.scheduled = {centers = scheduled}
        end

        local equilibrium = cryptid_equilibrium_snapshot()
        if equilibrium then by_type.equilibrium = equilibrium end


        for type_key, type_snapshot in pairs(by_type) do
            for _, key in ipairs(type_snapshot.centers or {}) do
                centers[key] = centers[key] or {}
                centers[key][#centers[key] + 1] = type_key
            end
            for _, pool in pairs(type_snapshot.pools or {}) do
                for _, key in ipairs(pool.keys) do
                    centers[key] = centers[key] or {}
                    centers[key][#centers[key] + 1] = type_key
                end
            end
            for _, key in ipairs(type_snapshot.card_fronts or {}) do
                card_fronts[key] = card_fronts[key] or {}
                card_fronts[key][#card_fronts[key] + 1] = type_key
            end
        end
        for _, types in pairs(centers) do table.sort(types) end
        for _, types in pairs(card_fronts) do table.sort(types) end


        return {
            source = 'create_card_for_shop',
            key_append = 'sho',
            by_type = by_type,
            centers = centers,
            card_fronts = card_fronts,
        }
    end


    function mod.export_card_catalog()
        if not (G and G.P_CENTERS and G.P_CARDS) then
            return false, 'card registries are not initialized'
        end
        if not (JSON and type(JSON.encode) == 'function') then
            return false, 'Steamodded JSON encoder is unavailable'
        end

        local centers, center_count = snapshot_registry(G.P_CENTERS)
        local cards, card_count = snapshot_registry(G.P_CARDS)
        local joker_drawer, drawer_error = mod.snapshot_joker_drawer()
        if not joker_drawer then
            return false, 'joker drawer snapshot failed: '..drawer_error
        end
        local ok, encoded = pcall(JSON.encode, {
            generated_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            source = {
                centers = 'G.P_CENTERS',
                card_centers = 'G.P_CARDS',
            },
            counts = {
                centers = center_count,
                card_centers = card_count,
            },
            centers = centers,
            card_centers = cards,
            joker_drawer = joker_drawer,
        })
        if not ok then return false, 'JSON encoding failed: '..tostring(encoded) end

        local ok_write, write_result = pcall(
            love.filesystem.write,
            catalog_file_name,
            encoded
        )
        if not ok_write or not write_result then
            return false, 'write failed: '..tostring(write_result)
        end

        local path = love.filesystem.getSaveDirectory()..'/'..catalog_file_name
        mod.card_catalog_export_path = path
        return true, path
    end

    -- Register a scalar-only endpoint so BalatroBot can serialize it safely.
    local balatrobot_registered = false
    function mod.register_balatrobot_diagnostics()
        if balatrobot_registered then return true end
        if not BB_DISPATCHER or type(BB_DISPATCHER.register) ~= 'function' then
            return false
        end

        local ok, registered = pcall(BB_DISPATCHER.register, {
            name = 'targeted_rerolls_debug',
            description = 'Return Targeted Rerolls lifecycle diagnostics',
            schema = {},
            requires_state = nil,
            execute = function(_, send_response)
                send_response(mod.reroll_diagnostics or {
                    active = false,
                    phase = 'idle',
                    detail = 'no targeted reroll has been started',
                    selected = 0,
                    money = 0,
                    cost = 0,
                    reserve = 0,
                })
            end,
        })
        balatrobot_registered = ok and registered
        if balatrobot_registered and sendInfoMessage then
            sendInfoMessage(
                'BalatroBot endpoint ready: targeted_rerolls_debug',
                'TargetedRerolls'
            )
        end
        return balatrobot_registered
    end

    -- Keep in-game diagnostics compact while retaining the full Bot payload.
    local function diagnostic_text()
        local diagnostic = mod.reroll_diagnostics
        if not diagnostic then return 'LAST: no targeted reroll started' end
        return string.format(
            'LAST: %s — %s',
            diagnostic.phase or 'unknown',
            diagnostic.detail or 'unknown'
        )
    end

    G.FUNCS.targeted_rerolls_debug_set_9m = function()
        if not in_run() then return end
        ease_dollars(
            (type(to_big) == 'function' and to_big(debug_money) or debug_money)
            - (type(to_big) == 'function' and to_big(G.GAME.dollars or 0) or (G.GAME.dollars or 0))
        )
    end

    G.FUNCS.targeted_rerolls_debug_reset_reroll = function()
        if not in_run() then return end
        G.GAME.current_round.reroll_cost = 1
    end

    G.FUNCS.targeted_rerolls_export_card_catalog = function()
        local ok, result = mod.export_card_catalog()
        local message = ok
            and 'Card catalog exported: '..result
            or 'Card catalog export failed: '..result
        if sendInfoMessage then
            sendInfoMessage(message, 'TargetedRerolls')
        else
            print(message)
        end
    end


    G.FUNCS.targeted_rerolls_close_debug_menu = mod.close_overlay

    -- The debug overlay deliberately pauses the game until it is closed.
    G.FUNCS.open_targeted_rerolls_debug_menu = function()
        if not in_run() then return end

        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu {
            definition = {
                n = G.UIT.ROOT,
                config = {
                    align = 'cm',
                    colour = G.C.BLACK,
                    padding = 0.2,
                    r = 0.1,
                    minw = 6,
                    minh = 4,
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = {align = 'cm', padding = 0.1},
                        nodes = {{
                            n = G.UIT.T,
                            config = {
                                text = 'TARGETED REROLLS DEBUG',
                                scale = 0.45,
                                colour = G.C.UI.TEXT_LIGHT,
                                shadow = true,
                            },
                        }},
                    },
                    {
                        n = G.UIT.R,
                        config = {align = 'cm', padding = 0.1},
                        nodes = {{
                            n = G.UIT.T,
                            config = {
                                text = diagnostic_text(),
                                scale = 0.28,
                                colour = G.C.UI.TEXT_LIGHT,
                                shadow = true,
                            },
                        }},
                    },
                    UIBox_button({
                        button = 'targeted_rerolls_debug_set_9m',
                        label = {'SET MONEY: $9,000,000'},
                        colour = G.C.PURPLE,
                        minw = 4.5,
                        minh = 0.8,
                        scale = 0.35,
                    }),
                    UIBox_button({
                        button = 'targeted_rerolls_debug_reset_reroll',
                        label = {'RESET REROLL COST'},
                        colour = G.C.PURPLE,
                        minw = 4.5,
                        minh = 0.8,
                        scale = 0.35,
                    }),
                    UIBox_button({
                        button = 'targeted_rerolls_close_debug_menu',
                        label = {'BACK'},
                        colour = G.C.GREY,
                        minw = 4.5,
                        minh = 0.8,
                        scale = 0.35,
                    }),
                },
            },
            config = {offset = {x = 0, y = 10}},
        }
    end

    if SMODS and SMODS.current_mod then
        SMODS.current_mod.config_tab = function()
            return {
                n = G.UIT.ROOT,
                config = {
                    r = 0.1,
                    align = 'cm',
                    padding = 0.15,
                    colour = G.C.BLACK,
                    minw = 8,
                    minh = 5,
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = {align = 'cm', padding = 0.1},
                        nodes = {{
                            n = G.UIT.T,
                            config = {
                                text = 'Targeted Rerolls',
                                scale = 0.5,
                                colour = G.C.UI.TEXT_LIGHT,
                                shadow = true,
                            },
                        }},
                    },
                    UIBox_button({
                        button = 'open_targeted_rerolls_debug_menu',
                        label = {'OPEN DEBUG MENU'},
                        colour = G.C.PURPLE,
                        minw = 3.5,
                        minh = 0.9,
                        scale = 0.4,
                    }),
                    UIBox_button({
                        button = 'targeted_rerolls_export_card_catalog',
                        label = {'EXPORT CARD CATALOG'},
                        colour = G.C.PURPLE,
                        minw = 3.5,
                        minh = 0.9,
                        scale = 0.4,
                    }),
                },
            }
        end
    end
end
