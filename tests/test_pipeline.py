import io
import json
import struct
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from zipfile import ZipFile

import build
import install
from test_install import binary_patch
from hashlib import sha256


class InstallIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.payload = self.root / 'payload'
        (self.payload / 'patches').mkdir(parents=True)
        self.original = b'original game'
        self.patched = b'patched game'
        self.delta = binary_patch([(0, len(self.patched), 0)], b'', self.patched, len(self.patched))
        (self.payload / 'patches/game.droid.bsdiff').write_bytes(self.delta)
        for name in ('README.md', 'controller.py', 'updater.py', 'install.py', 'gameinfo.xml', install.LAUNCHER):
            (self.payload / name).write_text('fixture')
        self.upstream = self.root / 'upstream.zip'
        self.make_upstream()
        self.manifest = {
            'version': 'test', 'patch_sha256': sha256(self.delta).hexdigest(),
            'upstream_sha256': sha256(self.upstream.read_bytes()).hexdigest(),
            'original_game_sha256': sha256(self.original).hexdigest(),
            'patched_game_sha256': sha256(self.patched).hexdigest(),
            'patched_game_size': len(self.patched),
        }
        self.ports = self.root / 'ports'
        self.game = self.ports / install.GAME_DIR
        (self.game / 'savedata').mkdir(parents=True)
        (self.game / 'savedata/Users').write_bytes(b'precious save')
        (self.game / 'zeldadoi.port').write_bytes(b'existing game')
        (self.ports / install.LAUNCHER).write_text('existing launcher')
        self.addCleanup(patch.stopall)
        patch.object(install, 'ROOT', self.payload).start()
        patch.object(install, 'ensure_game_stopped').start()

    def make_upstream(self, extra=None):
        buffer = io.BytesIO()
        with ZipFile(buffer, 'w') as port:
            port.writestr('assets/game.droid', self.original)
            port.writestr('assets/audio.ogg', b'unchanged audio')
        with ZipFile(self.upstream, 'w') as archive:
            archive.writestr('zeldadoi/zeldadoi.port', buffer.getvalue())
            archive.writestr('zeldadoi/gmloadernext.aarch64', b'runner')
            archive.writestr('zeldadoi/cover.png', b'cover')
            if extra:
                archive.writestr(extra, b'untrusted path')

    def run_install(self):
        (self.payload / 'manifest.json').write_text(json.dumps(self.manifest))
        install.install(self.ports, self.upstream, refresh=False)

    def assert_preserved(self):
        self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'precious save')
        self.assertEqual((self.game / 'zeldadoi.port').read_bytes(), b'existing game')
        self.assertEqual((self.ports / install.LAUNCHER).read_text(), 'existing launcher')
        self.assertFalse(list(self.ports.glob('.doi43-install-*')))

    def test_install_and_reinstall_preserve_saves_and_assets(self):
        for _ in range(2):
            self.run_install()
            with ZipFile(self.game / 'zeldadoi.port') as port:
                self.assertEqual(port.read('assets/game.droid'), self.patched)
                self.assertEqual(port.read('assets/audio.ogg'), b'unchanged audio')
            self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'precious save')
            self.assertEqual((self.game / 'patch-version.txt').read_text(), 'test\n')
            self.assertEqual((self.game / 'controller.py').read_text(), 'fixture')
            self.assertTrue((self.ports / install.LAUNCHER).stat().st_mode & 0o111)

    def test_inventory_migration_backup_survives_reinstallation(self):
        self.manifest['save_schema'] = 2
        self.run_install()
        backup = self.game / 'save-backups/before-inventory-v1.zip'
        original_backup = backup.read_bytes()
        with ZipFile(backup) as archive:
            self.assertEqual(archive.read('Users'), b'precious save')
        (self.game / 'savedata/Users').write_bytes(b'new schema save')
        self.run_install()
        self.assertEqual(backup.read_bytes(), original_backup)
        self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'new schema save')
        self.assertEqual((self.game / 'save-schema.txt').read_text(), '2\n')

    def test_every_checksum_failure_keeps_the_existing_install(self):
        for field in ('patch_sha256', 'upstream_sha256', 'original_game_sha256', 'patched_game_sha256'):
            with self.subTest(field=field):
                digest = self.manifest[field]
                self.manifest[field] = '0' * 64
                with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                    self.run_install()
                self.assert_preserved()
                self.manifest[field] = digest

    def test_content_upgrade_backs_up_schema_two_saves_once(self):
        (self.game / 'save-schema.txt').write_text('2\n')
        self.manifest['save_schema'] = 3
        self.run_install()
        backup = self.game / 'save-backups/before-content-v3.zip'
        snapshot = backup.read_bytes()
        with ZipFile(backup) as archive:
            self.assertEqual(archive.read('Users'), b'precious save')
        (self.game / 'savedata/Users').write_bytes(b'Topaz and challenge settings')
        self.run_install()
        self.assertEqual(backup.read_bytes(), snapshot)
        self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'Topaz and challenge settings')
        self.assertEqual((self.game / 'save-schema.txt').read_text(), '3\n')

    def test_archive_traversal_fails_before_commit(self):
        self.make_upstream('zeldadoi/../../escape')
        self.manifest['upstream_sha256'] = sha256(self.upstream.read_bytes()).hexdigest()
        with self.assertRaisesRegex(ValueError, 'Invalid package path'):
            self.run_install()
        self.assert_preserved()
        self.assertFalse((self.root / 'escape').exists())

    def test_running_game_blocks_the_install(self):
        install.ensure_game_stopped.side_effect = RuntimeError('Close the game')
        with self.assertRaisesRegex(RuntimeError, 'Close the game'):
            self.run_install()
        self.assert_preserved()


class BuildTests(unittest.TestCase):
    def test_runner_rejects_a_function_table_without_locals(self):
        def game(payload):
            chunk = b'FUNC' + struct.pack('<I', len(payload)) + payload
            return b'FORM' + struct.pack('<I', len(chunk)) + chunk
        functions = struct.pack('<I', 3) + bytes(3 * 12)
        with self.assertRaisesRegex(ValueError, 'locals table is missing'):
            build.verify_runner_format(game(functions))
        build.verify_runner_format(game(functions + struct.pack('<I', 0)))
        with self.assertRaisesRegex(ValueError, 'truncated'):
            build.verify_runner_format(game(functions + struct.pack('<I', 1)))

    def test_compiler_zero_exit_without_completion_marker_fails(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(build, 'BUILD', Path(temporary)):
            tool = Path(temporary) / 'fake-compiler'
            tool.write_text('#!/bin/sh\necho "Script exception"\nexit 0\n')
            tool.chmod(0o755)
            with self.assertRaisesRegex(RuntimeError, 'Compiler failed'):
                build.run_umt(tool, Path('fixture'), 'apply.csx', sentinel='compiled')

    def test_cached_download_is_verified(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'cached.zip'
            path.write_bytes(b'corrupt cache')
            with patch('urllib.request.urlopen') as network:
                with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                    build.download('https://example.invalid/archive', path, '0' * 64)
                network.assert_not_called()

    def test_failed_download_leaves_no_cache_entry(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'cached.zip'
            with patch('urllib.request.urlopen', return_value=io.BytesIO(b'bad download')):
                with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                    build.download('https://example.invalid/archive', path, '0' * 64)
            self.assertFalse(path.exists())
            self.assertFalse(path.with_suffix('.download').exists())


class ReleaseTests(unittest.TestCase):
    def test_archive_contains_only_the_patch_installer_allowlist(self):
        import package_release
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'patches').mkdir()
            names = (*package_release.PAYLOAD_FILES, package_release.INSTALLER_LAUNCHER)
            for name in names:
                (root / name).write_text(name)
            (root / 'game.droid').write_bytes(b'game must not ship')
            (root / 'runtime-tests.droid').write_bytes(b'test build must not ship')
            first, second = root / 'a.zip', root / 'b.zip'
            package_release.write_archive(root, first)
            package_release.write_archive(root, second)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            with ZipFile(first) as archive:
                self.assertEqual(set(archive.namelist()), {
                    package_release.INSTALLER_LAUNCHER,
                    *('zeldadoi-43-installer/' + name for name in package_release.PAYLOAD_FILES),
                })
                self.assertTrue(archive.getinfo(package_release.INSTALLER_LAUNCHER).external_attr >> 16 & 0o111)
            with self.assertRaises(FileExistsError):
                package_release.write_archive(root, first)

    def test_instrumented_build_cannot_be_released(self):
        from package_release import validate_production
        for name in (b'oNovaTests', b'NovaTestInput', b'oNovaVillageTest'):
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, 'Instrumented'):
                validate_production(b'FORM' + name + b'\0')
