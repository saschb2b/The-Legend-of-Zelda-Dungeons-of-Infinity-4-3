# Changelog

These versions identify the 4:3 patch, independently of the original game's version. Each entry describes changes since the preceding release.

## Unreleased

## [1.7.3](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.7.3) - 2026-09-22

In-game updates install again.

### Fixed

- Fix in-game updates failing with "Close the 4:3 edition before installing the update." The launcher's controller helper, gptokeyb, keeps running during installation and was mistaken for the game.

### Updating from v1.6.0 through v1.7.2

The update step uses the check from the installed version, so **Options > Updates** cannot install this release. Install it once with the **Nova patch installer ZIP** under Assets, following the [update instructions](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.7.3/README.md#install-on-the-nova). Later releases will install from the adventure menu. The game itself is unchanged from v1.7.2. Existing saves remain compatible.

Validation: 39 unit tests passed. On the Nova, the update step installed a release while a controller helper with the game's arguments was running, and preserved saves.

For a fresh installation, follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.7.3/README.md#install-on-the-nova).

[Changes from v1.7.2](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.7.2...v1.7.3).

## [1.7.2](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.7.2) - 2026-09-21

Menu hints now match the compact gameplay HUD.

### Fixed

- Size inventory actions, item information, map and arcade hints at the same integer scale as gameplay hints, 3x on the Nova. Keep a consistent footer baseline and right margin.
- Keep smaller L/R glyphs beside the inventory heading, aligned to whole screen pixels. Item artwork and descriptions retain their reading size.
- Fix a test-suite crash caused by dormant dungeon enemies surviving the test-only jump to the village. Add a regression case for that cleanup.

### Inventory before and after

<table>
<tr>
<th width="50%">v1.7.1</th>
<th width="50%">v1.7.2</th>
</tr>
<tr>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/inventory.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/inventory.png" alt="Bag inventory with larger shoulder glyphs and action hints" width="640"></a></td>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.2/screenshots/inventory.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.2/screenshots/inventory.png" alt="Bag inventory with compact shoulder glyphs and action hints at the gameplay HUD scale" width="640"></a></td>
</tr>
</table>

Unedited Nova captures from test saves. Existing saves remain compatible.

Validation: 38 unit tests and 1,535 device assertions passed. The [testing guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.7.2/TESTING.md#nova-runtime-suite) records a separate, pre-existing native shutdown fault after test completion.

Run the **Nova patch installer ZIP** under Assets. **Options > Updates** cannot install this release; [v1.7.3](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.7.3) fixes in-game updates.

For a fresh installation, follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.7.2/README.md#install-on-the-nova).

[Changes from v1.7.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.7.1...v1.7.2).

## [1.7.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.7.1) - 2026-09-21

More room for the dungeon, smoother interaction hints, and a CRT-Lottes effect tuned for the Nova.

### Changed

- **Smaller, sharper HUD:** health, magic, equipment, counters and gameplay hints use their own integer scale, 3x on the Nova. The world still fills the 4:3 screen. Four-digit rupees and full heart rows remain visible.
- **CRT-Lottes:** replace the gameplay CRT effect with Timothy Lottes' shader, adapted from RetroArch. Gamma-correct filtering, shaped scanlines, a phosphor grille and soft bloom preserve dark detail and the full playfield. The HUD stays crisp. Arcade machines keep their original effect.
- **Smoother input hints:** fade contextual hints in and out. Keep the button in place while its label changes, including Lift to Throw. Input response remains immediate.

### Fixed

- Fix a crash when a new floor generates a Kinstone pedestal, including the transition to floor 3. Keep the candle sprite correction specific to candles.

### CRT before and after

<table>
<tr>
<th width="50%">Previous CRT effect</th>
<th width="50%">CRT-Lottes</th>
</tr>
<tr>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/crt-before.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/crt-before.png" alt="Previous CRT effect with prominent horizontal lines" width="640"></a></td>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/crt-after.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/crt-after.png" alt="CRT-Lottes with a phosphor grille, soft bloom and a crisp HUD" width="640"></a></td>
</tr>
</table>

Both captures use the compact HUD to isolate the shader change. Open an image at full size to inspect the CRT detail.

### Compact HUD

<table>
<tr>
<th width="50%">During play</th>
<th width="50%">In the inventory</th>
</tr>
<tr>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/playfield.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/playfield.png" alt="Compact HUD leaves more of the village visible, with CRT disabled" width="640"></a></td>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/inventory.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.1/screenshots/inventory.png" alt="Bag inventory beneath the compact HUD, with controller hints below the frame" width="640"></a></td>
</tr>
</table>

Unedited Nova screenshots from test saves.

### Update

Choose **Options > Updates** from the adventure menu, or download the **Nova patch installer ZIP** under Assets. Existing saves remain compatible.

For a fresh installation, follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.7.1/README.md#install-on-the-nova).

Validation: 38 unit tests and 1,498 device assertions passed. The Nova test scene ran at 60 fps with CRT both enabled and disabled.

[Changes from v1.7.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.7.0...v1.7.1).

## [1.7.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.7.0) - 2026-09-21

Take a break on floor 6: the village arcade has a claw machine, and the pub has Mothula's Money.

**Republished with corrected slot-machine visuals.** Mothula's Money uses the original 1.2.1 title font, payout layout, gold Bet/Spin buttons, reel markers, scrolling direction and CRT effect. The first download used an adapted layout and a shader that failed to compile on the Nova.

### Added

- **Claw machine:** spend ten rupees per play, move the claw left or right, and press A to grab a prize.
- **Mothula's Money:** play the pub's four slot machines. L/R changes the bet from one to five rupees. A starts a spin.
- Both games use the original 1.2.1 artwork, audio, prize pools and payout rules, adapted to the PortMaster VM build.
- Button hints follow your mappings. B closes either game. Closing a paid spin settles its result once. Closing the claw before grabbing refunds the unused play.

### In the village

Reach the village after the sewers on **floor 5**. Enter the arcade and inspect the cabinet marked **CLAW**, or visit the pub for the slots.

<table>
<tr>
<th width="50%">Arcade: claw machine</th>
<th width="50%">Pub: Mothula's Money</th>
</tr>
<tr>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.0/screenshots/village-claw.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.0/screenshots/village-claw.png" alt="Link playing the original claw cabinet, with Grab A and Close B hints" width="640"></a></td>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.0/screenshots/village-slots.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.7.0/screenshots/village-slots.png" alt="Mothula's Money with three reels, payout symbols, balance, bet and controller hints" width="640"></a></td>
</tr>
</table>

Unedited Nova captures using a test save. Select either image to view it at full size.

### Update

If you already installed v1.7.0, rerun the replacement patch installer ZIP under Assets. The in-game updater cannot detect a replacement with the same version number. Existing saves and migration backups stay intact.

From an earlier version, choose **Options > Updates** from the adventure menu or run the installer.

For a fresh installation, follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.7.0/README.md#install-on-the-nova).

Validation includes 38 unit tests, 1,349 device assertions, both buildings' entry and exit paths, and physical playtesting on the Nova.

[Changes from v1.6.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.6.1...v1.7.0).

## [1.6.1](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/tag/v1.6.1) - 2026-09-20

Continue your adventure in one press, with a simpler start menu and clearer controls throughout the game.

### Added

- Show nearby interactions beside Status: Talk to people, Open chests, Lift pots, Throw carried objects, Read signs, or Inspect shop goods. The hint follows your Interact binding and appears only when the action is available.

### Changed

- Keep the classic centered title screen, then animate its logo into the adventure menu. Continue selects your last player, with their name and floor beneath it. Character portraits and hearts stay together in Change player.
- Choose a character, bonus and challenges in one frame, with Begin adventure selected first. New players start as Link without mandatory name entry.
- Use one active menu frame over a shared scene. All five players, records, renaming, controls and credits remain available. Find Updates under Options.
- Confirm before replacing an adventure or deleting a player, with the safe choice selected first. Browsing new-run choices preserves saved progress. Close returns to the previous selection.
- Use Switch 2 button glyphs, with action labels before buttons in a consistent bottom-right row. Keep A before B Close, inventory actions in fixed positions, and L/R beside page headings.

### Before and after

**From Player Select to Continue.** The saved name and floor sit beneath the action that resumes the run.

<table>
<tr><th width="50%">Before · v1.6.0</th> <th width="50%">After · v1.6.1</th></tr>
<tr>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.0/screenshots/profile.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.0/screenshots/profile.png" alt="Player Select in v1.6.0, with five save slots and Updates" width="640"></a></td>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.1/screenshots/profile.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.1/screenshots/profile.png" alt="Adventure menu in v1.6.1, with LINK and Floor 5 beneath Continue" width="640"></a></td>
</tr>
</table>

**One place for action hints.** The footer stays below the inventory frame, while shoulder buttons stay beside its heading.

<table>
<tr><th width="50%">Before · v1.6.0</th> <th width="50%">After · v1.6.1</th></tr>
<tr>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.0/screenshots/inventory.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.0/screenshots/inventory.png" alt="Inventory in v1.6.0, with colored button hints inside the frame" width="640"></a></td>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.1/screenshots/inventory.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.1/screenshots/inventory.png" alt="Inventory in v1.6.1, with Switch 2 hints below the frame and L/R beside the heading" width="640"></a></td>
</tr>
</table>

**An action when you need it.** Talk appears beside Status when Link faces someone within reach.

<table>
<tr><th width="50%">Before · v1.6.0</th> <th width="50%">After · v1.6.1</th></tr>
<tr>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.0/screenshots/playfield.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.0/screenshots/playfield.png" alt="Gameplay in v1.6.0, with only a Status hint" width="640"></a></td>
<td><a href="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.1/screenshots/interaction.png"><img src="https://raw.githubusercontent.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/v1.6.1/screenshots/interaction.png" alt="Gameplay in v1.6.1, with Talk and its mapped A button beside Status" width="640"></a></td>
</tr>
</table>

Screenshots are unedited captures from a Nova, using test saves. Select an image to view it at full size.

### Update

On v1.6.0, open **Updates** from Player Select. After this update, it lives under **Options > Updates**. The installer preserves saves and migration backups.

For a fresh installation or an older version, use the patch installer ZIP under Assets and follow the [installation guide](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/blob/v1.6.1/README.md#install-on-the-nova).

[Changes from v1.6.0](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/compare/v1.6.0...v1.6.1).

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
