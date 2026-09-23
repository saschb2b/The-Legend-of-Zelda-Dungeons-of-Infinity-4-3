import argparse
import hashlib
import html
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import time
import urllib.request
from pathlib import Path
from zipfile import BadZipFile, ZipFile

REPOSITORY = 'saschb2b/The-Legend-of-Zelda-Dungeons-of-Infinity-and-Beyond'
# The numeric repository ID keeps release checks working if the repository is renamed again.
API = 'https://api.github.com/repositories/1377115680/releases/latest'
DOWNLOAD = f'https://github.com/{REPOSITORY}/releases/download/'
LAUNCHER = 'Zelda Dungeons of Infinity and Beyond.sh'
INSTALLER_LAUNCHER = 'Install Zelda Dungeons of Infinity and Beyond.sh'
PAYLOAD = 'zeldadoi-beyond-installer'
GAME = 'zeldadoi-beyond'
MAX_INSTALLER = 8 * 1024 * 1024
MAX_UPSTREAM = 128 * 1024 * 1024


def version_key(value):
    match = re.fullmatch(r'v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-rc\.(\d+))?', value)
    if not match:
        raise ValueError('Unrecognized patch version.')
    major, minor, patch, candidate = match.groups()
    return int(major), int(minor), int(patch), candidate is None, int(candidate or 0)


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix('.tmp')
    with temporary.open('w') as stream:
        json.dump(value, stream)
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def read_json(path):
    return json.loads(path.read_text())


def fetch(url, limit, progress=None):
    request = urllib.request.Request(url, headers={
        'User-Agent': 'DOI-Beyond-Updater', 'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2026-03-10',
    })
    chunks = []
    size = 0
    deadline = time.monotonic() + 180
    with urllib.request.urlopen(request, timeout=15) as response:
        length = int(response.headers.get('Content-Length', 0))
        if length > limit:
            raise ValueError('Download exceeds the size limit.')
        while True:
            chunk = response.read(128 * 1024)
            if not chunk:
                break
            size += len(chunk)
            if size > limit or time.monotonic() > deadline:
                raise ValueError('Download did not finish within its limits.')
            chunks.append(chunk)
            if progress:
                progress(size, length)
    return b''.join(chunks)


def select_release(release, installed):
    version = release['tag_name'].removeprefix('v')
    key = version_key(version)
    if release.get('draft') or release.get('prerelease') or not key[3]:
        raise ValueError('The latest release is not a stable patch.')
    if key <= version_key(installed):
        return None
    filename = f'Dungeons-of-Infinity-and-Beyond-v{version}-Patch-Installer.zip'
    assets = {item['name']: item for item in release['assets']}
    archive = assets[filename]
    checksum = assets[filename + '.sha256']
    digest = archive.get('digest', '')
    if not re.fullmatch(r'sha256:[0-9a-f]{64}', digest):
        raise ValueError('The release has no verified download checksum.')
    for asset in (archive, checksum):
        if asset['state'] != 'uploaded' or asset['browser_download_url'] != DOWNLOAD + 'v' + version + '/' + asset['name']:
            raise ValueError('Unexpected release download.')
    if not 0 < archive['size'] <= MAX_INSTALLER:
        raise ValueError('Invalid installer size.')
    return {'version': version, 'name': filename, 'sha256': digest[7:], 'size': archive['size']}


def plain_release_notes(body):
    lines = []
    for line in body.splitlines():
        if line.startswith('[Changes from ') or '[installation guide]' in line:
            continue
        line = re.sub(r'!\[[^\]]*\]\([^)]*\)', '', line)
        line = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', line)
        line = re.sub(r'<[^>]+>', '', line)
        line = re.sub(r'^#{1,6}\s*', '', line).replace('**', '').replace('`', '')
        line = html.unescape(line).translate(str.maketrans({'’': "'", '“': '"', '”': '"', '–': '-', '—': '-'}))
        line = ''.join(c for c in line if 32 <= ord(c) < 127).strip()
        if line:
            lines.append(line)
    return '\n'.join(lines)[:40000] or 'No release notes were provided.'


def changes_since(releases, installed, latest):
    changes = []
    for release in releases:
        try:
            version = release['tag_name'].removeprefix('v')
            key = version_key(version)
        except (KeyError, TypeError, ValueError):
            continue
        if (release.get('draft') or release.get('prerelease') or not key[3]
                or not version_key(installed) < key <= version_key(latest)):
            continue
        changes.append((key, version + '\n' + plain_release_notes(release.get('body') or '')))
    return '\n\n'.join(text for _, text in sorted(changes, reverse=True))[:60000]


def unpack_installer(data, destination, version):
    archive = destination / 'installer.zip'
    archive.write_bytes(data)
    with ZipFile(archive) as zipped:
        seen = set()
        total = 0
        for entry in zipped.infolist():
            name = entry.filename
            path = Path(name)
            mode = entry.external_attr >> 16
            total += entry.file_size
            if (path.is_absolute() or '..' in path.parts or '\\' in name or name in seen
                    or stat.S_ISLNK(mode) or total > 32 * 1024 * 1024
                    or not (name == INSTALLER_LAUNCHER or name.startswith(PAYLOAD + '/'))):
                raise ValueError('Invalid installer archive.')
            seen.add(name)
        zipped.extractall(destination)
    payload = destination / PAYLOAD
    manifest = read_json(payload / 'manifest.json')
    if manifest['version'] != version:
        raise ValueError('Installer version does not match the release.')
    delta = (payload / 'patches/game.droid.bsdiff').read_bytes()
    if hashlib.sha256(delta).hexdigest() != manifest['patch_sha256']:
        raise ValueError('Patch checksum mismatch.')
    if not manifest['upstream_url'].startswith('https://github.com/PortsMaster-MV/PortMaster-MV-New/releases/download/'):
        raise ValueError('Unexpected upstream download.')
    for field in ('upstream_sha256', 'original_game_sha256', 'patched_game_sha256'):
        if not re.fullmatch(r'[0-9a-f]{64}', manifest[field]):
            raise ValueError('Invalid game checksum.')
    if not 0 < manifest['patched_game_size'] <= MAX_UPSTREAM:
        raise ValueError('Invalid patched game size.')
    for required in ('install.py', 'controller.py', 'updater.py', LAUNCHER):
        if not (payload / required).is_file():
            raise ValueError('The release does not support in-game updates.')
    return manifest


class Cancelled(Exception):
    pass


class Updater:
    def __init__(self, game):
        self.game = game.resolve()
        self.work = self.game.parent / ('.' + self.game.name + '-update')
        source = self.game if self.game.exists() else self.work / 'previous'
        config = read_json(source / 'gmloader.json')
        self.saves = self.game / config['save_dir']
        self.request = self.saves / 'nova-update-request.json'
        self.status = self.saves / 'nova-update-status.json'
        self.installed = (source / 'patch-version.txt').read_text().strip()
        self.request_id = ''
        self.release = None
        self.download_message = 'Downloading update...'

    def publish(self, state, message, **extra):
        write_json(self.status, {'id': self.request_id, 'state': state, 'message': message,
                                'installed': self.installed, 'available': self.release['version'] if self.release else '',
                                'notes': self.release.get('notes', '') if self.release else '', **extra})

    def current(self):
        try:
            return read_json(self.request).get('id') == self.request_id
        except (OSError, ValueError):
            return False

    def progress(self, size, total):
        if not self.current():
            raise Cancelled()
        percent = min(100, size * 100 // total) if total else 0
        self.publish('downloading', self.download_message, percent=percent)

    def check(self):
        self.publish('checking', 'Checking for updates...')
        latest = json.loads(fetch(API, 2 * 1024 * 1024))
        self.release = select_release(latest, self.installed)
        if self.release:
            notes = self.release['version'] + '\n' + plain_release_notes(latest.get('body') or '')
            try:
                history = json.loads(fetch(API.removesuffix('/latest') + '?per_page=100', 2 * 1024 * 1024))
                notes = changes_since(history, self.installed, self.release['version']) or notes
            except (OSError, ValueError, KeyError, TypeError):
                notes += '\n\nEarlier release notes could not be loaded.'
            self.release['notes'] = notes
        self.publish('available' if self.release else 'current',
                     'An update is available.' if self.release else 'Your patch is up to date.')

    def prepare(self):
        if not self.release:
            raise ValueError('Check for an update first.')
        self.work.mkdir(exist_ok=True)
        prepared = self.work / 'prepared'
        shutil.rmtree(prepared, ignore_errors=True)
        prepared.mkdir()
        release = self.release
        base = DOWNLOAD + 'v' + release['version'] + '/'
        checksum = fetch(base + release['name'] + '.sha256', 4096).decode().strip().split()
        if checksum != [release['sha256'], release['name']]:
            raise ValueError('Release checksums do not match.')
        self.download_message = 'Downloading update...'
        data = fetch(base + release['name'], MAX_INSTALLER, self.progress)
        if len(data) != release['size'] or hashlib.sha256(data).hexdigest() != release['sha256']:
            raise ValueError('Installer checksum mismatch.')
        manifest = unpack_installer(data, prepared, release['version'])
        self.download_message = 'Downloading game files...'
        self.publish('downloading', self.download_message, percent=0)
        upstream = fetch(manifest['upstream_url'], MAX_UPSTREAM, self.progress)
        if hashlib.sha256(upstream).hexdigest() != manifest['upstream_sha256']:
            raise ValueError('Game download checksum mismatch.')
        (prepared / 'upstream.zip').write_bytes(upstream)
        if not self.current():
            raise Cancelled()
        needed = sum(p.stat().st_size for p in self.game.rglob('*') if p.is_file()) + 4 * len(upstream) + 32 * 1024 * 1024
        if shutil.disk_usage(self.work).free < needed:
            raise ValueError('Not enough free space for the update.')
        write_json(self.work / 'ready.json', {'id': self.request_id, 'version': release['version']})
        self.publish('ready', 'Ready to restart and install.')

    def serve(self, parent):
        self.request.unlink(missing_ok=True)
        (self.work / 'ready.json').unlink(missing_ok=True)
        self.publish('idle', 'Check for the latest stable patch.')
        while os.getppid() == parent:
            if not self.request.exists():
                time.sleep(0.2)
                continue
            try:
                request = read_json(self.request)
            except (OSError, ValueError):
                time.sleep(0.2)
                continue
            try:
                if request['id'] == self.request_id:
                    time.sleep(0.2)
                    continue
                self.request_id = request['id']
                (self.work / 'ready.json').unlink(missing_ok=True)
                if request['action'] == 'check':
                    self.check()
                elif request['action'] == 'install':
                    self.prepare()
                else:
                    self.publish('idle', 'Update cancelled.')
            except Cancelled:
                pass
            except (OSError, ValueError, KeyError, TypeError, RuntimeError, BadZipFile) as error:
                print(f'Update failed: {error}', flush=True)
                if isinstance(error, BadZipFile):
                    message = 'Update file is damaged. Please try again.'
                elif isinstance(error, ValueError):
                    message = str(error)
                elif isinstance(error, (KeyError, TypeError)):
                    message = 'Release files are incomplete. Please try later.'
                else:
                    message = 'Download failed. Check Wi-Fi and try again.'
                self.publish('error', message)
                time.sleep(0.2)

    def recover(self):
        journal = self.work / 'transaction.json'
        if not journal.exists():
            return
        old = self.work / 'previous'
        launcher = self.game.parent / LAUNCHER
        if old.exists():
            shutil.rmtree(self.game, ignore_errors=True)
            old.replace(self.game)
        old_launcher = self.work / 'previous-launcher.sh'
        if old_launcher.exists():
            old_launcher.replace(launcher)
        journal.unlink()

    def apply(self):
        ready_path = self.work / 'ready.json'
        if not ready_path.exists():
            return False
        ready = read_json(ready_path)
        ready_path.unlink()
        if not self.request.exists():
            return False
        request = read_json(self.request)
        if ready['id'] != request['id'] or request['action'] != 'restart':
            return False
        import install
        install.ensure_game_stopped(self.game)
        prepared = self.work / 'prepared'
        staged_ports = self.work / 'stage'
        shutil.rmtree(staged_ports, ignore_errors=True)
        staged_ports.mkdir()
        staged_game = staged_ports / GAME
        self.publish('installing', 'Installing update. Keep the device on.')
        try:
            shutil.copytree(self.game, staged_game)
            command = [sys.executable, '-u', str(prepared / PAYLOAD / 'install.py'),
                       '--ports-dir', str(staged_ports), '--upstream-zip', str(prepared / 'upstream.zip'), '--no-refresh']
            subprocess.run(command, check=True, timeout=240)
            manifest = read_json(prepared / PAYLOAD / 'manifest.json')
            with ZipFile(staged_game / 'zeldadoi.port') as port:
                install.verify(port.read('assets/game.droid'), manifest['patched_game_sha256'], 'Installed game')
            if (staged_game / 'patch-version.txt').read_text().strip() != ready['version']:
                raise ValueError('Installed version mismatch.')
            launcher = self.game.parent / LAUNCHER
            shutil.copy2(launcher, self.work / 'previous-launcher.sh')
            shutil.copy2(Path(__file__), self.work / 'recovery.py')
            shutil.copy2(Path(install.__file__), self.work / 'install.py')
            previous = self.work / 'previous'
            if previous.exists():
                shutil.rmtree(previous)
            write_json(self.work / 'transaction.json', {'version': ready['version']})
            self.game.replace(self.work / 'previous')
            staged_game.replace(self.game)
            (staged_ports / LAUNCHER).replace(launcher)
            os.sync()
            (self.work / 'transaction.json').unlink()
            os.sync()
            shutil.rmtree(self.work, ignore_errors=True)
            return True
        except (OSError, ValueError, RuntimeError, BadZipFile, subprocess.SubprocessError):
            self.recover()
            self.publish('error', 'Update failed. Your previous game is ready.')
            raise


def main():
    parser = argparse.ArgumentParser(description='Update Dungeons of Infinity and Beyond from its stable GitHub releases.')
    parser.add_argument('command', choices=('serve', 'apply', 'recover'))
    parser.add_argument('--game-dir', type=Path, required=True)
    parser.add_argument('--parent', type=int, default=os.getppid())
    args = parser.parse_args()
    updater = Updater(args.game_dir)
    try:
        if args.command == 'serve':
            updater.serve(args.parent)
        elif args.command == 'recover':
            updater.recover()
        elif updater.apply():
            return 10
    except (OSError, ValueError, RuntimeError, BadZipFile, subprocess.SubprocessError) as error:
        print(f'Update failed: {error}', file=sys.stderr, flush=True)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
