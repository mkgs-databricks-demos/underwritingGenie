# 2026-11-15 — Project onboarding: README, PROJECT_MEMORY, naming sweep, feature branch

Summary of the full onboarding session. Detailed sub-logs: [README and PROJECT_MEMORY](2026-11-15_readme_and_project_memory.md), [naming sweep](2026-11-15_naming_sweep.md).

## Goal
Understand the newly cloned `underwritingGenie` repo, document it, create project memory, correct stale naming, and put the work on a feature branch for PR.

## Problems
1. `README.md` contained only a title; no entry point for the 53-file design package.
2. No `PROJECT_MEMORY.md` for future Genie Code build sessions.
3. Docs referenced a repo name that does not exist (`genie-one-large-group-underwriting`) and the retired product name "Databricks Asset Bundle" / "DAB".
4. Working copy was on `main`.

## Root causes
- Design package was authored before the Git folder was created, using a proposed folder name (research/06 D1) that changed when the repo was set up as `mkgs-databricks-demos/underwritingGenie`.
- Docs were written with the pre-rename bundle product name.
- Repo was freshly cloned; no feature branch existed yet.

## Changes
- **README.md:** purpose, status, demo beats, components (C1–C7), base-scenario reference numbers, repo layout, build plan (8 sessions / 4 waves), planned deployment, contributing, license.
- **PROJECT_MEMORY.md (new, repo root):** identity/remote, status, non-negotiable rules, assumed decisions D2–D11, planned Databricks resources, reference numbers and S2 checks, key docs, open items, conventions.
- **Naming sweep:** `underwritingGenie` and "Declarative Automation Bundle" across L100 (md + html), L400-01, L400-02, L400-03, research/06.
- **Session logs:** two sub-logs plus this summary; `INDEX.md` updated.
- **Git:** created `mg-genie-readme-project-memory` from `main`, committed `bbb4ee4` (11 files, +245/−12), pushed with upstream tracking.

## Decisions
- Kept file name `L400-03_dab_deployment_and_reset.md` to avoid breaking links.
- Historical session logs left unchanged.
- D1 in research/06 keeps the original proposed name as a note for traceability.
- No `hi_genie/` collaboration folder exists, so no Polly/Isaac context to read.

## Verification
- Re-grep for `genie-one-large-group-underwriting|Asset Bundle|\bDABs?\b` returns only the D1 note, `PROJECT_MEMORY.md` history line and session logs.
- `git status` before commit showed exactly the 11 expected files; push succeeded to `origin/mg-genie-readme-project-memory`.

## Files modified
- `README.md`, `PROJECT_MEMORY.md` (new)
- `docs/design/L100_demo_overview.md`, `docs/design/L100_demo_overview.html`
- `docs/design/L400-01_genie_code_build_sessions.md`, `docs/design/L400-02_demo_runbook.md`, `docs/design/L400-03_dab_deployment_and_reset.md`
- `docs/research/06_design_decisions_assumed.md`
- `docs/sessions/INDEX.md`, `docs/sessions/2026-11-15_readme_and_project_memory.md` (new), `docs/sessions/2026-11-15_naming_sweep.md` (new), `docs/sessions/2026-11-15_project_onboarding.md` (new)

## Follow-ups
- Merge the PR into `main`.
- Build wave 1 (S1 bundle/schema, S2 synthetic data) per L400-01, on a new feature branch.
