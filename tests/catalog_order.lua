-- Run from the project root: lua tests/catalog_order.lua
local bof = {id = 'bof', name = 'Bundles of Fun'}
local alpha = {id = 'alpha', display_name = 'Alpha Mod'}
SMODS = {Rarity = {obj_buffer = {'Common', 'Uncommon', 'Rare', 'Legendary', 'my_epic'}}}
G = {
    P_CENTERS = {},
    P_CARDS = {S_A = {name = 'Ace of Spades'}, H_2 = {name = '2 of Hearts'}},
    localization = {descriptions = {Joker = {
        j_localized = {name = 'Aardvark'},
    }}},
}
local function card(key, name, rarity, fields)
    local center = fields or {}
    center.key, center.name, center.rarity = key, name, rarity
    center.set = center.set or 'Joker'
    G.P_CENTERS[key] = center
end
card('j_zulu', 'Zulu', 1)
card('j_alpha', 'alpha', 'Common')
card('j_localized', 'Internal ZZZ', 1)
card('j_rare', 'A Rare', 3)
card('j_owned', 'Taken Over', 2, {mod = bof, taken_ownership = true})
card('j_mod', 'Zed', 4, {mod = alpha})
card('j_apple', 'Apple', 1, {mod = bof, bundle = 'appetizers'})
card('j_shrimp', 'Shrimp', 1, {mod = bof, bundle = {'appetizers', {'minnows'}}})
card('j_food_rare', 'A Rare Food', 3, {mod = bof, bundle = 'appetizers'})
card('j_fable', 'Beltrame', 4, {mod = bof, bundle = 'fables'})
card('j_jester', 'Zed Jester', 1, {mod = bof, bundle = 'jesters'})
card('j_epic', 'A Jester', 'my_epic', {mod = bof, bundle = 'jesters'})
card('j_unknown', 'A Unknown', 'unknown', {mod = bof, bundle = 'jesters'})
card('j_original', 'Original Owner', 1, {original_mod = bof, mod = alpha, taken_ownership = true})
card('c_fish', 'Fish', nil, {set = 'Fish', consumeable = true, mod = bof, bundle = 'minnows'})
card('c_planet', 'Planet', nil, {set = 'Planet', consumeable = true})
card('c_spectral', 'Spectral', nil, {set = 'Spectral', consumeable = true})
card('c_tarot', 'Tarot', nil, {set = 'Tarot', consumeable = true})
card('v_hidden', 'Voucher', nil, {set = 'Voucher'})
local mod = {}
dofile('src/search_index.lua')(mod)
local function keys(entries)
    local out = {}
    for _, entry in ipairs(entries) do out[#out + 1] = entry.key end
    return table.concat(out, ',')
end
local expected_jokers = table.concat({
    'j_localized', 'j_alpha', 'j_zulu', 'j_owned', 'j_rare',
    'j_mod', 'j_apple', 'j_shrimp', 'j_food_rare', 'j_original',
    'j_fable', 'j_jester', 'j_epic', 'j_unknown',
}, ',')
assert(keys(mod.search_index.search('', 'Joker')) == expected_jokers,
    'Jokers must sort by base game, bundle/mod, rarity, then displayed name')
local expected_all = expected_jokers .. ',c_fish,c_planet,c_spectral,c_tarot,H_2,S_A'
assert(keys(mod.search_index.search('')) == expected_all,
    'See All must put Jokers before alphabetical consumable types and other types')
assert(table.concat(mod.search_index.center_types(), ',') == 'Joker,Fish,Planet,Spectral,Tarot,Playing Card',
    'Sidebar must match See All type ordering')
assert(keys(mod.search_index.search('rare', 'Joker')) == 'j_rare,j_food_rare',
    'Filtering must preserve origin precedence over name and rarity')

-- Equal display names must remain stable across registry rebuilds.
card('j_tie_b', 'Tie', 1)
card('j_tie_a', 'Tie', 1)
mod.search_index.refresh()
assert(keys(mod.search_index.search('tie', 'Joker')) == 'j_tie_a,j_tie_b',
    'Equal names must use stable keys as a tie-breaker')
print('PASS: origin/bundle and rarity precedence, ownership, localized names, type order, and stable ties')
