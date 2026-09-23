return function(mod)
    local card_grid = {}
    mod.selected_cards = mod.selected_cards or {}

    local entry_id = mod.entry_id


    -- Restore persisted choices only after the search index is available.
    local function load_saved_selection()
        if mod.selection_loaded then return end
        mod.selection_loaded = true

        local config = SMODS and SMODS.current_mod and SMODS.current_mod.config
        for _, target in ipairs(config and config.targets or {}) do
            if type(target) == 'table' and target.type and target.key then
                for _, entry in ipairs(mod.search_index.all()) do
                    if entry.key == target.key
                        and (target.type == 'Playing Card'
                            or entry.set == target.type)
                    then
                        mod.selected_cards[entry_id(entry)] = true
                        break
                    end
                end
            end
        end
    end


    -- Persist selections as type/key pairs so mod configuration stays portable.
    function mod.save_selected_cards()
        local current_mod = SMODS and SMODS.current_mod
        if not current_mod then return end

        local targets = {}
        for _, entry in ipairs(mod.search_index.all()) do
            if mod.selected_cards[entry_id(entry)] then
                targets[#targets + 1] = {
                    type = entry.kind == 'playing_card' and 'Playing Card'
                        or entry.set,
                    key = entry.key,
                }
            end
        end
        current_mod.config = current_mod.config or {}
        current_mod.config.targets = targets
        if SMODS.save_mod_config then SMODS.save_mod_config(current_mod) end
    end




    -- Mark previews as overlay cards so joker setup cannot touch run state.
    local function create_preview_card(x, y, w, h, card, center, params)
        local previous_overlay = G.OVERLAY_MENU
        G.OVERLAY_MENU = true
        local ok, preview = pcall(function()
            return Card(x, y, w, h, card, center, params)
        end)
        G.OVERLAY_MENU = previous_overlay
        if not ok then error(preview) end
        return preview
    end


    -- Each preview card is the real click target; layout padding is not.
    local function card_node(entry)
        assert(entry, 'Card entry is missing')

        local base_center = assert(G.P_CENTERS.c_base, 'Base card center is not registered')
        local card_w = G.CARD_W * 0.8
        local card_h = G.CARD_H * 0.8
        local front = entry.kind == 'playing_card' and entry.front or {}
        local center = entry.kind == 'playing_card'
            and base_center
            or assert(entry.center, 'Center is not registered: '..entry.key)
        local id = entry_id(entry)
        local card = create_preview_card(
            0,
            0,
            card_w,
            card_h,
            front,
            center,
            {
                bypass_discovery_center = true,
                bypass_discovery_ui = true,
            }
        )
        -- Keep every grid slot the same size for special centers.
        card.T.w = card_w
        card.T.h = card_h
        if card.VT then
            card.VT.w = card_w
            card.VT.h = card_h
        end
        if card.original_T then
            card.original_T.w = card_w
            card.original_T.h = card_h
        end
        for _, child in pairs(card.children or {}) do
            if child.T then
                child.T.w = card_w
                child.T.h = card_h
            end
        end

        local selectable = mod.shop_targets.is_selectable(entry)

        -- The preview Card owns its own click target, so the visible card
        -- face, not the surrounding layout padding—toggles selection.
        card.no_ui = false
        card.greyed = not selectable
        card.states.hover.can = true
        card.states.collide.can = true
        card.states.click.can = selectable
        card.states.drag.can = false
        card.click = function()
            if selectable and mod.on_card_click then
                mod.on_card_click(id)
            end
        end
        card:start_materialize()

        local selected = selectable and mod.selected_cards[id] == true

        return {
            n = G.UIT.C,
            config = {
                align = 'cm',
                minw = card.T.w,
                padding = 0.05,
                r = 0.05,
                hover = true,
                one_press = false,
                ref_table = {entry_id = id},
                func = 'targeted_rerolls_update_card_selection',
                outline = selected and 2 or 0,
                outline_colour = G.C.BLUE,
            },
            nodes = {
                {
                    n = G.UIT.O,
                    config = {
                        object = card,
                        w = card.T.w,
                        h = card.T.h,
                        hover = true,
                    },
                },
            },
        }
    end

    local function add_row(rows)
        local row = {
            n = G.UIT.R,
            config = {
                align = 'cm',
                padding = 0.05,
            },
            nodes = {},
        }
        rows[#rows + 1] = row
        return row
    end
    local function empty_state_row(text)
        return {
            n = G.UIT.R,
            config = {
                align = 'cm',
                minh = G.CARD_H * 0.8,
                padding = 0.2,
            },
            nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        text = text,
                        scale = 0.5,
                        colour = G.C.WHITE,
                        shadow = true,
                    },
                },
            },
        }
    end


    -- Render one filtered page and keep pagination state in the grid module.
    function card_grid.page(query, pool, page, columns, rows_per_page)
        columns = columns or 8
        rows_per_page = rows_per_page or 3
        local entries = mod.search_index.search(query or '', pool)
        if mod.show_selected then
            local selected_entries = {}
            for _, entry in ipairs(entries) do
                if mod.selected_cards[entry_id(entry)] then
                    selected_entries[#selected_entries + 1] = entry
                end
            end
            entries = selected_entries
        end
        if mod.show_selected and #entries == 0 then
            card_grid.page_number = 1
            card_grid.total_pages = 1
            return {empty_state_row(localize('tagr_no_cards_selected'))}
        end
        local page_size = columns * rows_per_page
        local total_pages = math.max(1, math.ceil(#entries / page_size))
        page = math.max(1, math.min(page or 1, total_pages))
        local rows = {}
        local first = (page - 1) * page_size + 1
        local last = math.min(#entries, first + page_size - 1)

        card_grid.page_number = page
        card_grid.total_pages = total_pages

        for index = first, last do
            local row_index = math.floor((index - first) / columns) + 1
            local row = rows[row_index] or add_row(rows)

            row.nodes[#row.nodes + 1] = {
                n = G.UIT.C,
                config = {
                    align = 'cm',
                    minw = G.CARD_W * 0.8,
                    minh = G.CARD_H * 0.8,
                    padding = 0.025,
                },
                nodes = {
                    card_node(entries[index]),
                },
            }
        end

        return rows
    end

    -- The modal always renders from the current search and category filters.
    function card_grid.all()
        load_saved_selection()
        local query = mod.show_selected and '' or (mod.search_query or '')
        local pool = mod.show_selected and nil or mod.center_type_filter
        return card_grid.page(
            query,
            pool,
            card_grid.page_number or 1,
            8,
            3
        )
    end

    -- Locked or hidden entries cannot be toggled, including saved selections.
    function card_grid.is_selectable(id)
        load_saved_selection()
        for _, entry in ipairs(mod.search_index.all()) do
            if entry_id(entry) == id then
                return mod.shop_targets.is_selectable(entry)
            end
        end
        return false
    end

    function card_grid.toggle_selected(id)
        if not card_grid.is_selectable(id) then return false end
        mod.selected_cards[id] = not mod.selected_cards[id]
        mod.save_selected_cards()
        return true
    end

    function card_grid.change_page(delta)
        local total_pages = card_grid.total_pages or 1
        local page = card_grid.page_number or 1
        card_grid.page_number = ((page - 1 + delta) % total_pages) + 1
    end


    mod.card_grid = card_grid
end