import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DISPATCH = ROOT / "scripts/common/test-runners/suite-dispatch.sh"
RUNNERS = (
    "run_python_unit_tests run_python_integration_tests run_python_e2e_tests "
    "run_python_mutation_tests run_nodejs_unit_tests run_nodejs_integration_tests "
    "run_nodejs_e2e_tests run_nodejs_mutation_tests run_rust_tests "
    "run_rust_integration_tests run_rust_e2e_tests run_rust_mutation_tests "
    "run_go_tests run_go_integration_tests run_go_e2e_tests run_go_mutation_tests "
    "run_csharp_tests run_csharp_integration_tests run_csharp_e2e_tests "
    "run_csharp_mutation_tests"
)


class SuiteDispatchTests(unittest.TestCase):
    def test_all_suites_are_dispatched_for_every_supported_language(self) -> None:
        setup = " ".join(f"{name}() {{ echo {name}; }};" for name in RUNNERS.split())
        command = (
            f"source '{DISPATCH}'; {setup} "
            "run_requested_suite all true true true true true"
        )
        result = subprocess.run(
            ["bash", "-c", command], capture_output=True, check=False, text=True
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertCountEqual(result.stdout.splitlines(), RUNNERS.split())
