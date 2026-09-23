# Targeted Rerolls blacklist API

Use this API when another mod should hide a card or a whole center type from the Targeted Rerolls picker.

The blacklist affects only Targeted Rerolls' catalog, search, categories, and selected-target lookup. It does **not** remove a card from Balatro's normal pools, packs, or other mods.

## Requirement

Call the API after Targeted Rerolls has loaded. Add it as a Steamodded dependency when possible:

```json
{
  "dependencies": ["TargetedRerolls (>=26.09.5)"]
}
```

The public table is `_G.TargetedRerolls`.

## Block one card

Pass a registered center key or the center object itself:

```lua
local blacklist = TargetedRerolls.blacklist

blacklist.add('c_fool')
blacklist.add(G.P_CENTERS.c_fool)
```

`add` returns `true` when it added a new entry and `false` when the entry was already blocked or invalid.

Remove a key later:

```lua
TargetedRerolls.blacklist.remove('c_fool')
```

## Block a complete center type

Pass a `center.set` name, such as a custom consumable type:

```lua
TargetedRerolls.blacklist.add_type('FakeCenter')
TargetedRerolls.blacklist.remove_type('FakeCenter')
```

You may also pass a center object. The type is resolved as:

```lua
center.set or center.object_type or 'Center'
```

Matching is case-sensitive.

## Query the current blacklist

```lua
local blacklist = TargetedRerolls.blacklist

blacklist.contains('c_fool')
blacklist.contains(G.P_CENTERS.c_fool)
blacklist.type_contains('FakeCenter')

local keys = blacklist.all()
local types = blacklist.all_types()
```

`contains(center)` checks both the center's key and its type. `all()` and `all_types()` return sorted arrays.

## Clear runtime entries

```lua
TargetedRerolls.blacklist.clear()
```

This clears key and type entries that are currently active and refreshes the Targeted Rerolls index.

## Built-in configuration

For a permanent local exclusion, edit `src/blacklist.lua` in Targeted Rerolls:

```lua
local configured_keys = {
    'c_fool',
}

local configured_types = {
    'FakeCenter',
}
```

Those entries are applied again whenever Targeted Rerolls loads.
