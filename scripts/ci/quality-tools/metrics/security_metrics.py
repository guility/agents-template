"""Resolve secret scan status from the fast and full repository scans."""

from pathlib import Path


def sast_result(value: str) -> str:
    normalized = value.strip().lower()
    if normalized in {"passed", "success", "pass"}:
        return "passed"
    if normalized in {"failed", "failure", "fail"}:
        return "failed"
    return "n/a"


def secrets_result(status_root: Path) -> str:
    paths = (
        status_root / "secrets" / "fast.status",
        status_root / "secrets" / "full.status",
    )
    outcomes = [path.read_text().strip().lower() for path in paths if path.exists()]
    if any(value in {"failed", "failure", "fail"} for value in outcomes):
        return "failed"
    if len(outcomes) == len(paths) and all(
        value in {"passed", "success", "pass"} for value in outcomes
    ):
        return "passed"
    return "n/a"
