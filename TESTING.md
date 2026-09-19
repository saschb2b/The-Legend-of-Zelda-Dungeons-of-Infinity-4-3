# Testing and releases

The harness has three layers. Each catches a different failure:

| Layer | Runs on | Checks |
| --- | --- | --- |
| Unit and installer integration | Python, no downloads | BSDIFF decoding, checksum failures, interrupted downloads, save preservation, repeated installation, archive traversal, release contents, compiler failure detection |
| Clean build | Linux x86-64 | Pinned upstream and compiler hashes, exact patch anchors, GML compilation, compiled room and code invariants, production/test separation, release delta equality, installation of the real package |
| Runtime regression | Nova with ROCKNIX | Real GameMaker menu, title, pause, Medusa, cannon, and Pikit events with controlled inputs and fixtures |

## Local and CI checks

From the repository root:

```sh
python3 -m unittest discover -v
python3 build.py --check-release --runtime-tests
bash -n ./*.sh
```

The unit suite uses temporary synthetic archives and needs no game files or third-party packages. CI runs it on Python 3.11 and 3.14. The build job uses Python 3.12 on Ubuntu 24.04. Actions use full commit pins, read-only repository permissions, and timeouts. Dependabot checks action pins monthly.

`build.py` verifies every cached input before use. `--utmt /path/to/UndertaleModCli` and `--upstream-zip /path/to/zeldadoi.zip` can reuse local downloads. A custom compiler path bypasses the compiler archive download check. Use version 0.9.2.0.

The compiler can exit successfully after a script exception. The build requires completion markers and an output file, then reloads the result for structural checks. The original game's audio alignment warning requires the CLI's verbose flag.

`--check-release` requires the checked-in delta to reconstruct exactly the bytes from the clean source build. During development, omit that flag until you regenerate the delta. CI uploads only `.build/build-report.json`. It never uploads full games, runtimes, saves, or instrumented builds.

## Nova runtime suite

Close any running game first. Install this patch on the device and enable SSH access. Use a key or an existing SSH control socket. The harness contains no credentials.

```sh
python3 build.py --runtime-tests
python3 tests/run_device.py root@your-device.local
```

Optional arguments include `--control-path /path/to/socket`, `--ports-dir /storage/roms/ports`, and `--report-dir .build/device-results`.

The runner creates a disposable game directory under `/storage/.cache/`, with fresh saves, and a temporary Ports launcher. It launches through EmulationStation and runs the suite automatically. It writes the JSON assertion report and game log locally, removes the disposable installation, and compares production save hashes. It never switches the production game to a test build. If SSH disconnects before cleanup, remove the reported `doi43-harness-*` directory and matching `DOI43 Harness *.sh` launcher after closing the test game.

The suite calls the compiled game events. It substitutes input at the input-query boundary, creates actual enemy instances, and checks projectiles, timers, inventory, menu state, and profile contents. It tests recovery and normal behavior as well as blocked actions. The test object and input substitution exist only in `runtime-tests.droid` and `runtime-baseline.droid`. Packaging rejects either test build.

To show that the assertions catch the original regressions:

```sh
python3 tests/run_device.py root@your-device.local \
  --game .build/runtime-baseline.droid \
  --report-dir .build/baseline-results
```

The baseline contains the unpatched 1.1.6 game with the same instrumentation. That command must fail on the behaviors the patch adds. Review each named failure. A launch error does not prove regression coverage.

GitHub-hosted CI compiles the runtime suite but cannot execute the Nova's ARM/GPU runtime. Before releasing, run the suite on a device. Also check the physical confirm/cancel buttons, title animation, R3 panel toggle, pause layout, CRT mode, and Select + Start. Injected input does not verify physical controller mapping, rendering quality, audio, or an entire generated dungeon run.

## Release procedure

1. Run unit tests and `python3 build.py --runtime-tests`.
2. Run the Nova suite and inspect any failures. Complete the physical-control and visual checks above.
3. Create the delta and patch-only installer with an unused version and output filename:

   ```sh
   python3 -m venv .build/patchenv
   .build/patchenv/bin/pip install -r requirements-build.txt
   .build/patchenv/bin/python package_release.py \
     --original-game .build/game.droid \
     --patched-game .build/patched.droid \
     --version 1.3.0 \
     --output dist/Dungeons-of-Infinity-4-3-v1.3.0-Nova-Patch-Installer.zip
   python3 build.py --check-release --runtime-tests
   ```

4. Commit the source, tests, binary delta, and manifest together. Push and require the GitHub checks to pass before tagging a release.
5. Publish only the installer ZIP and its SHA-256 checksum. Never attach `.droid`, `.port`, `.build/`, test reports containing device data, or upstream downloads.

`package_release.py` writes a fixed allowlist of installer files with stable ZIP timestamps. It verifies binary-patch reconstruction and refuses an existing output filename. `manifest.json` records the original game, patched game, delta, and upstream archive hashes.
