# 1.2.x backport audit

The base remains the PortMaster 1.1.6 VM build. Patch release numbers are independent of the original game's versions. Version 1.5.0 adds Topaz, revised recipes and artwork, variable challenges, and a Wallmaster mode to the inventory, combat, and fixes below. It does not provide full 1.2.1 parity.

The references are the developer's bundled change log, manual, Gem Combo Poster, dungeon templates, and Windows 1.2.1 build. Its native executable retains named functions and data initializers. Reading those initializers supplied the exact gem recipes, drop weights, rod capacities, and challenge choices recorded in `content_1_2_1.json`. That file identifies the source executable by SHA-256. The gem recipes also match the poster. Gameplay integrations described below adapt those values to the older VM game.

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
| Wishstones in the treasure bag; dropping the candle | Device tests drop and recover the starting candle, check its light, retain its absence through save/load, and check lamp upgrades |
| Sword poke, level-three spin, level-two pot breaking | Device tests cover charging, pause, release, movement, interruption, pot breaking and damage across floor boundaries |
| Hookshot/boomerang in large chests and wishing ponds | Device loot-pool checks |
| Rod damage and charge limits | Device checks cover boss damage/immunities, per-rod caps and preservation of legacy charges |
| Topaz and all 55 revised gem recipes | Device checks cover all 100 ordered pairs, poster examples, incomplete pairs, old gem identities, and Topaz save/load |
| Variable challenges | Device checks cover the three-page menu, heart/defence/slot limits, prices, rupee collection/spending, food stalls, saved settings, and legacy restrictions |
| Wallmaster challenge | Device checks cover pursuit, pause, attack, damage, falling, safe levels, and entry from all four directions |
| Food bag, pendant bag, master-key and Wallmaster artwork | Binary artwork patches from 1.2.1, with source/result hashes and compiled sprite bounds/pickup-mask checks |
| Fairy-orb contents | Implemented distribution described below; compiled and reviewed |
| Keyboard menu/direction remapping | Device tests complete remapping, persist bindings and restore prior bindings on abort |

## Adaptations for this patch

Inventory uses pages sized for the 4:3 playfield. In the unreleased control update, LB/RB changes pages while D-pad navigation stays in the item grid. The narrower window sits below the HUD. Slot upgrades use the heart-container price and treasure limiter. Their loot pools support incremental upgrades. This does not reproduce an undisclosed upstream probability table.

The candle occupies the light slot and the oil lamp replaces it when collected. Dropping either removes its light and prevents torch ignition until you recover a light source.

Old saves migrate on load. Dedicated gear moves out of the main bag. Items that do not fit remain accessible on an overflow page and move back when space opens. Migration retains the equipped item and quantities. The installer backs up saves before the inventory update and again before content schema 3. Reinstallation preserves those backups.

The sword uses existing poses. Holding the button after a swing keeps the blade out and slows movement to 65%. Charging for 45 frames enables a 16-frame spin with sword level three or higher. Spin damage uses the existing sword damage rules and respects floor levels. These timings and animation are this patch's implementation, not extracted 1.2.1 code.

Diagonal movement follows the NTSC SNES walking ratio from [ALttP's reconstructed movement code](https://github.com/snesrev/zelda3/blob/fbbb3f967a51fafe642e6140d0753979e73b4090/src/player.c#L5656-L5745). Its normal walking table uses 24 units straight and 16 per diagonal axis, with 16 units per pixel. DOI therefore walks at 1.5 pixels per frame straight and 1.0 on each diagonal axis. Total diagonal speed is about 6% slower than straight movement.

The patch applies that two-thirds ratio to DOI's existing running, carrying, and sword-ready speeds before wall collision checks. Opposing inputs cancel first. This adapts the SNES walking rule rather than copying its complete terrain and speed tables. Scripted movement, corner assistance, knockback, and falls retain DOI's behavior. This correction is independent of the 1.2.1 backports.

Rod capacities, in game index order, are 20, 16, 16, 16, 12, and 12 charges, recovered from 1.2.1. Existing rods keep excess charges until spent. Fairy orbs produce one fairy 80% of the time, two 18%, or three 2%. The upstream notes specify mostly single-fairy orbs without giving numbers. The fairy distribution remains a patch choice.

Gem recipes and drop weights use the recovered 1.2.1 values. Topaz uses a new save index so existing gems retain their identities. Pond rewards retain the older engine's fallback rupee formula, with gem ranks adjusted for Topaz.

Challenge choices use the recovered values. Enemy crowds multiply the older engine's encounter budget by one, two, three, or four. The second darkness setting adds 30 percentage points to eligible random dark rooms. Higher settings force darkness, with the highest setting applying the existing restrictions on lights and lamps. Curse settings multiply existing chances by one, two, four, or six. These rules adapt the existing generation code rather than reproduce the native code in full.

Wallmaster uses the recovered artwork, damage, chase speed, attack speed/duration, hover height, and wait values. Its pursuit and collision handling are a VM implementation. It follows Link across dungeon rooms, pauses during menus and transitions, and leaves village levels. It uses normal Link damage and invulnerability rules. A full dungeon run may reveal differences from the native encounter.

`dungeon_fixes.json` is the source for the template corrections. The comparison matched rooms by grid geometry and translated connected-room indices into the 1.1.6 ordering. It excluded cosmetic room/door reordering. The build generates guarded assignments before the game creates rotated and mirrored templates. Each assignment checks its original value.

## Not included

The pub slot machine, arcade claw machine, new prisoner, seasonal decorations, and character customization remain unported. Artwork changes beyond those listed above also remain outside this patch. Unspecified upstream tweaks remain unverified.

GitHub CI compiles the patch and runtime tests, validates the release delta, and tests installation. The device suite runs in a disposable installation. It does not replace a full generated-dungeon playthrough or verification of every physical controller.
