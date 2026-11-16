# R1-03 Metric views as YAML fixtures with a `for_each` deploy job

**Status:** Open
**Origin:** Owner request, 2026-11-16 (owner's standard convention for metric views)
**Related:** R1-02, R1-04, R1-05 (new renewal columns may feed `mv_quote_outcomes`)

## Problem

Build 0 creates the metric views inside a single SQL file task, not through the owner's standard metric view deployment pattern.

## Current state (evidence)

* `uw-genie-infra/src/sql/20_metric_views.sql` runs as the `create_metric_views` SQL task in `setup_demo`.
* It creates `mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops` and the regular view `renewal_book_scenarios`, using `EXECUTE IMMEDIATE` and a `__FQ__` token replaced by the backtick-quoted `:catalog.:schema`. The `source` must be double-quoted in YAML because a plain YAML scalar cannot start with a backtick (session 04).
* Tags are set with `:domain_tag` + `EXECUTE IMMEDIATE` (dev: `mkgs_underwriting`).

## Reference implementation (owner's convention)

`semanticGroundTruth/ground-truth-infra`:

* `resources/jobs/metric_view_deploy.job.yml`: task `list_fixtures` (notebook) -> `for_each_task` over `{{tasks.list_fixtures.values.fixture_files}}` (concurrency 1) running `deploy_metric_view` with `fixture_file: "{{input}}"`, catalog, schema, warehouse id and `validate_only`.
* `src/notebooks/list_fixtures`: lists `fixtures/metric_views/*.yaml` and emits `fixture_files` (JSON array) and `fixture_count` with `dbutils.jobs.taskValues.set`.
* `src/notebooks/deploy_metric_view`: loads one YAML (`name`, `sql`), replaces `${catalog}` / `${schema}`, executes the `CREATE VIEW` on the warehouse through the Statement Execution API (polling past the 50 s wait limit), verifies with `DESCRIBE TABLE EXTENDED ... AS JSON`; `validate_only=true` runs `EXPLAIN` on the metric view `source` instead.

## Requested change

1. One YAML file per view under `uw-genie-infra/fixtures/metric_views/`: `name` plus `sql` holding `CREATE OR REPLACE VIEW ${catalog}.${schema}.<name> WITH METRICS LANGUAGE YAML AS $$ ... $$`, with placeholders only (never literal names).
2. A job resource (one per `.job.yml`) mirroring `metric_view_deploy.job.yml`, with notebooks ported into `uw-genie-infra/src/notebooks/`.
3. Parameters: `${resources.schemas.uw_genie.catalog_name}`, `${resources.schemas.uw_genie.name}`, `${resources.sql_warehouses.uw_genie_warehouse.id}`, plus `domain_tag` so the deploy notebook applies the governed tags after create.
4. `setup_demo` calls the job (`run_job_task` or equivalent) in place of `create_metric_views`.
5. Decide where `renewal_book_scenarios` (a regular view) lives: a fixture handled by the same notebook (it runs any `CREATE VIEW`), or a small SQL task. Keep the order: base view before the metric views that read it.
6. **Do not copy the reference's hard-coded values** (R1-04): drop the `.bundle/ground-truth-infra/dev/files/fixtures/metric_views` fallback in `list_fixtures` and the literal widget defaults (`hls_fde_dev`, `dev_matthew_giglia_semantic_ground_truth`) in `deploy_metric_view`. Parameters are required and fail fast.
7. Notebook paths in YAML must match the file extension on disk (owner convention); run `bundle validate --strict` after authoring.

## Files affected

* `uw-genie-infra/fixtures/metric_views/*.yaml` (new)
* `uw-genie-infra/resources/jobs/metric_view_deploy.job.yml` (new), `setup_demo.job.yml`, `reset_demo.job.yml` if it rebuilds views
* `uw-genie-infra/src/notebooks/list_fixtures`, `deploy_metric_view` (new)
* `uw-genie-infra/src/sql/20_metric_views.sql` (remove or reduce)
* `docs/design/L300-03` (deployment section), `docs/architecture.md`

## Acceptance criteria

* `list_fixtures` emits exactly the YAML files present (count matches the directory).
* The `for_each` deploys every view; each passes `DESCRIBE TABLE EXTENDED ... AS JSON`; `validate_only=true` runs EXPLAIN only and creates nothing.
* Tags on the views match today's (`uw_finance` / `intake_quote`, `certified=true`).
* `setup_demo` green end to end; the Genie space still resolves all data sources.
* No literal catalog/schema/warehouse in the fixtures, notebooks or job YAML.
