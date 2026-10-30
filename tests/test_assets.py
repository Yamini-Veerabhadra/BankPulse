
"""Integrity checks for source data, Power BI report structure and screenshots."""

import hashlib
import json
import struct
import unittest
import zipfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# SHA-256 of source CSV normalized to LF line endings.
SOURCE_SHA256 = (
    "0ee1d5b8ace45dc84c6059e7bd52f5993731339bf25c9eecdec9bb277a25e6f9"
)


def validate_png(path):
    with path.open("rb") as fh:
        assert fh.read(8) == b"\x89PNG\r\n\x1a\n", f"Not a PNG: {path}"

        found_ihdr = found_iend = False

        while True:
            length_bytes = fh.read(4)
            assert len(length_bytes) == 4, "Unexpected PNG end-of-file"

            size = struct.unpack(">I", length_bytes)[0]
            kind = fh.read(4)
            payload = fh.read(size)
            crc = struct.unpack(">I", fh.read(4))[0]

            assert zlib.crc32(kind + payload) & 0xffffffff == crc, (
                f"CRC failed: {kind}"
            )

            if kind == b"IHDR":
                found_ihdr = True
                width, height = struct.unpack(">II", payload[:8])
                assert width > 500 and height > 400

            if kind == b"IEND":
                found_iend = True
                assert fh.read(1) == b"", "Unexpected trailing image data"
                break

        return found_ihdr and found_iend


class RepoAssetTests(unittest.TestCase):

    def test_bundled_csv_unchanged(self):
        source_bytes = (
            ROOT / "data/raw/bank-full.csv"
        ).read_bytes()

        # Normalize Windows CRLF to Linux LF.
        # This preserves the CSV data while removing
        # platform-specific newline differences.
        canonical_bytes = source_bytes.replace(
            b"\r\n", b"\n"
        )

        digest = hashlib.sha256(
            canonical_bytes
        ).hexdigest()

        self.assertEqual(digest, SOURCE_SHA256)

    def test_powerbi_package_json_integrity_and_expected_visuals(self):
        p = ROOT / "powerbi/BankPulse_Dashboard.pbix"

        with zipfile.ZipFile(p) as report:
            self.assertIsNone(report.testzip())

            names = report.namelist()
            self.assertIn("DataModel", names)

            pages = json.loads(
                report.read("Report/definition/pages/pages.json")
            )

            page_ids = pages["pageOrder"]
            self.assertEqual(len(page_ids), 2)

            page_names = [
                json.loads(
                    report.read(
                        f"Report/definition/pages/{n}/page.json"
                    )
                )["displayName"]
                for n in page_ids
            ]

            self.assertEqual(
                page_names,
                [
                    "Campaign Overview",
                    "Customer & Campaign Insights",
                ],
            )

            visuals = [
                n for n in names
                if n.endswith("/visual.json")
            ]

            self.assertEqual(len(visuals), 17)

            for name in visuals:
                json.loads(report.read(name))

            preview = json.dumps([
                json.loads(report.read(n))
                for n in visuals
            ])

            for expected in (
                "Total Campaign Records",
                "Total Subscriptions",
                "Conversion Rate",
            ):
                self.assertIn(expected, preview)

    def test_powerbi_approved_saved_revision(self):
        digest = hashlib.sha256(
            (
                ROOT / "powerbi/BankPulse_Dashboard.pbix"
            ).read_bytes()
        ).hexdigest()

        self.assertEqual(
            digest,
            "fe5f767cec2741e5e5327cac858967c44b6f17eb3a0081bfd8c9da87b8c3c038",
        )

    def test_screenshots_are_uncorrupted_pngs(self):
        for filename in [
            "campaign_overview.png",
            "customer_campaign_insights.png",
        ]:
            with self.subTest(filename=filename):
                self.assertTrue(
                    validate_png(ROOT / "screenshots" / filename)
                )

    def test_readme_internal_links_resolve(self):
        import re

        readme = (
            ROOT / "README.md"
        ).read_text(encoding="utf-8")

        links = re.findall(
            r"!?\[[^\]]+\]\(([^)]+)\)",
            readme,
        )

        local = [
            link.split("#", 1)[0]
            for link in links
            if not link.startswith(
                ("http://", "https://", "mailto:", "#")
            )
        ]

        self.assertGreaterEqual(len(local), 13)

        for item in local:
            with self.subTest(link=item):
                self.assertTrue(
                    (ROOT / item).is_file(),
                    f"Broken README link: {item}",
                )

    def test_no_accidental_private_paths_or_project_histories(self):
        # Root .git is normal in a cloned repository.
        # Nested Git repositories should not be included.
        self.assertFalse(
            any(
                p != ROOT / ".git"
                for p in ROOT.rglob(".git")
            )
        )

        self.assertFalse(
            (ROOT / "SQL password.sql").exists()
        )

        for path in ROOT.rglob("*"):
            if (
                "__pycache__" in path.parts
                or ".venv" in path.parts
            ):
                continue

            if path.is_file():
                self.assertNotEqual(
                    path.suffix.lower(),
                    ".env",
                )


if __name__ == "__main__":
    unittest.main()
