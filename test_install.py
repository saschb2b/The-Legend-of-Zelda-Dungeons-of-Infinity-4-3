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
            self.assertFalse(list(ports.glob('.doi43-install-*')))


if __name__ == '__main__':
    unittest.main()
