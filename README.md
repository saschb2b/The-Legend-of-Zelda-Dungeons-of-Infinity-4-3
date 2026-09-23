# Dungeons of Infinity and Beyond

**The full dungeon on your handheld, whatever its screen.**

Play Dungeons of Infinity fullscreen on ROCKNIX handhelds, with a classic Zelda HUD and a layout that fits 4:3, 16:9 and other screens. Health, magic, your active item and supplies stay in view. Equipment, the map and dungeon progress sit beside the playfield on wide screens and open over it on 4:3 screens.

[**Download the installer**](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-and-Beyond/releases/latest) · [Installation](#install) · [Screens](#screens) · [Controls](#controls) · [What's changed](CHANGELOG.md)

![Dungeons of Infinity on a 16:9 Retroid Pocket Flip 2, with equipment, pendants and crystals left of the playfield and the minimap and floor progress to its right](docs/screenshots/widescreen.png)

- The complete playfield keeps its SNES shape on every screen. The title and menus fill wide screens.
- Status panels sit beside the playfield where they fit, as in the original 16:9 game.
- Display options for a CRT effect, square pixels and integer scaling.
- Selected updates from the newer game include inventory bags, sword poke and spin, Topaz, adjustable challenges, and Wallmaster mode.
- Visit the village arcade for the claw machine, or play Mothula's Money in the pub.

## Install

You need a ROCKNIX handheld with at least 4 GB of RAM, PortMaster, Wi-Fi, and about 300 MiB of free space. The game is tested on the Retroid Nova (4:3) and Retroid Pocket Flip 2 (16:9); other Qualcomm-based ROCKNIX handhelds share their graphics driver.

1. Download the **patch installer ZIP** from the [latest release](https://github.com/saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-and-Beyond/releases/latest).
2. Extract the ZIP and copy both items into `/storage/roms/ports/`:

   ```text
   ports/
   ├── Install Zelda Dungeons of Infinity and Beyond.sh
   └── zeldadoi-beyond-installer/
   ```

3. Refresh the game list and run **Install Zelda Dungeons of Infinity and Beyond** from Ports.
4. Wait for installation to finish, then launch **Zelda Dungeons of Infinity and Beyond**.

The installer downloads the official PortMaster package and applies the patch automatically. You do not need to download or patch game files yourself.

**Updating:** close the game, replace the installer files with the newer download, and run the installer again. Your saves stay in `zeldadoi-beyond/savedata/`. The installer preserves them and keeps migration backups in `zeldadoi-beyond/save-backups/`.

An installation in `zeldadoi-43`, from a release before 2.0.0, cannot update in the game. Run this installer once: it moves the game and all saves to `zeldadoi-beyond` and removes the old launcher and installer.

For updates over Wi-Fi, choose **Options > About > Updates** from the adventure menu. It shows the installed and available patch versions and the changes since your version. Use L/R to page through the notes. Choose **Install update** to download the update and restart the game. Press **B** to close or cancel a download.

The updater checks stable releases only when you open Updates or choose Check again. It verifies downloads before installation and preserves your saves. If installation fails, the previous version remains available. Keep the device powered on during installation.

If installation fails, check `zeldadoi-beyond-installer/install.log`. For another attempt, run the installer again.

## Screens

The playfield always shows the full 256×224 picture in the SNES's 4:3 shape. On other screen shapes it is centered with black borders, and the HUD and button hints stay on the playfield.

| Screen | Examples | Status panels |
| --- | --- | --- |
| 4:3 | Retroid Nova, Retroid Pocket Mini | Open over the playfield with the right stick |
| Taller than 4:3 | AYANEO Pocket DMG, Retroid Pocket Mini V2 | Open over the playfield; borders above and below |
| 3:2 | AYANEO Pocket ACE | Open over the playfield; narrow side borders |
| 16:9 and 5:3 | Retroid Pocket 5, Flip 2 and 6, AYN Odin 2, RG552 | Beside the playfield, shown from the start; the right stick hides them |

![Dungeons of Infinity on a 4:3 Retroid Nova, with the classic HUD and Status button hint](docs/screenshots/playfield.png)

The title shows its full scene on wide screens, and the menus extend their landscape to the edges. The title and adventure menu show the installed version at the bottom left, and **Options > About** lists it with the base game version.

Under **Options > Display**, **Square pixels** draws game pixels square instead of slightly wide, which narrows the playfield. **Integer scaling** gives every pixel row the same height, with wider borders. Both apply to the whole device. **CRT effect** adds scanlines, a phosphor grille and soft bloom to the playfield and is saved for each player.

## Controls

These are the default controller bindings. Change them under **Options > Controls**, from the adventure menu or the pause menu. Each button hint follows your current mapping, including keyboard bindings.

![Gamepad remapping grouped by Combat and World, with two changed actions marked and the default shown](docs/screenshots/controls.png)

| Button | During play | In the inventory |
| --- | --- | --- |
| D-pad / left stick | Move | Highlight an object or action |
| A | Interact | Open Actions, open a bag, or confirm the highlighted action |
| B | Sword | Close the current view |
| X | Use the equipped item | Equip the highlighted object, when available |
| Y | Open the map | |
| Start | Open the inventory | Close the inventory |
| Select | Pause | Close the inventory |
| Right-stick click | Show or hide Status | |
| L / R | | Previous / next inventory page |
| Select + Start | Exit to Ports | Exit to Ports |

![Pause menu with Resume, Options and Controls above Start over and the quit options, a run summary with floor, hearts, bonus, challenges and an active curse, and the Save Tent warning](docs/screenshots/pause.png)

The pause menu (Select) shows your run: floor, time, hearts, bosses, bonus, challenges and any curse. **Resume**, **Options** and **Controls** come first; **Start over**, **Quit to title** and **Quit to desktop** sit below a divider and ask before acting. The game saves only at Save Tents, so quitting says that progress since the last tent is lost. **Controls** opens your current button mapping directly.

Press **B** to close the map, menus, item information, or inventory. Closing an action list or item information returns to the inventory. Closing a pause submenu returns to the pause menu. In name entry, B closes without saving. Choose **Erase letter** to delete a character. On a keyboard, Escape closes or cancels the current view.

At a shop counter, press **A** to inspect an item. In its dialog, A confirms the highlighted choice and **B** closes without buying. Closing also works while reading item information or a purchase refusal.

During play, a hint beside **Status** names the interaction within reach: **Talk**, **Open**, **Lift**, or **Throw** while carrying. Signs show **Read** and shop goods show **Inspect**. The hint follows your Interact binding and disappears when you turn away, open a menu, or lose control during an animation or room transition.

**Actions** opens an object's choices. **Equip** assigns it to the active item button. **Use** activates or consumes it immediately. Gear in dedicated equipment slots is already active. Its action list provides information and, where allowed, Drop.

Use **L/R** to switch inventory pages, or **Page Up/Page Down** on a keyboard. The D-pad stays in the item grid. Health and counters remain visible while browsing or reading item information.

Input hints sit together at the bottom right, with each action label followed by its button. The primary action (A) comes before Close (B), which stays at the far right. Equip and the current action keep fixed positions as inventory contents and labels change. L/R stays beside the page heading, with room reserved for the longest title.

| Inventory below the HUD | Contextual item actions |
| --- | --- |
| ![Compact bag inventory below health and counters, with Switch 2 button hints below the frame](docs/screenshots/inventory.png) | ![Item action list with a confirm hint that names the highlighted Info action](docs/screenshots/inventory-actions.png) |

Inventory and menu screenshots use test saves to show progress and full inventories. They come from a Retroid Nova (4:3); the wide-screen view comes from a Retroid Pocket Flip 2.

| Status on a 4:3 screen | Continue your adventure |
| --- | --- |
| ![Equipment, map, and dungeon progress over the playfield](docs/screenshots/overlay.png) | ![Adventure menu with the saved name and floor beneath Continue and the installed version at the bottom left](docs/screenshots/profile.png) |

The title screen leads into an adventure menu with your last selected player. Their name and floor sit beneath **Continue**, which resumes the saved run in one press. **New adventure** shows your character beside the bonus and challenges, with a line below explaining the highlighted choice. Press **A** on any row except Challenges to begin, and **Begin adventure** is selected by default. **Random** picks another character. Each player's last setup is remembered. A fresh player starts as Link, with no required name entry.

![New adventure with a character preview, Wooden Shield bonus, the Second Quest challenge preset with its level meter and icons, and Begin adventure](docs/screenshots/adventure-setup.png)

![Players as cards with character, floor, play time, challenge level, hearts, wins and deaths, and a New player card](docs/screenshots/players.png)

**Change player** shows each player as a card with their character, floor, play time, hearts, wins and deaths, and it opens on the current player. The line below says when each player last played. Select a player to return to their adventure, or press **Details** for their full records, **Rename** and **Delete player**. Deleting asks first, with Cancel selected, and names the run that will be erased. When renaming, L erases a letter and R adds a space. Starting over an existing save asks for confirmation. Options, controls, updates and credits are available before entering the dungeon.

![Options on the Display tab with CRT effect, Square pixels, Integer scaling and Blood and remains, and a description of the selected setting](docs/screenshots/options.png)

**Options** opens the same screen from the adventure menu and the pause menu. L/R switch between Game, Display, Audio and Controls, and left/right changes the highlighted setting. **Display** holds the CRT effect, **Square pixels** and **Integer scaling**. Changes apply immediately, and a line below the list explains each setting. **Defaults** restores the current tab after confirmation. Gamepad and Keyboard list every action by group. Choose one and press its new button; a button another action already uses swaps between them. Changed actions are marked, the help line shows the default, and **Reset** restores just the highlighted action. **Restore all defaults** at the end of the list asks first. Menu Confirm (A), Back (B) and Pause (Select) stay fixed, so remapping can never lock you out of the menus. Select cancels a remap, which also stops after ten seconds. Music and sound effects have ten volume steps; zero mutes them. Controls, CRT and item messages are saved for each player. Volume, blood, title skipping, square pixels and integer scaling apply to the whole device. Updates and credits are under **About** in the adventure menu.

## Playing and updating

The village on floor 6 has two more minigames. The claw costs ten rupees: move left/right and grab with A. In the pub, L/R changes the slot bet and A plays. B closes either game.

Hold Sword after a swing to poke while moving. With a level-three sword or higher, hold until the blade flashes, then release to spin. Level-two swords can break pots.

Choose a challenge preset with left/right: **Hero's Path** is the standard game, **Second Quest** is tougher, and **Master Quest** is for veterans. The level meter adds up every challenge, and icons show which ones are active. Press **A** on Challenges to customize health, darkness, inventory space, shop prices and other restrictions; each explains itself, changed values are marked, and **Defaults** restores Hero's Path after asking. The last page includes No map, No food, and Wall Master. Existing runs keep their original challenge restrictions, and saves started with challenges show their level beside the floor.

Press Start or confirm to skip the opening title animation. To require the full animation, turn off **Skip title intro** under **Options > Game**.

This is an unofficial patch of the PortMaster **1.1.6 VM** build with selected 1.2.x backports. It does not include every change from 1.2.1. Read the [backport audit](docs/BACKPORTS.md) for coverage and the [changelog](CHANGELOG.md) for changes between patch releases.

<details>
<summary>Save format and backups</summary>

Saves from earlier save formats convert when loaded. Items beyond the inventory's capacity remain available on overflow pages.

Before converting a save format, the installer keeps a copy of the saves in `save-backups/`:

- `before-inventory-v1.zip`: saves in the format before inventory bags.
- `before-content-v3.zip`: saves in the format before Topaz and adjustable challenges.

Reinstallation keeps these backups. An earlier patch release can only read the saves in its own format.

</details>

## Development and testing

The repository distributes patch code and binary deltas. Installer downloads contain no standalone game or runtime. Checksums verify the upstream package and patched output.

[TESTING.md](docs/TESTING.md) covers builds, GitHub CI, the isolated device regression suite, and the release procedure. Patch versions are independent of the original game's versions. Related fixes stay under Unreleased until the batch is ready.

<details>
<summary>Build the patch on Linux</summary>

Use Linux x86-64 and Python 3.11 or newer:

```sh
python3 -m unittest discover -v
python3 build.py --check-release --runtime-tests
```

The build downloads the pinned PortMaster package and UndertaleModTool CLI 0.9.2.0, checks their hashes, and compiles the patch. It verifies the checked-in delta against the clean build, then tests installation and reinstallation. Full game archives stay in the ignored `.build/` directory.

GitHub Actions runs the unit suite and build checks on pushes and pull requests. Runtime assertions run separately on a device. The installer uses Python's standard library. Release packaging uses `requirements-build.txt`.

</details>

<details>
<summary>Rendering and device support</summary>

Device tests run on the Retroid Nova (1280×960) and Retroid Pocket Flip 2 (1920×1080). Layout tests also cover the other screens of ROCKNIX devices that meet the port's 4 GB requirement: 1240×1080, 1620×1080, 1920×1152 and 2560×1440. On Qualcomm Adreno GPUs the launcher selects Freedreno; other GPUs keep Mesa's default. It also selects SDL's evdev controller backend.

Gameplay presents the complete 256×224 playfield at 4:3 with horizontal pixel aspect correction. **Square pixels** shows it at 8:7. **Integer scaling** rounds its height down to a whole multiple of 224. Where the side borders fit the original 72-pixel Status panels at 2× or more, the panels sit there at a whole-number scale. Elsewhere they open over the playfield at 75% scale and 90% opacity.

The title view is 300×225 on 4:3 screens and widens to the full 400×225 scene at 16:9. Menus keep their 400×300 layout; wider screens extend the landscape at both sides and move the button hints to the corner.

The HUD renders after the playfield at its own integer scale, with square pixels and a smaller footprint: 3× on a 1280×960 screen and 4× at 1920×1080. Equipment and counters sit at the playfield's left edge, with hearts at the right. The CRT option affects the world while the HUD and gameplay hints stay crisp.

Inventory, map and arcade hints share the HUD scale, footer baseline and right margin. Smaller L/R glyphs stay beside the inventory heading. Item artwork and descriptions retain their larger scale for browsing.

The CRT effect is a port of CRT-Lottes. It keeps the full playfield visible and preserves dark detail. Arcade machines use their original effect.

</details>

## Credits

Justin Bohemier created Dungeons of Infinity. The [PortMaster package](https://github.com/PortsMaster-MV/PortMaster-MV-New/tree/main/ports/zeldadoi) supplies the game files and [GMLoader-next](https://github.com/JohnnyonFlame/gmloader-next) runtime during installation. The installer preserves upstream license files in `zeldadoi-beyond/license/`.

Controller glyphs use Kenney's Input Prompts 1.5A, from `Nintendo Switch 2/Double`, under [CC0](assets/buttons/LICENSE.txt). [The asset manifest](assets/buttons/manifest.json) records source filenames and checksums. The patch copies this artwork without redrawing it.

The gameplay CRT shader adapts Timothy Lottes' public-domain CRT-Lottes shader from RetroArch. [Shader source and tuning notes](src/shaders/README.md) document the port and its attribution.

The release builder uses [bsdiff4](https://pypi.org/project/bsdiff4/) to create the binary patch.
