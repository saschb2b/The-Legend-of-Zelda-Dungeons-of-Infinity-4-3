# Testing and releases

Testing has three layers. Each catches a different failure:

| Layer | Runs on | Checks |
| --- | --- | --- |
| Unit and installer integration | Python, no downloads | Controller mapping, BSDIFF decoding, checksum failures, interrupted downloads, save preservation, repeated installation, archive traversal, release contents, compiler failure detection, inventory-save backup, runner binary format |
| Clean build | Linux x86-64 | Pinned upstream and compiler hashes, exact patch anchors, GML compilation, compiled room and code invariants, production/test separation, release delta equality, installation of the real package |
| Runtime regression | Nova with ROCKNIX | Real GameMaker menus, combat, inventory migration, Topaz and challenge save/load, gem recipes, challenge limits, Wallmaster attacks, dungeon templates, and enemy status events |

## Local and CI checks

From the repository root:

```sh
python3 -m unittest discover -v
python3 build.py --runtime-tests
bash -n ./*.sh
```

The unit suite uses temporary synthetic archives and needs no game files or third-party packages. CI runs it on Python 3.11 and 3.14. The build job uses Python 3.12 on Ubuntu 24.04. Actions use full commit pins, read-only repository permissions, and timeouts. Dependabot checks action pins monthly.

`build.py` verifies every cached input before use. `--utmt /path/to/UndertaleModCli` and `--upstream-zip /path/to/zeldadoi.zip` can reuse local downloads. A custom compiler path bypasses the compiler archive download check. Use version 0.9.2.0.

The compiler can exit successfully after a script exception. The build requires completion markers and an output file, then reloads the result for structural checks. The original game's audio alignment warning requires the CLI's verbose flag. The patch pins serialization to the older runner's format and verifies that the FUNC chunk includes a locals-table count. The tool can otherwise misidentify the empty upstream table as newer alignment padding and produce a file that crashes at startup.

`--check-release` requires the checked-in delta to reconstruct exactly the bytes from the clean source build. Branch and pull-request CI builds source and the runtime harness. Version-tag CI also checks the release delta and installer. Before publishing a tag, run `python3 build.py --check-release --runtime-tests` locally. CI uploads only `.build/build-report.json`. It never uploads full games, runtimes, saves, or instrumented builds.

## Nova runtime suite

CRT checks compile the shader on the device and render black, gray, impulse and edge patterns. They check brightness, neutral grays, bloom, full-frame coverage, native-pixel sampling, stable phosphors, fallback behavior and restored graphics state. The report includes average and 95th-percentile frame times for 120 gameplay frames with CRT disabled and enabled, after a warm-up. Existing HUD checks run with both settings.

Close any running game first. Install this patch on the device and enable SSH access. Use a key or an existing SSH control socket. The test runner contains no credentials.

```sh
python3 build.py --runtime-tests
python3 tests/run_device.py root@your-device.local
```

Optional arguments include `--control-path /path/to/socket`, `--ports-dir /storage/roms/ports`, and `--report-dir .build/device-results`. Add `--capture` to save screenshots of all seven inventory categories, item actions and information, keyboard prompts, CRT mode, a second overflow page, curse text, and the map footer after the assertions. Status captures cover the default binding, CRT mode, a remapped button, and keyboard input. Review the screenshots for clipping, HUD overlap, and incomplete frames. Screenshot comparisons are manual.

The runner creates a disposable game directory under `/storage/.cache/`, with fresh saves, and a temporary Ports launcher. It launches through EmulationStation and runs the suite automatically. It writes the JSON assertion report and game log locally, removes the disposable installation, and compares production save hashes. It never switches the production game to a test build. If SSH disconnects before cleanup, remove the reported `doi43-harness-*` directory and matching `DOI43 Harness *.sh` launcher after closing the test game.

The suite calls the compiled game events. It substitutes input at the input-query boundary, creates actual enemy instances, and checks projectiles, timers, inventory, menu state, and profile contents. It tests recovery and normal behavior as well as blocked actions. Control cases cover remapped button and stick glyphs, alternate and empty bindings, old profile imports, label-before-glyph spacing, fixed footer positions, shoulder-page wrapping, contextual action labels, simultaneous inputs, item-information closure, and map dismissal. The test object and input substitution exist only in `runtime-tests.droid` and `runtime-baseline.droid`. Packaging rejects either test build.

Movement tests measure displacement through Link's compiled Step event over eight frames in all eight directions, including walking, running, carrying, and sword-ready movement. They also check opposing inputs, strafe, doorway speed limits, corner assistance, scripted movement, knockback, and falls. Real wall instances check sliding on all four sides while walking, carrying, or holding the sword. Across eight frames, SNES walking covers 12 pixels straight or 8 per diagonal axis. Carrying and sword-ready movement cover 10 straight or 6.5 per diagonal axis. The tests use fresh saves in the starting clearing.

Sword tests check release and charge-indicator readiness at 0, 1, 44, 45, 47, 48, and 49 held updates. They check pause and resume at the threshold, sword-level restrictions, and indicator dismissal after release. The build verifier requires the indicator to call the same readiness function as the attack.

Facing tests cover every starting direction against eight movement directions and idle input through Link's compiled Step event. Each case runs with eight random seeds and checks the first three updates while walking, running, carrying, strafing, or holding the sword ready. They also check corner-assist and knockback locks, releasing either diagonal input, and stopping. Expected ordinary turns follow the reconstructed SNES [facing routine](https://github.com/snesrev/zelda3/blob/fbbb3f967a51fafe642e6140d0753979e73b4090/src/player.c#L5932-L5967): keep a facing included in the diagonal, otherwise prefer its vertical direction. DOI's facing locks remain in effect.

HUD tests call the compiled renderer with room-scroll, doorway-exit, door-closing, and stair states. They cover all four scroll directions, CRT on and off, and returning control to the player. Draw counters check HUD and Status-hint visibility. A pixel sample checks that the magic meter stays at its screen position while camera coordinates change. Pause-menu, map, dialogue, inventory, and unrelated-pause cases check visibility outside travel. These fixtures test the renderer's response to transition states, not an entire doorway crossing.

HUD scaling tests render four-digit rupees, full magic and twenty hearts at eight resolutions from 256×224 to 1920×1440. They compare individual output pixel blocks with the native HUD surface, check integer positions and equal side margins, and verify separation between counters and hearts. The build checks that the HUD pass follows world scaling and restores texture filtering. Use `--capture` to inspect full inventories, maximum counters and CRT rendering on the device.

Shop tests use an actual merchant, item, and purchase script with keyboard and controller profiles. They check closing from every choice, item information, and insufficient-funds messages, including simultaneous confirm and close presses. Closing must preserve goods, rupees, and coupons. Confirming Buy must charge once and start receiving the item. The opening interaction must not also submit or close the dialog.

Interaction-hint tests place real pots, chests, NPCs and shop goods within reach, then invoke Interact to verify that the hint matches the resulting action. They cover facing, floor separation, unavailable objects, carrying priority, remapping, keyboard bindings and modal suppression. Repeated hint queries must preserve inventory, saves, treasure state, merchant selection and random-number state. The build derives the read-only query from the patched interaction predicates and rejects unreviewed function calls or instance-field writes.

Animation cases run at 30, 60 and 120 Hz. They check the 120 ms entrance, 100 ms exit and 120 ms label change (40 ms out, 80 ms in). They exercise the real pickup state, rapid label changes, interrupted fades, fixed glyph positions and clearing hints when a menu opens. Drawing must preserve animation state and incoming HUD opacity. The animation advances in End Step after gameplay updates. It does not delay input.

Add `--capture-context` for Talk, Open, Lift, remapped-controller and keyboard screenshots. Review their spacing beside Status. The same run exports 96 `nova-context-motion-*.png` frames at simulated 60 Hz through the device's renderer. Play the frames at 60 Hz to inspect appearance, Lift-to-Throw and disappearance. This deterministic rendering preview complements the pickup-state tests. It is not a recording of physical input timing.

Village tests enumerate every slot roll and check all stakes and payouts, reel alignment, insufficient funds, wallet limits and repeated settlement. Claw tests cover weighted prize pools, purchase cancellation, payment, movement bounds, grabbing, refunds, losing stakes and item delivery. The suite also walks into and out of both buildings through their real door events. Add `--capture-arcade` for pub, slot, claw and prize screenshots. Review original sprite tiling, reel clipping and footer spacing.

Controller tests check PortMaster's Nintendo A/B mapping and preserve other controls, Xbox mappings, and custom layouts. The device runner uses the repository's launcher and controller adapter. Before release, verify the physical Nova buttons: B swings the sword, A interacts, and menus use A to confirm and B to close. Logical input injection alone cannot verify the controller translation.

Updater tests cover stable-version selection, release URLs, checksums, archive paths, cancellation, insufficient space, installation failure, and recovery after each file-switch step. An integration test downloads fixture bytes and runs the real installer in a separate directory, preserving saves and migration backups.

The runtime suite checks the Updates menu, stale responses, confirmation, cancellation, retry, window bounds, and controller hints. Its launcher disables the network worker so menu fixtures cannot download or install a release. `--capture` includes update-available and error screens. Check the live service separately before release.

Startup tests cover empty players, saved runs, partial hearts, remembered selection, direct player switching, renaming and Close behavior. They cycle every character, bonus and challenge option. Browsing a new-run draft must leave saved progress unchanged. Replacement and deletion default to keeping progress. Canceling Create player restores the previous selection without creating a profile. The harness intercepts start/continue at the room-change boundary, then separately enters the dungeon for gameplay regression tests. Keyboard and controller hints must clear the shared frame.

Use `--capture-profiles` for the adventure menu, setup, challenges, players and keyboard controls, or `--capture-updates` for the updater. `--capture` includes both. Menu captures include three consecutive samples because remote captures can omit parts of a frame. Inspect the two-row heart display, selected cursor, and footer spacing on the device.

The updater downloads and verifies the installer and upstream package while the game runs. After the game exits, it installs into a separate directory. A recovery journal protects the directory switch and launcher replacement. The launcher restores an interrupted transaction before starting the game. Diagnostics are in `zeldadoi-43/update.log`.

To show that the assertions catch the original regressions:

```sh
python3 tests/run_device.py root@your-device.local \
  --game .build/runtime-baseline.droid \
  --report-dir .build/baseline-results
```

The baseline contains the unpatched 1.1.6 game with the same instrumentation. That command must fail on the behaviors the patch adds. Review each named failure. Some original bugs terminate the runner before the report can complete. Retain the partial assertion report and the named error in `game.log`. A launch error does not prove regression coverage.

GitHub-hosted CI compiles the runtime suite but cannot execute the Nova's ARM/GPU runtime. Before releasing, run the suite on a device. Also check the physical confirm/cancel buttons, title animation, remapped Status toggling, shoulder paging, item actions and information, pause layout, CRT mode, and Select + Start. Verify that the glyph matches the button that actually triggers each action. Inspect all three challenge pages, including the longest values and returning to the start menu. Runtime assertions measure the text columns and window bounds, but screenshots still need review. Injected input does not verify physical controller mapping, rendering quality, audio, or an entire generated dungeon run.

For inventory prompts, compare empty slots, equipment, usable items, action lists, and item information. Close must retain its position throughout. Shoulder hints must stay fixed across all page titles, including both overflow pages. Check remapped buttons and keyboard keycaps for overlap. This follows [XAG 112's guidance on consistent prompt locations and order](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112). The specific Equip / Close / primary-action row is a design choice for this compact layout.

## Playable village test

After a clean build, this command leaves a separate **DOI Village Test** entry in Ports and launches it:

```sh
python3 tests/run_village.py root@your-device.local --control-path /path/to/socket
```

The test starts outside the village arcade with 500 rupees and normal physical controls.

1. Walk through the entrance so the game records the return doorway.
2. Face the CLAW cabinet and press A. Move left/right and grab with A.
3. Leave the arcade and enter the pub to try Mothula's Money. Change bets with L/R.
4. Check both entrances and exits, repeated plays, insufficient funds, prize collection, audio, and B to close.

The slot rendering checks compare pixels before the CRT pass: title font and baseline, Bet/Spin buttons, payout suffixes, payline markers and reel-strip wrapping. They also require the CRT shader to compile on the device and produce a dark border with filtered interior pixels. Compare the final capture with the original 1.2.1 screen; a passing economy test does not establish visual parity.

Each launch starts a fresh village adventure in an isolated save directory. The script checks production save and backup hashes, disables the updater worker, and records the test paths in `.build/village-preview.json`. After closing the test, remove its `DOI Village Test.sh` launcher and the recorded `doi43-village-*` directory. The build and release packager reject the preview object in production binaries.

## Versioning and release cadence

Use [SemVer-style](https://semver.org/spec/v2.0.0.html) version numbers for the patch, independently of the upstream game. Compatibility means existing installations can update and load saves, including through documented automatic migrations.

| Increment | Use for |
| --- | --- |
| Patch (`x.y.Z`) | Bug fixes and refinements to existing layout, controls, or installation |
| Minor (`x.Y.0`) | A planned batch of new gameplay features, modes, or substantial backports |
| Major (`X.0.0`) | Changes that break the documented installation or save compatibility contract |

Batch related work under **Unreleased** in [CHANGELOG.md](CHANGELOG.md). A completed task, commit, or test run does not require a release. Publish routine fixes together after the batch passes verification. Publish a separate hotfix when an existing release has a serious crash, save, or installation problem.

Keep work-in-progress builds local. For shared testing, use a GitHub draft or an `-rc.N` prerelease for the intended version. Promote a tested batch to stable once it is ready. Documentation, release-note corrections, tests, and CI maintenance alone do not need an installer release or a version bump.

Published tags, version numbers, archives, and checksums stay unchanged. Correct release titles or notes when needed, without replacing their downloads. The next version describes the actual shipped changes, not the amount of development activity.

Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) for release notes. `CHANGELOG.md` is the source for GitHub release bodies. Each entry lists only changes since the preceding release, grouped under Added, Changed, or Fixed when useful. Omit empty groups and cumulative feature lists. Include save-migration details, known limitations introduced by the release, and a comparison link. Link to the installation guide instead of repeating it in every entry.

Use the title `vX.Y.Z: Short description` and copy that version's changelog section into the GitHub release body. Do not generate player-facing notes from raw commit subjects. Check the wording against the actual tag diff before publishing.

## Release procedure

1. Review the Unreleased changes, choose the increment using the policy above, and run unit tests and `python3 build.py --runtime-tests`.
2. Run the Nova suite and inspect any failures. Complete the physical-control and visual checks above.
3. Create the delta and patch-only installer with an unused version and output filename:

   ```sh
   read -r -p 'New patch version (without v): ' release_version
   python3 -m venv .build/patchenv
   .build/patchenv/bin/pip install -r requirements-build.txt
   .build/patchenv/bin/python package_release.py \
     --original-game .build/game.droid \
     --patched-game .build/patched.droid \
     --version "$release_version" \
     --output "dist/Dungeons-of-Infinity-4-3-v${release_version}-Nova-Patch-Installer.zip"
   python3 build.py --check-release --runtime-tests
   ```

4. Move the shipped changelog entries from Unreleased to the chosen version, with the release date and comparison link.
5. Commit the source, tests, binary delta, manifest, and changelog together. Push and require the GitHub checks to pass before tagging a release.
6. Publish the matching changelog section, installer ZIP, and SHA-256 checksum. Never attach `.droid`, `.port`, `.build/`, test reports containing device data, or upstream downloads.

`package_release.py` writes a fixed allowlist of installer files with stable ZIP timestamps. It verifies binary-patch reconstruction and refuses an existing output filename. `manifest.json` records the original game, patched game, delta, and upstream archive hashes.
