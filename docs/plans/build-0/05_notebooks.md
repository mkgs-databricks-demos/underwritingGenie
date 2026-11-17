# Session 05 — Notebooks: generate_synthetic_book, upload_packages, reset_demo

**Wave:** 0-1 (edit, parallel)
**Mode:** edit
**Depends on:** 01

## Goal

Write the three Python notebooks for the infra bundle. Do not deploy or run.

## Context files to read first

* `docs/design/L200-01_synthetic_data_foundation.md` — data generation rules, testing assertions
* `docs/design/L300-01_data_model_and_generation_spec.md` — all pinned values, table schemas, seed values
* `docs/design/L300-05_broker_documents.md` — northwind_v1 seeded gaps (5), v2 complete package
* `PROJECT_MEMORY.md` — reference numbers, S2 checks

## Files to create (owned_paths)

* `uw-genie-infra/src/notebooks/generate_synthetic_book.py`
* `uw-genie-infra/src/notebooks/upload_packages.py`
* `uw-genie-infra/src/notebooks/reset_demo.py`

## Steps

1. Write `generate_synthetic_book.py`:
   - First cell: `%pip install --upgrade databricks-sdk` + `dbutils.library.restartPython()`
   - Widgets: `catalog`, `schema` (from job parameters)
   - Seed 2027; load all pinned values from L300-01 exactly (Northwind: 420 EEs, 980 members, 23,520 member months; Lakeview; assumption tables AV-2027.1; intake checklist; persistency curve; plan options)
   - Generate 58 random groups + Northwind + Lakeview = 60 total
   - Load census/claims/claimants for Northwind from `demo-assets/broker_packages/northwind_v2` (v1 rows from `northwind_v1`)
   - Generate `trend_monitor` table
   - Assertions from L200-01 Testing: Northwind member_months = 23,520; claims paid_to_date sum = 10,480,000.00; tier counts 168/76/59/117; `broker_submissions` has Northwind v1 BLOCKED and v2 READY_WITH_WARNINGS; 60 groups; all tables tagged
2. Write `upload_packages.py`:
   - First cell: `%pip install --upgrade databricks-sdk` + `dbutils.library.restartPython()`
   - Widgets: `catalog`, `schema`
   - Upload `docs/demo-assets/broker_packages/northwind_v1` and `northwind_v2` to the `broker_packages` volume
   - Verify v1 contains the 5 seeded gaps from L300-05
   - No real names/emails (all `.example`)
3. Write `reset_demo.py`:
   - First cell: `%pip install --upgrade databricks-sdk` + `dbutils.library.restartPython()`
   - Widgets: `catalog`, `schema`
   - Truncate `submission_findings`; restore `broker_submissions` statuses; rebuild scenarios; run tests
   - Must complete in < 5 minutes
4. Run `databricks bundle validate --strict --target dev` in `uw-genie-infra/`.

## Acceptance criteria

* `databricks bundle validate --strict --target dev` passes in `uw-genie-infra/`
* All 3 notebooks exist with `%pip install` + `dbutils.library.restartPython()` as first cell
* `generate_synthetic_book.py` loads all pinned values from L300-01 and asserts Northwind checks
* `upload_packages.py` uploads both folders and verifies 5 seeded gaps
* `reset_demo.py` truncates and rebuilds
