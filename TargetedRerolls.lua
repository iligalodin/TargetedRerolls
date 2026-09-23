if _G.TargetedRerolls then return end

local mod = {}
_G.TargetedRerolls = mod

-- Modules receive the same table so public hooks stay available to other mods.
local function load_module(path)
    assert(SMODS.load_file(path))()(mod)
end

load_module('src/common.lua')
load_module('src/blacklist.lua')
load_module('src/search_index.lua')
load_module('src/shop_targets.lua')
load_module('src/targeted_reroll.lua')
load_module('src/card_grid.lua')
load_module('src/ui.lua')
load_module('src/debug.lua')
load_module('src/shop_hooks.lua')
