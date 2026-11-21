# DECISION-001: Rust branch coverage reporting

**Status:** Accepted
**Date:** 2026-11-21

## Context

The quality matrix reports line and branch coverage per component. Rust line coverage is available from `cargo-llvm-cov` 0.9.1. Its upstream documentation marks `--branch` as unstable. Running the Rust template with the pinned tool and nightly 2026-11-20 produced 100% line coverage but `BRF=0` and `BRH=0` in LCOV, including for code with conditional paths. A zero denominator is not a branch-coverage measurement.

## Decision

Use `cargo-llvm-cov` 0.9.1 to gate Rust unit line coverage at 100%. Report Rust branch coverage as `n/a` until the upstream tool emits branch counts for Rust source. Keep the 100% line and applicable-mutation gates unchanged. Recheck this decision when updating the Rust coverage toolchain.

## Consequences

- Rust coverage artifacts remain available as LCOV for the shared matrix and Mutator.
- No branch percentage is fabricated from lines or cyclomatic complexity.
- Rust branch coverage can return to a 100% gate after the pinned reporter produces a non-zero branch denominator.

## References

- [cargo-llvm-cov branch coverage and known limitations](https://github.com/taiki-e/cargo-llvm-cov#known-limitations)
- [cargo-llvm-cov branch option](https://github.com/taiki-e/cargo-llvm-cov#options)
