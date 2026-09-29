-- Run from the project root: lua tests/collection_visibility.lua
local enabled = true
local apple = {
    key = 'j_bof_apple', name = 'Apple', set = 'Joker',
    no_collection = function() return not enabled end,
}
local fish = {
    key = 'c_bof_bass_s', name = 'Small Bass', set = 'Fish', consumeable = true,
    no_collection = function() return not enabled end,
}
G = {P_CENTERS = {
    j_bof_apple = apple,
    c_bof_bass_s = fish,
    j_plain = {key = 'j_plain', name = 'Plain', set = 'Joker'},
    j_hidden = {key = 'j_hidden', set = 'Joker', no_collection = true},
    j_disabled = {key = 'j_disabled', set = 'Joker', no_collection = function() return true end},
}}
local mod = {}
dofile('src/search_index.lua')(mod)
dofile('src/shop_targets.lua')(mod)

local function only(query)
    local entries = mod.search_index.search(query)
    assert(#entries == 1, query .. ': expected one visible result, got ' .. #entries)
    return entries[1]
end

local apple_entry = only('j_bof_apple')
local fish_entry = only('c_bof_bass_s')
assert(mod.shop_targets.is_selectable(apple_entry), 'Enabled bundle Joker must be selectable')
assert(mod.shop_targets.is_selectable(fish_entry), 'Enabled bundle consumable must be selectable')
assert(mod.shop_targets.is_selectable(only('j_plain')), 'Ordinary Joker must remain selectable')
assert(#mod.search_index.search('j_hidden') == 0, 'Boolean hidden flag must be respected')
assert(#mod.search_index.search('j_disabled') == 0, 'Callback returning true must hide the card')

-- A cached entry must stop being selectable when its bundle is disabled.
enabled = false
assert(not mod.shop_targets.is_selectable(apple_entry), 'Disabled bundle must not remain selectable')
assert(not mod.shop_targets.is_selectable(fish_entry), 'Disabled consumable must not remain selectable')
mod.search_index.refresh()
assert(#mod.search_index.search('j_bof_apple') == 0, 'Disabled bundle must disappear after refresh')
assert(#mod.search_index.search('c_bof_bass_s') == 0, 'Disabled consumable must disappear after refresh')
enabled = true
mod.search_index.refresh()
apple_entry = only('j_bof_apple')
fish_entry = only('c_bof_bass_s')

-- Visibility must not bypass actual shop eligibility (Fish normally has rate 0).
mod.snapshot_joker_drawer = function()
    return {centers = {j_bof_apple = true}, card_fronts = {}}
end
assert(mod.shop_targets.refresh_availability())
assert(mod.shop_targets.is_selectable(apple_entry), 'Eligible bundle Joker must be selectable')
assert(not mod.shop_targets.is_selectable(fish_entry), 'Non-shop consumable must remain unselectable')
print('PASS: dynamic collection visibility, bundle toggles, boolean flags, and shop eligibility')
