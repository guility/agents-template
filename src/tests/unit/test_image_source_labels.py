import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
LANGUAGES = ("python", "nodejs", "rust", "go", "csharp")
SOURCE_LABEL = (
    "--label org.opencontainers.image.source=https://github.com/guility/agents-template"
)


class ImageSourceLabelTests(unittest.TestCase):
    def test_both_builders_apply_repository_label_to_each_target(self):
        builders = (
            ("scripts/ci/images/build-targets.sh", "build "),
            ("scripts/ci/images/buildah/build-targets-buildah.sh", "bud "),
        )
        for builder, command in builders:
            with (
                self.subTest(builder=builder),
                tempfile.TemporaryDirectory() as directory,
            ):
                root = Path(directory)
                self._create_fixture(root)
                environment = {
                    **os.environ,
                    "CI_PROJECT_DIR": str(root),
                    "CI_PROJECT_PATH": "guility/agents-template",
                    "CI_COMMIT_SHA": "test-sha",
                    "GITHUB_REPOSITORY": "guility/agents-template",
                    "BUILD_LOG": str(root / "build.log"),
                    "PATH": f"{root / 'fake-bin'}:{os.environ['PATH']}",
                }
                result = subprocess.run(
                    ["bash", str(REPOSITORY_ROOT / builder)],
                    env=environment,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                builds = [
                    line
                    for line in (root / "build.log").read_text().splitlines()
                    if line.startswith(command)
                ]
                self.assertEqual(len(builds), len(LANGUAGES) * 2)
                self.assertTrue(all(SOURCE_LABEL in line for line in builds))

    def _create_fixture(self, root):
        for directory in (
            "deploy/Dockerfiles",
            "scripts/setup",
            "scripts/ci/images",
            "scripts/common",
            "scripts/ci/checks/test-runners",
            "fake-bin",
        ):
            (root / directory).mkdir(parents=True, exist_ok=True)
        (root / "scripts/setup/fetch_language_templates.sh").write_text("exit 0\n")
        helper = REPOSITORY_ROOT / "scripts/ci/images/source-label.sh"
        (root / "scripts/ci/images/source-label.sh").write_text(helper.read_text())
        (root / "scripts/common/helper.sh").write_text("true\n")
        (root / "scripts/ci/checks/test-runners/unit.sh").write_text("true\n")
        for language in LANGUAGES:
            package = root / f"src/templates/{language}"
            dockerfile = package / "deploy/Dockerfiles/Dockerfile"
            dockerfile.parent.mkdir(parents=True)
            dockerfile.write_text(
                "FROM python:3.14 AS production\nFROM production AS tests\n"
            )
            (package / ".dockerignore").write_text(".git\n")
        tool = root / "fake-bin/tool"
        tool.write_text(
            "#!/usr/bin/env bash\nset -eu\n"
            'printf \'%s\\n\' "$*" >> "$BUILD_LOG"\n'
            'if [[ "$1" == image || "$1" == images ]]; then echo sha256:test; fi\n'
        )
        tool.chmod(0o755)
        (root / "fake-bin/docker").symlink_to(tool)
        (root / "fake-bin/buildah").symlink_to(tool)


if __name__ == "__main__":
    unittest.main()
