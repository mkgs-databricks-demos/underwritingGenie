# PROJECT_MEMORY — underwritingGenie

Working memory for Genie Code sessions. Read this, then `docs/design/L100_demo_overview.md`, before substantive work. Update it when decisions, IDs or status change.

## Identity

* **Name:** Underwriting Genie — Large Group Experience Rating with Genie One
* **Owner:** Matthew Giglia (Field Engineering)
* **Workspace path:** `/Users/matthew.giglia@databricks.com/underwritingGenie/`
* **Remote:** `https://github.com/mkgs-databricks-demos/underwritingGenie.git` (default branch `main`)
* **License:** MIT (MKG Solutions Databricks Demos)
* **Purpose:** 12–15 min carrier-neutral, synthetic-data demo of fully insured, experience-rated large group underwriting: intake completeness, a governed NB quote delivered as an interactive Genie Artifact, and decisions → financial outcomes.

## Status (as of 2026-11-16)

* Design package v1.0-draft complete (53 files under `docs/`); review gate passed; 7 diagrams rendered to SVG/HTML.
* Build 0 plan complete: `docs/plans/waves.json` (6 waves, 9 sessions), `docs/plans/build-waves.vars.json`, 9 session plan files, Devin monitor prompt.
* **Build 0 executed** on branch `mg-genie-uw-genie-build-1` (build job `309617019935041`): waves 0-0..0-4 passed (bundles authored, infra deployed + setup_demo green, Genie Agent deployed + 5/5 probes, 4 UC Skills published); wave 0-5 (docs) in build run `1025333002364111`. Architecture: `docs/architecture.md`.
* **Devin monitor session:** `691668f25c744b66a13d30d15c94f93b` (level 4).
* **Next (owner):** merge PR #3 (`mg-genie-uw-genie-build-1` -> `main`, opened by Devin 2026-11-16); check the 4 skills resolve in Genie One (dev: the owner is the only demo user and owns every object, so no grants are needed; the demo-users group grants apply to the `demo` target only); record benchmarks; create the scheduled Morning Brief; build the NB quote artifact; demo target still needs a per-target space file for `hls_fde.uw_genie`.

## Non-negotiable rules

* **Neutrality:** no real carrier, customer, vendor, employee or colleague names in data, prompts, artifacts or slides (vendor names allowed only in `research/05`). Emails use `.example`. Neutrality grep is a CI step (L400-03 §4); prohibited list lives outside the repo.
* **Governed math:** rates, credibility, pooling and trend come only from `rate_new_business()` / `nb_quote_scenarios`. Skills forbid freehand rate math.
* **Synthetic tagging:** all objects tagged `domain=underwriting`, `data_class=synthetic`; synthetic label on every artifact.
* **Email:** draft only, never send.
* **Determinism:** tests assert function output = golden CSV within $0.01.
* Use bundle variables `${var.catalog}` / `${var.schema}` / `${var.warehouse_id}`; never hardcode workspace URLs. Ask before deleting anything outside the target schema.

## Assumed decisions (docs/research/06 — all stand after approval)

| # | Decision |
| --- | --- |
| D2 | Catalog/schema via bundle vars; default `hls_fde_dev.uw_genie`; fallback `home_<user>.uw_genie` if no CREATE CATALOG |
| D3 | Hero group Northwind Manufacturing: 420 EEs, ~980 members (keeps credibility partial) |
| D4 | Square-root credibility; full-credibility standard keyed by pooling point (30K/42K/60K MM) |
| D5 | Trend Low 7.5% / Base 9.0% / High 10.5%, 2.0 trend years |
| D6 | 12% retention ⇒ 88% target loss ratio |
| D7 | Precompute 18 scenarios for artifact (artifacts are snapshot-based); fallback comparison panel |
| D8 | Rating logic = UC SQL table function `rate_new_business()` + materialized `nb_quote_scenarios`; Genie Agent trusted asset |
| D9 | Chat upload of broker docs for demo; production = `ai_parse_document` → `ai_extract` |
| D10 | Build with Genie Build Waves (build 0, Devin level 4) |
| D11 | Incumbent renewal +14.2%; our base quote +2.2% vs current |

D1 folder name updated in docs to the actual repo `underwritingGenie/` (originally proposed `genie-one-large-group-underwriting/`).

## Planned Databricks resources

* **Bundle:** `uw-genie-infra` (schema, volume, warehouse, jobs, SQL, notebooks) and `uw-genie-agent` (Genie Agent via genie_spaces resource); targets `dev` (default; development mode in uw-genie-agent only, infra uses `var.name_prefix` so the schema stays `hls_fde_dev.uw_genie`), `demo` (production mode). Deploy infra first, then agent; see `docs/architecture.md`.
* **Schema + volume:** `${catalog}.${schema}`, volume `broker_packages`.
* **Jobs:** `setup_demo` (create_tables → generate_synthetic_book → upload_packages → build_nb_quote_scenarios → create_metric_views → run_tests, serverless < 10 min); `reset_demo` (< 5 min).
* **SQL:** `src/sql/00_ddl.sql` (18 objects), `10_rate_new_business.sql`, `20_metric_views.sql`, `90_tests.sql`.
* **Notebooks:** `src/notebooks/generate_synthetic_book.py` (seed 2027), `upload_packages.py`, `reset_demo.py`.
* **Functions:** `rate_new_business`, `rate_renewal` (Lakeview).
* **Metric views:** `mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops` (tag `certified=true`).
* **Genie Agent:** "Underwriting Genie" — 15 benchmarks (★1–★8 must pass); export to `src/genie/underwriting_genie.geniespace.json`.
* **UC Skills:** `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief` (source in `docs/demo-assets/skills/`).
* **Scheduled task:** "Large Group Underwriting Morning Brief", weekdays 7:00 AM ET.
* **Artifact:** "Northwind Manufacturing — New Business Quote" (8 sections), backup in shared `genie_artifacts`.
* **Permissions:** demo users group — USE CATALOG/SCHEMA, SELECT, EXECUTE on rating functions, READ VOLUME, CAN RUN on Genie Agent.

**Deployed resource IDs (target `dev`, build 0, verified 2026-11-16):**

| Resource | Name | ID |
|---|---|---|
| UC schema | `hls_fde_dev.uw_genie` | `483077d3-6960-4824-9586-30917977d687` |
| UC volume (managed) | `hls_fde_dev.uw_genie.broker_packages` | `bb8d00f0-34a0-4596-b78e-5e9a925a9829` |
| SQL warehouse (serverless 2X-Small) | `[dev matthew_giglia] uw_genie_warehouse` | `dcca64ab7f26cea7` |
| Job setup_demo | `[dev matthew_giglia] Underwriting Genie: Setup Demo` | `989657833792246` (good run `35433824231283`) |
| Job reset_demo | `[dev matthew_giglia] Underwriting Genie: Reset Demo` | `1105533136205325` |
| Genie Agent | `[dev matthew_giglia] Underwriting Genie` | `01f1e1554179173991a4a487c2ae28ef` |
| UC Skills | `hls_fde_dev.uw_genie.{lg-intake-checklist, experience-rating-explainer, nb-quote-artifact, uw-morning-brief}` | finalized (session 08) |

Functions `rate_new_business`, `rate_renewal` and metric views `mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops` exist in `hls_fde_dev.uw_genie`. Genie space parent path: `underwritingGenie/.genie_agents` (gitignored).

**genie-build-waves job IDs (deployed 2026-11-15, instance `-uw-genie`):**

| Job | ID |
|---|---|
| `uw-genie: Build Waves` | `309617019935041` |
| `uw-genie: Build Waves Setup` | `609015504722082` |
| `uw-genie: Build Waves Smoke Test` | `946512050297997` |

**Devin monitor session:** `691668f25c744b66a13d30d15c94f93b`  
**Monitor skill:** `hls_fde_dev.dev_matthew_giglia_build_waves.genie_build_monitor`

## Reference numbers (base scenario)

Northwind: 23,520 member months; completed claims $10,590,477 (IBNR $110,477); $540,000 excess over $250K pooled out; experience PMPM $427.32; trend 1.1881 × demo 1.010 + $24.00 pooling charge ⇒ $536.77; manual $590.45; Z 0.748 (0.7483); blended $550.28; premium **$625.32 PMPM** / $1,459.07 PEPM; tiers EE/ES/EC/EF $803.58 / $1,607.16 / $1,486.63 / $2,290.21; **+2.2%** vs $612.00 current. Grid range −7.8% to +7.3%.

S2 checks: Northwind paid_to_date sum 10,480,000.00; tier counts 168/76/59/117; 60 groups total (58 random + Northwind + Lakeview); v1 BLOCKED (5 seeded gaps), v2 READY_WITH_WARNINGS.

## Key docs

* `docs/design/L100_demo_overview.md` — demo constitution
* `docs/design/L400-01_genie_code_build_sessions.md` — session prompts + acceptance
* `docs/design/L400-03_dab_deployment_and_reset.md` — repo layout, jobs, permissions
* `docs/design/L200-07_demo_script_and_acceptance.md` — beats + Must/Should criteria
* `docs/design/L300-01..05` — data model, rating spec, metric views/agent config, skills, broker docs
* `docs/demo-assets/nb_quote_scenarios_expected.csv` — golden 18-scenario results
* `docs/diagrams/render_diagrams.py` — Playwright + local mermaid.js renderer

## Known gaps / open items

* Naming sweep done 2026-11-15: docs now use "Underwriting Genie" (not "Underwriting Cockpit"); two bundles `uw-genie-infra` and `uw-genie-agent`; catalog/schema `hls_fde_dev.uw_genie`. File name `L400-03_dab_deployment_and_reset.md` kept to avoid breaking links; historical session logs left as written.
* Artifact form controls are undocumented; fallback comparison panel defined.
* ★7/★8 benchmark expected values to be recorded after S5.
* Optional: internal field brief HTML rendering.
* **Post-build 0 (owner request, 2026-11-16): switch `dev` back to real development mode.** Build 0 removed `mode: development` from the `uw-genie-infra` `dev` target (`uw-genie-agent` dev is already in development mode; it owns no schema) to keep the schema name `hls_fde_dev.uw_genie` (development mode always prefixes UC schemas with `dev_<user>_`, and an empty `presets.name_prefix` is ignored). Once build 0 is complete, put `mode: development` back on infra `dev`, accept the prefixed schema (`hls_fde_dev.dev_matthew_giglia_uw_genie`, as in scAuditor), and drop the `var.name_prefix` workaround. Everything that hard-codes `hls_fde_dev.uw_genie` must follow the deployed name:
  * `uw-genie-agent/databricks.yml` `catalog`/`schema` variables per target (cross-bundle, so they can't use `${resources...}`; they must match infra values per target).
  * The Genie space `serialized_space` table identifiers in `uw-genie-agent/resources/genie_spaces/underwriting_genie.genie_space.yml` (render them from variables, which also covers the per-target `demo` render that session 07 asked for).
  * The `waves.json` runtime targets, session scopes and `context_notes`, plus `docs/demo-assets/skills/lg-intake-checklist/SKILL.md` and the published UC Skills location.
  * Do NOT add `lifecycle.prevent_destroy` to `dev` resources: dev deployments must stay destroyable (`bundle destroy --target dev`). Protection, if any, belongs only on non-dev targets.
* **Post-build 0 (owner request): `${resources...}` references everywhere.** All catalog/schema references in resource definitions must use `${resources.schemas.uw_genie.catalog_name}` / `${resources.schemas.uw_genie.name}`; raw `${var.catalog}`/`${var.schema}` belongs only in the schema resource itself. Status on 2026-11-16: `uw-genie-infra` already follows this (jobs and volume use `${resources.schemas.uw_genie.*}`); `uw-genie-agent` has no schema resource and uses `var.catalog`/`var.schema` plus hard-coded identifiers. Recheck both bundles when switching to development mode.
* **Post-build 0 (owner request): metric views via YAML + for_each job (owner's standard convention).** Today `uw-genie-infra/src/sql/20_metric_views.sql` (the `create_metric_views` SQL task in `setup_demo`) creates `mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops` (and the `renewal_book_scenarios` view) with `EXECUTE IMMEDIATE` and a `__FQ__` token. Replace it with the convention used in `semanticGroundTruth/ground-truth-infra`:
  * One YAML file per metric view under `uw-genie-infra/fixtures/metric_views/` (`name` + `sql` holding the `CREATE OR REPLACE VIEW ... WITH METRICS LANGUAGE YAML AS $$ ... $$` definition, with `${catalog}` / `${schema}` placeholders, never literal names).
  * A job (reference: `ground-truth-infra/resources/jobs/metric_view_deploy.job.yml`) with a `list_fixtures` notebook task that finds the exact `*.yaml` files in that directory and emits them as task values (`fixture_files`), and a `for_each_task` over `{{tasks.list_fixtures.values.fixture_files}}` that runs a notebook (reference: `ground-truth-infra/src/notebooks/deploy_metric_view`) which resolves the placeholders, builds and executes the SQL on the bundle warehouse via the Statement Execution API, and verifies with `DESCRIBE TABLE EXTENDED ... AS JSON`. Keep the `validate_only` parameter (EXPLAIN on the `source`).
  * Parameters come from `${resources.schemas.uw_genie.catalog_name}` / `.name` and `${resources.sql_warehouses.uw_genie_warehouse.id}`. `setup_demo` calls it (run_job_task or equivalent) in place of `create_metric_views`; tags still use `domain_tag`.
* **Post-build 0 (owner request): 100% parameterized, including the Genie Agent.** No catalog, schema, warehouse or object name is hard-coded anywhere (SQL, notebooks, job YAML, skills, `waves.json`, docs examples aside). The Genie space's table and metric view list must be parameterized too: build `serialized_space` (tables, metric views, example SQL, instructions) from bundle variables / a template rendered per target, not literal `hls_fde_dev.uw_genie.*` identifiers in `underwriting_genie.genie_space.yml`. Adding or removing a table or metric view should be a config change, not an edit to fully qualified names.
  * Required parameters, no literal defaults: notebook widgets and job parameters for catalog, schema, warehouse, paths and tag keys default to empty and fail fast when blank (as `generate_synthetic_book.py` must stop defaulting to `hls_fde_dev` / `uw_genie` / `underwriting`). Values come only from the bundle (`${resources...}` / `${var...}` per target). When copying the `ground-truth-infra` metric view notebooks, drop the hard-coded `.bundle/ground-truth-infra/dev/...` fallback in `list_fixtures` and the literal widget defaults in `deploy_metric_view`. (Owner confirmed 2026-11-16.)

## Conventions

* Feature branches `mg-genie-<short-description>`; never commit to `main`.
* Session logs in `docs/sessions/YYYY-MM-DD_<slug>.md` (Goal, Changes, Decisions, Verification, Observations, Follow-ups); update `INDEX.md` newest first.
* No `hi_genie/` collaboration folder exists yet.
* **SDK on serverless:** use `WorkspaceClient(host=_host, token=_token)` with credentials from `dbutils.notebook.entry_point`. Default `WorkspaceClient()` auth fails on serverless (no REPL context).
* **CLI on serverless:** `databricks bundle deploy/run` is blocked. Use web terminal or trigger jobs via REST API (`w.jobs.run_now()`).
* **waves.json converge sessions:** every converge session needs a non-empty `runtime_targets` list; every key in that list must also appear in the wave's `runtime_gate`. Catch both with the pre-flight cell in `Genie Code Session Starter - DO NOT EDIT.ipynb`.
* **bundle run --var flags:** always pass the same `--var` flags to `bundle run` as to `bundle deploy`. Without `--var=instance_suffix=-uw-genie`, the CLI defaults to the global instance and may trigger a different project's setup job.
