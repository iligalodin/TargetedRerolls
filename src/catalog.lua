return function(mod)
    local state = mod.state
    local catalog = state.catalog
    local search = state.search
    local utils = mod.utils
    local targets = mod.targets

    local function save_selected_targets()
        local current_mod = state.current_mod
        if not current_mod then return end

        current_mod.config = current_mod.config or {}
        local saved = {}
        for _, id in ipairs(state.selected_target_order) do
            local target = state.selected_targets[id]
            if target then
                saved[#saved + 1] = {type = target.type, key = target.key}
            end
        end
        current_mod.config.targets = saved
        if SMODS.save_mod_config then SMODS.save_mod_config(current_mod) end
    end

    local function selected_count()
        return #state.selected_target_order
    end

    local function toggle_target(state_entry)
        local id = utils.target_id(state_entry.type, state_entry.key)
        if state.selected_targets[id] then
            state.selected_targets[id] = nil
            for index, selected_id in ipairs(state.selected_target_order) do
                if selected_id == id then
                    table.remove(state.selected_target_order, index)
                    break
                end
            end
            state_entry.selected = false
        else
            state.selected_targets[id] = {type = state_entry.type, key = state_entry.key}
            state.selected_target_order[#state.selected_target_order + 1] = id
            state_entry.selected = true
        end

        state_entry.text = state_entry.selected and 'SELECTED' or 'SELECT'
        catalog.start_state.text = 'REROLL ('..tostring(selected_count())..')'
        save_selected_targets()
    end

    G.FUNCS.can_toggle_targeted_card = function(e)
        local state_entry = e and e.config and e.config.ref_table
        if not state_entry or not state_entry.possible then
            utils.disable_button(e)
            return
        end
        utils.enable_button(e, state_entry.selected and G.C.BLUE or G.C.GREEN, 'toggle_targeted_card')
    end

    G.FUNCS.toggle_targeted_card = function(e)
        if search.active then return end
        local state_entry = e and e.config and e.config.ref_table
        if not state_entry or not state_entry.possible then return end
        toggle_target(state_entry)
    end

    G.FUNCS.targeted_rerolls_set_card_type = function(e)
        local option = e and e.cycle_config and e.cycle_config.current_option or 1
        catalog.card_type = mod.card_types[option] or mod.card_types[1]
        G.FUNCS.close_targeted_reroll_catalog()
        G.FUNCS.open_targeted_reroll_catalog()
    end

    G.FUNCS.clear_targeted_reroll_targets = function()
        state.selected_targets = {}
        state.selected_target_order = {}
        catalog.start_state.text = 'REROLL (0)'
        save_selected_targets()
        G.FUNCS.close_targeted_reroll_catalog()
        G.FUNCS.open_targeted_reroll_catalog()
    end

    local function shop_button(id, button, func, colour, lines, height, ref_table, ref_value)
        local text_nodes = {}
        for _, line in ipairs(lines) do
            local text_config = {scale = 0.30, colour = G.C.WHITE, shadow = true}
            if ref_table and ref_value then
                text_config.ref_table = ref_table
                text_config.ref_value = ref_value
            else
                text_config.text = line
            end
            text_nodes[#text_nodes + 1] = {
                n = G.UIT.R,
                config = {align = 'cm', padding = 0, minw = 2.8, maxw = 2.6, minh = height or 1.35},
                nodes = {{n = G.UIT.T, config = text_config}},
            }
        end

        return {
            n = G.UIT.R,
            config = {
                id = id,
                minw = 2.8,
                minh = height or 1.35,
                maxh = height or 1.35,
                no_overflow = 'v',
                r = 0.15,
                colour = colour,
                button = button,
                func = func,
                hover = true,
                shadow = true,
            },
            nodes = text_nodes,
        }
    end

    local function add_targeted_button(node)
        if type(node) ~= 'table' or type(node.nodes) ~= 'table' then return false end
        for index, child in ipairs(node.nodes) do
            if child.config and child.config.button == 'reroll_shop' then
                child.config.minh = 0.8
                child.config.maxh = 0.8
                table.insert(node.nodes, index + 1, shop_button(
                    'targeted_reroll_button',
                    'open_targeted_reroll_catalog',
                    'can_open_targeted_reroll_catalog',
                    G.C.PURPLE,
                    {'Targeted Reroll'},
                    0.8,
                    search,
                    'button_label'
                ))
                return true
            end
            if add_targeted_button(child) then return true end
        end
        return false
    end

    local function collection_contents(collection)
        return collection.nodes
            and collection.nodes[1]
            and collection.nodes[1].nodes
            and collection.nodes[1].nodes[1]
            and collection.nodes[1].nodes[1].nodes
            and collection.nodes[1].nodes[1].nodes[1]
            and collection.nodes[1].nodes[1].nodes[1].nodes
    end

    local function isolate_collection_page_callback(node)
        if type(node) ~= 'table' then return end

        local config = node.config
        local ref_table = config and config.ref_table
        if ref_table and ref_table.opt_callback == 'SMODS_card_collection_page' then
            ref_table.opt_callback = 'targeted_reroll_collection_page'
        end
        if config and config.opt_callback == 'SMODS_card_collection_page' then
            config.opt_callback = 'targeted_reroll_collection_page'
        end

        for _, child in ipairs(node.nodes or {}) do
            isolate_collection_page_callback(child)
        end
    end
    local function remove_collection_back(collection)
        local outer = collection.nodes and collection.nodes[1]
        local panel = outer and outer.nodes and outer.nodes[1]
        local panel_nodes = panel and panel.nodes
        local back_button = panel_nodes and panel_nodes[2]
        if back_button and back_button.config and back_button.config.id == 'overlay_menu_back_button' then
            table.remove(panel_nodes, 2)
        end
    end
    local function add_cycle_shadows(node)
        if type(node) ~= 'table' then return end

        local config = node.config
        if config and (config.ref_value == 'l' or config.ref_value == 'r') then
            config.shadow = true
        end
        for _, child in ipairs(node.nodes or {}) do
            add_cycle_shadows(child)
        end
    end




    local function add_catalog_controls(contents)
        local current_type_index = 1
        for index, card_type in ipairs(mod.card_types) do
            if card_type == catalog.card_type then current_type_index = index end
        end

        local type_cycle = create_option_cycle({
            options = mod.card_type_labels,
            current_option = current_type_index,
            w = 4.5,
            cycle_shoulders = true,
            opt_callback = 'targeted_rerolls_set_card_type',
            colour = G.C.RED,
            no_pips = true,
        })
        add_cycle_shadows(type_cycle)
        table.insert(contents, 1, {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = {
            type_cycle,
        }})

        table.insert(contents, #contents + 1, {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = {
            UIBox_button({
                button = 'close_targeted_reroll_catalog',
                label = {'BACK'},
                colour = G.C.ORANGE,
                minw = 1.7,
                scale = 0.32,
                col = true,
            }),
            {n = G.UIT.C, config = {align = 'cm', padding = 0.03}, nodes = {
                {n = G.UIT.T, config = {text = 'KEEP', scale = 0.32, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                mod.numeric_text_input({
                    id = 'targeted_rerolls_reserve_input',
                    w = 1.8,
                    h = 0.7,
                    max_length = 8,
                    ref_table = catalog,
                    ref_value = 'reserve_text',
                    prompt_text = '$',
                    callback = function() utils.parse_whole_number(catalog.reserve_text) end,
                }),
            }},
            UIBox_button({
                button = 'start_targeted_reroll_search',
                func = 'can_start_targeted_reroll_search',
                dynamic_label = catalog.start_state,
                label = {},
                minw = 2.3,
                minh = 0.8,
                scale = 0.32,
                col = true,
            }),
            UIBox_button({
                button = 'clear_targeted_reroll_targets',
                label = {'CLEAR'},
                colour = G.C.GREY,
                minw = 1.7,
                minh = 0.8,
                scale = 0.32,
                col = true,
            }),
        }})
    end

    local function build_collection(pool)
        local previous_active_mod_ui = G.ACTIVE_MOD_UI
        G.ACTIVE_MOD_UI = nil
        local previous_overlay_menu = G.OVERLAY_MENU
        G.OVERLAY_MENU = true
        local previous_collection_page = G.FUNCS.SMODS_card_collection_page
        local collection = SMODS.card_collection_UIBox(pool, {5, 5}, {
            no_back = true,
            modify_card = function(card, center)
                local meta = catalog.entry_meta[center]
                if meta.type == 'Playing Card' then
                    card.playing_card = true
                    card:set_base(center.targeted_front, true)
                end

                local id = utils.target_id(meta.type, meta.key)
                local card_state = {
                    type = meta.type,
                    key = meta.key,
                    possible = meta.possible,
                    selected = state.selected_targets[id] ~= nil,
                    text = meta.possible and (state.selected_targets[id] and 'SELECTED' or 'SELECT') or 'UNAVAILABLE',
                }
                catalog.button_states[id] = card_state
                card.children.targeted_select_button = UIBox {
                    definition = {
                        n = G.UIT.ROOT,
                        config = {
                            id = 'targeted_select_'..center.key,
                            minw = 1.2,
                            maxw = 1.4,
                            minh = 0.62,
                            padding = 0.08,
                            align = 'cm',
                            colour = card_state.possible and (card_state.selected and G.C.BLUE or G.C.GREEN) or G.C.GREY,
                            shadow = true,
                            r = 0.08,
                            button = 'toggle_targeted_card',
                            func = 'can_toggle_targeted_card',
                            ref_table = card_state,
                            hover = true,
                        },
                        nodes = {{n = G.UIT.T, config = {ref_table = card_state, ref_value = 'text', scale = 0.34, colour = G.C.WHITE, shadow = true}}},
                    },
                    config = {
                        align = 'bm',
                        offset = {x = 0, y = -0.3},
                        major = card,
                        bond = 'Weak',
                        parent = card,
                    },
                }
            end,
        })

        local targeted_collection_page = G.FUNCS.SMODS_card_collection_page
        if targeted_collection_page then
            G.FUNCS.targeted_reroll_collection_page = targeted_collection_page
        end
        G.FUNCS.SMODS_card_collection_page = previous_collection_page
        isolate_collection_page_callback(collection)
        remove_collection_back(collection)
        add_cycle_shadows(collection)

        G.OVERLAY_MENU = previous_overlay_menu
        G.ACTIVE_MOD_UI = previous_active_mod_ui
        return collection
    end

    G.FUNCS.close_targeted_reroll_catalog = function()
        if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
        G.SETTINGS.paused = false
    end

    G.FUNCS.open_targeted_reroll_catalog = function()
        if G.OVERLAY_MENU then G.FUNCS.close_targeted_reroll_catalog() end
        if not utils.shop_is_open() or search.active then return end
        if G.CONTROLLER and G.CONTROLLER.locks and G.CONTROLLER.locks.shop_reroll then return end

        local pool = targets.available(catalog.card_type)
        if #pool == 0 then return end
        if not catalog.initialized then
            catalog.reserve_text = tostring(math.ceil(math.max(0, utils.money()) * 0.05))
            catalog.initialized = true
        end

        catalog.start_state.text = 'REROLL ('..tostring(selected_count())..')'
        catalog.button_states = {}
        G.SETTINGS.paused = true

        local collection = build_collection(pool)
        local contents = collection_contents(collection)
        if not contents then return end
        add_catalog_controls(contents)

        G.FUNCS.overlay_menu {
            definition = collection,
            config = {offset = {x = 0, y = 10}},
        }
    end

    G.FUNCS.can_open_targeted_reroll_catalog = function(e)
        if search.active then
            utils.enable_button(e, G.C.RED, 'stop_targeted_reroll')
            return
        end

        local cost = utils.current_cost()
        if utils.shop_is_open()
            and not (G.CONTROLLER and G.CONTROLLER.locks and G.CONTROLLER.locks.shop_reroll)
            and (cost == 0 or utils.can_pay(cost)) then
            utils.enable_button(e, G.C.PURPLE, 'open_targeted_reroll_catalog')
            return
        end
        utils.disable_button(e)
    end

    mod.add_targeted_button = add_targeted_button
end
