"""Render complete per-component reports from the merged metrics document."""

import os
from pathlib import Path


def report_url(component: str) -> str:
    if project_url := os.environ.get("CI_PROJECT_URL"):
        job_id = os.environ.get("CI_JOB_ID", "")
        if job_id:
            return (
                f"{project_url}/-/jobs/{job_id}/artifacts/file/docs/quality/"
                f"reports/{component}.md"
            )
    if run_url := os.environ.get("GITHUB_RUN_URL"):
        return run_url
    if all(
        os.environ.get(key)
        for key in ("GITHUB_SERVER_URL", "GITHUB_REPOSITORY", "GITHUB_RUN_ID")
    ):
        return (
            f"{os.environ['GITHUB_SERVER_URL']}/{os.environ['GITHUB_REPOSITORY']}"
            f"/actions/runs/{os.environ['GITHUB_RUN_ID']}"
        )
    return f"reports/{component}.md"


def render_reports(data: dict, reports_root: Path) -> None:
    for component, details in data["components"].items():
        details["report"] = report_url(component)
        report = reports_root / f"{component}.md"
        report.parent.mkdir(parents=True, exist_ok=True)
        rows = [f"| {name} | {value} |" for name, value in details["metrics"].items()]
        report.write_text(
            f"# {details['name']} quality report\n\n"
            f"Commit: `{data.get('commit', 'unknown')}`\n\n"
            "| Metric | Value |\n|---|---:|\n" + "\n".join(rows) + "\n"
        )
