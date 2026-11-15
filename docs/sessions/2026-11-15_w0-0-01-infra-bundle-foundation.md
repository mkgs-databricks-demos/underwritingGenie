# Session 01 (wave 0-0): infra bundle foundation

Run `1076347254049076` · branch `mg-genie-uw-genie-build-1` · mode `edit` · status **blocked**

## Changes

* `.gitignore`: `.build-status/`, `.databricks/`.
* `uw-genie-infra/databricks.yml`: bundle `uw-genie-infra`, CLI `>= 1.23.0`, `engine: direct`, `include: resources/**/*.yml`, variables `catalog` / `schema` / `warehouse_id`, `root_path /Workspace/.bundle/${bundle.name}/${bundle.target}`, `sync_mode: overwrite`. Targets `dev` (default, development, `hls_fde_dev`) and `demo` (production, `hls_fde`), with `presets.tags` domain/data_class/project/env.
* `resources/schemas/uw_genie.schema.yml`: schema `${var.schema}` in `${var.catalog}`, with properties domain/data_class.
* `resources/volumes/broker_packages.yml`: MANAGED volume, uses `${resources.schemas.uw_genie.*}`.
* `resources/sql_warehouses/uw_genie.sql_warehouse.yml`: `uw_genie_warehouse`, 2X-Small, serverless PRO, 1 cluster, auto-stop after 10 min.
* `resources/jobs/setup_demo.job.yml`: "Underwriting Genie: Setup Demo". Tasks: create_tables (SQL 00_ddl) -> generate_synthetic_book (nb) -> upload_packages (nb) -> build_nb_quote_scenarios (SQL 10) -> run_tests (SQL 90). Settings: `max_concurrent_runs: 1`, queue enabled, job params `catalog`/`schema` set from the schema resource.
* `resources/jobs/reset_demo.job.yml`: "Underwriting Genie: Reset Demo". Tasks: reset_state (nb reset_demo.py) -> build_nb_quote_scenarios (SQL 10) -> run_tests (SQL 90). Same params.
* `src/sql/00_ddl.sql`: the 18 L300-01 objects (17 tables + view `group_tier_counts`), using `CREATE OR REPLACE`, `USE CATALOG/SCHEMA IDENTIFIER(:catalog/:schema)`, column and table comments, TBLPROPERTIES, and `ALTER ... SET TAGS` domain=underwriting, data_class=synthetic.

## Decisions

* Python notebook tasks run on serverless jobs compute (no cluster spec), because a Python notebook cannot run on a SQL warehouse. SQL file tasks run on `${resources.sql_warehouses.uw_genie_warehouse.id}`.
* The DDL covers the 18 L300-01 objects (the manifest scope wins). Plan step 8 also lists nb_quote_scenarios, nb_quote_waterfall and renewal_scenarios. These are derived objects owned by 03/04 in 10_/20_ SQL, so they are not created here. The manifest also asks for CREATE OR REPLACE, while L300-01 uses IF NOT EXISTS; I followed the manifest.
* reset_demo is split into a notebook task plus SQL tasks, so scenario rebuild and tests reuse 10_/90_ SQL.

## Checks

* DDL static check: 18 CREATE statements, 18 SET TAGS, 18 TBLPROPERTIES, same object set (pass).
* `databricks bundle validate --strict --target dev` (uw-genie-infra): **FAIL**, `Error: notebook src/notebooks/generate_synthetic_book.py not found`. The job YAML must reference files that sessions 03 and 05 own and create in wave 0-1 (`src/notebooks/*.py`, `src/sql/10_rate_new_business.sql`, `src/sql/90_tests.sql`). Validate stops at the first missing file. The rest of the config could not be validated, including the resolved dev schema name.

## Requests

* owner (high): the wave 0-0 gate "bundle validate --strict passes in uw-genie-infra" cannot pass until wave 0-1 creates the referenced notebooks and SQL files. Options: move the infra validate gate to wave 0-1, or allow session 01 to create stub files.
* 05: reset_demo.py only needs to truncate `submission_findings` and restore `broker_submissions` statuses. The job runs build_nb_quote_scenarios and run_tests as SQL tasks after it. Notebooks receive widgets `catalog`, `schema` and run on serverless.
* 06: `20_metric_views.sql` is not run by setup_demo (the scope fixes 5 tasks). Add a `create_metric_views` SQL task after build_nb_quote_scenarios, before run_tests.
* 02/06: deployed warehouse name in dev is expected to be `[dev matthew_giglia] uw_genie_warehouse`. Development mode may also prefix the schema name (`dev_matthew_giglia_uw_genie`), which would conflict with the `hls_fde_dev.uw_genie` runtime targets. This is unverified (validate stopped early). Check with `bundle validate -o json` once the files exist.
