import bz2
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import install


def integer(value):
    return (abs(value) | ((1 << 63) if value < 0 else 0)).to_bytes(8, 'little')


def binary_patch(controls, diff, extra, size):
    control = bz2.compress(b''.join(integer(value) for triple in controls for value in triple))
    difference = bz2.compress(diff)
    return b'BSDIFF40' + integer(len(control)) + integer(len(difference)) + integer(size) + control + difference + bz2.compress(extra)


class InstallerTests(unittest.TestCase):
    def test_backward_copy_and_insert(self):
        data = binary_patch([(3, 1, -3), (2, 0, 0)], b'\x02\x02\x02\x00\x00', b'!', 6)
        self.assertEqual(install.apply_patch(b'ABCDE', data, 6), b'CDE!AB')

    def test_copy_outside_original_uses_zero(self):
        data = binary_patch([(1, 0, -2), (2, 0, 0)], bytes([0, ord('!'), ord('Z') - ord('A')]), b'', 3)
        self.assertEqual(install.apply_patch(b'ABCDE', data, 3), b'A!Z')

    def test_seek_without_output(self):
        data = binary_patch([(0, 0, 2), (3, 0, 0)], b'\x00\x00\x00', b'', 3)
        self.assertEqual(install.apply_patch(b'ABCDE', data, 3), b'CDE')

    def test_truncated_patch_fails(self):
        data = binary_patch([(6, 0, 0)], b'\x00', b'', 6)
        with self.assertRaises(ValueError):
            install.apply_patch(b'ABCDE', data, 6)

    def test_running_game_blocks_install_but_input_helper_does_not(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            game = root / 'zeldadoi-beyond'
            game.mkdir()
            proc = root / 'proc'

            def process(pid, *argv, cwd=game):
                entry = proc / str(pid)
                entry.mkdir(parents=True)
                (entry / 'cmdline').write_bytes(b'\0'.join(argv) + b'\0')
                (entry / 'cwd').symlink_to(cwd)
                return entry

            # The Ports launcher keeps gptokeyb running after the game exits.
            process(10715, b'/roms/ports/PortMaster/gptokeyb', b'-1', b'gmloadernext.aarch64')
            process(10716, b'./gmloadernext.aarch64', b'-c', b'gmloader.json', cwd=root)
            (proc / 'self').mkdir()
            install.ensure_game_stopped(game, proc)
            game_process = process(10717, b'./gmloadernext.aarch64', b'-c', b'gmloader.json')
            with self.assertRaisesRegex(RuntimeError, 'Close Dungeons of Infinity'):
                install.ensure_game_stopped(game, proc)
            (game_process / 'cmdline').write_bytes(b'')
            install.ensure_game_stopped(game, proc)

    def test_bad_download_keeps_existing_install(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = root / 'payload'
            (payload / 'patches').mkdir(parents=True)
            data = b'test patch'
            (payload / 'patches/game.droid.bsdiff').write_bytes(data)
            (payload / 'manifest.json').write_text(json.dumps({
                'patch_sha256': hashlib.sha256(data).hexdigest(),
                'upstream_sha256': '0' * 64,
            }))
            ports = root / 'ports'
            game = ports / install.GAME_DIR
            (game / 'savedata').mkdir(parents=True)
            (game / 'savedata/Users').write_bytes(b'keep this save')
            (game / 'zeldadoi.port').write_bytes(b'keep this game')
            upstream = root / 'bad.zip'
            upstream.write_bytes(b'invalid download')
            with patch.object(install, 'ROOT', payload):
                with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                    install.install(ports, upstream, refresh=False)
            self.assertEqual((game / 'savedata/Users').read_bytes(), b'keep this save')
            self.assertEqual((game / 'zeldadoi.port').read_bytes(), b'keep this game')
            self.assertFalse(list(ports.glob('.doi-install-*')))


    def legacy_ports(self, root):
        ports = root / 'ports'
        legacy = ports / install.LEGACY_GAME_DIR
        (legacy / 'savedata').mkdir(parents=True)
        (legacy / 'savedata/Users').write_bytes(b'4:3 save')
        (legacy / 'save-backups').mkdir()
        (legacy / 'save-backups/before-content-v3.zip').write_bytes(b'backup')
        (ports / install.LEGACY_LAUNCHER).write_text('old launcher')
        return ports, legacy

    def test_legacy_install_moves_to_the_new_folder(self):
        with tempfile.TemporaryDirectory() as temporary:
            ports, legacy = self.legacy_ports(Path(temporary))
            (ports / f'.{install.LEGACY_GAME_DIR}-update').mkdir()
            found = install.prepare_legacy(ports)
            self.assertEqual(found, legacy)
            self.assertTrue(legacy.is_dir(), 'Checks must not move anything')
            install.finish_legacy(ports, found)
            game = ports / install.GAME_DIR
            self.assertEqual((game / 'savedata/Users').read_bytes(), b'4:3 save')
            self.assertEqual((game / 'save-backups/before-content-v3.zip').read_bytes(), b'backup')
            self.assertFalse(legacy.exists())
            self.assertFalse((ports / install.LEGACY_LAUNCHER).exists())
            self.assertFalse((ports / f'.{install.LEGACY_GAME_DIR}-update').exists())

    def test_legacy_migration_refuses_two_folders(self):
        with tempfile.TemporaryDirectory() as temporary:
            ports, legacy = self.legacy_ports(Path(temporary))
            (ports / install.GAME_DIR).mkdir()
            with self.assertRaisesRegex(RuntimeError, 'Both'):
                install.prepare_legacy(ports)
            self.assertEqual((legacy / 'savedata/Users').read_bytes(), b'4:3 save')

    def test_legacy_migration_restores_an_interrupted_update_first(self):
        with tempfile.TemporaryDirectory() as temporary:
            ports, legacy = self.legacy_ports(Path(temporary))
            recovery = ports / f'.{install.LEGACY_GAME_DIR}-update' / 'recovery.py'
            recovery.parent.mkdir()
            recovery.write_text('')
            with patch.object(install.subprocess, 'run') as run:
                install.prepare_legacy(ports)
            command = run.call_args.args[0]
            self.assertEqual(command[1:], [str(recovery), 'recover', '--game-dir', str(legacy)])

    def test_failed_download_leaves_the_legacy_install_untouched(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            ports, legacy = self.legacy_ports(root)
            payload = root / 'payload'
            (payload / 'patches').mkdir(parents=True)
            data = b'test patch'
            (payload / 'patches/game.droid.bsdiff').write_bytes(data)
            (payload / 'manifest.json').write_text(json.dumps({'patch_sha256': hashlib.sha256(data).hexdigest(), 'upstream_sha256': '0' * 64}))
            upstream = root / 'bad.zip'
            upstream.write_bytes(b'invalid download')
            with patch.object(install, 'ROOT', payload):
                with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                    install.install(ports, upstream, refresh=False)
            self.assertEqual((legacy / 'savedata/Users').read_bytes(), b'4:3 save')
            self.assertTrue((ports / install.LEGACY_LAUNCHER).exists())
            self.assertFalse((ports / install.GAME_DIR).exists())

    def test_old_installer_is_removed_only_when_recognized(self):
        with tempfile.TemporaryDirectory() as temporary:
            ports = Path(temporary)
            payload = ports / install.LEGACY_PAYLOAD_DIR
            payload.mkdir()
            (ports / install.LEGACY_INSTALLER_LAUNCHER).write_text('old installer')
            install.remove_legacy_installer(ports)
            self.assertTrue(payload.exists(), 'An unrecognized folder must stay')
            (payload / 'install.py').write_text('')
            (payload / 'manifest.json').write_text('{}')
            install.remove_legacy_installer(ports)
            self.assertFalse(payload.exists())
            self.assertFalse((ports / install.LEGACY_INSTALLER_LAUNCHER).exists())


if __name__ == '__main__':
    unittest.main()
