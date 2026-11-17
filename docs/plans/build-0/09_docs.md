# Session 09 — Docs: README Deployed IDs + Architecture

**Wave:** 0-5 (edit)
**Mode:** edit
**Depends on:** 07, 08

## Goal

Update README.md and PROJECT_MEMORY.md with actual deployed resource IDs from the wave 0-2, 0-3, and 0-4 session summaries. Write `docs/architecture.md` describing the two-bundle split and data flow. Do not deploy.

## Context files to read first

* `docs/sessions/` — wave 0-2, 0-3, 0-4 session summaries (for actual IDs)
* `README.md` — current content
* `PROJECT_MEMORY.md` — current content

## Files to modify (owned_paths)

* `README.md`
* `PROJECT_MEMORY.md`
* `docs/architecture.md`

## Steps

1. Update `README.md`:
   - Status table: mark build 0 as Done with actual run IDs
   - Deployment section: add actual job IDs, warehouse ID, Genie Agent space ID, UC Skills names
   - Repository layout: add `uw-genie-infra/` and `uw-genie-agent/` bundle directories
2. Update `PROJECT_MEMORY.md`:
   - Add actual deployed resource IDs (job IDs, warehouse ID, space ID, skills)
   - Update status to reflect build 0 completion
3. Write `docs/architecture.md`:
   - Two-bundle split (uw-genie-infra owns schema/volume/warehouse/jobs/SQL/notebooks; uw-genie-agent owns Genie Agent)
   - Data flow: DDL → synthetic data → rating function → scenarios → metric views → Genie Agent
   - Deploy order: infra first, then agent
   - How the agent bundle finds the infra schema and warehouse (variables + warehouse lookup)
   - Genie Build Waves framework overview (waves, gates, sessions)
4. Run `databricks bundle validate --strict --target dev` in both bundle folders.

## Acceptance criteria

* `databricks bundle validate --strict --target dev` passes in both bundles
* `README.md` lists both bundles and every deployed resource with actual IDs
* `PROJECT_MEMORY.md` updated with deployed IDs
* `docs/architecture.md` exists and describes the two-bundle split and data flow
