"""Resolve per-component lint results from checks that actually ran."""

from pathlib import Path

REQUIRED_SLOW_COMPONENTS = {"python", "nodejs", "csharp"}
FAILED_STATUSES = {"failed", "failure", "fail"}
PASSED_STATUSES = {"passed", "success", "pass"}


def _read_status(path: Path) -> str | None:
    if not path.exists():
        return None
    return path.read_text().strip().lower()


def _slow_status_passed(status_root: Path, component: str) -> bool:
    path = status_root / "slow" / f"{component}.status"
    return _read_status(path) in PASSED_STATUSES


def lint_result(status_root: Path, component: str, require_slow: bool = False) -> str:
    outcomes = [
        _read_status(status_root / mode / f"{component}.status")
        for mode in ("fast", "slow")
    ]
    if any(value in FAILED_STATUSES for value in outcomes):
        return "failed"
    if (
        require_slow
        and component in REQUIRED_SLOW_COMPONENTS
        and not _slow_status_passed(status_root, component)
    ):
        return "n/a"
    if any(value in PASSED_STATUSES for value in outcomes):
        return "passed"
    return "n/a"
