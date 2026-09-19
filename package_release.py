import argparse
import hashlib
import json
import stat
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parent
ORIGINAL_HASH = 'd1c7f76420650d27d1abd6003657e81841efe5c28d35f012166a3ec4b981c047'
UPSTREAM_HASH = 'cf13009f3f8f5578a17ca4a45de051ea1315280037f01434c187ebc9d9e91353'
UPSTREAM_URL = 'https://github.com/PortsMaster-MV/PortMaster-MV-New/releases/download/2024-12-03_1532/zeldadoi.zip'

PAYLOAD_FILES = ('install.py', 'manifest.json', 'patches/game.droid.bsdiff', 'README.md',
                 'gameinfo.xml', 'Zelda Dungeons of Infinity 4-3.sh')
INSTALLER_LAUNCHER = 'Install Zelda Dungeons of Infinity 4-3.sh'


def write_archive(root, output):
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, 'x', compression=ZIP_DEFLATED, compresslevel=9) as release:
        def add(source, destination):
            entry = ZipInfo(destination, date_time=(2026, 9, 19, 0, 0, 0))
            entry.create_system = 3
            entry.compress_type = ZIP_DEFLATED
            entry.external_attr = (stat.S_IFREG | (0o755 if source.endswith('.sh') else 0o644)) << 16
            release.writestr(entry, (root / source).read_bytes(), compresslevel=9)

        add(INSTALLER_LAUNCHER, INSTALLER_LAUNCHER)
        for name in PAYLOAD_FILES:
            add(name, 'zeldadoi-43-installer/' + name)


def validate_production(patched):
    if b'oNovaTests' in patched or b'NovaTestInput' in patched:
        raise ValueError('Instrumented test builds cannot be packaged as a release.')


def main():
    import bsdiff4

    parser = argparse.ArgumentParser(description='Build a patch-only Nova installer release.')
    parser.add_argument('--original-game', type=Path, required=True)
    parser.add_argument('--patched-game', type=Path, required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    original = args.original_game.read_bytes()
    patched = args.patched_game.read_bytes()
    if hashlib.sha256(original).hexdigest() != ORIGINAL_HASH:
        raise SystemExit('Use game.droid from the pinned PortMaster 1.1.6 VM package.')
    validate_production(patched)
    if args.output.exists():
        raise SystemExit('Use an unused output filename.')
    patch = bsdiff4.diff(original, patched)
    if bsdiff4.patch(original, patch) != patched:
        raise SystemExit('Binary patch verification failed.')
    manifest = {
        'version': args.version,
        'upstream_url': UPSTREAM_URL,
        'upstream_sha256': UPSTREAM_HASH,
        'original_game_sha256': ORIGINAL_HASH,
        'patched_game_sha256': hashlib.sha256(patched).hexdigest(),
        'patched_game_size': len(patched),
        'patch_sha256': hashlib.sha256(patch).hexdigest(),
    }
    (ROOT / 'patches').mkdir(exist_ok=True)
    (ROOT / 'patches/game.droid.bsdiff').write_bytes(patch)
    (ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    write_archive(ROOT, args.output)
    print(f'{args.output}: {args.output.stat().st_size:,} bytes, patch only')


if __name__ == '__main__':
    main()
