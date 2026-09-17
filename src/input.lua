return function(mod)
    local state = mod.state
    local search = state.search

    function mod.numeric_text_input(args)
        args = args or {}
        args._targeted_numeric_input = true
        return create_text_input(args)
    end

    local vanilla_text_input_key = G.FUNCS.text_input_key
    if vanilla_text_input_key then
        G.FUNCS.text_input_key = function(args)
            local hook = G.CONTROLLER and G.CONTROLLER.text_input_hook
            local input = hook and hook.config and hook.config.ref_table
            if not (input and input._targeted_numeric_input and args and args.key == '0') then
                return vanilla_text_input_key(args)
            end

            local text = input.text
            TRANSPOSE_TEXT_INPUT(0)
            if input.max_length > string.len(text.ref_table[text.ref_value]) then
                MODIFY_TEXT_INPUT{
                    letter = '0',
                    text_table = text,
                    pos = text.current_position + 1,
                }
                TRANSPOSE_TEXT_INPUT(1)
            end
        end
    end

    local function shop_button()
        if not search.active or not G.shop then return nil end
        return G.shop:get_UIE_by_ID('targeted_reroll_button')
    end

    local function button_hit(controller, x, y)
        local button = shop_button()
        if not button then return nil end
        if controller.hovering and controller.hovering.target == button then return button end
        if not x or not y then return nil end

        local point = {
            x = x / (G.TILESCALE * G.TILESIZE),
            y = y / (G.TILESCALE * G.TILESIZE),
        }
        return button:collides_with_point(point) and button or nil
    end

    local original_queue_L_cursor_press = Controller and Controller.queue_L_cursor_press
    if original_queue_L_cursor_press then
        Controller.queue_L_cursor_press = function(self, x, y)
            if button_hit(self, x, y) then
                G.FUNCS.stop_targeted_reroll()
                self.L_cursor_queue = nil
                self.is_cursor_down = false
                return
            end
            return original_queue_L_cursor_press(self, x, y)
        end
    end
end
