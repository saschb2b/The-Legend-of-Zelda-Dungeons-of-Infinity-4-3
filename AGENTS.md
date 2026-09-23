# AGENTS.md

## Project and scope

Dungeons of Infinity: 4:3 edition is a patch for the Retroid Nova on ROCKNIX. The base is PortMaster's **1.1.6 GameMaker VM** build, with selected 1.2.x backports. Patch release numbers are independent of the original game's versions.

Use Linux x86-64 and Python 3.11 or newer for builds. `build.py` downloads and verifies the pinned upstream package and UndertaleModTool CLI. The installer uses Python's standard library. Release packaging also needs `requirements-build.txt`.

Work from this repository's root. Check `git status` before editing and preserve unrelated changes. Keep generated games, native executables, decompilation dumps, saves, credentials and device logs out of commits and releases.

## Read before changing

| Task | Source of truth |
| --- | --- |
| Player experience, controls and installation | [README.md](README.md) |
| Builds, device tests, captures and releases | [docs/TESTING.md](docs/TESTING.md) |
| Backport coverage, recovered behavior and deliberate adaptations | [docs/BACKPORTS.md](docs/BACKPORTS.md) |
| Shipped changes and release notes | [CHANGELOG.md](CHANGELOG.md) |
| CRT provenance and tuning | [src/shaders/README.md](src/shaders/README.md) |

Read the relevant implementation too. If documentation disagrees with code, investigate the difference before repeating either claim.

## Repository layout

| Path | Contents |
| --- | --- |
| `build.py`, `package_release.py` | Build, verification and release packaging entry points |
| `src/apply.csx` | Compiler entry script; loads `content.csx`, `context.csx` and `arcade.csx` beside it |
| `src/data/` | Guarded upstream edits and recovered data: `backports.json`, `dungeon_fixes.json`, `content_1_2_1.json` |
| `src/gml/render/` | World composition, HUD and CRT: `composite.gml`, `hud.gml`, `crt.gml` |
| `src/gml/input/` | Bindings, glyphs and contextual hints: `controls.gml` |
| `src/gml/menus/` | Title-to-game flow, Options, updates and challenges: `adventure.gml`, `profiles.gml`, `options.gml`, `pause_cancel.gml`, `updates.gml`, `challenge_menu.gml` |
| `src/gml/inventory/` | Inventory behavior and presentation |
| `src/gml/gameplay/` | Combat and challenges: `sword.gml`, `gems.gml`, `challenges.gml`, `wallmaster_*.gml` |
| `src/gml/arcade/` | Village minigames, imported by `src/arcade.csx` |
| `src/shaders/` | CRT-Lottes port and its provenance |
| `assets/` | Imported art: controller glyphs, arcade resources, recovered content art |
| `installer/` | Everything the patch installer ships beside the player README: `install.py`, `updater.py`, `controller.py`, launchers, `gameinfo.xml`, `manifest.json`, `patches/game.droid.bsdiff` |
| `tests/` | Host tests (`test_*.py`), build verification (`verify.csx`), device runners and the runtime suite in `tests/runtime/` |
| `docs/` | Testing and release guide, backport audit, README screenshots |
| `tools/` | Manual helpers, such as `repack.py` for a local patched port |

`src/apply.csx` imports patch fragments into named GameMaker events. Treat `.gml` files as injected code: understand their event, instance scope and execution order before editing. Paths in the `.csx` scripts are relative to the repository root, where `build.py` runs the compiler.

## Patch implementation rules

- Make durable changes in tracked patch sources. Rebuild from the pinned original. Editing `.build/patched.droid` alone is not a reproducible fix.
- Keep replacement anchors exact and unique. A missing or repeated anchor must fail the build. Do not bypass hash or structural checks to make an edit compile.
- Preserve the GameMaker serialization version and FUNC locals-table handling unless deliberately changing the supported runtime.
- Use `build.py` for compilation. The CLI can exit successfully after a script error. Require completion markers and output verification.
- Inspect every caller before changing a shared GML function. Check object inheritance, constructor fields, instance lifetime and cleanup paths.
- Do not assume every caller has an item `Class` field. `Item_SetIndex` also serves Kinstone pedestals. Keep candle-specific behavior scoped to candles.
- Put behavior changes in Step events or shared state functions. Draw calls and contextual-hint queries must not advance gameplay or consume input.
- Restore shader, texture-filtering, blend, alpha and alignment state after drawing when the code changes them.
- Preserve saved item identities, inventory quantities and overflow access. Format changes need migration, save/load tests and installer backup coverage.

## Controls and presentation

Preserve these decisions unless the requested change explicitly revises them:

- Nintendo button layout: **A interacts and confirms. B swings the sword and closes menus.** Shop entry uses A. B must close without submitting or buying.
- Menu Confirm, Back and Pause use the fixed verbs `nova_confirm`, `nova_back` and `menu_access`. Remapping gameplay actions must never move them. The remapper changes one action at a time, swaps on conflict and marks bindings that differ from `__input_config_verbs()`.
- Resolve prompts from the current action binding, including remapped controls and keyboard input. Keep physical controller translation separate from logical game actions.
- Use the checked-in **Kenney Nintendo Switch 2/Double** glyphs. Retain their filenames, checksums and license. Do not redraw or invent replacements.
- Place action hints at the bottom right, label before glyph. A precedes B Close. Keep L/R beside page headings and reserve space for the longest label.
- Size gameplay, inventory, map and arcade prompts from `NovaHUDLayout`. Anchor footer rows to its `right`, `footer_y` and `footer_width`. Keep page glyphs beside their headings on whole screen pixels. Title and adventure menus use their own scale.
- Keep one Options screen, `src/gml/menus/options.gml`, for the adventure and pause menus. Settings apply immediately and explain themselves below the list. Defaults restores one tab after confirmation. Nested pages keep the tab strip, name their parents in the header breadcrumb and label B as **Back**. Confirmations open as a dialog over the page they affect. Pause draws the screen after the CRT pass.
- Use **Status** for the collapsible HUD panels and **Close** for dismissal. Actions, Equip and Use have distinct meanings documented in the README.
- New adventure (`src/gml/menus/setup.gml`) keeps Begin one press away and explains the highlighted choice. Challenge presets are Hero's Path, Second Quest and Master Quest. Each player's last setup is stored as plain numbers under `[Setup]` in `nova-menu.ini`, because ini values cannot hold JSON. Last-played dates share that file under `[LastPlayed]`. Player cards and Details live in `src/gml/menus/players.gml`; Delete stays on Details and always opens a Cancel-first dialog.
- Keep the centered title logo, then transition to the adventure menu. Continue resumes the selected player's save. Keep setup within one active frame.
- Match the game's existing fonts, sprites and window frames. Use original artwork for backports and record its provenance. Distinguish recovered behavior from patch adaptations.
- Preserve the complete 256×224 playfield and its 4:3 pixel-aspect correction. Render the HUD separately at an integer scale with square pixels, 3× on the Nova.
- Keep four-digit rupees and full heart rows visible. Keep the HUD visible through room travel. Suppress contextual actions when the player cannot use them.
- Render HUD and gameplay hints after the world CRT pass. Arcade machines retain their own effect. The gameplay shader is CRT-Lottes.

SNES alignment is selective. Preserve DOI's combat balance, spin duration, hitboxes and protection after damage unless the user requests changes. Consult the backport audit before extending alignment to another system.

## Verification

Run checks appropriate to the files and behavior changed:

| Change | Required checks |
| --- | --- |
| Documentation only | Check referenced paths, commands, claims and `git diff --check` |
| Python, installer, updater or controller adapter | `python3 -m unittest discover -v` |
| Shell launchers | `bash -n installer/*.sh`, plus affected installation or device behavior |
| GML, shader, resource import or patch data | Unit suite, `python3 build.py --runtime-tests`, then affected device cases |
| Release package | Full device suite and `python3 build.py --check-release --runtime-tests` after packaging |

`--check-release` compares the checked-in release delta with a clean source build. During development, use `--runtime-tests`. Repackage before checking a changed release delta.

For regressions, add a test that fails through the affected game event, then verify the fix and neighboring behavior. A floor-generation fix needs actual generation and transition coverage. Test cancellation, remapping, save/load or vanished instances when the change affects those paths.

GitHub CI runs host tests and compiles the device suite. It **does not execute the Nova runtime**. Compilation also cannot prove GPU shader support, physical button mapping or visual quality. Report those limits if device validation is unavailable.

## Device work and crash investigation

Use an authenticated SSH key or existing control socket. Keep device addresses and credentials in local session context, not this file.

```sh
python3 build.py --runtime-tests
python3 tests/run_device.py root@your-device.local \
  --control-path /path/to/socket \
  --report-dir .build/device-results
```

Confirm the device is idle before testing or replacing files. Do not terminate a player's active run to make room for tests. The runner checks EmulationStation's `runningGame` endpoint and creates a disposable installation with fresh saves.

- Production lives in `/storage/roms/ports/zeldadoi-43`. Game code is `assets/game.droid` inside `zeldadoi.port`.
- Preserve `savedata/` and `save-backups/`. Verify save hashes around deployment. Install only the verified production build, never an instrumented test or village-preview build.
- After a crash, preserve `log.txt` and the relevant saves locally before relaunching. Read the first error and call chain before attributing it to the latest visible change.
- Reproduce with isolated fixtures or a private copy of the affected save. Keep the regression report and crash log under ignored `.build/`.
- Before a test fixture generates another floor, activate all instances so `Dungeon_Clear` can remove dormant enemies. Follow normal floor travel's cleanup sequence.
- Use `--capture`, `--capture-context`, `--capture-arcade`, `--capture-profiles` or `--capture-updates` for the relevant screen. Inspect captures for clipping, spacing and incomplete frames.
- Remote screenshots can omit parts of a frame. Recheck on the physical screen before treating that artifact as a rendering defect.

Use the cleanup and playable-village instructions in [docs/TESTING.md](docs/TESTING.md) for interrupted runs or manual minigame testing. Keep user playtesting separate from production saves.

## Releases and documentation

Group development changes under **Unreleased**. Use patch versions for fixes and refinements, and minor versions for substantial gameplay additions. Avoid a release for every individual adjustment.

When the user requests or has already authorized publication, follow [the release procedure](docs/TESTING.md#release-procedure). Finish the build, device checks and package verification before tagging.

- Generate `installer/manifest.json` and the binary delta with `package_release.py`. Do not hand-edit their hashes. Use an unused output filename.
- Publish only the patch installer ZIP and its SHA-256 checksum. Preserve the package allowlist and upstream hash checks. Never attach full games, runtimes or instrumented builds.
- Keep published tags and downloads immutable unless the user explicitly requests replacement. Normally, ship corrections as the next patch version.
- Commit source, tests, delta, manifest and release notes together. Require GitHub checks to pass before tagging. Tag CI also verifies the release delta.
- Derive release notes from the matching changelog entry. Describe changes since the previous release and any save implications. Do not claim complete 1.2.1 parity.
- Use authentic device captures for screenshots, with comparable states for before/after images. Pin release-note image links to the release tag.
- After publication, verify the download checksum, screenshot links and updater selection from the preceding version.

Keep the README focused on the player: presentation, installation and controls before technical detail. Update the backport audit when coverage or provenance changes. Keep private device history and other installed games out of public documentation.

When handing off, state what changed, which checks ran and what remains unverified. State whether you deployed, committed or published the change.
