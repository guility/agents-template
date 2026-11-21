import importlib.util
import sys
import unittest
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[3]


def load_module(name: str, relative_path: str):
    spec = importlib.util.spec_from_file_location(name, REPOSITORY_ROOT / relative_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


class TemplateAndPathTests(unittest.TestCase):
    """Cover shared quality policy and script path contracts."""

    def test_maintainability_index_uses_the_shared_formula(self):
        module = load_module(
            "maintainability_index", "scripts/testing/maintainability_index.py"
        )
        row = {"H-volume": 1, "CCN": 1, "NLOC": 1}
        self.assertEqual(module.maintainability_index(row), 99.87)
        self.assertIsNone(module.maintainability_index({}))

    def test_reviewed_helpers_resolve_from_repository(self):
        bootstrap = (REPOSITORY_ROOT / "scripts/setup/bootstrap.sh").read_text(
            encoding="utf-8"
        )
        test_runner = (REPOSITORY_ROOT / "scripts/common/run-tests.sh").read_text(
            encoding="utf-8"
        )
        unified = (REPOSITORY_ROOT / "scripts/ci/unified_ci_runner.sh").read_text(
            encoding="utf-8"
        )
        unified += (REPOSITORY_ROOT / "scripts/ci/unified/tests.sh").read_text(
            encoding="utf-8"
        )
        unified += (REPOSITORY_ROOT / "scripts/ci/unified/acceptance.sh").read_text(
            encoding="utf-8"
        )
        pre_commit = (REPOSITORY_ROOT / ".hooks/pre-commit").read_text(encoding="utf-8")

        self.assertIn("PROJECT_ROOT=", bootstrap)
        self.assertNotIn("$SCRIPT_DIR/.git", bootstrap)
        self.assertIn("$SCRIPT_DIR/../..", test_runner)
        self.assertIn("$SCRIPTS_DIR/testing/mutation_runner.py", unified)
        self.assertIn("gitleaks git --staged", pre_commit)
        self.assertIn("lizard -C 10", pre_commit)

    def test_ci_entrypoints_target_nested_templates(self):
        workflow_dir = REPOSITORY_ROOT / ".github/workflows"
        fast_checks = (workflow_dir / "fast-checks.yml").read_text(encoding="utf-8")
        (workflow_dir / "ci-cd.yml").read_text(encoding="utf-8")
        gitlab_entrypoint = (REPOSITORY_ROOT / ".gitlab-ci.yml").read_text(
            encoding="utf-8"
        )

        for language in ("python", "nodejs", "rust", "go", "csharp"):
            template_workflow = (workflow_dir / f"{language}-tests.yml").read_text(
                encoding="utf-8"
            )
            self.assertIn(
                f"working-directory: src/templates/{language}", template_workflow
            )
        self.assertIn("/.gitlab/ci/.gitlab-ci.yml", gitlab_entrypoint)
        self.assertIn("CARGO_TARGET_DIR: ${{ runner.temp }}/cargo-target", fast_checks)
