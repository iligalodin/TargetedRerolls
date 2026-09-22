return function(mod)
    G.FUNCS.open_test_modal = function()
        local padding = 0.4
        local screen_w = G.ROOM.T.w
        local screen_h = G.ROOM.T.h
        local content_w = screen_w - padding * 2
        local content_h = screen_h - padding * 2
        local category_w = 3.2
        local panel_w = content_w - category_w - 0.4
        local panel_h = content_h - 2.4

        G.FUNCS.overlay_menu {
            definition = {
                n = G.UIT.ROOT,
                config = {
                    align = 'cm',
                    colour = G.C.BLACK,
                    padding = padding,
                    r = 0.1,
                    minw = content_w,
                    minh = content_h,
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = {
                            align = 'cm',
                            minw = content_w,
                            padding = 0.1,
                        },
                        nodes = {
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cl',
                                    minw = content_w * 0.5,
                                },
                                nodes = {
                                    UIBox_button({
                                        button = 'nil',
                                        label = {'SEARCH'},
                                        colour = G.C.BLUE,
                                        minw = 4,
                                        minh = 0.8,
                                        scale = 0.4,
                                    }),
                                },
                            },
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cr',
                                    minw = content_w * 0.5,
                                },
                                nodes = {
                                    UIBox_button({
                                        button = 'exit_overlay_menu',
                                        label = {'CLOSE'},
                                        colour = G.C.RED,
                                        minw = 2,
                                        minh = 0.8,
                                        scale = 0.4,
                                    }),
                                },
                            },
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = {
                            align = 'cm',
                            padding = 0.1,
                        },
                        nodes = {
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cm',
                                    padding = 0.05,
                                    minw = category_w,
                                },
                                nodes = {
                                    UIBox_button({button = 'nil', label = {'^'}, colour = G.C.RED, minw = category_w, minh = 0.55, scale = 0.3}),
                                    UIBox_button({button = 'nil', label = {'Jokers'}, colour = G.C.RED, minw = category_w, minh = 0.65, scale = 0.3}),
                                    UIBox_button({button = 'nil', label = {'Tarot'}, colour = G.C.RED, minw = category_w, minh = 0.65, scale = 0.3}),
                                    UIBox_button({button = 'nil', label = {'Spectral'}, colour = G.C.RED, minw = category_w, minh = 0.65, scale = 0.3}),
                                    UIBox_button({button = 'nil', label = {'Voucher'}, colour = G.C.RED, minw = category_w, minh = 0.65, scale = 0.3}),
                                    UIBox_button({button = 'nil', label = {'Cards'}, colour = G.C.RED, minw = category_w, minh = 0.65, scale = 0.3}),
                                    UIBox_button({button = 'nil', label = {'v'}, colour = G.C.RED, minw = category_w, minh = 0.55, scale = 0.3}),
                                },
                            },
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cm',
                                    minw = panel_w,
                                    minh = panel_h,
                                    colour = G.C.GREY,
                                },
                                nodes = {},
                            },
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = {
                            align = 'cr',
                            minw = content_w,
                            padding = 0.1,
                        },
                        nodes = {
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cm',
                                    minw = 2.1,
                                },
                                nodes = {
                                    UIBox_button({
                                        button = 'nil',
                                        label = {'CLEAR'},
                                        colour = G.C.GREY,
                                        minw = 2,
                                        minh = 0.8,
                                        scale = 0.4,
                                    }),
                                },
                            },
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cm',
                                    minw = 2.1,
                                },
                                nodes = {
                                    UIBox_button({
                                        button = 'nil',
                                        label = {'ROLL'},
                                        colour = G.C.PURPLE,
                                        minw = 2,
                                        minh = 0.8,
                                        scale = 0.4,
                                    }),
                                },
                            },
                        },
                    },
                },
            },
            config = {
                offset = {x = 0, y = 0},
            },
        }
    end







    SMODS.Atlas({
        key = 'die_shaded',
        path = 'die_shaded.png',
        px = 32,
        py = 34,
        force_pixel = true,
    })

    local function get_die_sprite()
        if not mod.die_sprite then
            mod.die_sprite = Sprite(
                0,
                0,
                1,
                1.1,
                G.ASSET_ATLAS['targeted_rerolls_die_shaded'],
                {x = 0, y = 0}
            )

            mod.die_sprite.states.drag.can = false
        end

        return mod.die_sprite
    end


    local reroll_size 
    reroll_size  = {width = 1.4, height = 1.4}

    G.FUNCS.die_button_callback = function()
        print('shop button werkt')
    end

    local function render_die_button()
        return {
            n = G.UIT.C,
            config = {
                id = 'die_button',
                align = 'cm',
                minw = reroll_size.width,
                maxw = reroll_size.width,
                minh = reroll_size.height,
                maxh = reroll_size.height,
                padding = 0.1,
                r = 0.15,
                colour = G.C.PURPLE,
                button = 'open_test_modal',
                hover = true,
                shadow = true,
            },
            nodes = {
                {
                    n = G.UIT.R,
                    config = {
                        align = 'cm',
                        padding = 0,
                    },
                    nodes = {{
                        n = G.UIT.T,
                        config = {
                            text = localize('tagr_shop_reroll'),
                            scale = 0.4,
                            colour = G.C.WHITE,
                            shadow = true,
                        },
                    }, },
                },
                {
                    n = G.UIT.R,
                    config = {
                        align = 'cm',
                        padding = 0,
                    },
                    nodes = {{
                        n = G.UIT.O,
                        config = {
                            object = get_die_sprite(),
                            w = 0.5,
                            h = 0.5,
                        },
                    }, },
                },
            },
        }
    end

    local function reshape_shop_buttons(node)
        if type(node) ~= 'table' or type(node.nodes) ~= 'table' then
            return false
        end

        local reroll_index
        local reroll_node

        for index, child in ipairs(node.nodes) do
            local config = child.config
            if config and config.button == 'reroll_shop' then
                reroll_index = index
                reroll_node = child
                break
            end
        end

        if reroll_index and reroll_node then
            reroll_node.config.minw = reroll_size.width
            reroll_node.config.maxw = reroll_size.width
            reroll_node.config.minh = reroll_size.height
            reroll_node.config.maxh = reroll_size.height

            local split_row = {
                n = G.UIT.R,
                config = {
                    align = 'cm',
                    padding = 0.05,
                },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = {align = 'cm', minw = 1.4},
                        nodes = {reroll_node},
                    },
                    {
                        n = G.UIT.B,
                        config = {
                            w = 0.05,
                            h = reroll_size.height
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = {align = 'cm', minw = 1.4},
                        nodes = {render_die_button()},
                    },
                },

            }
            node.nodes[reroll_index] = split_row
            return true
        end

        for _, child in ipairs(node.nodes) do
            if reshape_shop_buttons(child) then
                return true
            end
        end

        return false
    end

    local original_shop = G.UIDEF and G.UIDEF.shop
    if original_shop and not mod.ui_shop_hooked then
        mod.ui_shop_hooked = true
        G.UIDEF.shop = function(...)
            local definition = original_shop(...)
            reshape_shop_buttons(definition)
            return definition
        end
    end

end