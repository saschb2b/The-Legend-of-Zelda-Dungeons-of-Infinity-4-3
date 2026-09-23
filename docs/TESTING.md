# Testing and releases

Testing has three layers. Each catches a different failure:

| Layer | Location | Runs on | Checks |
| --- | --- | --- | --- |
| Host | `tests/host/` | Python, no downloads | Controller mapping, BSDIFF decoding, checksums, interrupted downloads, save preservation, 4:3-edition migration, repeated installation, archive traversal, release contents, compiler failure detection, runner binary format, device report formatting |
| Build | `tests/build/verify.csx` | Linux x86-64 | Pinned upstream and compiler hashes, exact patch anchors, GML compilation, compiled room and code invariants, production/test separation, release delta equality, installation of the real package |
| Device | `tests/device/` | ROCKNIX device (Nova 4:3, Flip 2 16:9) | Real GameMaker events: menus, combat, movement, inventory and saves, HUD and screen layouts, CRT, shops, interaction hints, arcade, floor travel |

```text
tests/
├── host/              Python unit and integration tests (test_*.py)
├── build/verify.csx   static checks on the compiled game
└── device/
    ├── run_device.py  runner: installs a disposable copy, launches it, collects the report
    ├── harness/       framework.gml, sequencer.gml, inject.csx
    ├── suites/        one file per feature area
    ├── captures/      screenshot modes
    └── run_village.py, village.csx   playable village preview (manual)
```

## Local and CI checks

From the repository root:

```sh
python3 -m unittest discover -v
python3 build.py --runtime-tests
bash -n installer/*.sh
```

The host suite uses temporary synthetic archives and needs no game files or third-party packages. CI runs it on Python 3.11 and 3.14. The build job uses Python 3.12 on Ubuntu 24.04. Actions use full commit pins, read-only repository permissions, and timeouts. Dependabot checks action pins monthly.

`build.py` verifies every cached input before use. `--utmt /path/to/UndertaleModCli` and `--upstream-zip /path/to/zeldadoi.zip` can reuse local downloads. A custom compiler path bypasses the compiler archive download check. Use version 0.9.2.0.

The compiler can exit successfully after a script exception. The build requires completion markers and an output file, then reloads the result for structural checks. The original game's audio alignment warning requires the CLI's verbose flag. The patch pins serialization to the older runner's format and verifies that the FUNC chunk includes a locals-table count. The tool can otherwise misidentify the empty upstream table as newer alignment padding and produce a file that crashes at startup.

`--check-release` requires the checked-in delta to reconstruct exactly the bytes from the clean source build. Branch and pull-request CI builds source and the device harness. Version-tag CI also checks the release delta and installer. Before publishing a tag, run `python3 build.py --check-release --runtime-tests` locally. CI uploads only `.build/build-report.json`. It never uploads full games, runtimes, saves, or instrumented builds.

## Device suite

### Running it

Close any running game first. The device needs this patch installed (or a 4:3-edition installation, which the runner reads from) and SSH access with a key or an existing control socket. The runner contains no credentials.

```sh
python3 build.py --runtime-tests
python3 tests/device/run_device.py root@your-device.local --control-path /path/to/socket
```

The runner creates a disposable game directory under `/storage/.cache/` with fresh saves and a temporary Ports launcher, launches it through EmulationStation, collects the report, removes the installation and checks that production save hashes are unchanged. It never switches the production game to a test build. If SSH disconnects before cleanup, remove the reported `doi-harness-*` directory and matching `DOI Harness *.sh` launcher after closing the test game.

It prints one line per suite and every failed test with its failed checks, and writes `report.json`, `junit.xml` and `game.log` to `--report-dir` (default `.build/device-results`). Other options:

| Option | Effect |
| --- | --- |
| `--suite WORD` | Runs only suites whose name contains the word; repeatable. The title and menu-exit suites always run because later contexts depend on them. |
| `--capture`, `--capture-profiles`, `--capture-updates`, `--capture-context`, `--capture-arcade` | Screenshot modes, see below |
| `--patch-version X.Y.Z` | Bundles a version file with the test game, as the installer does, so screenshots show a release version instead of `dev` |
| `--game PATH` | Another instrumented build, such as the baseline |

Inspect `game.log` even when every test passes. Some runs log a native `gmloadernext` segmentation fault after `###game_end###0`. The report verifies the tests, not a clean native shutdown.

### Structure

The instrumented build adds one object, `oNovaTests`. `inject.csx` concatenates the framework, every suite file in run order and the screenshot modes into its Create event, and the sequencer into its Step event. It fails the build when a suite file is missing from the run order. Only `runtime-tests.droid` and `runtime-baseline.droid` contain this object and the input substitution; packaging rejects both.

The framework follows the usual xUnit shape:

- A **suite** covers one feature area and names the game context it needs: `title`, `menu`, `menu-exit`, `gameplay`, or `travel` for multi-frame tests after gameplay.
- A **test** checks one behaviour and is named as a sentence ("closing rename discards the draft"). Table-driven tests loop over their cases inside one test and name the row in each check.
- A **check** is one expectation. A test passes when all its checks pass; a test without checks fails.
- `BeforeAll` arranges state a whole suite needs. Exceptions fail the current test, or the suite setup, and the run continues.
- `AsyncTest(name, start, step)` runs `step` every frame until it returns true.

The sequencer moves the game through the title, the adventure menu, back to the title, into a dungeon, and through floor and arcade travel. At each stage it runs the suites registered for that phase in file order.

The suites call compiled game events directly. `PressEvent` substitutes input at the input-query boundary, so a test presses Confirm by running the target's real Step event. Tests create real enemies, pots, chests, merchants and machines, and they check projectiles, timers, inventory, saves and menu state.

### Writing a test

Add it to the suite file for its feature, or create `tests/device/suites/<area>.gml` and add the name to the run order in `inject.csx`. Keep each test independent: create the instances it needs, destroy them, and restore any global it changes. GML methods do not capture locals, so tests share state only through instance variables with a suite prefix or through `BeforeAll`. Keep helper fixtures as named functions at the top of the file.

```gml
Suite("Pause menu", "gameplay", function() {
    Test("every close input resumes", function() {
        var pause = PauseOpen();
        PausePress(pause, "escape");
        Check("Escape resumes from the pause list", pause.Close && !pause.Quitting);
        PauseClose(pause);
    });
});
```

For a regression, add a test that fails through the affected game event before the fix.

### Coverage

| File | Suites | Covers |
| --- | --- | --- |
| `title.gml` | Title screen, Adventure menu exit | Title skip option, version label, Escape back to the title |
| `menus.gml` | Adventure menu navigation | Close, Back and Escape on every page; drafts, delete default, binding scans |
| `setup.gml` | Challenges, New adventure setup | Presets, custom mixes, Random, remembered setups, damaged records, layout and footers |
| `profiles.gml` | Player profiles, Players screen | Continue, partial hearts, player switching, rename, 64-bit play times, last-played dates, Cancel-first delete |
| `updates.gml` | Updates | Update states, stale responses, confirmation, cancellation, retry, restart, window bounds; the network worker is disabled |
| `options.gml` | Options | Tabs, toggles, device settings (including square pixels and integer scaling), volume, Defaults, remapping with swaps, Reset, timeout, Restore all, About, layout |
| `backports.gml` | Kinstones, Backported fixes, Progression, Floor travel | Upstream fixes, Moon Pearl, Treeman, Red Armos, Zora, templates, keys, rods; the floor 2-to-3 staircase through generation with both orientations and CRT settings |
| `movement.gml` | Movement and facing | Eight-frame SNES distances (12 px straight, 8 per diagonal axis walking; 10 and 6.5 carrying or sword-ready), the reconstructed [SNES facing routine](https://github.com/snesrev/zelda3/blob/fbbb3f967a51fafe642e6140d0753979e73b4090/src/player.c#L5932-L5967) with eight seeds, strafe, doorways, corner assistance, knockback, falls, wall sliding |
| `pause.gml` | Pause menu | Rows, Options and Controls under Paused, Cancel-first quits, Save Tent warning, run summary, every resume input |
| `enemies.gml` | Enemy status guards | Medusa, cannon and Pikit while frozen, stoned, paused or protected |
| `inventory.gml` | Inventory, Sword charge | Candle and lamp, gear slots, bags, overflow, migration, save/load; poke, spin readiness at exactly 48 updates, pause, falls, pots |
| `content.gml` | Recovered 1.2.1 items, Challenge effects, Wall Master | Gem recipes, Topaz save/load, challenge limits and legacy saves, Wall Master behaviour |
| `controls.gml` | Controller bindings, Inventory controls, Map controls | Nintendo A/B, remapped glyphs, keyboard keycaps, old profiles, inventory footers and paging, map dismissal |
| `hud.gml` | HUD scaling, Screen shapes, HUD visibility | Integer HUD pixels at eight resolutions, 4:3 playfield on 4:3, 16:9, 3:2, 5:3, 1:1 and 1440p screens, docked panels, square pixels, integer scaling, HUD through room transitions |
| `crt.gml` | CRT shader, CRT image, CRT performance | Compilation, black level, neutral grays, bloom, native-pixel sampling, stable phosphors, fallback, restored graphics state; frame times with CRT off and on |
| `shop.gml` | Shop | Closing every choice without buying, item information, insufficient funds, single charge on Buy |
| `context.gml` | Interaction hints, Interaction hint motion | Talk, Open, Lift, Throw, Read and Inspect against the real Interact result; read-only queries; 120 ms entrance, 100 ms exit and label changes at 30, 60 and 120 Hz |
| `arcade.gml` | Arcade slot machine, Arcade claw machine, Arcade doorways | Every slot roll, stakes and payouts, reel rendering against 1.2.1, wallet caps; claw pools, payment and refunds; walking through both doors |

The build verifier covers what needs no device: that prompts use the HUD layout, the HUD follows world scaling and restores filtering, the compositor draws into the playfield rectangle, the sword indicator uses the attack's readiness function, the interaction query stays read-only, and start screens size their views from the window.

### Screenshots

Screenshot modes run after the tests and report under the Screenshots suite. Menu modes take three consecutive samples, because remote captures can omit parts of a frame.

| Option | Captures |
| --- | --- |
| `--capture-profiles` | Adventure menu, setup, challenges, players, Details, Rename, the delete dialog, Options tabs including About, the Defaults dialog, gamepad and keyboard remapping, a remap in progress, Credits |
| `--capture-updates` | Update available and update error |
| `--capture` | Both of the above, then every inventory page, item actions and information, keyboard prompts, CRT, overflow and curse text, the map, the pause menu and its quit dialog, pause Options over the CRT, Status in four variants and the Status panels (docked on wide screens) |
| `--capture-context` | Talk, Open, Lift, a remapped button, the keyboard, and 96 motion frames at simulated 60 Hz |
| `--capture-arcade` | Pub, slot, claw and prize screens |

Review captures for clipping, overlap, spacing and incomplete frames on both a 4:3 and a 16:9 device. For inventory prompts, Close must keep its position and shoulder hints must stay fixed across all page titles, following [XAG 112's guidance on consistent prompt locations](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112). Remote screenshots can omit parts of a frame; recheck on the physical screen before treating that as a rendering defect.

### Baseline and limits

To show that the tests catch the original regressions:

```sh
python3 tests/device/run_device.py root@your-device.local \
  --game .build/runtime-baseline.droid \
  --report-dir .build/baseline-results
```

The baseline contains the unpatched 1.1.6 game with the same harness. It must fail on the behaviours the patch adds; review each failed test. Some original bugs end the run before the report completes; keep the partial report and the error in `game.log`. A launch error does not prove coverage.

GitHub-hosted CI compiles the device suite but cannot execute the device's ARM/GPU runtime. Before a release, run the suite on a 4:3 and a 16:9 device. Injected input does not verify physical controller mapping, rendering quality, audio, or an entire generated dungeon run, so also check on the device: B swings the sword, A interacts, menus confirm with A and close with B, the glyphs match the buttons that trigger them, Status toggling, shoulder paging, item actions, the pause layout, CRT mode, all three challenge pages, and Select + Start. Verify **Options > Updates** through the real launcher, and check the live release service separately; the updater downloads and verifies while the game runs, installs after it exits, and logs to `zeldadoi-beyond/update.log`.

## Playable village test

After a clean build, this command leaves a separate **DOI Village Test** entry in Ports and launches it:

```sh
python3 tests/device/run_village.py root@your-device.local --control-path /path/to/socket
```

The test starts outside the village arcade with 500 rupees and normal physical controls.

1. Walk through the entrance so the game records the return doorway.
2. Face the CLAW cabinet and press A. Move left/right and grab with A.
3. Leave the arcade and enter the pub to try Mothula's Money. Change bets with L/R.
4. Check both entrances and exits, repeated plays, insufficient funds, prize collection, audio, and B to close.

The slot rendering checks compare pixels before the CRT pass: title font and baseline, Bet/Spin buttons, payout suffixes, payline markers and reel-strip wrapping. They also require the CRT shader to compile on the device and produce a dark border with filtered interior pixels. Compare the final capture with the original 1.2.1 screen; a passing economy test does not establish visual parity.

Each launch starts a fresh village adventure in an isolated save directory. The script checks production save and backup hashes, disables the updater worker, and records the test paths in `.build/village-preview.json`. After closing the test, remove its `DOI Village Test.sh` launcher and the recorded `doi-village-*` directory. The build and release packager reject the preview object in production binaries.

## Versioning and release cadence

Use [SemVer-style](https://semver.org/spec/v2.0.0.html) version numbers for the patch, independently of the upstream game. Compatibility means existing installations can update and load saves, including through documented automatic migrations.

| Increment | Use for |
| --- | --- |
| Patch (`x.y.Z`) | Bug fixes and refinements to existing layout, controls, or installation |
| Minor (`x.Y.0`) | A planned batch of new gameplay features, modes, or substantial backports |
| Major (`X.0.0`) | Changes that break the documented installation or save compatibility contract |

Batch related work under **Unreleased** in [CHANGELOG.md](../CHANGELOG.md). A completed task, commit, or test run does not require a release. Publish routine fixes together after the batch passes verification. Publish a separate hotfix when an existing release has a serious crash, save, or installation problem.

Keep work-in-progress builds local. For shared testing, use a GitHub draft or an `-rc.N` prerelease for the intended version. Promote a tested batch to stable once it is ready. Documentation, release-note corrections, tests, and CI maintenance alone do not need an installer release or a version bump.

Published tags, version numbers, archives, and checksums stay unchanged. Correct release titles or notes when needed, without replacing their downloads. The next version describes the actual shipped changes, not the amount of development activity.

Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) for release notes. `CHANGELOG.md` is the source for GitHub release bodies. Each entry lists only changes since the preceding release, grouped under Added, Changed, or Fixed when useful. Omit empty groups and cumulative feature lists. Include save-migration details, known limitations introduced by the release, and a comparison link. Link to the installation guide instead of repeating it in every entry.

Use the title `vX.Y.Z: Short description` and copy that version's changelog section into the GitHub release body. Do not generate player-facing notes from raw commit subjects. Check the wording against the actual tag diff before publishing.

## Release procedure

1. Review the Unreleased changes, choose the increment using the policy above, and run unit tests and `python3 build.py --runtime-tests`.
2. Run the device suite on a 4:3 device (Nova) and a 16:9 device (Flip 2) and inspect any failures. Complete the physical-control and visual checks above.
3. Create the delta and patch-only installer with an unused version and output filename:

   ```sh
   read -r -p 'New patch version (without v): ' release_version
   python3 -m venv .build/patchenv
   .build/patchenv/bin/pip install -r requirements-build.txt
   .build/patchenv/bin/python package_release.py \
     --original-game .build/game.droid \
     --patched-game .build/patched.droid \
     --version "$release_version" \
     --output "dist/Dungeons-of-Infinity-and-Beyond-v${release_version}-Patch-Installer.zip"
   python3 build.py --check-release --runtime-tests
   ```

4. Move the shipped changelog entries from Unreleased to the chosen version, with the release date and comparison link.
5. Commit the source, tests, binary delta, manifest, and changelog together. Push and require the GitHub checks to pass before tagging a release.
6. Publish the matching changelog section, installer ZIP, and SHA-256 checksum. Never attach `.droid`, `.port`, `.build/`, test reports containing device data, or upstream downloads.

`package_release.py` writes a fixed allowlist of installer files with stable ZIP timestamps. It verifies binary-patch reconstruction and refuses an existing output filename. `installer/manifest.json` records the original game, patched game, delta, and upstream archive hashes.
