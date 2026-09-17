if _G.TargetedRerolls then return end

local mod = {}
_G.TargetedRerolls = mod

local function load_module(path)
    assert(SMODS.load_file(path))()(mod)
end

load_module('src/state.lua')
load_module('src/utils.lua')
load_module('src/targets.lua')
load_module('src/search.lua')
load_module('src/input.lua')
load_module('src/catalog.lua')
load_module('src/debug.lua')
load_module('src/hooks.lua')
