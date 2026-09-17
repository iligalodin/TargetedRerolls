return function(mod)
    local state = mod.state
    local search = state.search
    local utils = mod.utils
    local targets = mod.targets

    local function finish_search()
        search.active = false
        search.button_label = 'Targeted Reroll'
        search.targets = {}
        search.reserve = 0
        search.rolls = 0
        search.total_spent = 0
    end

    local function enqueue_step()
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            blocking = false,
            func = function()
                if not search.active then return true end
                if not utils.shop_is_open() then
                    finish_search()
                    return true
                end

                if targets.shop_contains(search.targets) then
                    finish_search()
                    return true
                end
                if G.CONTROLLER and G.CONTROLLER.locks and G.CONTROLLER.locks.shop_reroll then
                    return false
                end

                local cost = utils.current_cost()
                if not utils.can_pay_to_reserve(cost, search.reserve) then
                    finish_search()
                    return true
                end

                G.FUNCS.reroll_shop({})
                search.rolls = search.rolls + 1
                search.total_spent = search.total_spent + cost
                return false
            end,
        }))
    end

    function mod.start_search()
        if search.active or not utils.shop_is_open() then return end

        local reserve = utils.parse_whole_number(state.catalog.reserve_text)
        local target_list = targets.selected()
        if not reserve or #target_list == 0
            or not utils.can_pay_to_reserve(utils.current_cost(), reserve) then
            return
        end
        if targets.shop_contains(target_list) then
            G.FUNCS.close_targeted_reroll_catalog()
            return
        end

        G.FUNCS.close_targeted_reroll_catalog()
        search.active = true
        search.button_label = 'STOP'
        search.targets = target_list
        search.reserve = reserve
        search.rolls = 0
        search.total_spent = 0
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            blocking = false,
            func = function()
                enqueue_step()
                return true
            end,
        }))
    end

    G.FUNCS.can_start_targeted_reroll_search = function(e)
        local reserve = utils.parse_whole_number(state.catalog.reserve_text)
        local target_list = targets.selected()
        if not utils.shop_is_open() or search.active or #target_list == 0 or not reserve
            or not utils.can_pay_to_reserve(utils.current_cost(), reserve) then
            utils.disable_button(e)
            return
        end
        utils.enable_button(e, G.C.PURPLE, 'start_targeted_reroll_search')
    end

    G.FUNCS.start_targeted_reroll_search = mod.start_search
    G.FUNCS.stop_targeted_reroll = function()
        if search.active then finish_search() end
    end

    mod.finish_search = finish_search
end
