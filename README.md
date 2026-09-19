# Dungeons of Infinity: 4:3 edition

A 4:3 layout patch for the Retroid Nova running ROCKNIX, based on the PortMaster **1.1.6 VM** build.

The title screen fills the display while keeping the logo's proportions. Profile menus use the full screen and keep every control visible. During gameplay, a persistent HUD shows health, magic, the equipped item, rupees, bombs, arrows, and keys. Compact side panels start hidden.

Backports from the 1.2.x releases add inventory compartments, sword poke/spin, Topaz, revised gem recipes, variable challenges, and a Wallmaster mode. They also include crash, progression, and control fixes. [BACKPORTS.md](BACKPORTS.md) lists the implemented changes, adaptations, and remaining gaps.

[CHANGELOG.md](CHANGELOG.md) records changes between patch releases. Patch version numbers are independent of the original game's versions.

## Install on the Nova

Install PortMaster on ROCKNIX and connect the Nova to Wi-Fi.

1. Download the **Nova patch installer ZIP** from the [latest release](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-4-3/releases/latest).
2. Extract the ZIP and copy both items into `/storage/roms/ports/`:

   ```text
   ports/
   ├── Install Zelda Dungeons of Infinity 4-3.sh
   └── zeldadoi-43-installer/
   ```

3. Refresh the game list and run **Install Zelda Dungeons of Infinity 4-3** from Ports.
4. Wait for installation to finish, then launch **Zelda Dungeons of Infinity 4-3**.

The download contains an installer and binary patches, including artwork changes. It contains no standalone game or runtime. The installer downloads the official PortMaster package, verifies its checksum, and applies the patch locally. Allow about 300 MiB of free space for installation.

Saves go in `zeldadoi-43/savedata/`. To update, close the game, replace the installer files with the latest release, and run the installer again. It preserves existing saves. Installation failures appear in `zeldadoi-43-installer/install.log`.

The installer keeps backups in `zeldadoi-43/save-backups/`. The first inventory update creates `before-inventory-v1.zip`. Updating to patch 1.5.0 also creates `before-content-v3.zip`, preserving the saves before Topaz and variable challenges. Reinstallation keeps both backups intact. Existing inventory migrates on load, with excess items available on an overflow page. Keep the backups to return to an earlier patch.

## Controls and layout

The HUD follows the classic Zelda layout. The vertical magic meter sits beside the equipped item, counters align beneath their icons, and hearts sit beneath LIFE. It uses the game's icons, live values, item quantities, and low-health pulse. The layout keeps Dungeons of Infinity's four-digit rupee counter and its separate key counter.

Click the **right stick** to show or hide equipment, attack/defence, the minimap, and dungeon progress. These panels sit below the HUD and start hidden for each run. A small **R3 STATUS** hint appears at the bottom right while the panels are hidden. Menus and dialogue hide the HUD, hint, and panels to keep their controls readable. **Select + Start** returns to Ports.

Press the **action button** to back out of a menu, or **Escape** on a keyboard. In name entry, the action button still deletes a letter and Escape cancels the edit. From a pause submenu, cancel returns to the pause menu. From the pause menu itself, cancel resumes play.

Press **Start** or the confirm button to skip the opening title animation. To require the full animation, create `zeldadoi-43/savedata/options.ini` with `[Preferences]` and `CanSkipTitle=0`. Set it to `1` to allow skipping. If you already have that file, add the key to its Preferences section.

The inventory separates equipment from the main bag. You start with five main slots and can add five more. Food and pendant bags each hold three items. The treasure bag also accepts wishstones. Press **Strafe** to advance pages, or move up to the heading and use left/right. Sword selects an item, Item equips it, and Action goes back.

The starting candle occupies the light slot. Drop it for a darker challenge, or replace it with an oil lamp. Topaz joins the nine existing gems, with all 55 gem recipes from 1.2.1. Food bags, pendant bags, and the master key use the newer artwork.

Before starting a run, open **Challenges** to adjust hearts, defence, darkness, starting slots, rupee limits, shop prices, enemy crowds, and curses. The last page offers **No map**, **No food**, and **Wall Master**. Confirm cycles a value, left/right cycles in either direction, and **Next page** moves between the three pages. Reduced starting inventory still upgrades to ten slots. Older saved runs keep their original challenge restrictions.

Hold **Sword** after a swing to poke while moving. With a level-three sword or higher, keep holding until the blade flashes, then release for a spin. Level-two swords can break pots.

Frozen or stoned Medusas and cannons cannot fire. Their attacks resume when the status ends. Pikits cannot steal items while Link falls into a pit or over an edge. Keyboard remapping includes Menu and all four directions. An aborted remap restores the previous bindings.

The title screen uses a centered 300×225 view. Profile menus use a taller 400×300 view with a tiled background. Gameplay presents the complete 256×224 playfield at 4:3 with horizontal pixel aspect correction. The side panels use 75% scale and 90% opacity. The CRT option processes the playfield and HUD together.

The renderer draws the control hint at screen resolution so its R3 glyph stays readable, including with CRT enabled.

| Title screen | Profile menu |
| --- | --- |
| ![4:3 title screen](screenshots/title.png) | ![4:3 profile menu](screenshots/profile.png) |

| Panels hidden | Panels visible |
| --- | --- |
| ![Fullscreen playfield](screenshots/playfield.png) | ![HUD overlay](screenshots/overlay.png) |

The launcher selects Freedreno and SDL's evdev controller backend. Testing covers the Retroid Nova on ROCKNIX.

## Rebuild the patch

On Linux x86-64, use Python 3.11 or newer:

```sh
python3 -m unittest discover -v
python3 build.py --check-release --runtime-tests
```

The build downloads the pinned PortMaster package and UndertaleModTool CLI 0.9.2.0, checks both SHA-256 hashes, and compiles the patch. It then verifies the checked-in binary delta against the clean build and tests installation and reinstallation. Build inputs and full game archives stay in `.build/`, outside Git.

[TESTING.md](TESTING.md) documents the CI checks, isolated Nova runtime suite, regression baseline, and release procedure. GitHub Actions runs the unit suite and build checks on pushes and pull requests. Runtime assertions run separately on a Nova.

The installer needs only Python's standard library, which ROCKNIX includes. The release builder uses the pinned dependency in `requirements-build.txt`.

## Credits

Justin Bohemier created Dungeons of Infinity. The [PortMaster package](https://github.com/PortsMaster-MV/PortMaster-MV-New/tree/main/ports/zeldadoi) supplies the game files and [GMLoader-next](https://github.com/JohnnyonFlame/gmloader-next) runtime during installation. The installer preserves the upstream license files in `zeldadoi-43/license/`. The release builder uses [bsdiff4](https://pypi.org/project/bsdiff4/) to create the binary patch.

The R3 glyph comes from the supplied controller icon pack's `P4Gamepad/Default/T_P4_R3.png`. `assets/right-stick-click.png` contains an unchanged copy.
