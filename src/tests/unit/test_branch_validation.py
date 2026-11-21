import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[3] / "scripts/common/validate-branch.sh"
COMMON_REMOTE = "https://github.com/guility/agents-template.git"
LANGUAGE_REMOTE = "https://github.com/guility/agents-template-langs.git"
LANGUAGE_BRANCHES = ("python", "nodejs", "rust", "go", "csharp")


def validate(
    branch: str,
    remote: str,
    allow_override: str = "0",
    ci_context: bool = False,
) -> int:
    with tempfile.TemporaryDirectory() as directory:
        subprocess.run(["git", "init", "--quiet"], cwd=directory, check=True)
        subprocess.run(
            ["git", "remote", "add", "origin", remote], cwd=directory, check=True
        )
        environment = os.environ.copy()
        environment["ALLOW_LANGUAGE_BRANCHES"] = allow_override
        if ci_context:
            repository = Path(remote).stem
            environment["CI_PROJECT_NAME"] = repository
            environment["GITHUB_REPOSITORY"] = "guility/" + repository
        else:
            environment.pop("CI_PROJECT_NAME", None)
            environment.pop("CI_PROJECT_PATH", None)
            environment.pop("GITHUB_REPOSITORY", None)
        result = subprocess.run(
            ["bash", str(SCRIPT), branch],
            cwd=directory,
            env=environment,
            capture_output=True,
            check=False,
            text=True,
        )
        return result.returncode


class BranchValidationTests(unittest.TestCase):
    def test_common_branch_patterns_are_accepted(self) -> None:
        branches = (
            "main",
            "dev",
            "test",
            "research/metrics",
            "feature/ci",
            "fix/bug-1",
        )
        for branch in branches:
            with self.subTest(branch=branch):
                self.assertEqual(validate(branch, COMMON_REMOTE), 0)

    def test_malformed_branch_names_are_rejected(self) -> None:
        for branch in ("feature/", "feature/..", "bad branch", "topic"):
            with self.subTest(branch=branch):
                self.assertEqual(validate(branch, COMMON_REMOTE), 2)

    def test_language_branches_are_accepted_only_in_language_repository(self) -> None:
        for branch in LANGUAGE_BRANCHES:
            with self.subTest(branch=branch):
                self.assertEqual(validate(branch, LANGUAGE_REMOTE), 0)
                self.assertEqual(validate(branch, COMMON_REMOTE), 2)
                self.assertEqual(validate(branch, COMMON_REMOTE, allow_override="1"), 2)

    def test_ci_project_identity_limits_language_exception(self) -> None:
        for branch in LANGUAGE_BRANCHES:
            with self.subTest(branch=branch):
                self.assertEqual(validate(branch, COMMON_REMOTE, ci_context=True), 2)
                self.assertEqual(validate(branch, LANGUAGE_REMOTE, ci_context=True), 0)
