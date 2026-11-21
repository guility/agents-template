import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class ProtectedPublicationTests(unittest.TestCase):
    def test_github_registry_push_is_protected_and_post_merge(self) -> None:
        workflow = (ROOT / ".github/workflows/ci-cd.yml").read_text()
        self.assertIn(
            "if: github.ref == 'refs/heads/main' && github.event_name == 'push' "
            "&& github.ref_protected",
            workflow,
        )
        self.assertIn(
            "needs: [run-image-gate, fast-check-status, prebuild-gate-status, "
            "image-gate-status, language-suites, mutator]",
            workflow,
        )
        self.assertIn("&& 'branch-gate'", workflow)
        self.assertIn("'push-branch-gate'", workflow)
        self.assertIn("'post-merge-branch-gate'", workflow)
        for gate in ("fast-checks", "prebuild-gates", "image-gate"):
            with self.subTest(gate=gate):
                self.assertIn(f"&& '{gate}'", workflow)
        self.assertIn("'fast-push-checks'", workflow)
        self.assertIn("'push-prebuild-gates'", workflow)
        self.assertIn("'push-image-gate'", workflow)
        self.assertNotIn("required-gate-checks", workflow)
        self.assertEqual(workflow.count("GATE_REQUIRED: ${{ github.event_name"), 2)

    def test_github_deploy_uses_digest_from_successful_main_run(self) -> None:
        workflow = (ROOT / ".github/workflows/deploy-production.yml").read_text()
        source_check = (ROOT / "scripts/ci/deploy/validate-source-run.sh").read_text()
        deploy_script = (ROOT / "scripts/ci/deploy/deploy-images.sh").read_text()
        self.assertIn("workflow_dispatch:", workflow)
        self.assertIn(
            "if: github.ref == 'refs/heads/main' && github.ref_protected", workflow
        )
        self.assertIn("name: registry-image-refs", workflow)
        self.assertIn("validate-source-run.sh", workflow)
        self.assertIn("packages: read", workflow)
        self.assertIn("docker login ghcr.io", workflow)
        for requirement in (
            '.path == ".github/workflows/ci-cd.yml"',
            '.head_branch == "main"',
            '.event == "push"',
            '.conclusion == "success"',
        ):
            with self.subTest(requirement=requirement):
                self.assertIn(requirement, source_check)
        self.assertIn("@sha256:", deploy_script)

    def test_metrics_publication_is_limited_to_protected_main(self) -> None:
        workflow = (ROOT / ".github/workflows/ci-cd.yml").read_text()
        self.assertIn(
            "if: github.event_name == 'push' && github.ref == 'refs/heads/main' "
            "&& github.ref_protected",
            workflow,
        )

    def test_gitlab_publish_and_deploy_require_protected_default_branch(self) -> None:
        condition = '$CI_COMMIT_REF_PROTECTED == "true"'
        for file in (
            ".gitlab/ci/images.yml",
            ".gitlab/ci/summary.yml",
            ".gitlab/ci/deploy.yml",
        ):
            with self.subTest(file=file):
                self.assertIn(condition, (ROOT / file).read_text())


if __name__ == "__main__":
    unittest.main()
