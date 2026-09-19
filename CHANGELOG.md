# Changelog

These versions identify the 4:3 patch, independently of the original game's version. Each entry describes changes since the preceding release.

## Unreleased

No unreleased game or installer changes.

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
