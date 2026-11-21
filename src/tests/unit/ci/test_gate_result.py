import subprocess
import unittest
from pathlib import Path

SCRIPT = (
    Path(__file__).resolve().parents[4]
    / "scripts/ci/checks/status/assert-gate-result.sh"
)


class GateResultTests(unittest.TestCase):
    def run_gate(self, result, required):
        return subprocess.run(
            ["bash", str(SCRIPT), "test-gate", result, required],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_success_always_passes(self):
        self.assertEqual(self.run_gate("success", "true").returncode, 0)

    def test_expected_skip_passes(self):
        self.assertEqual(self.run_gate("skipped", "false").returncode, 0)

    def test_required_skip_fails(self):
        self.assertNotEqual(self.run_gate("skipped", "true").returncode, 0)

    def test_failure_fails_even_when_optional(self):
        result = self.run_gate("failure", "false")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("test-gate", result.stderr)


if __name__ == "__main__":
    unittest.main()
