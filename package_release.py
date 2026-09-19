import argparse
import hashlib
import stat
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

parser = argparse.ArgumentParser(description='Package the Nova 4:3 edition for the Ports folder.')
parser.add_argument('--port-zip', type=Path, required=True)
parser.add_argument('--game-archive', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parent
launcher = 'Zelda Dungeons of Infinity 4-3.sh'
expected_upstream = 'cf13009f3f8f5578a17ca4a45de051ea1315280037f01434c187ebc9d9e91353'
expected_game = '39b86a7d8e5c212c3c44b3ae90545471aa79b1bce0a6d25532dd94d1f8f34d7f'

if hashlib.sha256(args.port_zip.read_bytes()).hexdigest() != expected_upstream:
    raise SystemExit('Use the pinned PortMaster 2024-12-03 archive.')

with ZipFile(args.game_archive) as patched:
    digest = hashlib.sha256(patched.read('assets/game.droid')).hexdigest()
    if digest != expected_game:
        raise SystemExit('The game data does not match the tested Nova patch.')

args.output.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(args.port_zip) as upstream, ZipFile(args.output, 'x', compression=ZIP_DEFLATED, compresslevel=9) as release:
    def add(name, content, executable=False):
        entry = ZipInfo(name, date_time=(2026, 9, 19, 0, 0, 0))
        entry.create_system = 3
        entry.compress_type = ZIP_DEFLATED
        entry.external_attr = (stat.S_IFREG | (0o755 if executable else 0o644)) << 16
        release.writestr(entry, content, compresslevel=9)

    add(launcher, (root / launcher).read_bytes(), executable=True)
    for entry in upstream.infolist():
        if entry.is_dir() or not entry.filename.startswith('zeldadoi/'):
            continue
        relative = entry.filename.removeprefix('zeldadoi/')
        if relative in ('port.json', 'gameinfo.xml', 'screenshot.png', 'zeldadoi.port'):
            continue
        add('zeldadoi-43/' + relative, upstream.read(entry),
            executable=relative in ('gmloadernext.aarch64', 'tools/splash'))
    add('zeldadoi-43/zeldadoi.port', args.game_archive.read_bytes())
    add('zeldadoi-43/gameinfo.xml', (root / 'gameinfo.xml').read_bytes())
    add('zeldadoi-43/screenshot.png', (root / 'screenshots/playfield.png').read_bytes())
    add('zeldadoi-43/README.md', (root / 'README.md').read_bytes())
    for name in ('apply.csx', 'composite.gml', 'repack.py', 'package_release.py'):
        add('zeldadoi-43/patch/' + name, (root / name).read_bytes())

print(args.output)
