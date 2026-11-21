import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
RUNNER = ROOT / "scripts/common/run-test-suite.sh"


class MutationSuiteRunnerTests(unittest.TestCase):
    def test_native_mutation_runs_without_fixture_directory(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "scripts/common").mkdir(parents=True)
            shutil.copy2(RUNNER, root / "scripts/common/run-test-suite.sh")
            stub = root / "scripts/common/run-tests.sh"
            stub.write_text('echo "$TEST_LANGUAGE:$TEST_SUITE" >> "$CALLS"\n')
            for language in ("rust", "go", "csharp"):
                (root / f"src/templates/{language}").mkdir(parents=True)
            env = dict(os.environ, CALLS=str(root / "calls"))

            result = subprocess.run(
                ["bash", str(root / "scripts/common/run-test-suite.sh"), "mutation"],
                capture_output=True,
                text=True,
                env=env,
                check=False,
            )

            self.assertEqual(0, result.returncode, result.stderr)
            self.assertCountEqual(
                ["rust:mutation", "go:mutation", "csharp:mutation"],
                (root / "calls").read_text().splitlines(),
            )
