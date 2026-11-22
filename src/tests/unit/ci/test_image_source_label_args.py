import os
import subprocess
import unittest

from src.tests.unit.ci.test_image_build_targets import SOURCE_SCRIPT


class ImageSourceLabelArgumentTests(unittest.TestCase):
    def test_github_gitlab_and_local_source_urls(self):
        scenarios = (
            (
                {
                    "GITHUB_REPOSITORY": "guility/agents-template",
                    "GITHUB_SERVER_URL": "https://github.example.com",
                },
                "https://github.example.com/guility/agents-template",
            ),
            (
                {"CI_PROJECT_URL": "https://gitlab.com/guility/agents-template"},
                "https://gitlab.com/guility/agents-template",
            ),
            ({}, None),
        )
        for variables, source in scenarios:
            self.assertEqual(self._arguments(variables), self._expected(source))

    def _arguments(self, variables):
        environment = self._environment(variables)
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; image_source_label_args',
                "test",
                str(SOURCE_SCRIPT),
            ],
            env=environment,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.splitlines()

    def _environment(self, variables):
        environment = {
            **os.environ,
            "CI_PROJECT_URL": "",
            "GITHUB_REPOSITORY": "",
            "GITHUB_SERVER_URL": "",
        }
        environment.update(variables)
        return environment

    def _expected(self, source):
        return (
            []
            if source is None
            else ["--label", f"org.opencontainers.image.source={source}"]
        )


if __name__ == "__main__":
    unittest.main()
