return function(mod)

    -- Modal state is kept on the shared mod table so reopening preserves filters.

    mod.search_input = mod.search_input or {
        text = '',
    }
    mod.search_query = mod.search_query or ''
    mod.money_reserve_input = mod.money_reserve_input or {
        text = tostring(mod.money_reserve or 0),
    }

    -- Convert bignum-backed values before using them in text inputs and layout.
    local function whole_number(value)
        if type(to_number) == 'function' then value = to_number(value) end
        value = tonumber(value)
        return value and math.floor(value) or nil
    end

    local function initialize_money_reserve()
        if mod.money_reserve == nil and G.GAME then
            mod.money_reserve = math.floor((whole_number(G.GAME.dollars) or 0) * 0.05)
            mod.money_reserve_input.text = tostring(mod.money_reserve)
        end
    end

    G.FUNCS.targeted_rerolls_apply_money_reserve = function()
        local amount = whole_number(mod.money_reserve_input.text)
        if not amount then return end
        mod.money_reserve = math.max(0, amount)
        mod.money_reserve_input.text = tostring(mod.money_reserve)
    end

    mod.shop_button_state = mod.shop_button_state or {
        label = localize('tagr_shop_reroll'),
        colour = G.C.PURPLE,
        button = 'targeted_rerolls_open_modal',
    }

    -- Keep the button label, color, and action synchronized with search state.
    local function refresh_shop_button_state()
        local active = mod.targeted_reroll.is_active()
        mod.shop_button_state.label = active
            and localize('tagr_shop_stop')
            or localize('tagr_shop_reroll')
        mod.shop_button_state.colour = active and G.C.RED or G.C.PURPLE
        mod.shop_button_state.button = active
            and 'targeted_rerolls_stop'
            or 'targeted_rerolls_open_modal'
    end

    G.FUNCS.targeted_rerolls_update_shop_button = function(e)
        refresh_shop_button_state()
        if not e or not e.config then return end
        e.config.button = mod.shop_button_state.button
        e.config.colour = mod.shop_button_state.colour
    end


    G.FUNCS.targeted_rerolls_open_modal = function()
        if mod.targeted_reroll.is_active() then
            G.FUNCS.targeted_rerolls_stop()
            return
        end
        G.FUNCS.open_reroll_modal()
    end

    G.FUNCS.targeted_rerolls_stop = function()
        mod.targeted_reroll.cancel()
        refresh_shop_button_state()
    end

    -- Closing any custom modal must resume Balatro's event queue.
    G.FUNCS.targeted_rerolls_close_modal = mod.close_overlay

    G.FUNCS.targeted_rerolls_start = function()
        mod.targeted_reroll.start()
    end



    local get_die_sprite
    local get_stop_sprite
    G.FUNCS.targeted_rerolls_update_shop_icon = function(e)
        if not e or not e.config then return end

        local active = mod.targeted_reroll.is_active()
        local icon = active and 'stop' or 'die'
        if e.config.targeted_rerolls_icon == icon then return end

        if e.config.object then e.config.object:remove() end
        e.config.object = active and get_stop_sprite() or get_die_sprite()
        e.config.targeted_rerolls_icon = icon
        e.config.object.ui_object_updated = true
    end
    -- Rebuild the modal after a filter change while keeping the game paused.
    local function reopen_reroll_modal()
        G.FUNCS.exit_overlay_menu()
        G.FUNCS.open_reroll_modal()
    end
    mod.on_card_click = function(id)
        mod.card_grid.toggle_selected(id)
    end

    G.FUNCS.targeted_rerolls_update_card_selection = function(e)
        local ref_table = e and e.config and e.config.ref_table
        if not ref_table then return end

        e.config.outline = mod.card_grid.is_selectable(ref_table.entry_id)
            and mod.selected_cards[ref_table.entry_id]
            and 2
            or 0
        e.config.outline_colour = G.C.BLUE
    end


    G.FUNCS.targeted_rerolls_previous_page = function()
        mod.card_grid.change_page(-1)
        reopen_reroll_modal()
    end

    G.FUNCS.targeted_rerolls_next_page = function()
        mod.card_grid.change_page(1)
        reopen_reroll_modal()
    end
    G.FUNCS.targeted_rerolls_apply_search = function()
        mod.search_query = mod.search_input.text or ''
        mod.center_type_filter = nil
        mod.center_type_page = 1
        mod.card_grid.page_number = 1
        mod.show_selected = false
        reopen_reroll_modal()
    end


    G.FUNCS.targeted_rerolls_show_selected = function()
        mod.show_selected = true
        mod.center_type_filter = nil
        mod.card_grid.page_number = 1
        reopen_reroll_modal()
    end

    G.FUNCS.targeted_rerolls_show_all = function()
        mod.show_selected = false
        mod.card_grid.page_number = 1
        reopen_reroll_modal()
    end
    G.FUNCS.targeted_rerolls_select_all_types = function()
        mod.show_selected = false
        mod.center_type_filter = nil
        mod.center_type_page = 1
        mod.card_grid.page_number = 1
        reopen_reroll_modal()
    end


    local function center_type_label(pool)
        if pool == 'Joker' then return 'Jokers' end
        if pool == 'Playing Card' then return 'Cards' end
        return pool
    end

    -- Build the paged category sidebar from the searchable index.
    local function center_type_nodes(category_w, panel_h)
        local types = mod.search_index.center_types()
        local type_height = 0.65
        local arrow_height = 0.55
        local all_height = 0.65
        local clear_height = 0.65
        local selected_height = 0.65
        local visible_types = math.max(
            1,
            math.floor(
                (panel_h - all_height - selected_height - clear_height
                    - arrow_height * 2) / type_height
            )
        )
        local total_pages = math.max(1, math.ceil(#types / visible_types))
        local page = math.max(
            1,
            math.min(mod.center_type_page or 1, total_pages)
        )
        local nodes = {}

        mod.center_type_page = page
        nodes[#nodes + 1] = UIBox_button({
            button = 'targeted_rerolls_select_all_types',
            label = {localize('tagr_see_all')},
            colour = not mod.center_type_filter and not mod.show_selected
                and G.C.BLUE
                or G.C.GREY,
            minw = category_w,
            minh = all_height,
            scale = 0.3,
        })
        nodes[#nodes + 1] = UIBox_button({
            button = mod.show_selected
                and 'targeted_rerolls_show_all'
                or 'targeted_rerolls_show_selected',
            label = {mod.show_selected
                and localize('tagr_back_all_cards')
                or localize('tagr_all_selected')},
            colour = mod.show_selected
                and G.C.GREY
                or G.C.BLUE,
            minw = category_w,
            minh = selected_height,
            scale = 0.3,
        })

        if page > 1 then
            nodes[#nodes + 1] = UIBox_button({
                button = 'targeted_rerolls_previous_center_type_page',
                label = {'^'},
                colour = G.C.GREY,
                minw = category_w,
                minh = arrow_height,
                scale = 0.3,
            })
        end

        local first = (page - 1) * visible_types + 1
        local last = math.min(#types, first + visible_types - 1)
        for index = first, last do
            local pool = types[index]
            nodes[#nodes + 1] = UIBox_button({
                button = 'targeted_rerolls_select_center_type',
                ref_table = {pool = pool},
                label = {center_type_label(pool)},
                colour = pool == mod.center_type_filter and G.C.BLUE or G.C.GREY,
                minw = category_w,
                minh = type_height,
                scale = 0.3,
            })
        end

        if page < total_pages then
            nodes[#nodes + 1] = UIBox_button({
                button = 'targeted_rerolls_next_center_type_page',
                label = {'v'},
                colour = G.C.GREY,
                minw = category_w,
                minh = arrow_height,
                scale = 0.3,
            })
        end

        nodes[#nodes + 1] = UIBox_button({
            button = 'targeted_rerolls_clear_selected',
            label = {localize('tagr_clear')},
            colour = G.C.GREY,
            minw = category_w,
            minh = clear_height,
            scale = 0.3,
        })

        return nodes
    end

    G.FUNCS.targeted_rerolls_select_center_type = function(e)
        local ref_table = e and e.config and e.config.ref_table
        if not ref_table then return end

        mod.center_type_filter = mod.center_type_filter == ref_table.pool
            and nil
            or ref_table.pool
        mod.card_grid.page_number = 1
        reopen_reroll_modal()
    end

    G.FUNCS.targeted_rerolls_previous_center_type_page = function()
        mod.center_type_page = (mod.center_type_page or 1) - 1
        reopen_reroll_modal()
    end

    G.FUNCS.targeted_rerolls_next_center_type_page = function()
        mod.center_type_page = (mod.center_type_page or 1) + 1
        reopen_reroll_modal()
    end


    G.FUNCS.targeted_rerolls_clear_selected = function()
        mod.selected_cards = {}
        mod.save_selected_cards()
        mod.show_selected = false
        mod.card_grid.page_number = 1
        reopen_reroll_modal()
    end

    -- Reuse one layout for the page arrows.
    local function pagination_button(button, label)
        return {
            n = G.UIT.C,
            config = {
                align = 'cm',
                minw = 1.2,
                minh = 0.8,
                padding = 0.1,
                r = 0.1,
                hover = true,
                shadow = true,
                colour = G.C.GREY,
                button = button,
                one_press = true,
            },
            nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        text = label,
                        scale = 0.4,
                        colour = G.C.WHITE,
                        shadow = true,
                    },
                },
            },
        }
    end

    -- Open the full-screen target picker without touching vanilla shop pools.
    G.FUNCS.open_reroll_modal = function()
        G.SETTINGS.paused = true
        initialize_money_reserve()
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
                    outline = 1,
                    outline_color = G.C.WHITE,
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

                                    maxw = content_w * 0.5,
                                },
                                nodes = {
                                    create_text_input({
                                        id = 'targeted_search_input',

                                        ref_table = mod.search_input,
                                        ref_value = 'text',

                                        w = 4,
                                        minh = 1.4,
                                        maxw = 5,
                                        max_length = 32,
                                        text_scale = .8,
                                        extended_corpus = true,
                                        all_caps = false,
                                        prompt_text = localize('tagr_search'),
                                        callback = function()
                                            G.FUNCS.targeted_rerolls_apply_search()
                                        end,
                                        colour = G.C.BLUE,
                                        hooked_colour = darken(G.C.BLUE, 0.5),
                                    }),
                                    {
                                        n = G.UIT.C,
                                        config = {
                                            align = 'cm',
                                            minw = 1,
                                            minh = 1,
                                            padding = 0.1,
                                            r = 0.1,
                                            hover = true,
                                            shadow = true,
                                            colour = G.C.PURPLE,
                                            button = 'targeted_rerolls_apply_search',
                                            one_press = true,
                                        },
                                        nodes = {
                                             {
                                                n = G.UIT.O,
                                                config = {
                                                    object = get_search_sprite(),
                                                    w = 0.5,
                                                    h = 0.5,
                                                },
                                            },
                                        },
                                    },
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
                                        button = 'targeted_rerolls_close_modal',
                                        label = {localize('tagr_close')},
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
                                    align = 't',
                                    padding = 0.05,
                                    minw = category_w,
                                    minh = panel_h,
                                },
                                nodes = center_type_nodes(category_w, panel_h),
                            },
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cm',
                                    minw = panel_w,
                                    minh = panel_h,
                                    colour = G.C.GREY,
                                    emboss = -0.1,
                                    r = .5,
                                },
                                nodes = mod.card_grid.all(),
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
                                    minw = 4.5,
                                },
                                nodes = {
                                    {
                                        n = G.UIT.R,
                                        config = {
                                            align = 'cm',
                                            padding = 0.05,
                                        },
                                        nodes = {
                                            {
                                                n = G.UIT.T,
                                                config = {
                                                    text = localize('tagr_keep_money'),
                                                    scale = 0.35,
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
                                            padding = 0.05,
                                        },
                                        nodes = {
                                            {
                                                n = G.UIT.T,
                                                config = {
                                                    text = '$',
                                                    scale = 0.5,
                                                    colour = G.C.WHITE,
                                                    shadow = true,
                                                },
                                            },
                                            create_text_input({
                                                id = 'targeted_money_reserve_input',
                                                ref_table = mod.money_reserve_input,
                                                ref_value = 'text',
                                                w = 2,
                                                minh = 0.7,
                                                max_length = 6,
                                                text_scale = 0.5,
                                                extended_corpus = false,
                                                all_caps = false,
                                                prompt_text = '0',
                                                callback = function()
                                                    G.FUNCS.targeted_rerolls_apply_money_reserve()
                                                end,
                                                colour = G.C.BLUE,
                                                hooked_colour = darken(G.C.BLUE, 0.5),
                                            }),
                                        },
                                    },
                                },
                            },
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cm',
                                    minw = panel_w * 0.5,
                                },
                                nodes = {
                                    {
                                        n = G.UIT.R,
                                        config = {
                                            align = 'cm',
                                            padding = 0,
                                        },
                                        nodes = {
                                            pagination_button(
                                                'targeted_rerolls_previous_page',
                                                '<'
                                            ),
                                            {
                                                n = G.UIT.C,
                                                config = {
                                                    align = 'cm',
                                                    minw = 1.7,
                                                    minh = 0.8,
                                                },
                                                nodes = {
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = string.format(
                                                                '%d / %d',
                                                                mod.card_grid.page_number or 1,
                                                                mod.card_grid.total_pages or 1
                                                            ),
                                                            scale = 0.4,
                                                            colour = G.C.WHITE,
                                                            shadow = true,
                                                        },
                                                    },
                                                },
                                            },
                                            pagination_button(
                                                'targeted_rerolls_next_page',
                                                '>'
                                            ),
                                        },
                                    },
                                },
                            },
                            {
                                n = G.UIT.C,
                                config = {
                                    align = 'cm',
                                    minw = 2.1,
                                },
                                nodes = {
                                    {
                                        n = G.UIT.C,
                                        config = {
                                            align = 'cm',
                                            minw = 2,
                                            minh = 0.8,
                                            padding = 0.1,
                                            r = 0.1,
                                            hover = true,
                                            shadow = true,
                                            colour = G.C.PURPLE,
                                            button = 'targeted_rerolls_start',
                                            one_press = true,
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
                                                        n = G.UIT.O,
                                                        config = {
                                                            object = get_die_sprite(),
                                                            w = 0.5,
                                                            h = 0.5,
                                                        },
                                                    },
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = localize('tagr_roll'),
                                                            scale = 0.4,
                                                            colour = G.C.WHITE,
                                                            shadow = true,
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                    },
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
    -- Shop controls share one atlas layout and differ only by sprite key.
    local function register_atlas(key)
        SMODS.Atlas({
            key = key,
            path = key..'.png',
            px = 32,
            py = 34,
            force_pixel = true,
        })
    end

    register_atlas('stop_shaded')
    register_atlas('die_shaded')
    register_atlas('search_shaded')

    local function control_sprite(key)
        local sprite = Sprite(
            0,
            0,
            1,
            1.1,
            G.ASSET_ATLAS['targeted_rerolls_'..key],
            {x = 0, y = 0}
        )
        sprite.states.drag.can = false
        return sprite
    end

    get_stop_sprite = function() return control_sprite('stop_shaded') end
    get_die_sprite = function() return control_sprite('die_shaded') end
    get_search_sprite = function() return control_sprite('search_shaded') end

    local reroll_size = {width = 1.4, height = 1.4}


    local function render_die_button()
        local active = mod.targeted_reroll.is_active()
        return {
            n = G.UIT.C,
            config = {
                id = 'targeted_reroll_button',
                align = 'cm',
                minw = reroll_size.width,
                maxw = reroll_size.width,
                minh = reroll_size.height,
                maxh = reroll_size.height,
                padding = 0.1,
                r = 0.15,
                colour = mod.shop_button_state.colour,
                button = mod.shop_button_state.button,
                func = 'targeted_rerolls_update_shop_button',
                hover = true,
                shadow = true,
                one_press = false,
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
                            ref_table = mod.shop_button_state,
                            ref_value = 'label',
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
                            object = active and get_stop_sprite() or get_die_sprite(),
                            targeted_rerolls_icon = active and 'stop' or 'die',
                            func = 'targeted_rerolls_update_shop_icon',
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
                            h = reroll_size.height,
                        },
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