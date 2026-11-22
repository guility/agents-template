import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[4]
LANGUAGES = ("python", "nodejs", "rust", "go", "csharp")
SOURCE_SCRIPT = REPOSITORY_ROOT / "scripts/ci/images/source-label.sh"
BUILDERS = (
    ("scripts/ci/images/build-targets.sh", "build "),
    ("scripts/ci/images/buildah/build-targets-buildah.sh", "bud "),
)


class ImageBuildTargetTests(unittest.TestCase):
    def test_both_builders_add_label_to_each_target(self):
        for builder, command in BUILDERS:
            self._assert_builder_labels(builder, command)

    def _assert_builder_labels(self, builder, command):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self._create_fixture(root)
            result = self._run_builder(root, builder)
            self.assertEqual(result.returncode, 0, result.stderr)
            self._assert_image_records(root, command)

    def _run_builder(self, root, builder):
        environment = self._environment(root)
        environment["GITHUB_REPOSITORY"] = "guility/agents-template"
        return subprocess.run(
            ["bash", str(REPOSITORY_ROOT / builder)],
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )

    def _assert_image_records(self, root, command):
        builds = [
            line
            for line in (root / "build.log").read_text().splitlines()
            if line.startswith(command)
        ]
        self.assertEqual(len(builds), len(LANGUAGES) * 2)
        label = "image.source=https://github.com/guility/agents-template"
        self.assertTrue(all(label in line for line in builds))

    def _create_fixture(self, root):
        self._create_directories(root)
        self._create_template_files(root)
        self._create_fake_builders(root)

    def _create_directories(self, root):
        directories = (
            "deploy/Dockerfiles scripts/setup scripts/ci/images scripts/common "
            "scripts/ci/checks/test-runners fake-bin"
        )
        for directory in directories.split():
            (root / directory).mkdir(parents=True, exist_ok=True)
        (root / "scripts/setup/fetch_language_templates.sh").write_text("exit 0\n")
        (root / "scripts/ci/images/source-label.sh").write_text(
            SOURCE_SCRIPT.read_text()
        )
        (root / "scripts/common/helper.sh").write_text("true\n")
        (root / "scripts/ci/checks/test-runners/unit.sh").write_text("true\n")

    def _create_template_files(self, root):
        for language in LANGUAGES:
            package = root / f"src/templates/{language}"
            dockerfile = package / "deploy/Dockerfiles/Dockerfile"
            dockerfile.parent.mkdir(parents=True)
            dockerfile.write_text(
                "FROM python:3.14 AS production\nFROM production AS tests\n"
            )
            (package / ".dockerignore").write_text(".git\n")

    def _create_fake_builders(self, root):
        tool = root / "fake-bin/tool"
        tool.write_text(
            "#!/usr/bin/env bash\nset -eu\n"
            'printf \'%s\\n\' "$*" >> "$BUILD_LOG"\n'
            'if [[ "$1" == image || "$1" == images ]]; then echo sha256:test; fi\n'
            'if [[ "$1" == save ]]; then mkdir -p "$(dirname "$3")"; touch "$3"; fi\n'
        )
        tool.chmod(0o755)
        for name in ("docker", "buildah"):
            (root / f"fake-bin/{name}").symlink_to(tool)

    def _environment(self, root):
        return {
            **os.environ,
            "CI_PROJECT_DIR": str(root),
            "CI_PROJECT_PATH": "guility/agents-template",
            "CI_COMMIT_SHA": "unit-test",
            "BUILD_LOG": str(root / "build.log"),
            "PATH": f"{root / 'fake-bin'}:{os.environ['PATH']}",
        }
