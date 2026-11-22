import os
import subprocess
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[3] / "scripts/ci/images/source-label.sh"


class ImageSourceLabelArgumentTests(unittest.TestCase):
    def test_github_server_url_overrides_default(self):
        environment = self._environment(
            GITHUB_REPOSITORY="guility/agents-template",
            GITHUB_SERVER_URL="https://github.example.com",
        )

        self.assertEqual(
            self._arguments(environment),
            [
                "--label",
                "org.opencontainers.image.source=https://github.example.com/guility/agents-template",
            ],
        )

    def test_gitlab_project_url_is_used_without_github_repository(self):
        environment = self._environment(
            CI_PROJECT_URL="https://gitlab.com/guility/agents-template"
        )

        self.assertEqual(
            self._arguments(environment),
            [
                "--label",
                "org.opencontainers.image.source=https://gitlab.com/guility/agents-template",
            ],
        )

    def test_no_label_is_returned_outside_ci(self):
        self.assertEqual(self._arguments(self._environment()), [])

    def _arguments(self, environment):
        result = subprocess.run(
            ["bash", "-c", 'source "$1"; image_source_label_args', "test", str(SCRIPT)],
            env=environment,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.splitlines()

    def _environment(self, **overrides):
        environment = {
            **os.environ,
            "CI_PROJECT_URL": "",
            "GITHUB_REPOSITORY": "",
            "GITHUB_SERVER_URL": "",
        }
        environment.update(overrides)
        return environment


if __name__ == "__main__":
    unittest.main()
