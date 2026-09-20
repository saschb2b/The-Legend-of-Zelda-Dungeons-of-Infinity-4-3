import argparse
import hashlib
import json
import re
import shlex
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from install import GAME_DIR, LAUNCHER


def remote(host, control, command, data=None):
    options = ['-S', str(control)] if control else []
    return subprocess.run(['ssh', *options, '-o', 'BatchMode=yes', host, command], input=data,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, timeout=120).stdout


def copy(host, control, source, destination):
    options = ['-o', f'ControlPath={control}'] if control else []
    subprocess.run(['scp', *options, '-o', 'BatchMode=yes', str(source), f'{host}:{destination}'],
                   check=True, timeout=120)


def main():
    parser = argparse.ArgumentParser(description='Run instrumented game events in a disposable Nova installation.')
    parser.add_argument('host', help='SSH destination with key or existing control-socket authentication')
    parser.add_argument('--control-path', type=Path)
    parser.add_argument('--game', type=Path, default=ROOT / '.build/runtime-tests.droid')
    parser.add_argument('--ports-dir', default='/storage/roms/ports')
    parser.add_argument('--capture', action='store_true', help='Capture inventory and Status hints after the assertions.')
    parser.add_argument('--capture-arcade', action='store_true', help='Capture the village arcade and pub machines.')
    parser.add_argument('--capture-context', action='store_true', help='Capture contextual gameplay hints with controller and keyboard mappings.')
    parser.add_argument('--capture-updates', action='store_true', help='Capture only the updater screens during regression tests.')
    parser.add_argument('--capture-profiles', action='store_true', help='Capture empty and saved profiles with controller and keyboard prompts.')
    parser.add_argument('--report-dir', type=Path, default=ROOT / '.build/device-results')
    args = parser.parse_args()
    game_bytes = args.game.read_bytes()
    game_digest = hashlib.sha256(game_bytes).hexdigest()
    request = lambda command, data=None: remote(args.host, args.control_path, command, data)
    token = uuid.uuid4().hex[:12]
    stage = f'/storage/.cache/doi43-harness-{token}'
    launcher = f'{args.ports_dir}/DOI43 Harness {token}.sh'
    source = f'{args.ports_dir}/{GAME_DIR}'
    args.report_dir.mkdir(parents=True, exist_ok=True)
    report = None
    created = False
    captures = set()
    try:
        setup = '''import hashlib,json,pathlib,shutil,urllib.request
source=pathlib.Path(SOURCE)
stage=pathlib.Path(STAGE)
launcher=pathlib.Path(LAUNCHER)
running=json.load(urllib.request.urlopen('http://127.0.0.1:1234/runningGame',timeout=5))
if running.get('msg') != 'NO GAME RUNNING': raise RuntimeError('Close the running game before testing.')
saves={str(p.relative_to(source)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (source/'savedata').rglob('*') if p.is_file()}
print(json.dumps(saves))
shutil.copytree(source,stage,ignore=shutil.ignore_patterns('savedata','test-savedata','log.txt'))
config=json.loads((stage/'gmloader.json').read_text())
config['save_dir']='harness-savedata'
if CAPTURE or CAPTURE_UPDATES or CAPTURE_PROFILES or CAPTURE_CONTEXT or CAPTURE_ARCADE:
 (stage/'harness-savedata').mkdir()
 for enabled,name in [(CAPTURE_ARCADE,'nova-arcade-capture-enabled.txt'),(CAPTURE_CONTEXT,'nova-context-capture-enabled.txt'),(CAPTURE,'nova-capture-enabled.txt'),(CAPTURE_UPDATES,'nova-update-capture-enabled.txt'),(CAPTURE_PROFILES,'nova-profile-capture-enabled.txt')]:
  if enabled: (stage/'harness-savedata'/name).touch()
(stage/'gmloader.json').write_text(json.dumps(config))
text=LAUNCHER_TEXT
service='python3 "$GAMEDIR/updater.py" serve --game-dir "$GAMEDIR" --parent "$$"'
if text.count(service)!=1: raise RuntimeError('Updater service boundary missing.')
text=text.replace(service, 'sleep 3600')
anchor='GAMEDIR="/$directory/ports/zeldadoi-43"'
if text.count(anchor)!=1: raise RuntimeError('Unrecognised launcher layout.')
text=text.replace(anchor,'GAMEDIR='+repr(str(stage)))
launcher.write_text(text)
launcher.chmod(0o755)
'''
        constants = f'CAPTURE_ARCADE={args.capture_arcade!r}\nCAPTURE_CONTEXT={args.capture_context!r}\nCAPTURE={args.capture!r}\nCAPTURE_UPDATES={args.capture_updates!r}\nCAPTURE_PROFILES={args.capture_profiles!r}\nSOURCE={source!r}\nSTAGE={stage!r}\nLAUNCHER={launcher!r}\nLAUNCHER_TEXT={(ROOT / LAUNCHER).read_text()!r}\n'
        snapshot, staging = setup.split('shutil.copytree', 1)
        before = json.loads(request('python3 -', (constants + snapshot).encode()))
        created = True
        request('python3 -', (constants + 'import json,pathlib,shutil\nsource=pathlib.Path(SOURCE)\nstage=pathlib.Path(STAGE)\nlauncher=pathlib.Path(LAUNCHER)\nshutil.copytree' + staging).encode())
        for helper in ('controller.py', 'updater.py', 'install.py'):
            copy(args.host, args.control_path, ROOT / helper, stage + '/' + helper)
        with tempfile.TemporaryDirectory() as directory:
            port_path = Path(directory) / 'runtime.port'
            with ZipFile(ROOT / '.build/original.port') as original, ZipFile(port_path, 'w') as port:
                for entry in original.infolist():
                    port.writestr(entry, game_bytes if entry.filename == 'assets/game.droid' else original.read(entry))
            copy(args.host, args.control_path, port_path, stage + '/zeldadoi.port')
        launch_code = f'''import urllib.request,time
urllib.request.urlopen('http://127.0.0.1:1234/reloadgames',timeout=5).read()
time.sleep(2)
r=urllib.request.Request('http://127.0.0.1:1234/launch',data={launcher.encode()!r},headers={{'Content-Type':'text/plain'}})
print(urllib.request.urlopen(r,timeout=10).read().decode())
'''
        print(request('python3 -', launch_code.encode()).decode().strip(), flush=True)
        deadline = time.monotonic() + 180
        while time.monotonic() < deadline:
            data = request(f'cat {shlex.quote(stage + "/harness-savedata/nova-test-report.json")} 2>/dev/null || true')
            if data:
                try:
                    report = json.loads(data)
                    report['game_sha256'] = game_digest
                    (args.report_dir / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
                except json.JSONDecodeError:
                    continue
                if report.get('complete'):
                    break
                capture = report.get('capture', '')
                if (args.capture or args.capture_updates or args.capture_profiles or args.capture_context or args.capture_arcade) and capture and capture not in captures:
                    if not re.fullmatch(r'(inventory|status|updates|profiles|map|context|arcade)-[a-z]+', capture):
                        raise RuntimeError('Invalid screenshot name in test report.')
                    path = stage + '/' + capture + '.png'
                    request('source /etc/profile; grim ' + shlex.quote(path))
                    (args.report_dir / (capture + '.png')).write_bytes(request('cat ' + shlex.quote(path)))
                    if capture.startswith(('profiles-', 'updates-', 'arcade-')):
                        for sample in range(2):
                            request('source /etc/profile; grim ' + shlex.quote(path))
                            (args.report_dir / f'{capture}-sample{sample + 2}.png').write_bytes(request('cat ' + shlex.quote(path)))
                    captures.add(capture)
                    request('touch ' + shlex.quote(stage + '/harness-savedata/nova-capture-done.txt'))
            error = request(f'grep -A5 "ERROR in action" {shlex.quote(stage + "/log.txt")} 2>/dev/null || true')
            if error:
                raise RuntimeError('Game runner failed: ' + error.decode(errors='replace'))
            time.sleep(2)
        if not report or not report.get('complete'):
            raise RuntimeError('No complete runtime report within 180 seconds.')
        (args.report_dir / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        failures = [case['name'] for case in report['results'] if not case['passed']]
        print(f'{len(report["results"])} runtime assertions; {len(failures)} failed', flush=True)
        for failure in failures:
            print(f'FAIL: {failure}')
        if failures:
            raise RuntimeError('Runtime regression suite failed.')
    finally:
        if created:
            cleanup = '''import hashlib,json,os,pathlib,shutil,signal,time,urllib.request
source=pathlib.Path(SOURCE)
stage=pathlib.Path(STAGE)
for p in pathlib.Path('/proc').iterdir():
 if not p.name.isdigit(): continue
 try:
  if (p/'cwd').resolve()==stage and b'gmloadernext' in (p/'cmdline').read_bytes(): os.kill(int(p.name),signal.SIGTERM)
 except (OSError,ProcessLookupError): pass
time.sleep(2)
saves={str(p.relative_to(source)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (source/'savedata').rglob('*') if p.is_file()}
print(json.dumps({'saves':saves,'log':(stage/'log.txt').read_text(errors='replace') if (stage/'log.txt').exists() else ''}))
pathlib.Path(LAUNCHER).unlink(missing_ok=True)
if stage.exists(): shutil.rmtree(stage)
urllib.request.urlopen('http://127.0.0.1:1234/reloadgames',timeout=5).read()
'''
            result = json.loads(request('python3 -', (constants + cleanup).encode()))
            (args.report_dir / 'game.log').write_text(result['log'])
            if result['saves'] != before:
                raise RuntimeError('Production saves changed during testing.')
            print('Disposable installation removed; production saves unchanged.', flush=True)


if __name__ == '__main__':
    main()
