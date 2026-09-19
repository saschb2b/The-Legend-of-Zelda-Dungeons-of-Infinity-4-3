# 1.2.x backport audit

The base remains the PortMaster 1.1.6 VM build. Patch release numbers are independent of the original game's versions. Version 1.4.0 backports the documented fixes and core inventory/combat changes below. It does not provide full 1.2.1 parity.

The references are the developer's bundled 1.2.0/1.2.1 change log, 1.2.1 game manual, and dungeon template data. The newer Windows game uses native compiled code. Except for the dungeon corrections, these are implementations of documented behavior in the older VM game.

| Change | Included and checked |
| --- | --- |
| Menu cancellation, title skipping, frozen/stoned Medusas and cannons, Pikit falling guard | Since patch 1.3.0; retained in device regression suite |
| Bari shock crash and missing Guru-bar children | Device tests exercise shock after sword destruction, a vanished attacker, frozen-bar updates and cleanup |
| Moon Pearl pausing enemies; pickups across floors | Device tests exercise both paths |
| Restricted dead-explorer loot | Device tests cover forbidden swords and allowed loot; eligibility is rechecked before collection |
| Treeman transformation from water and powder-bag payment exploit | Device tests cover water activation and missing payment |
| Zora spread-bow upgrade; first-frame arrow position | Device tests cover basic/max bows and all four arrow directions |
| Red Armos never landing; crystal hold soft lock | Device tests force stalled travel and looping fanfare, then check recovery |
| Lightning during death; carried-object water overlay | Death alarm tested on device; carried-overlay guard compiled and reviewed |
| Agahnim arena-edge fall; fortress fairy-room water | Compiled and reviewed; not exercised in a complete boss-level playthrough |
| Wall-lamp floor layers | All four placement orientations patched; compiled and reviewed |
| Dungeon locks and doors leading nowhere | Twelve data corrections; transformed lock, position and destination checks on device |
| Dedicated equipment; five-to-ten main slots; food/pendant bags | Device tests cover capacity, routing, equipped-item compaction, migration, save/load and overflow; all seven inventory pages captured on Nova |
| Wishstones in the treasure bag; dropping the candle | Device inventory tests |
| Sword poke, level-three spin, level-two pot breaking | Device tests cover charging, pause, release, movement, interruption, pot breaking and damage across floor boundaries |
| Hookshot/boomerang in large chests and wishing ponds | Device loot-pool checks |
| Rod damage and charge limits | Device checks cover boss damage/immunities, per-rod caps and preservation of legacy charges |
| Fairy-orb contents | Implemented distribution described below; compiled and reviewed |
| Keyboard menu/direction remapping | Device tests complete remapping, persist bindings and restore prior bindings on abort |

## Adaptations for this patch

Inventory uses pages sized for the 4:3 playfield. Strafe advances a page. Moving up from the first item row focuses the heading, where left/right changes pages. The food and pendant bags reuse existing bag sprites. Slot upgrades use the heart-container price and treasure limiter. Their loot pools support incremental upgrades. This does not reproduce an undisclosed upstream probability table.

Old saves migrate on load. Dedicated gear moves out of the main bag. Items that do not fit remain accessible on an overflow page and move back when space opens. Migration retains the equipped item and quantities. The installer creates a one-time backup before the first inventory-schema update. This patch writes saves with the new inventory schema.

The sword uses existing poses. Holding the button after a swing keeps the blade out and slows movement to 65%. Charging for 45 frames enables a 16-frame spin with sword level three or higher. Spin damage uses the existing sword damage rules and respects floor levels. These timings and animation are this patch's implementation, not extracted 1.2.1 code.

Rod capacities, in game index order, are 16, 12, 12, 12, 8 and 8 charges. Existing rods keep excess charges until spent. Fairy orbs produce one fairy 80% of the time, two 18%, or three 2%. The upstream notes specify capacities by value and mostly single-fairy orbs without giving numbers. These values are explicit patch choices.

`dungeon_fixes.json` is the source for the template corrections. The comparison matched rooms by grid geometry and translated connected-room indices into the 1.1.6 ordering. It excluded cosmetic room/door reordering. The build generates guarded assignments before the game creates rotated and mirrored templates. Each assignment checks its original value.

## Not included

Variable challenge settings, the Wallmaster challenge, the tenth topaz and revised gem recipes remain unported. They need separate work on rules, menus, save compatibility and content. The existing challenge options and gem recipes remain available.

New arcade games, characters, seasonal decorations and replacement artwork are outside this pass. Unspecified upstream tweaks cannot be claimed as reproduced.

GitHub CI compiles the patch and harness, validates the release delta, and tests installation. The device suite runs in a disposable installation. It does not replace a full generated-dungeon playthrough or verification of every physical controller.
