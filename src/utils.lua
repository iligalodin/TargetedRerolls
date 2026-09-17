return function(mod)
    local utils = {}

    function utils.number(value)
        if type(value) == 'number' then return value end
        if type(to_number) == 'function' then return to_number(value) end
        return tonumber(value) or 0
    end

    function utils.shop_is_open()
        return G and G.STATE == G.STATES.SHOP and G.GAME and G.shop_jokers
    end

    function utils.money()
        return utils.number(G.GAME.dollars or 0)
    end

    function utils.current_cost()
        return utils.number(G.GAME.current_round.reroll_cost or 0)
    end

    function utils.can_pay(cost)
        return utils.money() - utils.number(G.GAME.bankrupt_at or 0) >= cost
    end

    function utils.can_pay_to_reserve(cost, reserve)
        return utils.can_pay(cost) and utils.money() - cost >= reserve
    end

    function utils.disable_button(e)
        if not e or not e.config then return end
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end

    function utils.enable_button(e, colour, button)
        if not e or not e.config then return end
        e.config.colour = colour
        e.config.button = button
    end

    function utils.target_id(target_type, key)
        return target_type..':'..key
    end

    function utils.parse_whole_number(text)
        text = tostring(text or '')
        if text == '' or not text:match('^%d+$') then return nil end
        local value = tonumber(text)
        if not value or value < 0 or value ~= math.floor(value) then return nil end
        return value
    end

    mod.utils = utils
end
