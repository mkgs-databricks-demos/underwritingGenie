# L400-01 — Genie Code Build Sessions: Instructions and Acceptance Criteria

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


Build the whole demo with **8 interactive Genie Code sessions in 4 waves** inside the DAB repo (L400-03). Sessions within a wave can run in parallel. Each session: paste the **Session prompt**, attach the listed docs, let Genie Code work, then verify **Acceptance criteria** before closing. Log each session in `docs/sessions/YYYY-MM-DD_<slug>.md` (Goal, Changes, Decisions, Verification, Observations, Follow-ups).

> See [diagrams/mermaid/07_build_waves_gantt.md](../diagrams/mermaid/07_build_waves_gantt.md).

## Universal session preamble (prepend to every session prompt)
```
Context: carrier-neutral synthetic demo "Underwriting Cockpit — Large Group Experience Rating with Genie One".
Repo: genie-one-large-group-underwriting (DAB). Read docs/design/L100_demo_overview.md first.
Rules: no real carrier/customer/vendor/employee names; all data synthetic and tagged data_class=synthetic;
use bundle variables ${var.catalog} / ${var.schema} / ${var.warehouse_id}; never hardcode workspace URLs;
write a session log to docs/sessions/ when done. Ask me before deleting anything outside the target schema.
```

## Wave 1 — Foundation
### S1 Bundle, catalog and schema
**Inputs:** L400-03, L100 §5–7. **Prompt:**
```
Create the Databricks Asset Bundle per docs/design/L400-03 §1: databricks.yml with targets dev (default) and demo,
variables catalog (default lg_underwriting_dev), schema (default demo), warehouse_id; resources: schema, volume
broker_packages, jobs setup_demo (tasks: create_tables, generate_synthetic_book, upload_packages,
build_nb_quote_scenarios, run_tests) and reset_demo. Add src/sql/00_ddl.sql from L300-01. Validate the bundle.
If I lack CREATE CATALOG, switch the default catalog to my home catalog and schema lg_uw_demo and record it.
```
**Acceptance:** `databricks bundle validate` passes · schema + volume exist after deploy · DDL creates all 18 objects · decision on catalog recorded in session log.

### S2 Synthetic data
**Inputs:** L200-01, L300-01. **Prompt:**
```
Write src/notebooks/generate_synthetic_book.py (seed 2027) that loads all pinned values in L300-01 exactly
(Northwind, Lakeview, assumption tables AV-2027.1, intake checklist, persistency) and generates the random book
(58 groups) plus trend_monitor. Load census/claims/claimants for Northwind from demo-assets/broker_packages/northwind_v2
(census v1 rows from northwind_v1). Add assertions from L200-01 Testing. Run it.
```
**Acceptance:** Northwind member_months = 23,520; claims paid_to_date sum = 10,480,000.00; tier counts 168/76/59/117; 4 claimants v2 with status; `broker_submissions` has Northwind v1 BLOCKED and v2 READY_WITH_WARNINGS; 60 groups; all tables tagged.

## Wave 2 — Governed math + documents
### S3 Rating function and scenarios
**Inputs:** L200-02, L300-02, `demo-assets/nb_quote_scenarios_expected.csv`. **Prompt:**
```
Implement src/sql/10_rate_new_business.sql exactly as L300-02 §1 (SQL table function with COMMENTs), §2
scenario materialization and waterfall view, §5 rate_renewal for Lakeview, and §4 tests in src/sql/90_tests.sql
comparing to the golden CSV (load it to a temp view). Run the job tasks build_nb_quote_scenarios and run_tests.
If LATERAL over the cross join fails, generate the 18-call UNION ALL fallback.
```
**Acceptance:** all 6 tests pass · base row premium_pmpm 625.32, rate_ef 2,290.21, credibility 0.7483 · EXECUTE granted to demo users group · function lineage visible in Catalog Explorer.

### S4 Broker documents and volume (parallel with S3)
**Inputs:** L300-05. **Prompt:**
```
Upload demo-assets/broker_packages/northwind_v1 and northwind_v2 to the broker_packages volume (job task
upload_packages). Optionally render claims_experience_*.csv and large_claimant_report.csv to watermarked PDFs
("SYNTHETIC DEMO DATA") alongside the CSVs. Verify v1 contains the 5 seeded gaps in L300-05.
```
**Acceptance:** both folders in volume · gap verification script prints 5/5 · no real names/emails (all `.example`).

## Wave 3 — Semantics
### S5 Metric views and UC Pages
**Inputs:** L200-03, L300-03 §1–3, semantics/01–03. **Prompt:**
```
Create renewal_book_scenarios and the three metric views from L300-03 (src/sql/20_metric_views.sql). Add column
and measure comments matching semantics/ definitions. Publish the semantics/ terms as UC Pages under domain
Underwriting with subdomains Rating & Experience, Intake & Quote, Underwriting Finance, linked to assets. Tag
metric views certified=true.
```
**Acceptance:** `SELECT MEASURE(...)` returns values for all measures · ≥30 Pages published and linked · Q1-2027 uncapped vs capped premium at risk recorded in session log (feeds benchmarks ★7–★8).

### S6 Genie Agent and benchmarks
**Inputs:** L300-03 §4–5. **Prompt:**
```
Create the Genie Agent "Large Group Underwriting Cockpit" with the data, instructions, example SQL and trusted
assets in L300-03 §4. Add the 15 benchmarks in §5 (fill ★7/★8 expected values from the S5 session log). Run the
benchmarks, fix instructions until all ★ benchmarks pass, and export the agent config (serialized space) to
src/genie/large_group_underwriting_cockpit.json.
```
**Acceptance:** ★1–★8 pass 100%; overall ≥ 90% · answers to ★1 show verified badge (trusted asset) · config exported.

## Wave 4 — Genie One
### S7 Skills and scheduled task
**Inputs:** L200-04, L200-06, L300-04, `demo-assets/skills/`. **Prompt:**
```
Publish the four skills in demo-assets/skills/ to UC Skills at ${catalog}.${schema} and copy them to my workspace
skills folder. Replace <catalog>.<schema> placeholders. In Genie One, create the scheduled task
"Large Group Underwriting Morning Brief" (weekdays 7:00 AM ET) with prompt "/uw-morning-brief Run today's
Large Group Underwriting Morning Brief." Run it now once.
```
**Acceptance:** skills visible and invocable with `/name` in Genie One · scheduled run meets AC-1-1…AC-1-3 · skill test prompts: "Is northwind_v1 ready to quote?" ⇒ BLOCKED, 5 findings; "Rate Northwind" ⇒ cites AV-2027.1 and no freehand math.

### S8 Artifact, backup and dry runs (Genie One, not Genie Code)
**Inputs:** L200-05, L200-07. **Steps:** run Beat 2 and Beat 2b exactly as L200-07; refine the `nb-quote-artifact` skill until AC-2b-1…AC-2b-10 pass; keep the best artifact as backup "Northwind Manufacturing — New Business Quote" in shared `genie_artifacts`; run 3 full dry runs and log timings.
**Acceptance:** 3 consecutive dry runs pass every **Must** criterion in L200-07 · artifact generation median ≤ 3 min · backup artifact saved.

## Exit criteria for the whole build
All Must criteria in L200-07 pass in 3 consecutive dry runs; reset job restores state in < 5 min; package contains no prohibited names (grep check in L400-03 §4).
