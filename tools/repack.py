import hashlib
import sys
from pathlib import Path
from zipfile import ZipFile

source, data, output = map(Path, sys.argv[1:])
expected = 'd1c7f76420650d27d1abd6003657e81841efe5c28d35f012166a3ec4b981c047'
if source.resolve() == output.resolve():
    raise SystemExit('Use a separate output archive.')
with ZipFile(source) as original:
    if hashlib.sha256(original.read('assets/game.droid')).hexdigest() != expected:
        raise SystemExit('The input must be the unmodified PortMaster 1.1.6 VM archive.')
    with ZipFile(output, 'x') as patched:
        for entry in original.infolist():
            content = data.read_bytes() if entry.filename == 'assets/game.droid' else original.read(entry)
            patched.writestr(entry, content)
