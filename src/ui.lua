return function(mod)

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
                button = 'die_button_callback',
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
                    nodes = {
                        {
                            n = G.UIT.T,
                            config = {
                                text = localize('tagr_shop_reroll'),
                                scale = 0.4,
                                colour = G.C.WHITE,
                                shadow = true,
                            },
                        },
                    },
                },
                {
                    n = G.UIT.R,
                    config = {
                        align = 'cm',
                        padding = 0,
                    },
                    nodes = {
                        {
                            n = G.UIT.O,
                            config = {
                                object = get_die_sprite(),
                                w = 0.5,
                                h = 0.5,
                            },
                        },
                    },
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