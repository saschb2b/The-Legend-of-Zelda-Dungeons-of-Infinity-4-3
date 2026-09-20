import argparse
import bz2
import hashlib
import io
import json
import shutil
import sys
import tempfile
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path
from zipfile import ZipFile

LAUNCHER = 'Zelda Dungeons of Infinity 4-3.sh'
GAME_DIR = 'zeldadoi-43'
ROOT = Path(__file__).resolve().parent


def verify(data, expected, label):
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError(f'{label} checksum mismatch. Installation stopped.')


def read_int(data):
    if len(data) != 8:
        raise ValueError('Truncated patch integer.')
    # BSDIFF40 stores negative offsets as sign and magnitude.
    value = int.from_bytes(data, 'little') & ((1 << 63) - 1)
    return -value if data[7] & 128 else value


def apply_patch(original, patch, expected_size):
    if patch[:8] != b'BSDIFF40' or len(patch) < 32:
        raise ValueError('Invalid binary patch header.')
    control_size = read_int(patch[8:16])
    diff_size = read_int(patch[16:24])
    size = read_int(patch[24:32])
    if min(control_size, diff_size) < 0 or size != expected_size:
        raise ValueError('Invalid binary patch size.')
    boundary = 32 + control_size + diff_size
    if boundary > len(patch):
        raise ValueError('Truncated binary patch.')
    control = io.BytesIO(bz2.decompress(patch[32:32 + control_size]))
    diff = io.BytesIO(bz2.decompress(patch[32 + control_size:boundary]))
    extra = io.BytesIO(bz2.decompress(patch[boundary:]))
    output = bytearray()
    old_position = 0
    while len(output) < size:
        add_size, copy_size, seek = (read_int(control.read(8)) for _ in range(3))
        if min(add_size, copy_size) < 0:
            raise ValueError('Invalid binary patch operation.')
        if len(output) + add_size + copy_size > size:
            raise ValueError('Binary patch exceeds the expected output size.')
        block = bytearray(diff.read(add_size))
        literal = extra.read(copy_size)
        if len(block) != add_size or len(literal) != copy_size:
            raise ValueError('Truncated binary patch operation.')
        for index in range(add_size):
            source_index = old_position + index
            if 0 <= source_index < len(original):
                block[index] = (block[index] + original[source_index]) & 255
        output.extend(block)
        output.extend(literal)
        old_position += add_size + seek
    return bytes(output)


def ensure_game_stopped(destination):
    proc = Path('/proc')
    if not proc.exists():
        return
    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            if b'gmloadernext' in (entry / 'cmdline').read_bytes():
                if (entry / 'cwd').resolve() == destination.resolve():
                    raise RuntimeError('Close the 4:3 edition before installing the update.')
        except (OSError, PermissionError):
            continue


def refresh_artwork(ports):
    # EmulationStation caches metadata; its API updates the live list and gamelist.xml together.
    base = 'http://127.0.0.1:1234'
    client = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def request(path, data=None, content_type='application/json'):
        req = urllib.request.Request(base + path, data=data, headers={'Content-Type': content_type})
        with client.open(req, timeout=3) as response:
            return response.read()

    try:
        request('/reloadgames')
        for _ in range(5):
            games = json.loads(request('/systems/ports/games'))
            game = next((item for item in games if Path(item['path']).resolve() == (ports / LAUNCHER).resolve()), None)
            if game:
                break
            time.sleep(0.5)
        if not game:
            return
        endpoint = '/systems/ports/games/' + game['id']
        xml = ET.parse(ROOT / 'gameinfo.xml').getroot().find('game')
        metadata = {key: xml.findtext(key) for key in ('name', 'desc', 'developer', 'publisher', 'genre', 'players')}
        request(endpoint, json.dumps(metadata).encode())
        cover = (ports / GAME_DIR / 'cover.png').read_bytes()
        for kind in ('image', 'thumbnail'):
            request(endpoint + '/media/' + kind, cover, 'image/png')
    except (OSError, ValueError, KeyError, TypeError, ET.ParseError):
        print('Refresh the Ports game list to display the new entry.', flush=True)


def backup_legacy_saves(destination, work, target_schema):
    saves = destination / 'savedata'
    schema = destination / 'save-schema.txt'
    current_schema = int(schema.read_text()) if schema.exists() else 0
    if not (saves / 'Users').is_file():
        return
    for required_schema, name in ((1, 'before-inventory-v1.zip'), (3, 'before-content-v3.zip')):
        backup = destination / 'save-backups' / name
        if current_schema >= required_schema or target_schema < required_schema or backup.exists():
            continue
        temporary = work / name
        with ZipFile(temporary, 'w') as archive:
            for source in sorted(saves.rglob('*')):
                if source.is_file():
                    archive.write(source, source.relative_to(saves))
        backup.parent.mkdir(parents=True, exist_ok=True)
        temporary.replace(backup)
        print(f'Saved a copy of the existing saves in save-backups/{name}.', flush=True)


def install(ports, upstream_path=None, refresh=True):
    ports = ports.resolve()
    ports.mkdir(parents=True, exist_ok=True)
    destination = ports / GAME_DIR
    ensure_game_stopped(destination)
    manifest = json.loads((ROOT / 'manifest.json').read_text())
    patch = (ROOT / 'patches/game.droid.bsdiff').read_bytes()
    verify(patch, manifest['patch_sha256'], 'Patch')
    with tempfile.TemporaryDirectory(prefix='.doi43-install-', dir=ports) as temporary:
        work = Path(temporary)
        if upstream_path is None:
            print('Downloading the official PortMaster package (44 MiB)...', flush=True)
            upstream_path = work / 'upstream.zip'
            req = urllib.request.Request(manifest['upstream_url'], headers={'User-Agent': 'DOI-4-3-Installer/' + manifest['version']})
            with urllib.request.urlopen(req, timeout=60) as response, upstream_path.open('wb') as output:
                shutil.copyfileobj(response, output)
        verify(upstream_path.read_bytes(), manifest['upstream_sha256'], 'PortMaster package')
        print('Applying the 4:3 patch...', flush=True)
        stage = work / GAME_DIR
        stage.mkdir()
        with ZipFile(upstream_path) as upstream:
            for entry in upstream.infolist():
                if not entry.filename.startswith('zeldadoi/') or entry.is_dir():
                    continue
                relative = Path(entry.filename.removeprefix('zeldadoi/'))
                if relative.is_absolute() or '..' in relative.parts:
                    raise ValueError('Invalid package path.')
                if relative.as_posix() in ('port.json', 'gameinfo.xml'):
                    continue
                target = stage / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(upstream.read(entry))
                target.chmod(0o755 if relative.as_posix() in ('gmloadernext.aarch64', 'tools/splash') else 0o644)
        game_archive = stage / 'zeldadoi.port'
        rebuilt_archive = work / 'patched.port'
        with ZipFile(game_archive) as game:
            original = game.read('assets/game.droid')
            verify(original, manifest['original_game_sha256'], 'Original game')
            patched = apply_patch(original, patch, manifest['patched_game_size'])
            verify(patched, manifest['patched_game_sha256'], 'Patched game')
            with ZipFile(rebuilt_archive, 'w') as rebuilt:
                for entry in game.infolist():
                    rebuilt.writestr(entry, patched if entry.filename == 'assets/game.droid' else game.read(entry))
        rebuilt_archive.replace(game_archive)
        shutil.copyfile(ROOT / 'gameinfo.xml', stage / 'gameinfo.xml')
        shutil.copyfile(ROOT / 'README.md', stage / 'README.md')
        for helper in ('controller.py', 'updater.py', 'install.py'):
            shutil.copyfile(ROOT / helper, stage / helper)
        (stage / 'patch-version.txt').write_text(manifest['version'] + '\n')
        if manifest.get('save_schema', 0) >= 1:
            backup_legacy_saves(destination, work, manifest['save_schema'])
            (stage / 'save-schema.txt').write_text(str(manifest['save_schema']) + '\n')
        staged_launcher = work / LAUNCHER
        shutil.copyfile(ROOT / LAUNCHER, staged_launcher)
        staged_launcher.chmod(0o755)
        print('Installing files and keeping existing saves...', flush=True)
        destination.mkdir(exist_ok=True)
        for source in sorted(stage.rglob('*')):
            if source.is_file():
                target = destination / source.relative_to(stage)
                target.parent.mkdir(parents=True, exist_ok=True)
                source.replace(target)
        staged_launcher.replace(ports / LAUNCHER)
    if refresh:
        refresh_artwork(ports)
    print('Installation complete. Launch Zelda Dungeons of Infinity 4-3 from Ports.', flush=True)


def main():
    parser = argparse.ArgumentParser(description='Install the Dungeons of Infinity 4:3 patch for Nova on ROCKNIX.')
    parser.add_argument('--ports-dir', type=Path, required=True)
    parser.add_argument('--upstream-zip', type=Path, help='Use a previously downloaded official PortMaster ZIP.')
    parser.add_argument('--no-refresh', action='store_true', help='Skip the local EmulationStation metadata update.')
    args = parser.parse_args()
    try:
        install(args.ports_dir, args.upstream_zip, not args.no_refresh)
    except (OSError, ValueError, RuntimeError) as error:
        print(f'Installation failed: {error}', file=sys.stderr, flush=True)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
