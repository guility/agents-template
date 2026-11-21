import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "scripts/ci/quality-tools"))

from metrics.lint_metrics import lint_result
from metrics.security_metrics import sast_result, secrets_result


class LintMetricTests(unittest.TestCase):
    def test_missing_component_results_are_not_marked_passed(self):
        with tempfile.TemporaryDirectory() as directory:
            result = lint_result(Path(directory), "rust")

        self.assertEqual("n/a", result)

    def test_result_uses_a_lint_check_that_ran(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "fast"
            root.mkdir(parents=True)
            (root / "go.status").write_text("passed\n")

            result = lint_result(Path(directory), "go")

        self.assertEqual("passed", result)

    def test_fast_pass_is_not_enough_when_mr_slow_check_is_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "fast"
            root.mkdir(parents=True)
            (root / "python.status").write_text("passed\n")

            result = lint_result(Path(directory), "python", require_slow=True)

        self.assertEqual("n/a", result)

    def test_failure_takes_precedence_over_another_passed_check(self):
        with tempfile.TemporaryDirectory() as directory:
            for mode, value in (("fast", "passed"), ("slow", "failed")):
                target = Path(directory) / mode
                target.mkdir()
                (target / "python.status").write_text(f"{value}\n")

            result = lint_result(Path(directory), "python")

        self.assertEqual("failed", result)


class SecurityMetricTests(unittest.TestCase):
    def test_sast_result_retains_completed_failure(self):
        self.assertEqual("failed", sast_result("failure"))

    def test_sast_result_retains_success_when_other_gate_fails(self):
        self.assertEqual("passed", sast_result("success"))

    def test_secret_status_requires_fast_and_full_scans(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "secrets").mkdir()
            (root / "secrets/fast.status").write_text("passed\n")

            self.assertEqual("n/a", secrets_result(root))

    def test_failed_full_scan_overrides_fast_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "secrets"
            root.mkdir()
            (root / "fast.status").write_text("passed\n")
            (root / "full.status").write_text("failed\n")

            self.assertEqual("failed", secrets_result(root.parent))

    def test_all_secret_scans_must_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "secrets"
            root.mkdir()
            (root / "fast.status").write_text("passed\n")
            (root / "full.status").write_text("passed\n")

            self.assertEqual("passed", secrets_result(root.parent))


if __name__ == "__main__":
    unittest.main()
