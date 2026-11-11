"""Regression checks for publication-bound formula synchronization."""

from __future__ import annotations

import importlib.util
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
SPEC = importlib.util.spec_from_file_location("sync_formula", ROOT / "scripts/sync_remove_ai_watermarks.py")
sync = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = sync
SPEC.loader.exec_module(sync)

SOURCE = (ROOT / "Formula/remove-ai-watermarks.rb").read_text()
# Keep a revision in the fixture even after the next source release resets it.
SOURCE = re.sub(r"(?m)^  revision [0-9]+\n", "", SOURCE).replace(
    '  license "Apache-2.0"', '  license "Apache-2.0"\n  revision 1'
)
OLD_URL = SOURCE.split('  url "', 1)[1].split('"', 1)[0]
OLD_SHA = SOURCE.split('  sha256 "', 1)[1].split('"', 1)[0]
NEW_URL = "https://files.pythonhosted.org/packages/ab/cd/remove_ai_watermarks-0.99.0.tar.gz"


def metadata():
    return {
        "info": {
            "name": "remove-ai-watermarks",
            "version": "0.99.0",
            "provides_extra": ["visible", "video", "future-extra", "diffusion"],
            "yanked": False,
        },
        "urls": [{"packagetype": "sdist", "url": NEW_URL, "digests": {"sha256": "a" * 64}}],
    }


class FormulaSyncTests(unittest.TestCase):
    def test_new_extra_reaches_native_options_and_resets_revision(self):
        release = sync.parse_release(metadata(), "0.99.0", NEW_URL, "a" * 64)
        output = sync.render_formula(SOURCE, release)
        self.assertIn('  url "' + NEW_URL + '"', output)
        self.assertIn('  sha256 "' + "a" * 64 + '"', output)
        self.assertIn("    future-extra\n", output)
        self.assertNotIn("    classify\n", output)
        self.assertNotIn("  revision ", output)
        self.assertIn('option "with-#{extra}"', output)
        self.assertIn("def selected_extras", output)

    def test_same_artifact_keeps_revision_and_is_idempotent(self):
        release = sync.Release("0.56.0", OLD_URL, OLD_SHA, ("diffusion", "video", "visible"))
        output = sync.render_formula(SOURCE, release)
        self.assertIn("  revision 1\n", output)
        self.assertEqual(output, sync.render_formula(output, release))

    def test_source_identity_mismatch_is_rejected(self):
        for version, url, sha in [
            ("0.98.0", NEW_URL, "a" * 64),
            ("0.99.0", "https://example.org/wrong.tar.gz", "a" * 64),
            ("0.99.0", NEW_URL, "b" * 64),
        ]:
            with self.subTest(version=version, url=url, sha=sha), self.assertRaises(ValueError):
                sync.parse_release(metadata(), version, url, sha)

    def test_invalid_extra_and_missing_inventory_are_rejected(self):
        for extras in [None, [], ["video"], ["visible", "broken]"], ["visible", 3]]:
            data = metadata()
            data["info"]["provides_extra"] = extras
            with self.subTest(extras=extras), self.assertRaises(ValueError):
                sync.parse_release(data, "0.99.0", None, None)

    def test_unsafe_archive_url_and_digest_are_rejected(self):
        for url, sha in [("https://example.org/source.tar.gz", "a" * 64), (NEW_URL, "not-a-digest")]:
            data = metadata()
            data["urls"][0]["url"] = url
            data["urls"][0]["digests"]["sha256"] = sha
            with self.subTest(url=url, sha=sha), self.assertRaises(ValueError):
                sync.parse_release(data, "0.99.0", None, None)

    def test_yanked_release_is_rejected(self):
        data = metadata()
        data["info"]["yanked"] = True
        with self.assertRaises(ValueError):
            sync.parse_release(data, "0.99.0", None, None)

    def test_broken_formula_shape_is_rejected(self):
        release = sync.parse_release(metadata(), "0.99.0", None, None)
        for text in [
            SOURCE.replace(sync.BEGIN, "# missing marker"),
            SOURCE + '\n  sha256 "' + OLD_SHA + '"\n',
            SOURCE.replace('  url "', '  changed_url "'),
        ]:
            with self.subTest(text=text[-80:]), self.assertRaises(ValueError):
                sync.render_formula(text, release)

    def test_check_never_writes_and_reports_stale_then_updated(self):
        with tempfile.TemporaryDirectory(prefix="raiw-tap-sync-") as directory:
            formula = Path(directory) / "formula.rb"
            formula.write_text(SOURCE)
            args = ["sync", "--formula", str(formula), "--version", "0.99.0"]
            with patch.object(sync, "fetch_release", return_value=metadata()), self.assertLogs(sync.log):
                with patch.object(sys, "argv", [*args, "--check"]):
                    self.assertEqual(sync.main(), 1)
                self.assertEqual(formula.read_text(), SOURCE)
                with patch.object(sys, "argv", args):
                    self.assertEqual(sync.main(), 0)
                updated = formula.read_text()
                self.assertIn("    future-extra\n", updated)
                with patch.object(sys, "argv", [*args, "--check"]):
                    self.assertEqual(sync.main(), 0)
                self.assertEqual(formula.read_text(), updated)
                self.assertFalse(formula.with_suffix(".rb.tmp").exists())


if __name__ == "__main__":
    unittest.main()
