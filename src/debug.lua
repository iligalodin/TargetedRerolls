return function(mod)
    local debug_money = 9000000

    -- Debug controls are available only while a run owns G.GAME.current_round.

    local function in_run()
        return G and G.GAME and G.GAME.current_round
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
                },
            }
        end
    end
end
