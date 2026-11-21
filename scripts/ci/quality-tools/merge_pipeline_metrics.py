"""Merge security gate results into the generated component matrix."""

import argparse
import json
from pathlib import Path

from metrics.component_reports import render_reports
from metrics.lint_metrics import lint_result
from metrics.metric_reports import coverage_metrics, mutation_score, read_counts
from metrics.security_metrics import sast_result, secrets_result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--metrics", type=Path, default=Path("docs/quality/quality-metrics.json")
    )
    parser.add_argument(
        "--dependency-counts",
        type=Path,
        default=Path("artifacts/reports/dependencies/counts.tsv"),
    )
    parser.add_argument("--sast-result", default="n/a")
    parser.add_argument(
        "--secret-status-root", type=Path, default=Path("artifacts/reports/quality")
    )
    parser.add_argument(
        "--lint-status-root", type=Path, default=Path("artifacts/reports/quality/lint")
    )
    parser.add_argument("--require-slow-lint", action="store_true")
    parser.add_argument(
        "--coverage-root", type=Path, default=Path("artifacts/reports/coverage")
    )
    parser.add_argument(
        "--mutation-root", type=Path, default=Path("artifacts/reports/mutation")
    )
    args = parser.parse_args()
    data = json.loads(args.metrics.read_text())
    for key, count in read_counts(args.dependency_counts).items():
        data["components"][key]["metrics"]["dependency_vulnerabilities"] = count
    for key, component in data["components"].items():
        metrics = component["metrics"]
        metrics.update(coverage_metrics(args.coverage_root / key))
        score = mutation_score(args.mutation_root / key / ".metrics" / "mutate")
        if score != "n/a":
            metrics["mutation_score"] = score
        metrics["sast"] = sast_result(args.sast_result)
        metrics["lint"] = lint_result(
            args.lint_status_root, key, require_slow=args.require_slow_lint
        )
        metrics["secrets"] = secrets_result(args.secret_status_root)
    render_reports(data, Path("docs/quality/reports"))
    args.metrics.write_text(json.dumps(data, indent=2) + "\n")


if __name__ == "__main__":
    main()
