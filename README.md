# Targeted Rerolls

Targeted Rerolls adds a second reroll button to the shop.

## Usage

1. Open the shop.
2. Click **TARGETED REROLL**.
3. Choose a card type: Joker, Tarot, Planet, Spectral, or Playing Card.
4. Set the minimum amount of money to keep.
5. Select one or more targets.
6. Click **REROLL (x)**. Rerolling stops as soon as any selected target appears.

The number in the button is the number of selected targets.

Selected targets are remembered in the mod configuration. Reopen the catalog
later to continue searching with the same selection, or use **CLEAR TARGETS**
to start a new selection.

The default reserve is 5% of the current money when the catalog first opens.
You can replace it with any specific whole-dollar amount, including `$0`.

The reserve is locked when a search starts. The mod never performs a paid
reroll if that reroll would reduce the balance below the configured reserve.

## Rules

- Every reroll uses Balatro's normal `reroll_shop()` logic.
- Reroll costs, free rerolls, vouchers, tags, and card effects remain
  vanilla/mod compatible.
- Joker duplicates require Showman, matching vanilla pool rules.
- Tarot, Planet, and Spectral targets use their current shop rate and
  `get_current_pool()` restrictions, including unlocks, bans, pool flags, and
  Planet softlocks.
- Playing Card targets use the current `playing_card_rate`. Both Base and
  Enhanced shop cards can match the selected playing-card front, while the
  voucher-controlled Base/Enhanced choice remains vanilla.
- The target is not spawned directly; real shop rerolls are performed.
- If any selected target is already in the shop, no reroll is performed.
- The targeted reroll button is disabled when the current reroll cost cannot
  be paid.
- Legendary and otherwise non-shop-generatable targets are excluded by the
  normal pool rules.
- While a targeted search is active, the shop button changes to a visible
  **STOP** button and cancels further rerolls, including during animation
  locks.

## Debug Menu

Open the Steamodded mod settings for **Targeted Rerolls** and select
**OPEN DEBUG MENU**.

Enter any nonnegative whole-dollar amount and select **SET MONEY**. The amount
replaces the current money total. The debug menu is only enabled while a run is
loaded and is not shown in the shop.
