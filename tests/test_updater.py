import hashlib
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from zipfile import ZipFile

import updater


class ReleaseSelectionTests(unittest.TestCase):
    def release(self, version='1.6.0'):
        name = f'Dungeons-of-Infinity-4-3-v{version}-Nova-Patch-Installer.zip'
        return {'tag_name': 'v' + version, 'draft': False, 'prerelease': False, 'assets': [
            {'name': asset, 'state': 'uploaded', 'size': 100, 'digest': 'sha256:' + 'a' * 64,
             'browser_download_url': updater.DOWNLOAD + 'v' + version + '/' + asset}
            for asset in (name, name + '.sha256')]}

    def test_stable_updates_compare_numbers_and_promote_candidates(self):
        for installed in ('1.5.3', '1.6.0-rc.1', '1.5.99'):
            self.assertEqual(updater.select_release(self.release(), installed)['version'], '1.6.0')
        for installed in ('1.6.0', '1.7.0', '1.10.0'):
            self.assertIsNone(updater.select_release(self.release(), installed))
        self.assertGreater(updater.version_key('1.10.0'), updater.version_key('1.9.0'))

    def test_prereleases_drafts_external_downloads_and_missing_digests_fail(self):
        mutations = [lambda r: r.update(draft=True), lambda r: r.update(prerelease=True),
                     lambda r: r.update(tag_name='v1.6.0-rc.1'),
                     lambda r: r['assets'][0].update(digest=None),
                     lambda r: r['assets'][0].update(browser_download_url='https://example.com/update.zip'),
                     lambda r: r['assets'][0].update(size=updater.MAX_INSTALLER + 1)]
        for mutate in mutations:
            with self.subTest(mutate=mutate):
                release = self.release()
                mutate(release)
                with self.assertRaises((ValueError, TypeError)):
                    updater.select_release(release, '1.5.3')


    def test_changes_include_missed_stable_releases_in_version_order(self):
        releases = [dict(self.release(v), body='### Fixed\n- Changes in ' + v) for v in ('1.5.2', '1.5.3', '1.6.0')]
        releases.append(dict(self.release('1.6.0-rc.1'), prerelease=True, body='Candidate only'))
        notes = updater.changes_since(releases, '1.5.2', '1.6.0')
        self.assertLess(notes.index('1.6.0'), notes.index('1.5.3'))
        self.assertNotIn('1.5.2', notes)
        self.assertNotIn('Candidate', notes)

    def test_notes_keep_content_without_markdown_links_or_unsupported_symbols(self):
        body = "### Fixed\n- Keep **saves** and `settings`.\n- Read [details](https://example.com).\n[Changes from v1.0.0](https://example.com/compare).\nDon’t lose progress — retry."
        notes = updater.plain_release_notes(body)
        self.assertIn('- Keep saves and settings.', notes)
        self.assertIn('- Read details.', notes)
        self.assertIn("Don't lose progress - retry.", notes)
        self.assertNotIn('https://', notes)
        self.assertNotIn('Changes from', notes)

    def test_archive_traversal_is_rejected_before_extraction(self):
        buffer = io.BytesIO()
        with ZipFile(buffer, 'w') as archive:
            archive.writestr('zeldadoi-43-installer/../../escape', 'bad')
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, 'archive'):
                updater.unpack_installer(buffer.getvalue(), Path(directory), '1.6.0')
            self.assertFalse((Path(directory).parent / 'escape').exists())

    def test_network_failure_does_not_change_installed_files(self):
        with tempfile.TemporaryDirectory() as directory:
            game = Path(directory)
            (game / 'gmloader.json').write_text('{"save_dir":"savedata"}')
            (game / 'patch-version.txt').write_text('1.5.3')
            worker = updater.Updater(game)
            with patch.object(updater, 'fetch', side_effect=OSError('offline')):
                with self.assertRaises(OSError):
                    worker.check()
            self.assertEqual((game / 'patch-version.txt').read_text(), '1.5.3')
            self.assertFalse((worker.work / 'ready.json').exists())


class UpdateTransactionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.ports = Path(self.temp.name)
        self.game = self.ports / updater.GAME
        (self.game / 'savedata').mkdir(parents=True)
        (self.game / 'savedata/Users').write_bytes(b'keep my save')
        (self.game / 'save-backups').mkdir()
        (self.game / 'save-backups/old.zip').write_bytes(b'keep my backup')
        (self.game / 'gmloader.json').write_text('{"save_dir":"savedata"}')
        (self.game / 'patch-version.txt').write_text('1.5.3')
        (self.game / 'zeldadoi.port').write_bytes(b'old game')
        (self.ports / updater.LAUNCHER).write_text('old launcher')
        self.worker = updater.Updater(self.game)
        payload = self.worker.work / 'prepared/zeldadoi-43-installer'
        payload.mkdir(parents=True)
        (payload / 'manifest.json').write_text(json.dumps({'patched_game_sha256': hashlib.sha256(b'new game').hexdigest()}))
        updater.write_json(self.worker.work / 'ready.json', {'id': 'test', 'version': '1.6.0'})
        updater.write_json(self.worker.request, {'id': 'test', 'action': 'restart'})
        self.addCleanup(patch.stopall)
        patch('install.ensure_game_stopped').start()
        patch.object(updater.os, 'sync').start()

    def fake_install(self, command, **kwargs):
        ports = Path(command[command.index('--ports-dir') + 1])
        game = ports / updater.GAME
        with ZipFile(game / 'zeldadoi.port', 'w') as archive:
            archive.writestr('assets/game.droid', b'new game')
        (game / 'patch-version.txt').write_text('1.6.0')
        (ports / updater.LAUNCHER).write_text('new launcher')

    def assert_old_game(self):
        self.assertEqual((self.game / 'zeldadoi.port').read_bytes(), b'old game')
        self.assertEqual((self.ports / updater.LAUNCHER).read_text(), 'old launcher')
        self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'keep my save')
        self.assertEqual((self.game / 'save-backups/old.zip').read_bytes(), b'keep my backup')

    def test_install_switches_only_after_verification_and_preserves_saves(self):
        with patch.object(updater.subprocess, 'run', side_effect=self.fake_install):
            self.assertTrue(self.worker.apply())
        with ZipFile(self.game / 'zeldadoi.port') as archive:
            self.assertEqual(archive.read('assets/game.droid'), b'new game')
        self.assertEqual((self.ports / updater.LAUNCHER).read_text(), 'new launcher')
        self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'keep my save')
        self.assertEqual((self.game / 'save-backups/old.zip').read_bytes(), b'keep my backup')
        self.assertFalse(self.worker.work.exists())

    def test_installer_failure_preserves_playable_game(self):
        with patch.object(updater.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'installer')):
            with self.assertRaises(subprocess.CalledProcessError):
                self.worker.apply()
        self.assert_old_game()

    def test_checksum_failure_preserves_playable_game(self):
        def wrong_game(*args, **kwargs):
            self.fake_install(*args, **kwargs)
            (self.worker.work / 'stage' / updater.GAME / 'patch-version.txt').write_text('wrong')
        with patch.object(updater.subprocess, 'run', side_effect=wrong_game):
            with self.assertRaises(ValueError):
                self.worker.apply()
        self.assert_old_game()

    def test_old_cleanup_remnants_cannot_replace_current_saves(self):
        previous = self.worker.work / 'previous'
        previous.mkdir()
        (previous / 'stale-save').write_text('obsolete')
        with patch.object(updater.subprocess, 'run', side_effect=self.fake_install):
            self.assertTrue(self.worker.apply())
        self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'keep my save')
        self.assertFalse((self.game / 'stale-save').exists())

    def test_launcher_switch_failure_restores_both_game_and_launcher(self):
        replace = Path.replace
        failed = False
        def fail_once(source, target):
            nonlocal failed
            if source.parent == self.worker.work / 'stage' and not failed:
                failed = True
                raise OSError('simulated filesystem failure')
            return replace(source, target)
        with patch.object(updater.subprocess, 'run', side_effect=self.fake_install), patch.object(Path, 'replace', fail_once):
            with self.assertRaises(OSError):
                self.worker.apply()
        self.assertTrue(failed)
        self.assert_old_game()
        self.assertFalse((self.worker.work / 'transaction.json').exists())

    def test_cancel_or_stale_request_cannot_install(self):
        for request in ({'id': 'test', 'action': 'cancel'}, {'id': 'another', 'action': 'restart'}):
            updater.write_json(self.worker.work / 'ready.json', {'id': 'test', 'version': '1.6.0'})
            updater.write_json(self.worker.request, request)
            with patch.object(updater.subprocess, 'run') as install:
                self.assertFalse(self.worker.apply())
                install.assert_not_called()
            self.assert_old_game()

    def test_power_loss_after_each_switch_step_can_recover(self):
        for stage in (0, 1, 2):
            with self.subTest(stage=stage):
                old = self.worker.work / 'previous'
                (self.worker.work / 'previous-launcher.sh').write_text('old launcher')
                updater.write_json(self.worker.work / 'transaction.json', {'version': '1.6.0'})
                self.game.replace(old)
                if stage >= 1:
                    self.game.mkdir()
                    (self.game / 'gmloader.json').write_text('{"save_dir":"savedata"}')
                    (self.game / 'patch-version.txt').write_text('1.6.0')
                if stage == 2:
                    (self.ports / updater.LAUNCHER).write_text('new launcher')
                updater.Updater(self.game).recover()
                self.assert_old_game()
                self.assertFalse((self.worker.work / 'transaction.json').exists())


class DownloadAndInstallTests(unittest.TestCase):
    def setUp(self):
        from tests.test_install import binary_patch
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.game = self.root / updater.GAME
        (self.game / 'savedata').mkdir(parents=True)
        (self.game / 'savedata/Users').write_bytes(b'keep this save')
        (self.game / 'gmloader.json').write_text('{"save_dir":"savedata"}')
        (self.game / 'patch-version.txt').write_text('1.5.3')
        (self.root / updater.LAUNCHER).write_text('old launcher')
        self.worker = updater.Updater(self.game)
        self.worker.request_id = 'download'
        updater.write_json(self.worker.request, {'id': 'download', 'action': 'install'})
        original = b'original game'
        updated = b'updated game'
        port = io.BytesIO()
        with ZipFile(port, 'w') as archive:
            archive.writestr('assets/game.droid', original)
        upstream = io.BytesIO()
        with ZipFile(upstream, 'w') as archive:
            archive.writestr('zeldadoi/zeldadoi.port', port.getvalue())
            archive.writestr('zeldadoi/gmloader.json', '{"save_dir":"savedata"}')
        self.upstream = upstream.getvalue()
        delta = binary_patch([(0, len(updated), 0)], b'', updated, len(updated))
        self.url = 'https://github.com/PortsMaster-MV/PortMaster-MV-New/releases/download/fixture/test.zip'
        manifest = {'version': '1.6.0', 'save_schema': 3, 'upstream_url': self.url,
                    'upstream_sha256': hashlib.sha256(self.upstream).hexdigest(),
                    'original_game_sha256': hashlib.sha256(original).hexdigest(),
                    'patched_game_sha256': hashlib.sha256(updated).hexdigest(),
                    'patched_game_size': len(updated), 'patch_sha256': hashlib.sha256(delta).hexdigest()}
        installer = io.BytesIO()
        root = Path(__file__).resolve().parents[1]
        with ZipFile(installer, 'w') as archive:
            for name in ('install.py', 'controller.py', 'updater.py', 'README.md', 'gameinfo.xml', updater.LAUNCHER):
                archive.writestr('zeldadoi-43-installer/' + name, (root / name if name == 'README.md' else root / 'installer' / name).read_bytes())
            archive.writestr('zeldadoi-43-installer/manifest.json', json.dumps(manifest))
            archive.writestr('zeldadoi-43-installer/patches/game.droid.bsdiff', delta)
        self.installer = installer.getvalue()
        self.worker.release = {'version': '1.6.0', 'name': 'Dungeons-of-Infinity-4-3-v1.6.0-Nova-Patch-Installer.zip',
                               'sha256': hashlib.sha256(self.installer).hexdigest(), 'size': len(self.installer)}

    def fetch(self, url, limit, progress=None):
        if url.endswith('.sha256'):
            r = self.worker.release
            return (r['sha256'] + '  ' + r['name'] + '\n').encode()
        data = self.upstream if url == self.url else self.installer
        if progress:
            progress(len(data), len(data))
        return data

    def test_verified_download_runs_real_installer_and_keeps_save_backups(self):
        with patch.object(updater, 'fetch', side_effect=self.fetch), patch.object(updater.os, 'sync'):
            self.worker.prepare()
            self.assertEqual(updater.read_json(self.worker.status)['state'], 'ready')
            self.assertEqual((self.game / 'patch-version.txt').read_text(), '1.5.3')
            updater.write_json(self.worker.request, {'id': 'download', 'action': 'restart'})
            self.assertTrue(self.worker.apply())
        self.assertEqual((self.game / 'savedata/Users').read_bytes(), b'keep this save')
        self.assertEqual((self.game / 'patch-version.txt').read_text().strip(), '1.6.0')
        with ZipFile(self.game / 'save-backups/before-content-v3.zip') as archive:
            self.assertEqual(archive.read('Users'), b'keep this save')

    def test_corrupt_download_cannot_be_marked_ready(self):
        self.worker.release['sha256'] = 'a' * 64
        with patch.object(updater, 'fetch', side_effect=self.fetch):
            with self.assertRaisesRegex(ValueError, 'checksum'):
                self.worker.prepare()
        self.assertFalse((self.worker.work / 'ready.json').exists())
        self.assertEqual((self.game / 'patch-version.txt').read_text(), '1.5.3')

    def test_cancel_during_download_cannot_be_marked_ready(self):
        updater.write_json(self.worker.request, {'id': 'cancelled', 'action': 'cancel'})
        with patch.object(updater, 'fetch', side_effect=self.fetch):
            with self.assertRaises(updater.Cancelled):
                self.worker.prepare()
        self.assertFalse((self.worker.work / 'ready.json').exists())

    def test_low_disk_space_cannot_be_marked_ready(self):
        from collections import namedtuple
        usage = namedtuple('usage', 'total used free')(100, 100, 0)
        with patch.object(updater, 'fetch', side_effect=self.fetch), patch.object(updater.shutil, 'disk_usage', return_value=usage):
            with self.assertRaisesRegex(ValueError, 'free space'):
                self.worker.prepare()
        self.assertFalse((self.worker.work / 'ready.json').exists())
