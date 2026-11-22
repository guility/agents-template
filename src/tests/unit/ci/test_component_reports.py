import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "scripts/ci/quality-tools"))

from metrics.component_reports import render_reports


def run_git(root: Path, *args: str) -> None:
    subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def initialize_repository(root: Path, remote: Path) -> None:
    subprocess.run(
        ["git", "init", "--bare", "--initial-branch=main", str(remote)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    for args in (
        ("init", "--initial-branch=main"),
        ("config", "user.name", "CI"),
        ("config", "user.email", "ci@example.com"),
    ):
        run_git(root, *args)


def make_metrics_repository(base: Path) -> tuple[Path, Path, Path]:
    root, remote = base / "repository", base / "origin.git"
    root.mkdir()
    initialize_repository(root, remote)
    metrics = root / "docs/quality/quality-metrics.json"
    metrics.parent.mkdir(parents=True)
    metrics.write_text('{"old": true}\n')
    run_git(root, "add", "docs/quality")
    run_git(root, "commit", "-m", "seed metrics")
    run_git(root, "remote", "add", "origin", str(remote))
    run_git(root, "push", "origin", "main")
    return root, remote, metrics


def seed_metrics_branch(root: Path, metrics: Path) -> None:
    run_git(root, "switch", "-c", "feature/quality-metrics")
    metrics.write_text('{"published": true}\n')
    run_git(root, "add", "docs/quality")
    run_git(root, "commit", "-m", "seed output branch")
    run_git(root, "push", "origin", "feature/quality-metrics")
    run_git(root, "switch", "main")
    run_git(
        root,
        "fetch",
        "origin",
        "refs/heads/feature/quality-metrics:refs/remotes/origin/feature/quality-metrics",
    )


def sample_component_data() -> dict:
    return {
        "commit": "abc123",
        "components": {
            "python": {
                "name": "Python",
                "metrics": {"max_ccn": 7, "line_coverage": 100},
            }
        },
    }


def render_python_report() -> tuple[dict, str]:
    data = sample_component_data()
    env = {
        "GITHUB_SERVER_URL": "https://github.com",
        "GITHUB_REPOSITORY": "guility/agents-template",
        "GITHUB_RUN_ID": "123",
    }
    with (
        tempfile.TemporaryDirectory() as directory,
        patch.dict("os.environ", env, clear=True),
    ):
        render_reports(data, Path(directory))
        report = (Path(directory) / "python.md").read_text()
    return data, report


def publish_metrics(root: Path) -> None:
    script = ROOT / "scripts/ci/quality-tools/publish-metrics-branch.sh"
    env = dict(
        os.environ,
        QUALITY_METRICS_BRANCH="feature/quality-metrics",
        GITHUB_TOKEN="",
        GITHUB_REPOSITORY="",
    )
    subprocess.run(
        ["bash", str(script)], cwd=root, env=env, check=True, stdout=subprocess.DEVNULL
    )


def read_published_file(remote: Path, path: str) -> str:
    ref = f"refs/heads/feature/quality-metrics:{path}"
    return subprocess.check_output(
        ["git", f"--git-dir={remote}", "show", ref], text=True
    )


class ComponentReportTests(unittest.TestCase):
    def test_report_contains_merged_metrics_and_links_to_the_workflow_run(self):
        data, report = render_python_report()
        self.assertEqual(
            "https://github.com/guility/agents-template/actions/runs/123",
            data["components"]["python"]["report"],
        )
        self.assertIn("| line_coverage | 100 |", report)

    def test_metrics_publisher_switches_with_downloaded_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            root, remote, metrics = make_metrics_repository(Path(temporary))
            seed_metrics_branch(root, metrics)
            metrics.write_text('{"new": true}\n')
            (metrics.parent / "component.md").write_text("generated report\n")
            publish_metrics(root)
            metrics_output = read_published_file(
                remote, "docs/quality/quality-metrics.json"
            )
            report_output = read_published_file(remote, "docs/quality/component.md")
        self.assertEqual('{"new": true}\n', metrics_output)
        self.assertEqual("generated report\n", report_output)


if __name__ == "__main__":
    unittest.main()
