return function(mod)
    local function shop_button()
        if not mod.targeted_reroll.is_active() or not G.shop then return nil end
        return G.shop:get_UIE_by_ID('targeted_reroll_button')
    end

    local function button_hit(controller, x, y)
        local button = shop_button()
        if not button then return nil end
        if controller.hovering and controller.hovering.target == button then
            return button
        end
        if not x or not y then return nil end

        local point = {
            x = x / (G.TILESCALE * G.TILESIZE),
            y = y / (G.TILESCALE * G.TILESIZE),
        }
        return button:collides_with_point(point) and button or nil
    end

    -- Other mods can replace Controller.queue_L_cursor_press after this mod
    -- loads. Install this exact upstream interception when a search starts,
    -- immediately before the shop reroll lock begins.
    function mod.ensure_stop_input_hook()
        local current = Controller and Controller.queue_L_cursor_press
        if not current or current == mod.stop_input_hook then return end

        mod.stop_input_hook = function(self, x, y)
            if button_hit(self, x, y) then
                G.FUNCS.targeted_rerolls_stop()
                self.L_cursor_queue = nil
                self.is_cursor_down = false
                return
            end
            return current(self, x, y)
        end
        Controller.queue_L_cursor_press = mod.stop_input_hook

        if sendInfoMessage then
            sendInfoMessage('STOP cursor interception installed', 'TargetedRerolls')
        end
    end

    mod.ensure_stop_input_hook()
end
