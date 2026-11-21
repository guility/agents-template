import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class GoCoverageMetricsTests(unittest.TestCase):
    def test_reports_statement_coverage_without_claiming_line_or_branch(self) -> None:
        sys.path.insert(0, str(ROOT / "scripts/ci/quality-tools/metrics"))
        from metric_reports import go_metrics

        profile = """mode: set
example.go:1.1,2.2 2 1
example.go:3.1,5.2 4 0
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "coverage.out"
            path.write_text(profile)
            result = go_metrics(path)

        self.assertEqual(result["statement_coverage"], 33.33)
        self.assertEqual(result["line_coverage"], "n/a")
        self.assertEqual(result["branch_coverage"], "n/a")
