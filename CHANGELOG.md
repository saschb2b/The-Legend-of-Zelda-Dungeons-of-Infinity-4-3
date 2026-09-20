# Changelog

These versions identify the 4:3 patch, independently of the original game's version. Each entry describes changes since the preceding release.

## Unreleased

### Added

- Show the available interaction beside Status during play, such as Talk, Open, Lift or Throw. Use the current Interact binding, keep Status anchored, and hide the hint while menus, dialogue or scripted movement prevent interaction.

### Changed

- Use the supplied Switch 2 glyphs for controller hints. Group hints at the bottom right with labels before buttons and the primary action (A) before Close (B). Keep inventory actions in fixed positions and L/R beside page headings.
- Keep the classic centered title reveal, then move its logo into an adventure menu with the last selected player and Continue first.
- Choose a character, bonus and challenges in one frame. Begin adventure is selected by default, and fresh players start as Link without mandatory name entry.
- Replace stacked startup windows with a shared scene and one active frame. Keep all five players, records, renaming, controls and credits available. Move Updates into Options.
- Keep new-run choices separate from saved progress. Confirm before replacing an adventure or deleting a player, with the safe choice selected first. Close restores the originating menu and selection.

## [1.6.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.6.0) - 2026-09-20

### Added

- Check for stable patch updates from the profile selection screen. Read changes since the installed version, download over Wi-Fi, and install with an automatic restart.
- Verify update checksums, preserve saves and migration backups, and recover the previous installation after an interrupted update.

### Changed

- Rework Player Select around a spacious Zelda-style frame, original character sprites, and saved hearts and floor. Keep all five profiles visible, with Updates and Exit below them and button hints clear of the frame.
- Give Updates the same frame position, title panel, and button-hint row as Player Select. Show more release notes per page.

The installer preserves existing saves and migration backups. Install this release once to get the in-game updater. Follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.6.0/README.md#install-on-the-nova).

[Changes from v1.5.3](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.5.3...v1.6.0).

## [1.5.3](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.5.3) - 2026-09-20

### Fixed

- Match ALttP's SNES walking ratio: diagonal movement uses two-thirds speed on each axis, removing DOI's diagonal speed boost. Running uses the same ratio while preserving its straight-line speed.
- Match SNES sword-ready and carrying speeds on normal ground: 1.25 pixels straight and 0.8125 per diagonal axis.
- Match the SNES 48-update sword-charge threshold and keep the charge indicator synchronized with spin readiness.
- Make diagonal turning predictable: retain Link's facing when it matches a held direction, otherwise face vertically. Fix turns that could randomly face away from both held directions.
- Keep health, magic, the equipped item, and counters visible through room scrolling, doorway exits, closing doors, and stairs. Hide the Status hint until its button is available again.
- Restore B for the sword and A for interactions on the Nova by correcting PortMaster's A/B translation. Menus use A to confirm and B to close, with matching glyphs and Controls labels.
- Close shop dialogs with B or Escape without buying or consuming a coupon. Consume the opening press so it cannot also act inside the dialog.

The installer preserves existing saves and migration backups. Follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.5.3/README.md#install-on-the-nova) to update.

[Changes from v1.5.2](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.5.2...v1.5.3).

## [1.5.2](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.5.2) - 2026-09-19

### Changed

- Place a narrower inventory below the HUD, keeping health, magic, the active item, and counters visible while browsing or reading item information.
- Switch inventory pages with remappable LB/RB controls, or Page Up/Page Down on a keyboard. D-pad navigation stays in the item grid.
- Show current bindings with the supplied Retro controller glyphs and colored face buttons. The Status hint updates after remapping. Keyboard prompts show the bound key.
- Replace the ambiguous Select hint with Actions, Open for bags, or the highlighted action's name. Show the Equip shortcut only when it applies.
- Keep inventory prompts in fixed positions: Equip on the left, Close in the middle, and the primary action on the right. Shoulder hints stay fixed beside the heading across every page.
- Reduce the Status glyph's size and spacing while keeping its label readable and its binding current.

### Fixed

- Close item actions, item information, inventory, and the map consistently with the action button or Escape. Closing consumes the input so it cannot also activate gameplay.
- Preserve existing controller and keyboard bindings while adding defaults for the new page controls.
- Keep all remapping rows inside the Controls window, including keyboard directions and the two bag controls.
- Split large migrated inventories across additional overflow pages so every retained item remains reachable in the compact layout.

The installer preserves existing saves and migration backups. Follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.5.2/README.md#install-on-the-nova) to update.

[Changes from v1.5.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.5.1...v1.5.2).

## [1.5.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.5.1) - 2026-09-19

### Changed

- Rename the right-stick hint from PANELS to STATUS to describe the equipment, stats, map, and dungeon progress it reveals.

[Changes from v1.5.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.5.0...v1.5.1).

## [1.5.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.5.0) - 2026-09-19

### Added

- Topaz, all 55 gem recipes, and gem drop weights recovered from Windows 1.2.1. Existing saves retain their original gem identities.
- Twelve challenge settings in three pages, covering hearts, defence, darkness, inventory, rupees, prices, enemies, curses, map visibility, food, and Wallmaster.
- Wallmaster mode using original game artwork and recovered combat values. Pursuit and collision handling are adaptations for the VM engine.
- Original 1.2.1 artwork for food bags, pendant bags, and the master key.

### Changed

- Rod capacities to the recovered values: 20, 16, 16, 16, 12, and 12 charges. Existing rods retain excess charges until spent.
- The installer creates `save-backups/before-content-v3.zip` before this content upgrade. Existing saves and earlier backups remain intact.

This remains a 1.1.6 backport. Arcade games, the new prisoner, seasonal decorations, and character customization remain unported. See the [backport audit](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.5.0/BACKPORTS.md) for adaptations and coverage.

Follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.5.0/README.md#install-on-the-nova) to install or update.

[Changes from v1.4.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.4.1...v1.5.0).

## [1.4.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.4.1) - 2026-09-19

### Fixed

- Dropping and recovering the starting candle from the light slot. Dropping it disables its light and torch ignition.
- Save/load retains a dropped candle's absence. Collecting an oil lamp replaces the candle without duplicating the light source.
- The dropped candle's artwork and collision bounds align, so walking onto it collects it correctly.
- The installer records the candle save-schema update while preserving the existing inventory backup.

Updates from v1.4.0 migrate candle ownership automatically. Regression tests cover dropping, pickup, lighting, and save/load.

[Changes from v1.4.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.4.0...v1.4.1).

## [1.4.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.4.0) - 2026-09-19

### Added

- Dedicated equipment storage, five main slots expandable to ten, and three-slot food and pendant bags. The treasure bag accepts wishstones.
- Sword poke, charged spin from sword level three, and pot breaking from level two.
- Hookshot and boomerang rewards in large chests and wishing ponds.
- Keyboard remapping for Menu and all four directions. Cancelling a remap restores the previous bindings.

### Fixed

- Bari shock and Guru-bar crashes, Moon Pearl pausing, and item pickups across floor boundaries.
- Dead-explorer loot restrictions, Treeman transformation/payment, Zora bow upgrades, and initial arrow positions.
- Red Armos landing and crystal fanfare recovery, Agahnim arena edges, and twelve dungeon lock/door errors.
- Lightning during death, carried-object water overlays, fortress fairy-room water, and wall-lamp floor placement.

### Changed

- Rod boss damage and charge limits, and fairy-orb contents. Some values in this release are patch adaptations, documented in the [audit](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.4.0/BACKPORTS.md).
- Existing inventory migrates into the new compartments. Excess items stay accessible on an overflow page.

The installer creates `save-backups/before-inventory-v1.zip` before migration. Keep it to restore saves when returning to an earlier inventory format.

[Changes from v1.3.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.3.0...v1.4.0).

## [1.3.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.3.0) - 2026-09-19

### Added

- Action-button and Escape cancellation in menus, preserving name-entry backspace.
- Skipping the title animation with Start or confirm. Set `CanSkipTitle=0` in the preferences file to require the full animation.
- Reproducible builds, GitHub CI, installer integration tests, and an isolated Nova runtime suite.

### Fixed

- Medusas and cannons firing while frozen, stoned, or paused. Attacks resume after the status ends.
- Pikits stealing items while Link falls into a pit or over an edge.

[Changes from v1.2.2](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.2.2...v1.3.0).

## [1.2.2](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.2.2) - 2026-09-19

### Fixed

- HUD alignment: balanced outer margins, more space between the item slot and rupees, counters beneath icons, and hearts beneath LIFE.
- Magic-meter proportions and stepped caps, while retaining four-digit rupees and the separate key counter.
- The unreadable right-stick hint. It uses the icon pack's explicit R3 glyph at screen resolution, including with CRT enabled.

[Changes from v1.2.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.2.1...v1.2.2).

## [1.2.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.2.1) - 2026-09-19

### Added

- A bottom-right stick-click hint labelled PANELS while the side panels are hidden. Opening panels or menus hides the hint.

[Changes from v1.2.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.2.0...v1.2.1).

## [1.2.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.2.0) - 2026-09-19

### Added

- A persistent classic HUD for health, magic, equipped items, rupees, bombs, arrows, and keys while panels are hidden.
- Item quantities, partial hearts, and low-health pulse using the game's existing artwork.

### Changed

- Smaller side panels below the HUD, containing equipment, attack/defence, the minimap, and dungeon progress. The panels omit duplicate metrics.
- Menus and dialogue hide both HUD layers. The CRT effect includes the HUD.

[Changes from v1.1.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.1.0...v1.2.0).

## [1.1.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.1.0) - 2026-09-19

### Fixed

- Title, credits, and profile menus fitting the Nova's 4:3 screen.
- Gameplay rendering size after leaving profile menus, keeping pause controls, play time, inventory, and the map visible.

### Changed

- Distribution to a patch-only installer. It downloads the official PortMaster package, verifies checksums, and applies the patch locally.

[Changes from v1.0.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.0.0...v1.1.0).

## [1.0.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.0.0) - 2026-09-19

Initial Nova 4:3 gameplay layout, hidden-by-default overlay panels, right-stick toggle, CRT composition, and Select + Start exit.

The original bundled download was withdrawn. Use the [latest patch-only installer](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/latest).
