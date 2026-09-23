import argparse
import hashlib
import io
import json
import shutil
import struct
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'installer'))
import install  # noqa: E402

BUILD = ROOT / '.build'
TOOL_URL = 'https://github.com/UnderminersTeam/UndertaleModTool/releases/download/0.9.2.0/UTMT_CLI_v0.9.2.0-Ubuntu.zip'
TOOL_SHA256 = 'd182f00c0e5ced8d9252aa1f796374cfee077a3889a658e70b68685f9cd559c7'


def download(url, path, digest):
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix('.download')
        try:
            with urllib.request.urlopen(url, timeout=60) as response, temporary.open('wb') as output:
                shutil.copyfileobj(response, output)
            install.verify(temporary.read_bytes(), digest, path.name)
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)
    install.verify(path.read_bytes(), digest, path.name)
    return path


def toolchain():
    archive = download(TOOL_URL, BUILD / 'utmt-0.9.2.0.zip', TOOL_SHA256)
    target = BUILD / 'utmt-0.9.2.0'
    with ZipFile(archive) as zipped:
        zipped.extractall(target)
    for path in target.rglob('UndertaleModCli'):
        path.chmod(0o755)
        return path
    raise RuntimeError('Compiler executable missing from pinned archive.')


def run_umt(tool, source, script, output=None, sentinel=None):
    command = [str(tool), 'load', str(source), '-s', str(ROOT / script), '-v']
    if output:
        output.unlink(missing_ok=True)
        command += ['-o', str(output), '-f']
    log = BUILD / (Path(script).stem + '.log')
    with log.open('w') as stream:
        # The CLI can wait on an inherited stdin; it never needs input.
        result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=stream, stderr=subprocess.STDOUT, timeout=240)
    content = log.read_text()
    # The CLI can return zero after a script exception. Require an explicit completion marker.
    if result.returncode or (sentinel and sentinel not in content) or (output and not output.is_file()):
        raise RuntimeError(f'Compiler failed. See {log}\n{content[-5000:]}')


def verify_runner_format(game):
    if len(game) < 8 or game[:4] != b'FORM' or struct.unpack_from('<I', game, 4)[0] != len(game) - 8:
        raise ValueError('Invalid GameMaker FORM length.')
    offset = 8
    found = False
    while offset + 8 <= len(game):
        tag, size = struct.unpack_from('<4sI', game, offset)
        end = offset + 8 + size
        if end > len(game):
            raise ValueError('GameMaker chunk exceeds the file.')
        if tag == b'FUNC':
            found = True
            if size < 8:
                raise ValueError('FUNC locals table is missing.')
            count = struct.unpack_from('<I', game, offset + 8)[0]
            locals_offset = offset + 12 + count * 12
            if locals_offset + 4 > end:
                raise ValueError('FUNC locals table is missing.')
            locals_count = struct.unpack_from('<I', game, locals_offset)[0]
            if locals_count > (end - locals_offset - 4) // 8:
                raise ValueError('FUNC locals table is truncated.')
        offset = end
    if offset != len(game) or not found:
        raise ValueError('Incomplete GameMaker chunk table.')


def extract_original(archive, manifest):
    install.verify(archive.read_bytes(), manifest['upstream_sha256'], 'PortMaster package')
    with ZipFile(archive) as zipped:
        port_data = zipped.read('zeldadoi/zeldadoi.port')
    with ZipFile(io.BytesIO(port_data)) as port:
        original = port.read('assets/game.droid')
    install.verify(original, manifest['original_game_sha256'], 'Original game')
    (BUILD / 'original.port').write_bytes(port_data)
    (BUILD / 'game.droid').write_bytes(original)
    return original


def check_release(original, rebuilt, manifest):
    delta = (ROOT / 'installer/patches/game.droid.bsdiff').read_bytes()
    install.verify(delta, manifest['patch_sha256'], 'Patch')
    reconstructed = install.apply_patch(original, delta, manifest['patched_game_size'])
    install.verify(reconstructed, manifest['patched_game_sha256'], 'Patched game')
    if reconstructed != rebuilt:
        raise ValueError('Release delta does not match a clean source build. Repackage the release.')
    with tempfile.TemporaryDirectory() as directory:
        ports = Path(directory) / 'ports'
        savedata = ports / install.GAME_DIR / 'savedata'
        savedata.mkdir(parents=True)
        (savedata / 'Users').write_bytes(b'CI save preservation sentinel')
        # Install from the packaged layout, which adds the player README beside installer/.
        import package_release
        package_release.write_archive(ROOT, Path(directory) / 'release.zip')
        with ZipFile(Path(directory) / 'release.zip') as release:
            release.extractall(Path(directory) / 'release')
        source_root = install.ROOT
        install.ROOT = Path(directory) / 'release' / package_release.PAYLOAD_DIR
        try:
            install.install(ports, BUILD / 'port.zip', refresh=False)
            install.install(ports, BUILD / 'port.zip', refresh=False)
        finally:
            install.ROOT = source_root
        with ZipFile(ports / install.GAME_DIR / 'zeldadoi.port') as port:
            if port.read('assets/game.droid') != rebuilt:
                raise ValueError('Installed game differs from the clean build.')
        if (savedata / 'Users').read_bytes() != b'CI save preservation sentinel':
            raise ValueError('Installer changed savedata.')


def main():
    parser = argparse.ArgumentParser(description='Build and verify the pinned PortMaster VM patch on Linux x86-64.')
    parser.add_argument('--utmt', type=Path, help='Use an existing UndertaleModCli 0.9.2.0 installation.')
    parser.add_argument('--upstream-zip', type=Path, help='Use an existing pinned PortMaster download.')
    parser.add_argument('--check-release', action='store_true', help='Compare the checked-in delta with a clean build and install it twice.')
    parser.add_argument('--runtime-tests', action='store_true', help='Also compile a separate instrumented game for the Nova harness.')
    args = parser.parse_args()
    BUILD.mkdir(exist_ok=True)
    manifest = json.loads((ROOT / 'installer/manifest.json').read_text())
    upstream = args.upstream_zip or download(manifest['upstream_url'], BUILD / 'port.zip', manifest['upstream_sha256'])
    original = extract_original(upstream, manifest)
    if upstream.resolve() != (BUILD / 'port.zip').resolve():
        shutil.copyfile(upstream, BUILD / 'port.zip')
    tool = args.utmt.resolve() if args.utmt else toolchain()
    output = BUILD / 'patched.droid'
    run_umt(tool, BUILD / 'game.droid', 'src/apply.csx', output, 'Dungeons of Infinity and Beyond patch compiled.')
    verify_runner_format(output.read_bytes())
    run_umt(tool, output, 'tests/verify.csx', sentinel='NOVA BUILD VERIFIED')
    if args.check_release:
        check_release(original, output.read_bytes(), manifest)
    if args.runtime_tests:
        run_umt(tool, output, 'tests/runtime/inject.csx', BUILD / 'runtime-tests.droid', 'NOVA TEST HARNESS COMPILED')
        run_umt(tool, BUILD / 'game.droid', 'tests/runtime/inject.csx', BUILD / 'runtime-baseline.droid', 'NOVA TEST HARNESS COMPILED')
        verify_runner_format((BUILD / 'runtime-tests.droid').read_bytes())
        verify_runner_format((BUILD / 'runtime-baseline.droid').read_bytes())
        run_umt(tool, output, 'tests/village.csx', BUILD / 'village-preview.droid', 'NOVA VILLAGE PREVIEW COMPILED')
        verify_runner_format((BUILD / 'village-preview.droid').read_bytes())
    summary = {'compiled': True, 'release_verified': args.check_release,
               'runtime_harness_compiled': args.runtime_tests,
               'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}
    (BUILD / 'build-report.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
