# Testing and releases

Testing has three layers. Each catches a different failure:

| Layer | Runs on | Checks |
| --- | --- | --- |
| Unit and installer integration | Python, no downloads | BSDIFF decoding, checksum failures, interrupted downloads, save preservation, repeated installation, archive traversal, release contents, compiler failure detection, inventory-save backup, runner binary format |
| Clean build | Linux x86-64 | Pinned upstream and compiler hashes, exact patch anchors, GML compilation, compiled room and code invariants, production/test separation, release delta equality, installation of the real package |
| Runtime regression | Nova with ROCKNIX | Real GameMaker menus, combat, inventory migration, Topaz and challenge save/load, gem recipes, challenge limits, Wallmaster attacks, dungeon templates, and enemy status events |

## Local and CI checks

From the repository root:

```sh
python3 -m unittest discover -v
python3 build.py --check-release --runtime-tests
bash -n ./*.sh
```

The unit suite uses temporary synthetic archives and needs no game files or third-party packages. CI runs it on Python 3.11 and 3.14. The build job uses Python 3.12 on Ubuntu 24.04. Actions use full commit pins, read-only repository permissions, and timeouts. Dependabot checks action pins monthly.

`build.py` verifies every cached input before use. `--utmt /path/to/UndertaleModCli` and `--upstream-zip /path/to/zeldadoi.zip` can reuse local downloads. A custom compiler path bypasses the compiler archive download check. Use version 0.9.2.0.

The compiler can exit successfully after a script exception. The build requires completion markers and an output file, then reloads the result for structural checks. The original game's audio alignment warning requires the CLI's verbose flag. The patch pins serialization to the older runner's format and verifies that the FUNC chunk includes a locals-table count. The tool can otherwise misidentify the empty upstream table as newer alignment padding and produce a file that crashes at startup.

`--check-release` requires the checked-in delta to reconstruct exactly the bytes from the clean source build. During development, omit that flag until you regenerate the delta. CI uploads only `.build/build-report.json`. It never uploads full games, runtimes, saves, or instrumented builds.

## Nova runtime suite

Close any running game first. Install this patch on the device and enable SSH access. Use a key or an existing SSH control socket. The test runner contains no credentials.

```sh
python3 build.py --runtime-tests
python3 tests/run_device.py root@your-device.local
```

Optional arguments include `--control-path /path/to/socket`, `--ports-dir /storage/roms/ports`, and `--report-dir .build/device-results`. Add `--capture` to save screenshots of all seven inventory categories, item actions and information, keyboard prompts, CRT mode, and a second overflow page after the assertions. Status captures cover the default binding, CRT mode, a remapped button, and keyboard input. Review the screenshots for clipping, HUD overlap, and incomplete frames. The harness does not compare pixels.

The runner creates a disposable game directory under `/storage/.cache/`, with fresh saves, and a temporary Ports launcher. It launches through EmulationStation and runs the suite automatically. It writes the JSON assertion report and game log locally, removes the disposable installation, and compares production save hashes. It never switches the production game to a test build. If SSH disconnects before cleanup, remove the reported `doi43-harness-*` directory and matching `DOI43 Harness *.sh` launcher after closing the test game.

The suite calls the compiled game events. It substitutes input at the input-query boundary, creates actual enemy instances, and checks projectiles, timers, inventory, menu state, and profile contents. It tests recovery and normal behavior as well as blocked actions. Control cases cover remapped button and stick glyphs, alternate and empty bindings, old profile imports, shoulder-page wrapping, contextual action labels, simultaneous inputs, item-information closure, and map dismissal. The test object and input substitution exist only in `runtime-tests.droid` and `runtime-baseline.droid`. Packaging rejects either test build.

Movement tests measure displacement through Link's compiled Step event over eight frames in all eight directions, including walking, running, carrying, and sword-ready movement. They also check opposing inputs, strafe, doorway speed limits, corner assistance, scripted movement, knockback, and falls. Real wall instances check blocked movement and sliding on all four sides. Walking expectations use the SNES values directly: 12 pixels straight or 8 per diagonal axis across eight frames. The tests use fresh saves in the starting clearing.

To show that the assertions catch the original regressions:

```sh
python3 tests/run_device.py root@your-device.local \
  --game .build/runtime-baseline.droid \
  --report-dir .build/baseline-results
```

The baseline contains the unpatched 1.1.6 game with the same instrumentation. That command must fail on the behaviors the patch adds. Review each named failure. Some original bugs terminate the runner before the report can complete. Retain the partial assertion report and the named error in `game.log`. A launch error does not prove regression coverage.

GitHub-hosted CI compiles the runtime suite but cannot execute the Nova's ARM/GPU runtime. Before releasing, run the suite on a device. Also check the physical confirm/cancel buttons, title animation, remapped Status toggling, shoulder paging, item actions and information, pause layout, CRT mode, and Select + Start. Verify that the glyph matches the button that actually triggers each action. Inspect all three challenge pages, including the longest values and returning to the start menu. Runtime assertions measure the text columns and window bounds, but screenshots still need review. Injected input does not verify physical controller mapping, rendering quality, audio, or an entire generated dungeon run.

For inventory prompts, compare empty slots, equipment, usable items, action lists, and item information. Close must retain its position throughout. Shoulder hints must stay fixed across all page titles, including both overflow pages. Check remapped buttons and keyboard keycaps for overlap. This follows [XAG 112's guidance on consistent prompt locations and order](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112). The specific Equip / Close / primary-action row is a design choice for this compact layout.

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
