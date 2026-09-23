return function(mod)
    -- Use one stable key format everywhere selections identify indexed entries.
    function mod.entry_id(entry)
        return entry.kind..':'..entry.key
    end

    -- Overlay menus pause Balatro. Always resume the game when closing one.
    function mod.close_overlay()
        if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
        G.SETTINGS.paused = false
    end
end
