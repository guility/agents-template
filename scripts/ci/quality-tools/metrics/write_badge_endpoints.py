"""Write Shields endpoint JSON for the protected-main metrics branch."""

import json
import re
from pathlib import Path

FIELDS = [
    "max_ccn",
    "functions_over_10",
    "cognitive_complexity_max",
    "nesting_depth_max",
    "max_nloc",
    "halstead_volume_max",
    "halstead_difficulty_max",
    "halstead_effort_max",
    "maintainability_index_min",
    "line_coverage",
    "branch_coverage",
    "lint",
    "secrets",
    "sast",
    "dependency_vulnerabilities",
    "mutation_score",
]
GATES = {
    "max_ccn": (10, True),
    "functions_over_10": (0, True),
    "dependency_vulnerabilities": (0, True),
    "line_coverage": (100, False),
    "branch_coverage": (100, False),
    "mutation_score": (100, False),
}


def color(field, value):
    if value in (None, "n/a"):
        return "lightgrey"
    if value in ("failed", "failure", "fail"):
        return "red"
    if value in ("passed", "success"):
        return "brightgreen"
    if not isinstance(value, (int, float)):
        return "blue"
    gate = GATES.get(field)
    if gate is None:
        return "blue"
    threshold, lower_is_better = gate
    passed = value <= threshold if lower_is_better else value >= threshold
    return "brightgreen" if passed else "red"


def main():
    source = Path("docs/quality/quality-metrics.json")
    target = Path("docs/quality/badges")
    target.mkdir(parents=True, exist_ok=True)
    data = json.loads(source.read_text())
    for component, details in data["components"].items():
        for field in FIELDS:
            value = details["metrics"].get(field, "n/a")
            payload = {
                "schemaVersion": 1,
                "label": re.sub(r"_", " ", field),
                "message": str(value),
                "color": color(field, value),
            }
            (target / f"{component}-{field}.json").write_text(
                json.dumps(payload) + "\n"
            )


if __name__ == "__main__":
    main()
