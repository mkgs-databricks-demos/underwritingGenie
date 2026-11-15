# PROJECT_MEMORY — underwritingGenie

Working memory for Genie Code sessions. Read this, then `docs/design/L100_demo_overview.md`, before substantive work. Update it when decisions, IDs or status change.

## Identity

* **Name:** Underwriting Cockpit — Large Group Experience Rating with Genie One
* **Owner:** Matthew Giglia (Field Engineering)
* **Workspace path:** `/Users/matthew.giglia@databricks.com/underwritingGenie/`
* **Remote:** `https://github.com/mkgs-databricks-demos/underwritingGenie.git` (default branch `main`)
* **License:** MIT (MKG Solutions Databricks Demos)
* **Purpose:** 12–15 min carrier-neutral, synthetic-data demo of fully insured, experience-rated large group underwriting: intake completeness, a governed NB quote delivered as an interactive Genie Artifact, and decisions → financial outcomes.

## Status (as of 2026-11-15)

* Design package v1.0-draft complete (53 files under `docs/`); review gate passed; 7 diagrams rendered to SVG/HTML.
* **No bundle code yet** — `databricks.yml`, `resources/`, `src/` are created in build wave 1.
* **Next:** Wave 1 — S1 (bundle, catalog, schema, DDL) and S2 (synthetic data), per `docs/design/L400-01`.

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
| D2 | Catalog/schema via bundle vars; default `lg_underwriting_dev.demo`; fallback `home_<user>.lg_uw_demo` if no CREATE CATALOG |
| D3 | Hero group Northwind Manufacturing: 420 EEs, ~980 members (keeps credibility partial) |
| D4 | Square-root credibility; full-credibility standard keyed by pooling point (30K/42K/60K MM) |
| D5 | Trend Low 7.5% / Base 9.0% / High 10.5%, 2.0 trend years |
| D6 | 12% retention ⇒ 88% target loss ratio |
| D7 | Precompute 18 scenarios for artifact (artifacts are snapshot-based); fallback comparison panel |
| D8 | Rating logic = UC SQL table function `rate_new_business()` + materialized `nb_quote_scenarios`; Genie Agent trusted asset |
| D9 | Chat upload of broker docs for demo; production = `ai_parse_document` → `ai_extract` |
| D10 | Build with 8 Genie Code sessions in 4 waves |
| D11 | Incumbent renewal +14.2%; our base quote +2.2% vs current |

D1 folder name updated in docs to the actual repo `underwritingGenie/` (originally proposed `genie-one-large-group-underwriting/`).

## Planned Databricks resources

* **Bundle:** `lg-underwriting-cockpit`; targets `dev` (default, development mode), `demo` (production mode).
* **Schema + volume:** `${catalog}.${schema}`, volume `broker_packages`.
* **Jobs:** `setup_demo` (create_tables → generate_synthetic_book → upload_packages → build_nb_quote_scenarios → run_tests, serverless < 10 min); `reset_demo` (< 5 min).
* **SQL:** `src/sql/00_ddl.sql` (18 objects), `10_rate_new_business.sql`, `20_metric_views.sql`, `90_tests.sql`.
* **Notebooks:** `src/notebooks/generate_synthetic_book.py` (seed 2027), `upload_packages.py`, `reset_demo.py`.
* **Functions:** `rate_new_business`, `rate_renewal` (Lakeview).
* **Metric views:** `mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops` (tag `certified=true`).
* **Genie Agent:** "Large Group Underwriting Cockpit" — 15 benchmarks (★1–★8 must pass); export to `src/genie/large_group_underwriting_cockpit.json`.
* **UC Skills:** `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief` (source in `docs/demo-assets/skills/`).
* **Scheduled task:** "Large Group Underwriting Morning Brief", weekdays 7:00 AM ET.
* **Artifact:** "Northwind Manufacturing — New Business Quote" (8 sections), backup in shared `genie_artifacts`.
* **Permissions:** demo users group — USE CATALOG/SCHEMA, SELECT, EXECUTE on rating functions, READ VOLUME, CAN RUN on Genie Agent.

Record actual IDs (job IDs, Genie space ID, warehouse ID) here once deployed.

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

* Naming sweep done 2026-11-15: docs now use `underwritingGenie` and "Declarative Automation Bundle". File name `L400-03_dab_deployment_and_reset.md` kept to avoid breaking links; historical session logs left as written.
* Artifact form controls are undocumented; fallback comparison panel defined.
* ★7/★8 benchmark expected values to be recorded after S5.
* Optional: internal field brief HTML rendering.

## Conventions

* Feature branches `mg-genie-<short-description>`; never commit to `main`.
* Session logs in `docs/sessions/YYYY-MM-DD_<slug>.md` (Goal, Changes, Decisions, Verification, Observations, Follow-ups); update `INDEX.md` newest first.
* No `hi_genie/` collaboration folder exists yet.
