return function(mod)
    local targeted_reroll = {}
    local active = false

    -- Search state stays private so only this module controls reroll events.

    local function comparable(value)
        return type(to_big) == 'function' and to_big(value) or value
    end

    local function display_value(value)
        return tostring(value or 0)
    end

    -- Keep the last transition available to the debug menu and BalatroBot.
    local function trace(phase, detail, entries)
        mod.reroll_diagnostics = {
            active = active,
            phase = phase,
            detail = detail,
            selected = entries or 0,
            money = display_value(G and G.GAME and G.GAME.dollars),
            cost = display_value(G and G.GAME and G.GAME.current_round and G.GAME.current_round.reroll_cost),
            reserve = tostring(math.max(0, math.floor(tonumber(mod.money_reserve) or 0))),
        }
    end

    -- A search can only run while the vanilla shop card area exists.
    local function shop_is_open()
        return G
            and G.STATES
            and G.STATE == G.STATES.SHOP
            and G.GAME
            and G.shop_jokers
    end

    local function reroll_cost()
        local round = G.GAME and G.GAME.current_round
        return round and round.reroll_cost or 0
    end

    local function money_available()
        return G.GAME and G.GAME.dollars or 0
    end

    local function reserve_amount()
        return math.max(0, math.floor(tonumber(mod.money_reserve) or 0))
    end

    -- Compare through Talisman/Amulet when those mods replace Lua numbers.
    local function can_pay_to_reserve(cost, reserve)
        local bankrupt_at = G.GAME and G.GAME.bankrupt_at or 0
        local money = comparable(money_available())
        return money - comparable(bankrupt_at) >= comparable(cost)
            and money - comparable(cost) >= comparable(reserve)
    end

    local function finish_search(reason, entries)
        local was_active = active
        active = false
        if was_active then trace('stopped', reason, entries) end
    end


    -- One event remains queued until a target appears, STOP is pressed, or funds run out.
    local function enqueue_step(entries, reserve)
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            blocking = false,
            func = function()
                if not active then return true end
                if not shop_is_open() then
                    finish_search('shop closed', #entries)
                    return true
                end
                if mod.shop_targets.shop_contains(entries) then
                    finish_search('target found', #entries)
                    return true
                end
                if G.CONTROLLER and G.CONTROLLER.locks
                    and G.CONTROLLER.locks.shop_reroll
                then
                    return false
                end

                local cost = reroll_cost()
                if not can_pay_to_reserve(cost, reserve) then
                    finish_search('reserve reached', #entries)
                    return true
                end

                trace('rolling', 'calling vanilla reroll_shop', #entries)
                G.FUNCS.reroll_shop({})
                return false
            end,
        }))
    end

    -- Expose the same preflight check used by the modal's start action.
    function targeted_reroll.can_start()
        if active or not shop_is_open() then return false end
        local entries = mod.shop_targets.selected_entries()
        return #entries > 0
            and can_pay_to_reserve(reroll_cost(), reserve_amount())
    end

    -- Snapshot targets and reserve once; later UI changes cannot alter this search.
    function targeted_reroll.start()

        if mod.ensure_stop_input_hook then
            mod.ensure_stop_input_hook()
        end
        if mod.register_balatrobot_diagnostics then
            mod.register_balatrobot_diagnostics()
        end

        if active then
            trace('rejected', 'search already active')
            return false
        end
        if not shop_is_open() then
            trace('rejected', 'shop is not open')
            return false
        end

        local reserve = reserve_amount()
        local entries = mod.shop_targets.selected_entries()
        if #entries == 0 then
            trace('rejected', 'no selected target')
            return false
        end
        if not can_pay_to_reserve(reroll_cost(), reserve) then
            trace('rejected', 'reroll would cross reserve', #entries)
            return false
        end

        if mod.shop_targets.shop_contains(entries) then
            trace('stopped', 'target already in shop', #entries)
            mod.close_overlay()
            return true
        end

        mod.close_overlay()
        active = true
        trace('queued', 'modal closed; waiting 0.1 seconds', #entries)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            blocking = false,
            func = function()
                trace('queued', 'search loop started', #entries)
                enqueue_step(entries, reserve)
                return true
            end,
        }))
        return true
    end

    function targeted_reroll.cancel()
        finish_search('stopped by player')
    end

    function targeted_reroll.is_active()
        return active
    end

    mod.targeted_reroll = targeted_reroll
end
