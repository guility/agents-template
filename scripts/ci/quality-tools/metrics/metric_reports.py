"""Read coverage, dependency and mutation reports for quality metrics."""

import re

from defusedxml import ElementTree as ET


def read_counts(path):
    counts = {}
    if path.exists():
        for line in path.read_text().splitlines():
            if line.strip():
                component, count = line.split("\t", 1)
                counts[component] = int(count)
    return counts


def percentage(covered, total):
    return round(100 * covered / total, 2) if total else "n/a"


def lcov_metrics(path):
    totals = {"LF": 0, "LH": 0, "BRF": 0, "BRH": 0}
    for line in path.read_text().splitlines():
        key, separator, value = line.partition(":")
        if separator and key in totals:
            totals[key] += int(value)
    return {
        "line_coverage": percentage(totals["LH"], totals["LF"]),
        "branch_coverage": percentage(totals["BRH"], totals["BRF"]),
    }


def cobertura_metrics(path):
    root = ET.parse(path).getroot()
    return {
        "line_coverage": percentage(
            int(root.get("lines-covered", "0")), int(root.get("lines-valid", "0"))
        ),
        "branch_coverage": percentage(
            int(root.get("branches-covered", "0")), int(root.get("branches-valid", "0"))
        ),
    }


def go_metrics(path):
    covered, total = 0, 0
    for line in path.read_text().splitlines()[1:]:
        match = re.search(r":\S+\s+(\d+)\s+(\d+)$", line)
        if match:
            count, hits = map(int, match.groups())
            total += count
            covered += count if hits else 0
    return {
        "statement_coverage": percentage(covered, total),
        "line_coverage": "n/a",
        "branch_coverage": "n/a",
    }


def coverage_metrics(directory):
    if not directory.exists():
        return {}
    reports = list(directory.rglob("*.info"))
    reports += list(directory.rglob("coverage.cobertura.xml"))
    reports += list(directory.rglob("coverage.xml"))
    reports += list(directory.rglob("go-coverage.out"))
    for report in reports:
        try:
            if report.suffix == ".info":
                return lcov_metrics(report)
            if report.name == "go-coverage.out":
                return go_metrics(report)
            return cobertura_metrics(report)
        except (ET.ParseError, ValueError, OSError):
            continue
    return {}


def mutation_score(directory):
    killed = survived = 0
    reports = directory.rglob("*.edn") if directory.exists() else []
    for report in reports:
        source = report.read_text(errors="replace")
        for form in re.findall(r"\{[^{}]*\}", source, flags=re.DOTALL):
            dead = re.search(r":killed\s+(\d+)", form)
            alive = re.search(r":survived\s+(\d+)", form)
            if dead and alive:
                killed += int(dead.group(1))
                survived += int(alive.group(1))
    return percentage(killed, killed + survived)
