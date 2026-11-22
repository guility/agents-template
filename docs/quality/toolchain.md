# Quality toolchain

## Fast push checks

The measured push set is Gitleaks for outgoing commits, Lizard CCN for changed source (including C# files), Ruff check/format, Prettier, `cargo fmt`/rustfmt, Clippy, `gofmt` and `golangci-lint`. A check runs only when its language is present in the changed files. File-based checks use changed files; compiler-aware Clippy and golangci-lint checks run on affected Rust crates and Go packages. Changes to dependency or project configuration expand analysis to the affected project. C# has no language-specific formatter or analyzer in the fast set; `dotnet format` runs in MR checks. Clippy and golangci-lint run in this fast class only; slow MR checks do not repeat them in a fresh runner. Their warm-cache timings are below 0.5 seconds per 10,000 lines, while first runs and cache misses are slower. Exact timings are recorded in [`fast-check-benchmark.md`](fast-check-benchmark.md). Tools and their limits are pinned in the workflow and local setup scripts.

## Full pipeline

- GitHub Actions are pinned to immutable commit SHAs and use the Node 24 runtime. Self-hosted GitHub runners must be version 2.327.1 or newer.
- Semgrep 1.99.0 runs full source SAST on merge requests and protected-main pipelines.
- CodeQL Action v4.39.3 with CodeQL bundle 2.27.5 analyzes Python and GitHub Actions source on merge requests and protected-main pipelines. Fork PRs still run the analysis without SARIF upload because their token is read-only; Semgrep remains the credentialless SAST result for those runs.
- Lizard 1.25.0 provides CCN, Cognitive Complexity, nesting, NLOC and Halstead metrics through its `-Ecognitive`, `-ENS` and `-Ehalstead` extensions.
- Maintainability Index is info-only and uses one function-level formula across components: `100 × (171 − 5.2 ln(max(1, H-volume)) − 0.23 × CCN − 16.2 ln(max(1, NLOC))) / 171`, clamped to 0–100. The matrix reports the minimum function score; zero volume or NLOC uses 1 for the logarithm.
- Trivy 0.73.0 scans lockfiles and the exact `production` and `tests` image archives built earlier in that pipeline. HIGH/CRITICAL findings with a published `FixedVersion` block the gate. Findings without an upstream fix remain in Trivy JSON reports and count metrics for review; they do not block by themselves. The dependency-vulnerability metric counts all HIGH/CRITICAL findings, including those without a fix.
- Rust line coverage uses `cargo-llvm-cov` 0.9.1 and requires 100%. Rust branch coverage is `n/a` under [DECISION-001](../design/DECISION-001-rust-branch-coverage.md): upstream's branch mode is unstable and emitted no branch counters for the Rust template, so the pipeline does not claim a branch percentage.
- Go coverage profiles report statement coverage; line and branch coverage are `n/a` under [DECISION-002](../design/DECISION-002-go-coverage.md). The metric report keeps statement coverage under its accurate name.
- Uncle Bob's Mutator, Dryer and their shared CRAPPER parser are pinned to immutable Git commits in [`quality-tools/pyproject.toml`](../../scripts/ci/quality-tools/pyproject.toml) and resolved in `quality-tools/uv.lock`. Dryer is an MR report; Mutator runs after merge for Python, TypeScript/JavaScript, Rust and Go.
- Native mutation gates remain enabled: Mutmut from the Python lock, StrykerJS 10.1.1 from the Node lock, cargo-mutants 27.1.0 with Rust 1.88+, Gremlins 0.6.0 with a verified release checksum, and Stryker.NET 5.0.0 with .NET 10.

Mutator and Dryer declare the 0BSD license in their upstream repositories. The Acceptance Pipeline Specification remains a reference until its licensing status is confirmed. SCRAP and AgNesse are not part of the standard pipeline because they do not fit the supported component/test workflow here.
