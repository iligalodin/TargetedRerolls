return function(mod)
    local state = mod.state
    local debug = state.debug
    local utils = mod.utils

    local function parse_money()
        return utils.parse_whole_number(debug.money_text)
    end

    G.FUNCS.can_targeted_rerolls_debug_money = function(e)
        if G and G.GAME and parse_money() then
            utils.enable_button(e, G.C.PURPLE, 'targeted_rerolls_debug_money')
            return
        end
        utils.disable_button(e)
    end

    G.FUNCS.targeted_rerolls_debug_money = function()
        local amount = parse_money()
        if G and G.GAME and amount then
            ease_dollars(amount - utils.money())
        end
    end

    G.FUNCS.open_targeted_rerolls_debug_menu = function()
        if G and G.GAME then
            debug.money_text = tostring(math.max(0, math.floor(utils.money())))
        end
        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu {
            definition = {
                n = G.UIT.ROOT,
                config = {align = 'cm', colour = G.C.BLACK, padding = 0.2, r = 0.1, minw = 6, minh = 4},
                nodes = {
                    {n = G.UIT.R, config = {align = 'cm', padding = 0.1}, nodes = {
                        {n = G.UIT.T, config = {text = 'DEBUG', scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }},
                    {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = {
                        {n = G.UIT.T, config = {text = 'SET MONEY TO', scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }},
                    {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = {
                        mod.numeric_text_input({
                            id = 'targeted_rerolls_debug_money_input',
                            w = 3.2,
                            h = 0.7,
                            max_length = 12,
                            ref_table = debug,
                            ref_value = 'money_text',
                            prompt_text = '$',
                            callback = function() parse_money() end,
                        }),
                    }},
                    {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = {
                        {n = G.UIT.T, config = {text = 'Enter a whole-dollar amount.', scale = 0.3, colour = G.C.UI.TEXT_LIGHT}},
                    }},
                    UIBox_button({
                        button = 'targeted_rerolls_debug_money',
                        func = 'can_targeted_rerolls_debug_money',
                        label = {'SET MONEY'},
                        colour = G.C.PURPLE,
                        minw = 3,
                        minh = 0.8,
                        scale = 0.4,
                    }),
                    UIBox_button({
                        button = 'exit_overlay_menu',
                        label = {'BACK'},
                        colour = G.C.GREY,
                        minw = 3,
                        minh = 0.8,
                        scale = 0.4,
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
                config = {r = 0.1, align = 'cm', padding = 0.15, colour = G.C.BLACK, minw = 8, minh = 5},
                nodes = {
                    {n = G.UIT.R, config = {align = 'cm', padding = 0.1}, nodes = {
                        {n = G.UIT.T, config = {text = 'Targeted Rerolls', scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }},
                    {n = G.UIT.R, config = {align = 'cm', padding = 0.15}, nodes = {
                        {n = G.UIT.T, config = {text = 'DEBUG MENU', scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }},
                    UIBox_button({
                        button = 'open_targeted_rerolls_debug_menu',
                        label = {'OPEN DEBUG MENU'},
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
