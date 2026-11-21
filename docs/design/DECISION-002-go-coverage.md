# DECISION-002: Go coverage metrics

## Status

Accepted

## Context

Go's built-in coverage profile counts statements in instrumented blocks. It does not report physical line coverage or branch counters, so the Go statement percentage must not be presented as line coverage.

## Decision

Keep the existing 100% Go statement-coverage gate. Publish it as `statement_coverage` in the component report. The shared matrix reports Go line and branch coverage as `n/a` until a pinned, validated tool provides those measurements.

## Consequences

Readers can distinguish Go statement coverage from line and branch metrics. The pipeline does not claim unsupported Go coverage measurements.
