#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR="/$directory/ports/zeldadoi-43"
SPLASHFILE="splash.png"
PORT_LAUNCHER="$(readlink -f "${BASH_SOURCE[0]}")"
RECOVERY="${GAMEDIR%/*}/.${GAMEDIR##*/}-update/recovery.py"
if [ -f "$RECOVERY" ]; then
  python3 "$RECOVERY" recover --game-dir "$GAMEDIR" || exit 1
fi

# CD and set permissions
cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x -R $GAMEDIR/*

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$GAMEDIR/lib:$LD_LIBRARY_PATH"
export MESA_LOADER_DRIVER_OVERRIDE=msm
export GALLIUM_DRIVER=freedreno
export SDL_JOYSTICK_HIDAPI=0
export SDL_GAMECONTROLLERCONFIG="$(printf '%s' "$sdl_controllerconfig" | python3 "$GAMEDIR/controller.py")"
# SDL's mapping file overrides the per-game mapping above.
unset SDL_GAMECONTROLLERCONFIG_FILE

# Display loading splash
if [ "$CFW_NAME" == "muOS" ]; then
  $ESUDO ./tools/splash $SPLASHFILE 1
fi
$ESUDO ./tools/splash $SPLASHFILE 5000

# Assign configs and load the game
$GPTOKEYB "gmloadernext.aarch64" &
pm_platform_helper "gmloadernext.aarch64"
python3 "$GAMEDIR/updater.py" serve --game-dir "$GAMEDIR" --parent "$$" >> "$GAMEDIR/update.log" 2>&1 &
updater_pid=$!
trap 'kill "$updater_pid" 2>/dev/null; wait "$updater_pid" 2>/dev/null' EXIT
./gmloadernext.aarch64 -c gmloader.json
kill "$updater_pid" 2>/dev/null
wait "$updater_pid" 2>/dev/null
trap - EXIT
if [ -f "$GAMEDIR/../.${GAMEDIR##*/}-update/ready.json" ]; then
  pm_message "Installing update. Keep the device on."
  python3 "$GAMEDIR/updater.py" apply --game-dir "$GAMEDIR" >> "$GAMEDIR/update.log" 2>&1
  update_result=$?
  pm_message_end
  if [ "$update_result" -eq 1 ]; then
    pm_show_error "Update failed. Previous version retained. See update.log."
  fi
  if [ "$update_result" -eq 10 ] || [ "$update_result" -eq 1 ]; then
    pm_finish
    exec "$PORT_LAUNCHER"
  fi
fi

# Cleanup
pm_finish
