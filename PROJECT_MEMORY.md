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
* `docs/requests/build-1/INDEX.md` — detailed build 1 requests (R1-01..R1-15); source for the build 1 plan
* `docs/setup/uc-domain-and-pages/README.md` — manual setup of the governed domain tag (dev: `mkgs_underwriting`, values core / intake_quote / uw_finance), the Discover "Underwriting" domain and the UC glossary pages; done on dev 2026-11-16 (Genie Agent tagged manually)
* `docs/prompts/genie-one-demo-briefing-artifact.md` — Genie One prompts for the Morning Brief routine and the customer-facing demo artifact

## Known gaps / open items

* Naming sweep done 2026-11-15: docs now use "Underwriting Genie" (not "Underwriting Cockpit"); two bundles `uw-genie-infra` and `uw-genie-agent`; catalog/schema `hls_fde_dev.uw_genie`. File name `L400-03_dab_deployment_and_reset.md` kept to avoid breaking links; historical session logs left as written.
* Artifact form controls are undocumented; fallback comparison panel defined.
* ★7/★8 benchmarks recorded 2026-11-16 in L300-03 §5: ★7 = 3 as of 2026-11-16 (date-dependent, see R1-10); ★8 = Q1 2027 premium at risk $25,303,698.74 uncapped vs $23,031,131.29 at a 12% cap (LR 88.2% vs 88.7%).
* Optional: internal field brief HTML rendering.
* **Build 1 requests (owner, 2026-11-16): full detail in [`docs/requests/build-1/`](docs/requests/build-1/INDEX.md).** Write the build 1 plan from these files; keep only one-line pointers here.
  * R1-01: switch infra `dev` back to `mode: development` (schema becomes `dev_matthew_giglia_uw_genie`); dev stays destroyable, no `prevent_destroy` on dev.
  * R1-02: `${resources...}` for every catalog/schema reference (infra compliant; agent uses per-target vars).
  * R1-03: metric views as `fixtures/metric_views/*.yaml` + `list_fixtures` -> `for_each` deploy job (ground-truth-infra pattern, without its hard-coded fallbacks).
  * R1-04: 100% parameterized, required params with no literal defaults; Genie space and skills rendered per target.
  * R1-05: three-tier governed-math rule (decided); governed renewal-offer comparison ($698.90, default -10.5%); open actuarial decision on off-grid inputs.
  * R1-06: `nb-quote-artifact` fixes (plan_designs / plan names / benefits, section 4 wording, claimant excess, readiness from findings, KPI box 5, footnote, notes).
  * R1-07: `experience-rating-explainer` fixes (tier rates, trend years, loss-ratio framing, list completeness) and the L200-07 beat 2b drivers prompt.
  * R1-08: intake fixes; **IC-01 rule vs v2 data is a design bug** (v2 strictly fails the 3-month rule); v1 has 6 blocking findings; IC-10; Gmail draft scope; write `submission_findings`.
  * R1-09: governed path for benefit changes (no relativity model today; unknown plans return 0 rows; `rate_renewal` has no plan parameter and defaults a missing relativity to 1.0); needs an actuarial decision.
  * R1-10: governed `demo_as_of_date` for "next N days" windows (★7 changes with the run date today; example SQL has no lower bound).
  * R1-11: **renewal rate actions are not governed** (stored `renewal_pipeline` matches live `rate_renewal()` for 1 of 59; calibrate the generator, then populate from the function and re-record ★7/★8); renewal "why" from the governed build-up; Morning Brief must keep blocked submissions with no `groups` row (showed 1 of 8). Owner: fix in build 1, not now.
  * R1-12: UC wiki drafts for all 25 objects in `hls_fde_dev.uw_genie` (no public wiki API: paste per table or fill from Genie Code on the table page); re-apply after R1-01's schema rename and update renewal caveats after R1-11.
  * R1-13: beats 3-4 (both pass on values): fix what-if causes, no reply-text dollar impacts, AE rationale template, one loss-ratio definition (Genie One follows the glossary page), `mv_renewal_book` count measure, chart + 85% MLR floor, number formatting.
  * R1-14: beats 1-2 carryovers: Morning Brief routine rules into the skill (names, not IDs), backup artifact, measure AC-2b-10, domain tagging in setup, demo prompt file per target.
  * R1-15: agent benchmarks pass 15/15 on values (agent layer is sound); load the 15 with SQL answers into the Genie space, agent instruction to show group names, keep `tests/genie_benchmarks/run_genie_benchmarks.py` as the scripted check.

## UC glossary pages (domain `mkgs_underwriting`)

30 draft pages (all 30 verified) in domain `mkgs_underwriting` (domain ID `61901539-1958-4b2e-8266-070462db8291`), created 2026-11-16 from `docs/semantics/01..03` and reworked by hand into a general format. Session log with page IDs: `docs/sessions/2026-11-16_uc-glossary-pages.md`. Rules for creating or editing these pages:

* **Format:** no "Synthetic demo content" banner. Sections: Definition · Business context · **Where to find it** · Related terms (ending "*Other pages in the Underwriting domain may also be related.*") · External references (where present). End with one line: *Linked data assets contain synthetic data.* No `---` rule (the editor shows it as literal text).
* **General wording:** pages must be reusable beyond the demo. No "(demo: …)" values or storyline beats in descriptions, definitions or business context; workspace-specific values go in "Where to find it", labelled "in the linked data". Carrier-neutral, no real company names.
* **Body claims:** only from `docs/semantics/` or verified against code (function/view definitions, metric view measure expressions, `information_schema`).
* **External references:** keep existing "External references" sections and their Sources. Add new references only on request, as references only (no new body claims). Prefer ASB, SOA, American Academy of Actuaries, CMS, eCFR; skip links without confirmed citations.
* **Related assets:** link only tables, views and metric views tagged `mkgs_underwriting` in `hls_fde_dev.uw_genie`, by full name. Never link UC functions (`rate_new_business`, `rate_renewal`): the resolver treats them as tables and 404s.
* **Page links:** add manually from **Add related asset → Pages** (draft pages may not appear there yet). Never pass page names or IDs to the Genie Code page-form tool — three attempts linked unrelated dashboards. Keep existing page links, including "Inaccessible" ones (valid links that resolve over time). Genie Code updates omit related assets so page links are preserved.
* **Renewal lineage:** `mv_renewal_book` is built on `renewal_book_scenarios` (`renewal_pipeline` joined to `persistency_curve` on `band_min`/`band_max`, uncapped and +12% capped). Never credit a renewal number to `rate_renewal()` unless it is read directly from `rate_renewal()` or `renewal_scenarios` (Lakeview Logistics only).
* **Measure names:** use the metric view names as-is, e.g. "Projected Loss Ratio (Uncapped)", "Projected Loss Ratio (12% Cap)", "Premium at Risk (Uncapped)", "Premium at Risk (12% Cap)".
* **Editing:** no API or bulk tool can edit or delete existing pages. Edit one page at a time: open it, click **Edit**, then have Genie Code update the form; save with **Save as draft**.

## Conventions

* Feature branches `mg-genie-<short-description>`; never commit to `main`.
* Session logs in `docs/sessions/YYYY-MM-DD_<slug>.md` (Goal, Changes, Decisions, Verification, Observations, Follow-ups); update `INDEX.md` newest first.
* No `hi_genie/` collaboration folder exists yet.
* **SDK on serverless:** use `WorkspaceClient(host=_host, token=_token)` with credentials from `dbutils.notebook.entry_point`. Default `WorkspaceClient()` auth fails on serverless (no REPL context).
* **CLI on serverless:** `databricks bundle deploy/run` is blocked. Use web terminal or trigger jobs via REST API (`w.jobs.run_now()`).
* **waves.json converge sessions:** every converge session needs a non-empty `runtime_targets` list; every key in that list must also appear in the wave's `runtime_gate`. Catch both with the pre-flight cell in `Genie Code Session Starter - DO NOT EDIT.ipynb`.
* **bundle run --var flags:** always pass the same `--var` flags to `bundle run` as to `bundle deploy`. Without `--var=instance_suffix=-uw-genie`, the CLI defaults to the global instance and may trigger a different project's setup job.
