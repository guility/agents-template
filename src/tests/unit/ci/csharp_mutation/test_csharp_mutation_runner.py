import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
RUNNER = ROOT / "scripts/common/test-runners/csharp-tests.sh"


def make_package(root: Path) -> None:
    (root / ".config").mkdir(parents=True)
    (root / ".config/dotnet-tools.json").write_text("{}\n")
    (root / "stryker-config.json").write_text("{}\n")
    (root / "src").mkdir()
    (root / "src/DDDTemplate.csproj").write_text("<Project />\n")
    (root / "DDDTemplate.Tests.csproj").write_text("<Project />\n")
    (root / "test-results").mkdir()


def make_dotnet_stub(directory: Path, calls: Path) -> None:
    directory.mkdir()
    stub = directory / "dotnet"
    stub.write_text(
        '#!/usr/bin/env bash\nprintf "%s|%s\\n" "$PWD" "$*" >> "$DOTNET_CALLS"\n'
    )
    stub.chmod(0o755)


def run_env(root: Path, tools: Path, calls: Path) -> dict[str, str]:
    return {
        "PATH": f"{tools}:/usr/bin:/bin",
        "ROOT_DIR": str(root),
        "DOTNET_CALLS": str(calls),
        "RUNNER": str(RUNNER),
    }


class CsharpMutationRunnerTests(unittest.TestCase):
    def test_restores_tool_and_runs_stryker_from_package_root(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            root, tools, calls = base / "package", base / "bin", base / "calls.txt"
            root.mkdir()
            make_package(root)
            make_dotnet_stub(tools, calls)
            subprocess.run(
                ["bash", "-c", 'source "$RUNNER"; run_csharp_mutation_tests'],
                env=run_env(root, tools, calls),
                check=True,
                capture_output=True,
                text=True,
            )
            expected = [
                f"{root}|tool restore --tool-manifest {root}/.config/dotnet-tools.json",
                f"{root}|stryker",
            ]
            self.assertEqual(expected, calls.read_text().splitlines())


if __name__ == "__main__":
    unittest.main()
