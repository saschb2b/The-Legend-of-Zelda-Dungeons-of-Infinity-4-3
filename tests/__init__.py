import sys
from pathlib import Path

# Installer modules are shipped side by side and import each other by name.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'installer'))
