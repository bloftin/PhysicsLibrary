"""Publication regressions using disposable copies, never modifying saved results."""
import contextlib
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify import DEFAULT_SITE, verify


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.site = Path(self.directory.name) / 'publication'
        shutil.copytree(DEFAULT_SITE, self.site)

    def test_complete_publication(self):
        with contextlib.redirect_stdout(io.StringIO()):
            verify(self.site)

    def test_missing_explorer(self):
        (self.site / 'index.html').unlink()
        with self.assertRaises(FileNotFoundError):
            verify(self.site)

    def test_modified_published_csv(self):
        with (self.site / 'after-bottom.csv').open('a') as stream:
            stream.write('unexpected data\n')
        with self.assertRaisesRegex(AssertionError, 'Changed file: after-bottom.csv'):
            verify(self.site)

    def test_stale_explorer_data(self):
        (self.site / 'trajectory-data.js').write_text('window.PLBrachistochrone = {};\n')
        with self.assertRaisesRegex(AssertionError, 'Changed file: trajectory-data.js'):
            verify(self.site)

    def test_draft_generator_rejected(self):
        path = self.site / 'build.json'
        report = json.loads(path.read_text())
        report['provenance']['generator'] = 'python-draft-reference'
        path.write_text(json.dumps(report))
        with self.assertRaisesRegex(AssertionError, 'Julia-generated'):
            verify(self.site)


if __name__ == '__main__':
    unittest.main()
