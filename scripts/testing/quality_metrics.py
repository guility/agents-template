#!/usr/bin/env python3
"""Collect component complexity values from pinned Lizard extensions."""

import argparse
import csv
import io
import json
import os
import subprocess
from pathlib import Path

from maintainability_index import maintainability_index

METRICS = {
    "max_ccn": ("CCN", int),
    "functions_over_10": ("CCN", int),
    "cognitive_complexity_max": ("CogC", int),
    "nesting_depth_max": ("NS", int),
    "max_nloc": ("NLOC", int),
    "halstead_volume_max": ("H-volume", float),
    "halstead_difficulty_max": ("H-diff", float),
    "halstead_effort_max": ("H-effort", float),
}


def lizard_rows(paths):
    result = subprocess.run(
        [
            "lizard",
            "-Ecognitive",
            "-Ehalstead",
            "-ENS",
            "-V",
            "--csv",
            *paths,
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    rows = list(csv.DictReader(io.StringIO(result.stdout)))
    return [{key.strip(): value.strip() for key, value in row.items()} for row in rows]


def maximum_metrics(rows):
    values = {name: [] for name in METRICS}
    for row in rows:
        for name, (field, convert) in METRICS.items():
            value = row.get(field)
            if value:
                values[name].append(convert(value))
    return {name: max(items) if items else "n/a" for name, items in values.items()}


def analyze(paths, threshold):
    rows = lizard_rows(paths)
    metrics = maximum_metrics(rows)
    metrics["functions_over_10"] = sum(int(row["CCN"]) > threshold for row in rows)
    mi_scores = [
        score for row in rows if (score := maintainability_index(row)) is not None
    ]
    metrics["maintainability_index_min"] = min(mi_scores) if mi_scores else "n/a"
    return metrics


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--component", required=True)
    parser.add_argument("--metrics", default="docs/quality/quality-metrics.json")
    parser.add_argument("--threshold", type=int, default=10)
    parser.add_argument("paths", nargs="+", help="Source paths to analyze")
    args = parser.parse_args()
    path = Path(args.metrics)
    data = json.loads(path.read_text())
    data["commit"] = os.environ.get(
        "CI_COMMIT_SHA", os.environ.get("GITHUB_SHA", "local")
    )
    metrics = analyze(args.paths, args.threshold)
    component = data["components"][args.component]
    component["metrics"].update(metrics)
    report = Path("docs/quality/reports") / f"{args.component}.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    component["report"] = f"reports/{report.name}"
    report.write_text(
        f"# {component['name']} quality report\n\n"
        f"Commit: `{data['commit']}`\n\n"
        "| Metric | Value |\n|---|---:|\n"
        + "\n".join(f"| {name} | {value} |" for name, value in metrics.items())
        + "\n"
    )
    path.write_text(json.dumps(data, indent=2) + "\n")
    if metrics["functions_over_10"]:
        raise SystemExit(
            f"{args.component} has {metrics['functions_over_10']} functions above CCN {args.threshold}"
        )


if __name__ == "__main__":
    main()
