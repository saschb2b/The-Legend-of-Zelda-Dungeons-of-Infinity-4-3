import argparse
import hashlib
import json
import shlex
import sys
import time
import uuid
from pathlib import Path
from zipfile import ZipFile

from run_device import copy, remote

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
INSTALLER = ROOT / 'installer'
sys.path.insert(0, str(INSTALLER))
import build
from install import GAME_DIR, LAUNCHER


def main():
    parser = argparse.ArgumentParser(description='Leave a separate playable village test on a Nova.')
    parser.add_argument('host')
    parser.add_argument('--control-path', type=Path)
    parser.add_argument('--ports-dir', default='/storage/roms/ports')
    args = parser.parse_args()
    tool = ROOT / '.build/utmt-0.9.2.0/UndertaleModCli'
    game = ROOT / '.build/village-preview.droid'
    build.run_umt(tool, ROOT / '.build/patched.droid', 'tests/village.csx', game,
                  'NOVA VILLAGE PREVIEW COMPILED')
    build.verify_runner_format(game.read_bytes())
    token = uuid.uuid4().hex[:12]
    stage = f'/storage/.cache/doi43-village-{token}'
    launcher = f'{args.ports_dir}/DOI Village Test.sh'
    source = f'{args.ports_dir}/{GAME_DIR}'
    request = lambda command, data=None: remote(args.host, args.control_path, command, data)
    constants = f'SOURCE={source!r}\nSTAGE={stage!r}\nLAUNCHER={launcher!r}\nLAUNCHER_TEXT={(INSTALLER / LAUNCHER).read_text()!r}\n'
    snapshot = '''import hashlib,json,pathlib,shutil,urllib.request
source=pathlib.Path(SOURCE)
stage=pathlib.Path(STAGE)
launcher=pathlib.Path(LAUNCHER)
def saves():
 return {str(p.relative_to(source)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ('savedata','save-backups') for p in (source/folder).rglob('*') if p.is_file()}
'''
    setup = '''
running=json.load(urllib.request.urlopen('http://127.0.0.1:1234/runningGame',timeout=5))
if running.get('msg') != 'NO GAME RUNNING': raise RuntimeError('Close the running game before testing.')
if launcher.exists(): raise RuntimeError('A village test already exists. Close and remove it before preparing another.')
print(json.dumps(saves()))
shutil.copytree(source,stage,ignore=shutil.ignore_patterns('savedata','save-backups','test-savedata','log.txt'))
config=json.loads((stage/'gmloader.json').read_text())
config['save_dir']='village-test-savedata'
(stage/'gmloader.json').write_text(json.dumps(config))
text=LAUNCHER_TEXT
for old,new in [('python3 "$GAMEDIR/updater.py" serve --game-dir "$GAMEDIR" --parent "$$"','sleep 3600'),('GAMEDIR="/$directory/ports/zeldadoi-43"','GAMEDIR='+repr(str(stage)))]:
 if text.count(old)!=1: raise RuntimeError('Unrecognised launcher boundary: '+old)
 text=text.replace(old,new)
launcher.write_text(text)
launcher.chmod(0o755)
'''
    before = json.loads(request('python3 -', (constants + snapshot + setup).encode()))
    record = {'stage': stage, 'launcher': launcher, 'game_sha256': hashlib.sha256(game.read_bytes()).hexdigest()}
    (ROOT / '.build/village-preview.json').write_text(json.dumps(record, indent=2) + '\n')
    for helper in ('controller.py', 'updater.py', 'install.py'):
        copy(args.host, args.control_path, INSTALLER / helper, stage + '/' + helper)
    port_path = ROOT / '.build/village-preview.port'
    with ZipFile(ROOT / '.build/original.port') as original, ZipFile(port_path, 'w') as port:
        for entry in original.infolist():
            port.writestr(entry, game.read_bytes() if entry.filename == 'assets/game.droid' else original.read(entry))
    copy(args.host, args.control_path, port_path, stage + '/zeldadoi.port')
    launch = f'''import urllib.request,time
urllib.request.urlopen('http://127.0.0.1:1234/reloadgames',timeout=5).read()
time.sleep(2)
request=urllib.request.Request('http://127.0.0.1:1234/launch',data={launcher.encode()!r},headers={{'Content-Type':'text/plain'}})
urllib.request.urlopen(request,timeout=10).read()
'''
    request('python3 -', launch.encode())
    for attempt in range(45):
        ready = request('cat ' + shlex.quote(stage + '/village-test-savedata/village-ready.txt') + ' 2>/dev/null || true')
        if ready:
            after = json.loads(request('python3 -', (constants + snapshot + 'print(json.dumps(saves()))\n').encode()))
            if before != after:
                raise RuntimeError('Production saves changed during village setup.')
            print(ready.decode())
            print(json.dumps(record, indent=2))
            return
        error = request('grep -A8 "ERROR in action" ' + shlex.quote(stage + '/log.txt') + ' 2>/dev/null || true')
        if error:
            raise RuntimeError(error.decode(errors='replace'))
        time.sleep(2)
    raise RuntimeError('Village did not become ready. See .build/village-preview.json for the installation paths.')


if __name__ == '__main__':
    main()
