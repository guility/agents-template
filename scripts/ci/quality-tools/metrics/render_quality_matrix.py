#!/usr/bin/env python3
"""Render the shared component-by-metric badge matrix."""

import json
import re
from pathlib import Path

FIELDS = [
    ("max_ccn", "Max CCN"),
    ("functions_over_10", "CCN > 10"),
    ("cognitive_complexity_max", "Cognitive"),
    ("nesting_depth_max", "Max depth"),
    ("max_nloc", "Max NLOC"),
    ("halstead_volume_max", "Halstead V"),
    ("halstead_difficulty_max", "Halstead D"),
    ("halstead_effort_max", "Halstead E"),
    ("maintainability_index_min", "Min MI"),
    ("line_coverage", "Line cov."),
    ("branch_coverage", "Branch cov."),
    ("lint", "Lint"),
    ("secrets", "Secrets"),
    ("sast", "SAST"),
    ("dependency_vulnerabilities", "Dependency vulns"),
    ("mutation_score", "Mutation"),
]


def badge(label, value, report):
    if value in (None, "n/a"):
        return "n/a"
    color = "red" if value in ("fail", "failed") else "brightgreen"
    slug = re.sub(r"[^A-Za-z0-9.-]+", "_", str(value))
    image = f"https://img.shields.io/badge/{label.replace(' ', '_')}-{slug}-{color}"
    return f"[![{label}: {value}]({image})]({report})"


def render(data):
    header = "| Component | " + " | ".join(title for _, title in FIELDS) + " |"
    rule = "|---|" + "|".join("---" for _ in FIELDS) + "|"
    rows = [header, rule]
    for component in data["components"].values():
        values = component["metrics"]
        cells = [
            badge(title, values.get(field, "n/a"), component.get("report", "#"))
            for field, title in FIELDS
        ]
        rows.append("| " + component["name"] + " | " + " | ".join(cells) + " |")
    return (
        "## Quality metrics\n\nValues link to the report; `n/a` means no measurement was produced.\n\n"
        + "\n".join(rows)
        + "\n"
    )


if __name__ == "__main__":
    source = Path("docs/quality/quality-metrics.json")
    output = Path("docs/quality/quality-matrix.md")
    output.write_text(render(json.loads(source.read_text())))
