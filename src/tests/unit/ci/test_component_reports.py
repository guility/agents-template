import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "scripts/ci/quality-tools"))

from metrics.component_reports import render_reports


def sample_component_data() -> dict:
    return {
        "commit": "abc123",
        "components": {
            "python": {
                "name": "Python",
                "metrics": {"max_ccn": 7, "line_coverage": 100},
            }
        },
    }


def render_python_report() -> tuple[dict, str]:
    data = sample_component_data()
    env = {
        "GITHUB_SERVER_URL": "https://github.com",
        "GITHUB_REPOSITORY": "guility/agents-template",
        "GITHUB_RUN_ID": "123",
    }
    with (
        tempfile.TemporaryDirectory() as directory,
        patch.dict("os.environ", env, clear=True),
    ):
        render_reports(data, Path(directory))
        report = (Path(directory) / "python.md").read_text()
    return data, report


class ComponentReportTests(unittest.TestCase):
    def test_report_contains_merged_metrics_and_links_to_the_workflow_run(self):
        data, report = render_python_report()
        self.assertEqual(
            "https://github.com/guility/agents-template/actions/runs/123",
            data["components"]["python"]["report"],
        )
        self.assertIn("| line_coverage | 100 |", report)


if __name__ == "__main__":
    unittest.main()
