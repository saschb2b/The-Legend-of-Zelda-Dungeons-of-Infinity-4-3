# Dungeons of Infinity: 4:3 edition

A layout patch for the Retroid Nova running ROCKNIX. It uses the PortMaster **1.1.6 VM** build and a separate save folder from the Windows 1.2.1 edition.

## Install on the Nova

Install PortMaster on ROCKNIX before adding this edition.

1. Download the **Nova-ROCKNIX ZIP** from the [latest release](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/latest).
2. Extract the ZIP on your computer.
3. Copy both extracted items into the Nova's `/storage/roms/ports/` folder:

   ```text
   ports/
   ├── Zelda Dungeons of Infinity 4-3.sh
   └── zeldadoi-43/
   ```

4. Refresh the game list or restart EmulationStation, then launch **Zelda Dungeons of Infinity 4-3** from Ports.

The release includes the game, ARM64 runtime, libraries, and artwork. Saves go in `zeldadoi-43/savedata/`, which the game creates on first use. To update this edition, close it, merge the folders, and replace the supplied files. Keep the `savedata` folder.

## Controls and layout

The gameplay image fills the Nova's 1280×960 display. Panels start hidden for each run. Click the **right stick** to show or hide them over the playfield. Menus and dialogue temporarily hide the panels to keep their controls readable. **Select + Start** returns to Ports.

The title and profile menus retain their original layout. The game renders a 256×224 playfield inside a 400×225 canvas. The patch presents the complete playfield at 4:3, applying horizontal pixel aspect correction. Each HUD panel overlays its corresponding screen edge at 90% opacity. The CRT option processes the composed image.

| Panels hidden | Panels visible |
| --- | --- |
| ![Fullscreen playfield](screenshots/playfield.png) | ![HUD overlay](screenshots/overlay.png) |

The launcher selects Freedreno for this game and uses SDL's evdev controller backend. The release targets the Nova on ROCKNIX. Testing covers the Nova on ROCKNIX only.

## Build the release

Use Python 3.9 or newer, `unzip`, and [UndertaleModTool CLI 0.9.2.0](https://github.com/UnderminersTeam/UndertaleModTool/releases/tag/0.9.2.0). Create `.build/`, then download the pinned [PortMaster archive](https://github.com/PortsMaster-MV/PortMaster-MV-New/releases/download/2024-12-03_1532/zeldadoi.zip) to `.build/port.zip`. Run these commands from the repository root:

```sh
mkdir -p .build dist
unzip -p .build/port.zip zeldadoi/zeldadoi.port > .build/original.port
unzip -p .build/original.port assets/game.droid > .build/game.droid
/path/to/UndertaleModCli load .build/game.droid -s apply.csx -o .build/patched-game.droid -f -v
python3 repack.py .build/original.port .build/patched-game.droid .build/zeldadoi-43.port
python3 package_release.py --port-zip .build/port.zip --game-archive .build/zeldadoi-43.port --output dist/Dungeons-of-Infinity-4-3-v1.0.0-Nova-ROCKNIX.zip
```

Both Python tools require an unused output filename. `package_release.py` verifies the upstream archive and patched game data against the hashes below. A changed patch needs a new expected game hash after testing.

The verbose CLI flag permits a known audio alignment warning when reading the original game data. The patch recompiles five code entries and replaces only `assets/game.droid` inside the game archive. `apply.csx` decompiles the required entries directly, so it needs no exported game source. Build inputs and release archives stay outside Git.

| Input or output | SHA-256 |
| --- | --- |
| PortMaster ZIP | `cf13009f3f8f5578a17ca4a45de051ea1315280037f01434c187ebc9d9e91353` |
| Original game data | `d1c7f76420650d27d1abd6003657e81841efe5c28d35f012166a3ec4b981c047` |
| Patched game data | `39b86a7d8e5c212c3c44b3ae90545471aa79b1bce0a6d25532dd94d1f8f34d7f` |

## Verification and credits

Verified on the Nova: hidden HUD on a new run, right-stick overlay toggle, unobstructed inventory/map/pause screens, CRT output, and Select + Start exit. A clean rebuild produced identical game data and archive hashes. The release contains no test profiles or saves. Full campaign testing remains outstanding.

Justin Bohemier created Dungeons of Infinity. The [PortMaster package](https://github.com/PortsMaster-MV/PortMaster-MV-New/tree/main/ports/zeldadoi) supplies the game files and [GMLoader-next](https://github.com/JohnnyonFlame/gmloader-next) runtime. Upstream license files accompany the download in `zeldadoi-43/license/`.
