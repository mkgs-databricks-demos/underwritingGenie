# Session 06 — Deploy Infra + Run setup_demo

**Wave:** 0-2 (converge)
**Mode:** converge
**Depends on:** 03, 04, 05
**Max attempts:** 5
**Timeout:** 120 minutes

## Goal

Deploy `uw-genie-infra` to dev. The `setup_demo` job runs automatically (or manually if deploy started no run). Fix issues within owned_paths until all tables exist, row counts match, and tests pass.

## Context files to read first

* `docs/design/L400-03_dab_deployment_and_reset.md` — deployment steps, job tasks
* `docs/design/L200-01_synthetic_data_foundation.md` — S2 checks (row counts, assertions)
* `docs/demo-assets/nb_quote_scenarios_expected.csv` — golden CSV for test comparison
* `PROJECT_MEMORY.md` — reference numbers

## Runtime targets

* `setup_demo_job` — job must complete with status SUCCEEDED
* `groups_table` — 60 rows minimum
* `broker_submissions_table` — 2 rows minimum (Northwind v1 BLOCKED + v2 READY_WITH_WARNINGS)
* `nb_quote_scenarios_table` — 18 rows minimum (Northwind, 3×3×2 grid)

## Steps

1. Run `databricks bundle validate --strict --target dev` in `uw-genie-infra/`.
2. Run `databricks bundle deploy --target dev` in `uw-genie-infra/`.
3. Find the `setup_demo` job run (triggered by deploy or run it manually if deploy started no run).
4. Wait for the run to complete.
5. Read the run output and verify:
   - `groups` table has 60 rows (58 random + Northwind + Lakeview)
   - `broker_submissions` has Northwind v1 with `completeness_status = BLOCKED` and v2 with `completeness_status = READY_WITH_WARNINGS`
   - `nb_quote_scenarios` has 18 rows for Northwind (3 pooling × 3 trend × 2 plan)
   - Base row: premium_pmpm = 625.32, rate_ef = 2290.21, credibility = 0.7483
   - `run_tests` task passed (golden CSV comparison)
6. If any check fails, fix the DDL, SQL, notebooks, or job YAML within owned_paths, re-validate, and re-deploy.
7. Record whether `bundle deploy` waited for the job run and whether a failed run failed the deploy.

## Owned paths

* `uw-genie-infra/**` (all files in the infra bundle)

## Acceptance criteria

* `setup_demo` job last run status is SUCCEEDED
* `groups` has >= 60 rows
* `broker_submissions` has >= 2 rows with correct statuses
* `nb_quote_scenarios` has >= 18 rows with correct base values
* `run_tests` task passed
* Session status is `pass` with final attempt classified `stable`
