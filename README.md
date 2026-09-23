# Targeted Rerolls

Targeted Rerolls lets you choose cards to look for in the shop. It keeps using Balatro's normal reroll action until one of those cards appears, you press **STOP**, or the next paid reroll would break your money reserve.

## Install

Install [Steamodded](https://github.com/Steamodded/smods) and Lovely, then place this folder in Balatro's `Mods` directory.

## Use

1. Enter a shop and click **TARGETED REROLL** beside the normal reroll button.
2. Search by name or key, or choose a category in the left sidebar.
3. Click cards to select them. A blue outline marks a selected card. Grey cards cannot be selected.
4. Set **KEEP MONEY** to the minimum dollar amount you want to retain.
5. Click **ROLL**.

The target picker closes and the mod performs normal shop rerolls. It stops when any selected card appears. During the search, the shop button becomes **STOP**. STOP remains usable while a reroll animation is running.

Selections are saved in the mod configuration. Use **CLEAR** in the target picker to remove them.

## Rules

- The mod does not spawn cards or rewrite vanilla card pools.
- Every roll calls Balatro's normal `reroll_shop()` function. Normal reroll costs, free rerolls, vouchers, tags, and other mod effects still apply.
- A paid reroll is never started if it would reduce your money below **KEEP MONEY**.
- If a selected target is already in the shop, the picker closes without rolling.
- The target list only shows cards that are visible and selectable in the catalog. Actual shop availability still follows Balatro and other installed mods.
- The default reserve is 5% of your current money the first time the picker opens. You can set it to any whole-dollar value, including `0`.

## Debug menu

Open Targeted Rerolls in Steamodded's mod settings and choose **OPEN DEBUG MENU** while a run is active.

The menu can set money to `$9,000,000` and reset the current reroll cost to `$1`. It is intended for testing, not normal play.

## For mod authors

Targeted Rerolls exposes a blacklist API for hiding cards from its target picker. See [blacklist.md](blacklist.md).
