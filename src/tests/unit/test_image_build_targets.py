import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
LANGUAGES = ("python", "nodejs", "rust", "go", "csharp")


class ImageBuildTargetTests(unittest.TestCase):
    def test_build_script_uses_the_language_cache_root(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            self._create_fixture(root)
            completed = subprocess.run(
                ["bash", str(REPOSITORY_ROOT / "scripts/ci/images/build-targets.sh")],
                env=self._environment(root),
                capture_output=True,
                text=True,
                check=False,
            )

            self.assertEqual(completed.returncode, 0, completed.stderr)
            manifest = (root / "artifacts/images/manifest.tsv").read_text()
            self.assertEqual(len(manifest.splitlines()), len(LANGUAGES))
            self.assertIn("template-python", manifest)
            self.assertIn("template-csharp", manifest)

    def _create_fixture(self, root):
        for directory in (
            "deploy/Dockerfiles",
            "scripts/setup",
            "scripts/common",
            "scripts/ci/checks/test-runners",
            "fake-bin",
        ):
            (root / directory).mkdir(parents=True, exist_ok=True)
        (root / "scripts/setup/fetch_language_templates.sh").write_text("exit 0\n")
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
        fake_docker = root / "fake-bin/docker"
        fake_docker.write_text(
            "#!/usr/bin/env bash\n"
            "set -eu\n"
            'printf \'%s\\n\' "$*" >> "$FAKE_DOCKER_LOG"\n'
            "if [[ \"$1\" == image ]]; then printf 'sha256:test-image-id\\n'; fi\n"
            'if [[ "$1" == save ]]; then mkdir -p "$(dirname "$3")"; touch "$3"; fi\n'
        )
        fake_docker.chmod(0o755)

    def _environment(self, root):
        return {
            **os.environ,
            "CI_PROJECT_DIR": str(root),
            "CI_COMMIT_SHA": "unit-test",
            "FAKE_DOCKER_LOG": str(root / "docker.log"),
            "PATH": f"{root / 'fake-bin'}:{os.environ['PATH']}",
        }


if __name__ == "__main__":
    unittest.main()
