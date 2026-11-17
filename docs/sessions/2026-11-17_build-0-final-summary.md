# 2026-11-17 Build 0 final summary

**Type:** close-out summary for build 0 (build, deploy, owner testing)
**Branch:** `mg-genie-uw-genie-build-1` (PR #3 to `main`, open, not yet merged)
**Covers:** 2026-11-15 to 2026-11-17. Detail lives in the per-session logs listed in [INDEX.md](INDEX.md); this file is the single place that says what build 0 delivered, what was tested, what passed and what moves to build 1.

## Outcome

* **Build:** all waves 0-0 to 0-5 passed on the `uw-genie: Build Waves` job (`309617019935041`); passing runs `581746600380456` (0-0, 0-1), `197898696497677` (0-2, 0-3), `1025333002364111` (0-4, 0-5). Earlier runs `1076347254049076`, `1060969502993602` and `121608533170151` stopped at blocked gates the owner fixed.
* **Testing:** complete (2026-11-16 to 2026-11-17). The governed data layer and the Genie Agent are correct (all checked values match; agent benchmarks 15/15 on values). The gaps are in skill behaviour, Genie One orchestration, the artifact's generation time, renewal calibration and parameterization; all are recorded as build 1 requests R1-01 to R1-15.
* **Exit criteria (README "Build plan"):** not met as written. AC-2b-1 (v2 ready to quote) and AC-2b-10 (prompt to artifact <= 3 min) fail; no three consecutive dry runs were done. Reset restores state well inside 5 minutes (1.5 min). The neutrality grep was not re-run during testing.

## What build 0 delivered (target `dev`)

| Area | Delivered |
| --- | --- |
| Bundles | `uw-genie-infra` (schema, `broker_packages` volume, SQL warehouse, `setup_demo` / `reset_demo` jobs, SQL, notebooks) and `uw-genie-agent` (Genie Agent from a serialized space file) |
| Data | `hls_fde_dev.uw_genie`: synthetic book (60 groups incl. Northwind Manufacturing and Lakeview Logistics), broker packages `northwind_v1/` and `northwind_v2/` |
| Governed math | `rate_new_business()`, `rate_renewal()`, `nb_quote_scenarios` (18 scenarios), `renewal_scenarios`, `nb_quote_waterfall` |
| Semantics | Metric views `mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops`; Genie Agent `[dev matthew_giglia] Underwriting Genie` (`01f1e1554179173991a4a487c2ae28ef`) |
| Genie One | UC Skills `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief` |
| Added during testing (manual) | Governed tag `mkgs_underwriting` (core / intake_quote / uw_finance) on 25 objects + schema, volume and agent; Discover domain `mkgs_underwriting` with 30 glossary pages; Genie One routine "Large Group Underwriting Morning Brief" (Active, Mon-Fri 07:00 America/New_York) |
| Added during testing (repo) | Agent benchmark runner `uw-genie-agent/tests/run_genie_benchmarks.ipynb`; setup guide `docs/setup/uc-domain-and-pages/README.md`; demo prompts `docs/prompts/genie-one-demo-briefing-artifact.md`; build 1 requests `docs/requests/build-1/` |

## Test results

| Test | Where | Result | Main findings -> request |
| --- | --- | --- | --- |
| AC-0-1 session instruction | Genie One, new chat | **Pass** ("Ready.") | Instruction text gaps -> R1-14 item 6 |
| Beat 1 Morning Brief skill | chat `06ea9987eb034f349bfaf73782c5f71a` | Partial pass | Sections 1/3/4/5 pass; blocked count 1 of 8; renewal drivers not governed -> R1-11 |
| Beat 1 routine (Prompt A) | chat `0c47a84b40db5463fb788a4fde321f9b1` | Pass on values | 8 of 8 blocked; group IDs instead of names for large-claimant groups -> R1-14 item 1 (recorded in `docs/prompts/genie-one-demo-briefing-artifact.md`) |
| Beat 2 intake (v1, v2) | chat `4fbc87afae364d29bdcda97dbaedecd2` | Pass with design bug | v1 BLOCKED; v2 BLOCKED on IC-01 alone (rule vs data design bug), so AC-2b-1 fails as written; Genie One is read-only, so findings and the exception live only in the artifact -> R1-08 |
| Beat 2 real flow v1 -> v2 -> IC-01 exception -> quote | same chat | Pass | Item-level readiness with source files; earlier artifacts collide ("v2" suffix) -> R1-08 items 7-8 |
| Beat 2b quote artifact (cold start) | chat `04e80baad93c48fc9dfcfe4f9ffda27a` | Pass | Plan details needed a prompt; readiness not evidence-based cold -> R1-06 |
| Beat 2b drivers / guardrails | same + `4fbc87af...` | Pass with nits | Live `rate_new_business()` call matches stored values; $1,500 deductible correctly refused -> R1-07, R1-09 |
| Beat 3 Lakeview renewal | chat `942324e816bd45aa92ea0e10d54c0cba` | Pass (AC-3-1, 3-2, 3-3) | First answer gave a wrong cause for the $500K what-if; reply arithmetic; rationale wording -> R1-13 |
| Beat 4 decisions to dollars | chat `de1a09587c2a47db843d18ae3735e275` | Values pass; AC-4-2, AC-4-4 not met | Matched benchmark 8 exactly via `MEASURE()` on `mv_renewal_book`; loss-ratio wording followed the glossary page -> R1-13. AC-4-1 (source of the group count) not confirmed from "Show generated code" |
| AC-2-4 Gmail draft | - | **Closed by owner decision** | Tested by the owner in other setups; pre-demo draft-permission check only -> R1-08 item 5 |
| AC-2b-10 prompt to artifact <= 3 min | owner stopwatch, real flow | **Fail**: 5:35 (2X-Small), 3:40 (Small), 4:17 (Large) | Query history: Step 5 SQL about 4-6 s on every size; about 3-3.5 min of artifact writing after the last query -> R1-14 item 3 |
| Agent benchmarks (L300-03 §5, 15 questions) | Genie Conversation API | **15/15 on values** (three runs, incl. after reset) | Benchmark 7 shows group IDs, not names; the space has no benchmarks defined -> R1-15 |
| Reset Demo (first run) | run `597932389562387` | **Pass**, about 1.5 min | Data identical before and after; tags and comments kept; benchmarks 15/15 afterwards |

## Key numbers confirmed (synthetic, base scenario)

* **Northwind ($250K / base / requested):** $625.32 PMPM, $1,459.07 PEPM, +2.2% vs $612.00 current, Z 0.7483, tiers $803.58 / $1,607.16 / $1,486.63 / $2,290.21, $540,000 pooled, IBNR $110,476.67. Incumbent renewal +14.2% ($698.90).
* **Lakeview ($250K / base / current):** $599.33 PMPM (+9.37% vs $548.00), Z 1.0, $435K pooled.
* **Benchmark 7:** 3 renewals as of 2026-11-16 (date-dependent until R1-10). **Benchmark 8:** Q1 2027 premium at risk $25,303,698.74 uncapped vs $23,031,131.29 at a 12% cap.

## Changes made during testing

* Governed tag policy and Discover domain `mkgs_underwriting`, 30 glossary pages (factual fixes recorded in `2026-11-16_uc-glossary-pages.md`).
* Genie One Morning Brief routine created by hand from Prompt A.
* SQL warehouse 2X-Small / 1 cluster / 10 min -> **Small / up to 2 clusters / 30 min** (YAML + `bundle deploy`); a Large test was reverted.
* Benchmark runner added to the agent bundle; four inline review comments left on it (matching too loose, weak checks on benchmarks 6 and 14, result-fetch errors, empty-result crash), code unchanged.

## Decisions (owner)

* Interim demo path kept the IC-01 "approve an exception" step until build 1 fixes the rule.
* Renewal rate actions (R1-11) are fixed in build 1, not now.
* AC-2-4 closed on prior testing; warehouse kept at Small; demo is complete, so the reset ran.

## Lessons for build 1

* Write every privileged action into `waves.json` `context_notes` up front; repair does not re-run a session that ended `SUCCESS`; uncommitted files in the Git folder fail the gate.
* Name the token explicitly for PR creation (`GH_TOKEN_MKGS`).
* SQL file tasks need `:param` with `EXECUTE IMMEDIATE` (not `{{param}}`), `\'` for quotes, and jobs with a `parameters:` block need `job_parameters` in `run-now`.
* `bundle validate` / `plan` / `deploy` work from Genie Code's Databricks CLI tool (not from inside `executeCode`).
* `system.query.history` can lag over an hour; use the SQL query history API for same-session checks.
* The dev agent title prefix (`[dev matthew_giglia] `) breaks prompts that name the agent; render titles and prompts per target (R1-04).

## Open after build 0

* Merge PR #3 (owner), then start build 1 on a new branch from `main`.
* Owner decisions before the build 1 plan: renewal calibration target (R1-11), demo as-of date (R1-10), benefit relativity ownership (R1-09), off-grid inputs (R1-05).
* Confirm AC-4-1 from the beat 4 chat's generated code (optional).
* R1-12 wikis may need re-pasting on `nb_quote_scenarios`, `renewal_scenarios` and `nb_quote_waterfall` after any rebuild (not checked).

## Files modified (this summary)

* `docs/sessions/2026-11-17_build-0-final-summary.md` (new), `docs/sessions/INDEX.md`
* `README.md`, `PROJECT_MEMORY.md`
