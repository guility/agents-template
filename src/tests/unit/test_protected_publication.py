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
        self.assertIn("needs: [image-gate, language-suites, mutator]", workflow)

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
