return function(mod)
    local state = mod.state
    local search = state.search
    local utils = mod.utils

    local original_shop = G.UIDEF.shop
    if original_shop then
        G.UIDEF.shop = function(...)
            local definition = original_shop(...)
            mod.add_targeted_button(definition)
            return definition
        end
    end

    local original_can_reroll = G.FUNCS.can_reroll
    if original_can_reroll then
        G.FUNCS.can_reroll = function(e)
            if search.active then
                utils.disable_button(e)
                return
            end
            return original_can_reroll(e)
        end
    end
end
