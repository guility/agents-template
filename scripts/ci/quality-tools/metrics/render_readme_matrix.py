"""Embed dynamic Shields badges that read the latest successful main metrics."""

from pathlib import Path
from urllib.parse import quote

from render_quality_matrix import FIELDS

REPOSITORY = "guility/agents-template"
BRANCH = "feature/quality-metrics"
START = "<!-- QUALITY-METRICS-START -->"
END = "<!-- QUALITY-METRICS-END -->"


def render():
    header = "| Component | " + " | ".join(title for _, title in FIELDS) + " |"
    rule = "|---|" + "|".join("---" for _ in FIELDS) + "|"
    rows = [header, rule]
    components = [
        ("common", "Common"),
        ("python", "Python"),
        ("nodejs", "Node.js / TypeScript"),
        ("rust", "Rust"),
        ("go", "Go"),
        ("csharp", "C#"),
    ]
    for component, label in components:
        cells = []
        for field, title in FIELDS:
            endpoint = f"https://raw.githubusercontent.com/{REPOSITORY}/{BRANCH}/docs/quality/badges/{component}-{field}.json"
            image = f"https://img.shields.io/endpoint?url={quote(endpoint, safe='')}"
            report = f"https://github.com/{REPOSITORY}/blob/{BRANCH}/docs/quality/reports/{component}.md"
            cells.append(f"[![{title}]({image})]({report})")
        rows.append("| " + label + " | " + " | ".join(cells) + " |")
    return "\n".join(rows)


def main():
    path = Path("README.md")
    content = path.read_text()
    if START not in content or END not in content:
        raise SystemExit("README quality matrix markers are missing")
    start = content.index(START) + len(START)
    end = content.index(END)
    path.write_text(content[:start] + "\n\n" + render() + "\n\n" + content[end:])


if __name__ == "__main__":
    main()
