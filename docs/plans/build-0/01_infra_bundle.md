# Session 01 — Infra Bundle Foundation

**Wave:** 0-0 (edit, parallel)
**Mode:** edit
**Depends on:** none

## Goal

Write the entire `uw-genie-infra/` bundle scaffolding: databricks.yml, schema resource, volume, SQL warehouse, both jobs (setup_demo, reset_demo), and the DDL file. Also write `.gitignore` at the repo root. Do not deploy.

## Context files to read first

* `docs/design/L400-03_dab_deployment_and_reset.md` — repo layout, bundle YAML excerpt, jobs table
* `docs/design/L300-01_data_model_and_generation_spec.md` — all 18 DDL objects, column definitions, tags
* `docs/design/L100_demo_overview.md` — interface contracts, component map
* `PROJECT_MEMORY.md` — non-negotiable rules, assumed decisions

## Files to create (owned_paths)

* `uw-genie-infra/databricks.yml`
* `uw-genie-infra/resources/schemas/uw_genie.schema.yml`
* `uw-genie-infra/resources/volumes/broker_packages.yml`
* `uw-genie-infra/resources/sql_warehouses/uw_genie.sql_warehouse.yml`
* `uw-genie-infra/resources/jobs/setup_demo.job.yml`
* `uw-genie-infra/resources/jobs/reset_demo.job.yml`
* `uw-genie-infra/src/sql/00_ddl.sql`
* `.gitignore`

## Steps

1. Write `.gitignore` at repo root with `.build-status/` and `.databricks/`.
2. Write `uw-genie-infra/databricks.yml`:
   - `bundle.name: uw-genie-infra`
   - `databricks_cli_version: >= 1.23.0`
   - `engine: direct`
   - `include: resources/**/*.yml`
   - Variables: `catalog` (default `hls_fde_dev`), `schema` (default `uw_genie`), `warehouse_id` (description: Serverless SQL warehouse)
   - Targets: `dev` (default: true, mode: development, catalog `hls_fde_dev`) and `demo` (mode: production, catalog `hls_fde`)
   - `workspace.root_path: /Workspace/.bundle/${bundle.name}/${bundle.target}`
   - `workspace.sync_mode: overwrite`
   - `presets.tags` per target (domain=underwriting, data_class=synthetic)
3. Write `resources/schemas/uw_genie.schema.yml`:
   - Schema `uw_genie` in catalog `${var.catalog}`
   - Comment: "Underwriting Genie synthetic demo data"
   - Tags: domain=underwriting, data_class=synthetic
4. Write `resources/volumes/broker_packages.yml`:
   - Volume `broker_packages` in schema `${resources.schemas.uw_genie.id}`
   - Comment: "Broker package PDFs and CSVs (synthetic)"
5. Write `resources/sql_warehouses/uw_genie.sql_warehouse.yml`:
   - Serverless SQL warehouse, 2X-Small, name `uw_genie_warehouse`
6. Write `resources/jobs/setup_demo.job.yml`:
   - Job `setup_demo` with 5 tasks in order: `create_tables` (SQL task running `src/sql/00_ddl.sql`), `generate_synthetic_book` (notebook task `src/notebooks/generate_synthetic_book.py`), `upload_packages` (notebook task `src/notebooks/upload_packages.py`), `build_nb_quote_scenarios` (SQL task running `src/sql/10_rate_new_business.sql`), `run_tests` (SQL task running `src/sql/90_tests.sql`)
   - All tasks on `${resources.sql_warehouses.uw_genie_warehouse.id}`
   - Job parameters: `catalog` from `${var.catalog}`, `schema` from `${var.schema}`
   - `max_concurrent_runs: 1`, queue enabled
7. Write `resources/jobs/reset_demo.job.yml`:
   - Job `reset_demo` with notebook task `src/notebooks/reset_demo.py` on the warehouse
   - Same job parameters as setup_demo
8. Write `src/sql/00_ddl.sql` from L300-01:
   - All 18 objects (tables, views) with `CREATE OR REPLACE`
   - All in `${catalog}.${schema}` using job parameters `:catalog` and `:schema`
   - All tables tagged `domain='underwriting'`, `data_class='synthetic'` via `ALTER TABLE ... SET TBLPROPERTIES`
   - Include: groups, broker_submissions, submission_findings, intake_checklist, assumption_tables (pooling_points, trend_assumptions, persistency_curve, plan_options), large_claimants, incurred_claims, nb_quote_scenarios, nb_quote_waterfall, renewal_pipeline, renewal_scenarios, trend_monitor
   - Column definitions exactly per L300-01
9. Run `databricks bundle validate --strict --target dev` in `uw-genie-infra/`.

## Acceptance criteria

* `databricks bundle validate --strict --target dev` passes in `uw-genie-infra/`
* All listed files exist
* DDL creates all 18 objects with correct columns per L300-01
* All tables tagged domain=underwriting, data_class=synthetic
* Jobs setup_demo and reset_demo defined with correct task order
* `.gitignore` contains `.build-status/` and `.databricks/`
