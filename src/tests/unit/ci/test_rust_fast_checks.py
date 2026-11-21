import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
CHECKS = ROOT / "scripts/ci/checks/language/run-rust-fast-checks.sh"


class RustFastCheckTests(unittest.TestCase):
    def fake_tools(self, root):
        tools = root / "bin"
        tools.mkdir()
        calls = root / "calls"
        for tool in ("cargo", "rustfmt"):
            path = tools / tool
            path.write_text(f'#!/bin/sh\necho "{tool} $*" >> "$CALLS"\n')
            path.chmod(0o755)
        return calls, dict(
            os.environ, PATH=f"{tools}:{os.environ['PATH']}", CALLS=str(calls)
        )

    def run_checks(self, root, env, *files):
        return subprocess.run(
            ["bash", str(CHECKS), str(root), *files],
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )

    def test_changed_source_and_config_lint_both_workspace_packages(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            calls, env = self.fake_tools(root)
            (root / "Cargo.toml").write_text(
                '[workspace]\nmembers = ["crates/a", "crates/b"]\n'
                '[workspace.package]\nedition = "2021"\n'
            )
            for name in ("a", "b"):
                package = root / f"crates/{name}"
                (package / "src").mkdir(parents=True)
                (package / "Cargo.toml").write_text(
                    f'[package]\nname = "{name}"\nedition.workspace = true\n'
                )
                (package / "src/lib.rs").write_text("pub fn run() {}\n")
            (root / "crates/b/rustfmt.toml").write_text("max_width = 100\n")
            result = self.run_checks(
                root, env, "crates/a/src/lib.rs", "crates/b/rustfmt.toml"
            )

            self.assertEqual(0, result.returncode, result.stderr)
            output = calls.read_text()
            for package in ("crates/a/Cargo.toml", "crates/b/Cargo.toml"):
                self.assertIn(f"fmt --manifest-path {root / package}", output)
                self.assertIn(f"clippy --manifest-path {root / package}", output)

    def test_changed_rust_file_uses_its_manifest_edition(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            calls, env = self.fake_tools(root)
            (root / "Cargo.toml").write_text(
                '[workspace]\nmembers = ["sample"]\n'
                '[workspace.package]\nedition = "2024" # shared edition\n'
            )
            project = root / "sample"
            project.mkdir()
            (project / "Cargo.toml").write_text(
                '[package]\nname = "sample"\nedition.workspace = true\n'
            )
            (project / "src").mkdir()
            (project / "src/lib.rs").write_text("pub fn run() {}\n")
            result = self.run_checks(root, env, "sample/src/lib.rs")

            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn(f"--edition 2024 {project / 'src/lib.rs'}", calls.read_text())

    def test_root_config_scans_nested_crates_without_root_manifest(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            calls, env = self.fake_tools(root)
            for name in ("a", "b"):
                crate = root / "src" / name
                (crate / "src").mkdir(parents=True)
                (crate / "Cargo.toml").write_text(f'[package]\nname = "{name}"\n')
                (crate / "src/lib.rs").write_text("pub fn run() {}\n")
            (root / "rustfmt.toml").write_text("max_width = 100\n")
            result = self.run_checks(root, env, "rustfmt.toml")

            self.assertEqual(0, result.returncode, result.stderr)
            output = calls.read_text()
            for crate in ("a", "b"):
                self.assertIn(
                    f"fmt --manifest-path {root / 'src' / crate / 'Cargo.toml'}", output
                )
