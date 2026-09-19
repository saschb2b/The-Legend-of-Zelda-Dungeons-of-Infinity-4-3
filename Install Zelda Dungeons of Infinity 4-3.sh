#!/bin/bash
set -o pipefail

PORTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$PORTS_DIR/zeldadoi-43-installer"
controlfolder="/roms/ports/PortMaster"
if [ ! -f "$controlfolder/control.txt" ]; then
    echo "Install PortMaster before running this installer."
    exit 1
fi
source "$controlfolder/control.txt"
get_controls
pm_message "Installing Dungeons of Infinity 4:3. Keep Wi-Fi connected."
python3 -u "$PAYLOAD/install.py" --ports-dir "$PORTS_DIR" 2>&1 | tee "$PAYLOAD/install.log" | while IFS= read -r line; do
    pm_message "$line"
done
result=${PIPESTATUS[0]}
if [ "$result" -ne 0 ]; then
    pm_show_error "Installation failed. See zeldadoi-43-installer/install.log for details."
fi
pm_message_end
exit "$result"
