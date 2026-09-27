return function(mod)
    local targeted_reroll = {}
    local active = false
    local elapsed = 0
    local rolls = 0
    local generation = 0
    local search_run
    local search_shop
    local ramp_seconds = 15

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
            and G.STAGES
            and G.STAGE == G.STAGES.RUN
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
        elapsed = 0
        rolls = 0
        generation = generation + 1
        search_run = nil
        search_shop = nil
        if was_active then trace('stopped', reason, entries) end
    end

    local function search_is_active()
        if active and (not shop_is_open()
            or G.GAME ~= search_run or G.shop_jokers ~= search_shop)
        then
            finish_search('shop closed')
        end
        return active
    end


    -- One event remains queued until a target appears, STOP is pressed, or funds run out.
    local function enqueue_step(entries, reserve, token)
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            blocking = false,
            func = function()
                if token ~= generation or not search_is_active() then return true end
                if G.SETTINGS.paused then return false end
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
                rolls = rolls + 1
                return false
            end,
        }))
    end

    -- Expose the same preflight check used by the modal's start action.
    function targeted_reroll.can_start()
        if search_is_active() or not shop_is_open() then return false end
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

        if search_is_active() then
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
        elapsed = 0
        rolls = 0
        generation = generation + 1
        local token = generation
        search_run = G.GAME
        search_shop = G.shop_jokers
        trace('queued', 'modal closed; waiting 0.1 seconds', #entries)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            blocking = false,
            func = function()
                if token ~= generation or not search_is_active() then return true end
                if G.SETTINGS.paused then return false end
                trace('queued', 'search loop started', #entries)
                enqueue_step(entries, reserve, token)
                return true
            end,
        }))
        return true
    end

    function targeted_reroll.cancel()
        finish_search('stopped by player')
    end

    function targeted_reroll.is_active()
        return search_is_active()
    end

    function targeted_reroll.get_heat()
        if not search_is_active() or rolls < 10 then return 0 end
        return math.min(1, 0.05 + 0.95 * (rolls - 10) / 20)
    end

    function targeted_reroll.speed_multiplier()
        if not search_is_active() or G.SETTINGS.paused then return 1 end
        return 1 + 9 * elapsed / ramp_seconds
    end

    -- Game:update receives real dt before vanilla applies SPEEDFACTOR.
    local game_update = Game.update
    function Game:update(dt)
        if search_is_active() and not G.SETTINGS.paused then
            elapsed = math.min(ramp_seconds, elapsed + dt)
        end
        local result = game_update(self, dt)
        -- The update itself may have left this shop or replaced the run.
        search_is_active()
        return result
    end

    mod.targeted_reroll = targeted_reroll
end
