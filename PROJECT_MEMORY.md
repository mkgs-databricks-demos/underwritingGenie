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
* **Post-build 0 (owner decision, 2026-11-16): replace "Never compute or modify numbers" with a three-tier governed-math rule.** The old rule mixed governance (rates only from the UC function) with an artifact limitation (precomputed 18-scenario snapshot, no live queries). Keep the first strict and drop the second:
  1. **Rating outputs** (rates, credibility, pooling, trend, premium, retention) come only from `rate_new_business()` / `rate_renewal()`. Live calls are allowed: Genie may call the function for any combination the governed assumption tables support and rebuild or update the artifact from the result, so it feels like a coworker rather than a dashboard. The precomputed `nb_quote_scenarios` grid is a fast cache, not a limit.
  2. **Derived display values** (differences, % vs incumbent renewal offer, per-claimant amount above the pooling point, step deltas, PMPM/PEPM/tier conversions) are allowed only when computed in SQL from governed values through the Underwriting Genie agent (the query is visible and traceable), never in the response text, and are labeled "Derived from governed values (not a rating output)".
  3. **Never**: change assumptions, override or adjust a governed rate, or do arithmetic in the response text.
  * Demo stance: keep the precomputed levers for speed and stage safety; show one live off-grid governed request as the "coworker" moment and let Genie update the artifact.
  * Build 1 work: rewrite the rules in `docs/demo-assets/skills/nb-quote-artifact/SKILL.md` and `experience-rating-explainer/SKILL.md` to the three tiers; update L100 principle 3 / §6 and L200-05 ("governed computation, cached or live"); add a Genie One acceptance check that tier-2 values come from SQL, not the reply text.
  * Governed renewal comparison (tier 1, the most common broker question): `rate_new_business()` returns `incumbent_renewal_pmpm` (= `incumbent_premium_pmpm` x (1 + `incumbent_renewal_offer_pct`)) and `rate_change_vs_renewal_offer`, materialized in `nb_quote_scenarios`, added to the golden CSV and tests, and shown as a fifth KPI box in artifact section 3 (skill + L200-05). Reference values (2026-11-16): renewal $698.90 PMPM; default $250K/Base/Requested -10.5%; grid range -6.1% ($500K/High/Requested) to -19.2% ($150K/Low/Alternate).
  * Open actuarial decision (not technical): whether `rate_new_business()` should accept values outside the governed assumption sets. Today `pooling_points` and `trend_assumptions` each hold 3 rows, so off-grid inputs return nothing; keeping that is arguably a governance feature.
* **Post-build 0: skill fixes from the Genie One tests (owner request, 2026-11-16).** Test results: `nb-quote-artifact` passed in Genie One. All 8 sections were present; base, $150K, $500K, Alternate and Reset to recommended were verified against `nb_quote_scenarios` / `nb_quote_waterfall` / `large_claimants`; the broker proposal view (all 10 rates) and its single-page PDF export passed (AC-2b-9). The drivers question passed AC-2b-8. Fixes:
  * `nb-quote-artifact` data list: add `plan_designs`. It was never queried, so the artifact could not say what "Alternate deductible" means. Show plan names (Choice PPO 1000 = requested, Choice PPO 2500 = alternate) on the lever buttons, in section 3 and in the broker proposal columns, with "Requested" / "Alternate deductible" as subtitles. Add a benefit comparison (deductible, out-of-pocket max, coinsurance) to the workbench and the broker proposal, plus the line "Copays and Rx are the same on both plans; only the deductible and out-of-pocket max differ." Show plan relativity (0.94) on the workbench only.
  * Data model (L300-01): `plan_designs` holds only individual deductible / OOP max and coinsurance. Add `deductible_fam`, `oop_max_fam` and copay / Rx columns so the broker page can show the full benefit summary from governed data (values are in `docs/demo-assets/broker_packages/northwind_v2/benefit_summary_*.md`).
  * Section 4 wording: replace "waterfall chart of the 10 steps" with "10-step build-up: step list plus a PMPM bar chart". The steps mix USD, PMPM, a ratio and PEPM, so a stacked waterfall is not meaningful, and step deltas would be tier-2 derived values.
  * Section 6 conflict: "amount above the selected pooling point" per claimant is a calculation, which the old no-compute rule forbade. Resolve it under the three-tier rule: a governed per-claimant excess output, or tier-2 SQL labeled derived.
  * Section 2 readiness: with no item-level findings, Genie marked items green because the package "wasn't flagged" for them, and "source file" showed the package, not files. Root cause: `lg-intake-checklist` never writes `submission_findings` (0 rows). Fix: have the intake skill (or a governed job) write item-level findings with file evidence to `submission_findings`, and have the artifact read them. With no findings, label rows "package-level status" instead of green/amber per item.
  * Section 3: add the fifth KPI box "Change vs incumbent renewal offer" from the governed renewal comparison above.
  * Broker proposal: under the rates table, reword the footnote to "Tier rates are per enrolled employee per month; composite = average per enrolled employee." Keep the PDF behavior Genie used (a separate single-page `... - Broker Proposal.pdf` in the chat outputs, with no view toggle).
  * Section 8: the underwriter notes stay on the recommended scenario when levers move. Document this as intended in the skill and L200-05.
  * `experience-rating-explainer`: step 3 ends with tier rates, but the drivers answer stopped at PEPM, so make tier rates a required bullet. State trend as "annual rate over `trend_years` years" (base 9.0% over 2 years = 1.1881), not "the trend period". Add the loss-ratio framing as an optional bullet (blended claims / premium = target 88%; at the incumbent's $612.00 the same claims run 89.9%), computed as tier-2 SQL.
  * `experience-rating-explainer` list completeness (guardrail test, 2026-11-16): asked to lower the Family rate to $2,200, Genie correctly refused and offered governed options, but its table "Governed scenarios with a Family rate at or below $2,200" showed 3 of the 7 qualifying rows. It omitted Choice PPO 2500 at $150K/High ($2,176.61, -2.9%), $150K/Low ($2,067.53, -7.8%), $250K/Low ($2,100.36, -6.3%) and $500K/Low ($2,142.42, -4.4%). Add a rule: when listing scenarios that meet a condition, either show all matching governed rows or say "selected options (n of N matching)" and how they were picked. Prefer including conservative-trend options (High) that still meet the condition.
  * L200-07 beat 2b: replace the Ask Genie prompt with "Why is our quote 2.2% above the incumbent's current premium? Walk me through what drives it." (AC-2b-8: large claimants, manual rate / credibility blend, trend, retention). Keep "Why is the Family rate higher than the incumbent's current rate?" as a units-mismatch test (expect a per-family vs PMPM explanation, tier factor 2.85, and "no incumbent tier rates on file").
  * Genie One test setup: answers used `experience-rating-explainer` before that skill was added in Genie One (the link pointed to the `~/.assistant/skills/` workspace copy). Before each skill test, confirm which skills the chat has active, so it is clear whether the added skill or a workspace copy drove the answer.
* **Post-build 0: intake findings from the Genie One `lg-intake-checklist` test (owner request, 2026-11-16).** Test result with the v1 package (zip): BLOCKED, all 5 seeded gaps found with exact file evidence (15 months Apr 2025-Jun 2026; PAID basis, no lag report; 22 of 420 employees = 11 missing tier + 11 missing birth date, census line numbers correct; LC-02/03/04 missing status; only the PPO 2500 summary attached), no rate quoted. AC-2-1, 2-2, 2-3 and 2-5 pass. Fixes:
  * **IC-01 rule vs v2 data (design bug, fix before relying on beat 2b).** Rule text: "24 consecutive incurred months ending no more than 3 months before the submission." v2 incurred months end Jun 2026 (paid through Aug 2026) and v2 was received 2026-11-13, so v2 strictly fails IC-01 too, contradicting L300-05's expected READY_WITH_WARNINGS (and AC-2b-1). Preferred fix: reword IC-01 in `intake_checklist` to measure recency from the paid-through date ("incurred months with a paid-through date no more than 3 months before the submission"); v2 then passes with no data change. Alternative: shift the v2 incurred window 2-3 months later in the generator (rates unchanged because monthly claims are flat and lags are preserved, but it touches the generator and golden-file inputs).
  * **L300-05 / AC-2-2 expected counts.** Against the governed checklist v1 has 6 blocking findings, not 5: IC-07 Current rates is also missing (the v1 email has the +14.2% renewal offer but no current premium; $612.00 PMPM first appears in the v2 email). Update L300-05 ("BLOCKED with 6 blocking findings") and AC-2-2 (6 gaps; pass at >= 5 of 6 with note), or add the current premium to the v1 email if 5 was intended.
  * **IC-10 Prior plan changes (warning).** Neither v1 nor v2 states plan changes (or "none"), so Genie correctly flags IC-10 as missing. Either add "No plan design changes during the experience period" to the v2 email / RFP, or list IC-10 as an expected v2 warning in L300-05 alongside IC-08.
  * **v1 file count.** `northwind_v1/` has 6 files (`benefit_summary_alternate.md`, `broker_email.txt`, `census.csv`, `claims_experience_paid.csv`, `large_claimant_report.csv`, `rfp_questionnaire.md`); L200-07 beat 2 says "drag all 5 files". Fix the count (or say "all files").
  * **Gmail draft (AC-2-4, Must).** The Genie One Gmail connector in this workspace is read-only, so the draft could only be shown in chat (the L200-07 §7 fallback). The demo setup in L200-07 §1 must require a Gmail connection that can create drafts, and the runbook (L400-02) should check this at T-30 min.
  * **IC-01 broker ask wording.** Genie asked for experience "through at least Aug 2026", which mixes incurred months and paid-through date. The `lg-intake-checklist` broker-ask template should say "24 consecutive incurred months with a paid-through date no earlier than <submission - 3 months>".
  * **Item-level findings.** The intake answer is exactly the item-level evidence the artifact readiness section needs; this confirms the `submission_findings` write already listed under the skill fixes above.

## Conventions

* Feature branches `mg-genie-<short-description>`; never commit to `main`.
* Session logs in `docs/sessions/YYYY-MM-DD_<slug>.md` (Goal, Changes, Decisions, Verification, Observations, Follow-ups); update `INDEX.md` newest first.
* No `hi_genie/` collaboration folder exists yet.
* **SDK on serverless:** use `WorkspaceClient(host=_host, token=_token)` with credentials from `dbutils.notebook.entry_point`. Default `WorkspaceClient()` auth fails on serverless (no REPL context).
* **CLI on serverless:** `databricks bundle deploy/run` is blocked. Use web terminal or trigger jobs via REST API (`w.jobs.run_now()`).
* **waves.json converge sessions:** every converge session needs a non-empty `runtime_targets` list; every key in that list must also appear in the wave's `runtime_gate`. Catch both with the pre-flight cell in `Genie Code Session Starter - DO NOT EDIT.ipynb`.
* **bundle run --var flags:** always pass the same `--var` flags to `bundle run` as to `bundle deploy`. Without `--var=instance_suffix=-uw-genie`, the CLI defaults to the global instance and may trigger a different project's setup job.
