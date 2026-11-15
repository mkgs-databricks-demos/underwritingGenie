# Session 02 — Agent Bundle: Genie Agent Serialized Space

**Wave:** 0-0 (edit, parallel)
**Mode:** edit
**Depends on:** none

## Goal

Write the entire `uw-genie-agent/` bundle: databricks.yml and the Genie Agent genie_spaces resource with a serialized space file (`.geniespace.json`). Do not deploy.

## Context files to read first

* `docs/design/L300-03_metric_views_and_genie_agent_config.md` — sections 4-5: Genie Agent config, instructions, example SQL, benchmarks
* `docs/design/L200-03_semantics_and_genie_agent.md` — agent overview, dependencies, design
* `docs/design/L100_demo_overview.md` — interface contracts (C3 → Genie One)
* `PROJECT_MEMORY.md` — non-negotiable rules

## Files to create (owned_paths)

* `uw-genie-agent/databricks.yml`
* `uw-genie-agent/resources/genie_spaces/underwriting_genie.genie_space.yml`
* `uw-genie-agent/underwriting_genie.geniespace.json`

## Steps

1. Write `uw-genie-agent/databricks.yml`:
   - `bundle.name: uw-genie-agent`
   - `databricks_cli_version: >= 1.23.0`
   - `engine: direct`
   - `include: resources/**/*.yml`
   - Variables: `catalog` and `schema` set per target to the infra bundle's deployed schema (dev: `hls_fde_dev` / `uw_genie`, demo: `hls_fde` / `uw_genie`), `warehouse_id` as a lookup of the infra warehouse by its deployed name per target
   - Targets: `dev` (default: true, mode: development) and `demo` (mode: production)
   - Same `workspace.root_path`, `workspace.sync_mode`, `presets.tags` as the infra bundle
   - This bundle uses the infra schema and warehouse but never defines or deploys them
2. Write `resources/genie_spaces/underwriting_genie.genie_space.yml`:
   - Genie space `underwriting_genie_space`
   - `title: Underwriting Genie`
   - `parent_path: /Workspace/Users/matthew.giglia@databricks.com/underwritingGenie/.genie_agents`
   - `file_path: ./underwriting_genie.geniespace.json`
   - `warehouse_id: ${var.warehouse_id}`
   - `permissions`: CAN_RUN for `account users` group (dev target only)
3. Write `underwriting_genie.geniespace.json` (serialized space file):
   - `version: 2`
   - `data_sources.tables`: all C1 tables (except raw volume), `nb_quote_scenarios`, `nb_quote_waterfall`, `renewal_scenarios`, three metric views (`mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops`) — all with identifiers `${var.catalog}.${var.schema}.<table>`
   - `column_configs`: key columns with descriptions from semantics docs
   - `config.sample_questions`: the 15 benchmarks from L300-03 section 5
   - `config.instructions`: the general instructions text from L300-03 section 4
   - `config.example_sql`: the 6 example SQL queries from L300-03 section 4
   - Trusted assets: `rate_new_business`, `rate_renewal`
4. Run `databricks bundle validate --strict --target dev --var=warehouse_id=0000000000000000` in `uw-genie-agent/`. The warehouse lookup cannot resolve before wave 0-2 deploys the infra warehouse; record the plain validate's lookup error as expected.

## Acceptance criteria

* `databricks bundle validate --strict --target dev --var=warehouse_id=0000000000000000` passes in `uw-genie-agent/` (warehouse lookup error is expected, not a failure)
* All listed files exist
* `underwriting_genie.geniespace.json` contains all data sources, instructions, example SQL, and 15 benchmark questions from L300-03
* Agent bundle defines no schema, warehouse, or job resource
* `parent_path` is `/Workspace/Users/matthew.giglia@databricks.com/underwritingGenie/.genie_agents`
* `file_path` points to the local `.geniespace.json` file
