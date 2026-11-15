# 2026-11-15 — Repo and product naming sweep

## Goal
Replace the old repo name `genie-one-large-group-underwriting` and the old product name "Databricks Asset Bundle" / "DAB" across the docs.

## Changes
- `docs/design/L400-01_genie_code_build_sessions.md`: intro, universal preamble and S1 prompt now say `underwritingGenie` / Declarative Automation Bundle.
- `docs/design/L400-03_dab_deployment_and_reset.md`: title and repo layout root.
- `docs/design/L400-02_demo_runbook.md`: review-gate prompt path is now `underwritingGenie/docs`.
- `docs/design/L100_demo_overview.md` and `.html`: Deployment row.
- `docs/research/06_design_decisions_assumed.md`: D1 folder (original name kept as a note), D2, D10.
- `PROJECT_MEMORY.md`: open item resolved.

## Decisions
- Kept file name `L400-03_dab_deployment_and_reset.md` so existing links keep working.
- Left historical session logs as written.

## Verification
Grep for `genie-one-large-group-underwriting|Asset Bundle|\bDAB\b` over `docs/` returns only the D1 historical note and session logs.

## Follow-ups
- Commit on a feature branch (working copy is on `main`).
