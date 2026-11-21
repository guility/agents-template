"""Merge security gate results into the generated component matrix."""

import argparse
import json
from pathlib import Path

from metrics.metric_reports import coverage_metrics, mutation_score, read_counts


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
    parser.add_argument("--fast-result", default="n/a")
    parser.add_argument("--lint-result", default="n/a")
    parser.add_argument("--secrets-result", default="n/a")
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
        metrics["sast"] = args.sast_result if args.sast_result == "success" else "n/a"
        metrics["lint"] = "passed" if args.lint_result == "success" else "n/a"
        if args.secrets_result == "success" or (
            key == "common" and args.fast_result == "success"
        ):
            metrics["secrets"] = "passed"
    args.metrics.write_text(json.dumps(data, indent=2) + "\n")


if __name__ == "__main__":
    main()
