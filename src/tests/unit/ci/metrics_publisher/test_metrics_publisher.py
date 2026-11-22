import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[5]


def git(root: Path, *args: str) -> None:
    subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def initialize_remote(remote: Path) -> None:
    subprocess.run(
        ["git", "init", "--bare", "--initial-branch=main", str(remote)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def seed_main(root: Path, remote: Path, metrics: Path) -> None:
    git(root, "init", "--initial-branch=main")
    git(root, "config", "user.name", "CI")
    git(root, "config", "user.email", "ci@example.com")
    metrics.parent.mkdir(parents=True)
    metrics.write_text('{"old": true}\n')
    git(root, "add", "docs/quality")
    git(root, "commit", "-m", "seed metrics")
    git(root, "remote", "add", "origin", str(remote))
    git(root, "push", "origin", "main")


def seed_metrics_branch(root: Path, metrics: Path) -> None:
    git(root, "switch", "-c", "feature/quality-metrics")
    metrics.write_text('{"published": true}\n')
    git(root, "add", "docs/quality")
    git(root, "commit", "-m", "seed output branch")
    git(root, "push", "origin", "feature/quality-metrics")
    git(root, "switch", "main")
    git(root, "branch", "-D", "feature/quality-metrics")


def repository(base: Path) -> tuple[Path, Path, Path]:
    root, remote = base / "repo", base / "origin.git"
    root.mkdir()
    initialize_remote(remote)
    metrics = root / "docs/quality/quality-metrics.json"
    seed_main(root, remote, metrics)
    seed_metrics_branch(root, metrics)
    return root, remote, metrics


def publish(root: Path) -> None:
    script = ROOT / "scripts/ci/quality-tools/publish-metrics-branch.sh"
    env = {
        "PATH": os.environ["PATH"],
        "HOME": os.environ.get("HOME", "/tmp"),
        "QUALITY_METRICS_BRANCH": "feature/quality-metrics",
    }
    subprocess.run(["bash", str(script)], cwd=root, env=env, check=True)


def remote_file(remote: Path, path: str) -> str:
    ref = f"refs/heads/feature/quality-metrics:{path}"
    return subprocess.check_output(
        ["git", f"--git-dir={remote}", "show", ref], text=True
    )


class MetricsPublisherTests(unittest.TestCase):
    def test_publishes_downloaded_and_untracked_files_without_ci_credentials(self):
        with tempfile.TemporaryDirectory() as temporary:
            root, remote, metrics = repository(Path(temporary))
            metrics.write_text('{"new": true}\n')
            (metrics.parent / "component.md").write_text("generated report\n")
            with patch.dict(
                "os.environ",
                {
                    "CI_JOB_TOKEN": "dummy",
                    "CI_SERVER_HOST": "gitlab.invalid",
                    "CI_PROJECT_PATH": "owner/repo",
                },
            ):
                publish(root)
            published_metrics = remote_file(remote, "docs/quality/quality-metrics.json")
            published_report = remote_file(remote, "docs/quality/component.md")
        self.assertEqual('{"new": true}\n', published_metrics)
        self.assertEqual("generated report\n", published_report)


if __name__ == "__main__":
    unittest.main()
