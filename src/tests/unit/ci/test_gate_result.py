import subprocess
import unittest
from pathlib import Path

SCRIPT = (
    Path(__file__).resolve().parents[4]
    / "scripts/ci/checks/status/assert-gate-result.sh"
)


class GateResultTests(unittest.TestCase):
    def run_gate(self, result):
        return subprocess.run(
            ["bash", str(SCRIPT), "test-gate", result],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_success_always_passes(self):
        self.assertEqual(self.run_gate("success").returncode, 0)

    def test_skipped_required_gate_fails(self):
        result = self.run_gate("skipped")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Required gate", result.stderr)

    def test_failure_fails(self):
        result = self.run_gate("failure")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("test-gate", result.stderr)


if __name__ == "__main__":
    unittest.main()
