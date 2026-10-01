# Targeted Rerolls

Targeted Rerolls lets you choose cards to look for in the shop. It keeps using Balatro's normal reroll action until one of those cards appears, you press **STOP**, or the next paid reroll would break your money reserve.

## Install

Install [Steamodded](https://github.com/Steamodded/smods) and Lovely, then place this folder in Balatro's `Mods` directory. Include `lovely.toml` and restart Balatro after installing or updating the mod so Lovely can apply the reroll-speed patch.

## Use

1. Enter a shop and click **TARGETED REROLL** beside the normal reroll button.
2. Search by displayed name, internal name, or key, or choose a category in the left sidebar.
3. Click cards to select them. A blue outline marks a selected card. Grey cards cannot be selected.
4. Set **KEEP MONEY** to the minimum dollar amount you want to retain.
5. Click **ROLL**.

The target picker closes and the mod performs normal shop rerolls. It stops when any selected card appears. During the search, the shop button becomes **STOP**. STOP remains usable while a reroll animation is running.

During each automatic search, flames begin small at the 10th reroll and grow to full strength at 30 rerolls. They rise behind the whole shop reroll and FIND/STOP buttons, using each button's current colour (green for reroll, red for STOP); text and icons remain unobscured. The picker ROLL button has no flames. Ending a search extinguishes the flames and resets the counter.

Selections are saved in the mod configuration. Use **CLEAR** in the target picker to remove them.

**See all** and the category sidebar list Jokers first, then consumable types alphabetically, then other card types alphabetically. Within each type, base-game cards come first, followed by bundles alphabetically (or mod names for mods without bundles). Each group sorts by rarity, then displayed card name. Standard rarities run Common → Uncommon → Rare → Legendary; custom rarities follow Steamodded's registration order. Taking ownership of a base-game card does not move it into a mod group.

## Rules

- The mod does not spawn cards or rewrite vanilla card pools.
- Every roll calls Balatro's normal `reroll_shop()` function. Normal reroll costs, free rerolls, vouchers, tags, and other mod effects still apply.
- Automatic searches ramp from your configured game speed to 10 times that speed over 15 unpaused seconds. Pausing freezes the ramp; STOP, finding a target, reaching the reserve, or leaving the shop resets it. Your saved game-speed setting is never changed. This uses Balatro's normal speed factor, like [Saturn's extended game-speed options](https://github.com/OceanRamen/Saturn), without requiring Saturn or skipping reroll effects.
- A paid reroll is never started if it would reduce your money below **KEEP MONEY**.
- If a selected target is already in the shop, the picker closes without rolling.
- The target list only enables cards that are visible, selectable, and currently eligible for the `G.shop_jokers` generation path. It uses Steamodded's normal shop pools plus Cryptid's scheduled-shop and Equilibrium sources when they are active. Ineligible cards remain visible but greyed out.
- Collection visibility respects both boolean and function-valued `no_collection` flags, including Bundles of Fun's bundle toggles. Its Joker bundles appear under **Jokers**, not as separate card types; normal shop eligibility still applies.
- The default reserve is 5% of your current money the first time the picker opens. You can set it to any whole-dollar value, including `0`.

## Debug menu

Open Targeted Rerolls in Steamodded's mod settings and choose **OPEN DEBUG MENU** while a run is active.

The menu can set money to `$9,000,000` and reset the current reroll cost to `$1`. It is intended for testing, not normal play.

## For mod authors

Targeted Rerolls exposes a blacklist API for hiding cards from its target picker. See [blacklist.md](blacklist.md).
