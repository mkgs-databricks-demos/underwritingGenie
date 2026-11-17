# 2026-11-17 AC-0-1, AC-2b-10 timing, warehouse sizing, benchmark runner move

**Type:** owner Genie One tests (stopwatch) + Genie Code verification, infra change and deploy
**Branch:** `mg-genie-uw-genie-build-1` (PR #3)
**Covers:** work from late 2026-11-16 to early 2026-11-17 (UTC), after the agent benchmark session (`2026-11-16_genie-agent-benchmarks.md`)

## Goal

Close the remaining build 0 tests (AC-0-1 session instruction, AC-2b-10 prompt-to-artifact time), see whether a bigger SQL warehouse helps, and put the benchmark runner where it can be deployed.

## Results

| Item | Result | Evidence |
| --- | --- | --- |
| AC-0-1 session instruction (L200-07 §1) | **Pass** | Genie One replied exactly "Ready." (new chat, four skills, no `@` mention) |
| AC-2b-10, 2X-Small / 1 cluster (warehouse stopped) | **Fail, 5:35** | Owner stopwatch, Step 5 (exception + quote) in the real v1 -> v2 flow; first output about 1 s |
| AC-2b-10, Small / up to 2 clusters (running) | **Fail, 3:40** | Same flow |
| AC-2b-10, Large / up to 2 clusters (running) | **Fail, 4:17** | Same flow |
| Query history review | Warehouse is not the bottleneck | SQL query history API, warehouse `dcca64ab7f26cea7`: Step 5 SQL about 4-6 s of query time in every run (each query 0.3-3.9 s, mostly compilation); 2-3 query waves with Genie reasoning pauses of 4 s to about 1 min between them; about 3-3.5 min of artifact writing after the last query |
| Benchmark runner end to end | Pass | Cells run in order on serverless with `space_id` set: 15/15 on values, names missing on 7, no assertion, 15-row results table |

## Problems and root causes

* **AC-2b-10 fails on any warehouse size.** Root cause: Genie writes the whole interactive artifact (8 sections, 18 lever scenarios and their build-ups) as new HTML on every run; that alone takes about 3-3.5 minutes. The earlier "about 1 minute of queries" estimate was the span between query waves, not query time; the corrected numbers are in R1-14 item 3.
* **`system.query.history` lagged about 80 minutes**, so the three timed runs were not in it when reviewed. The SQL query history API (`w.query_history.list`, which returns `.res` + `next_page_token` in SDK 0.122) is near real time and was used instead.
* **The benchmark runner was a workspace file at the repo root**, outside both bundles: not deployed by `bundle deploy` and not runnable as a job notebook task.
* **Parallel notebook edits collided** while recreating the runner (the install cell was dropped once); found by reading the notebook back and re-added.

## Changes

* **Warehouse (`uw-genie-infra/resources/sql_warehouses/uw_genie.sql_warehouse.yml`):** 2X-Small / 1 cluster / 10 min auto-stop -> Small / up to 2 clusters / 30 min -> Large (test) -> **Small / up to 2 clusters / 30 min** (final). Each step deployed with `bundle plan` + `bundle deploy --target dev` (deployment version 6 is current); the first step was also applied through the warehouses API before deploying.
* **Benchmark runner:** recreated as a notebook at `uw-genie-agent/tests/run_genie_benchmarks.ipynb` (cells verified identical to the original file); repo-root `tests/` moved to Trash. Widgets moved into a first "Parameters" cell (owner request; widgets survive `restartPython`). Four inline review comments left (substring false positives, weak checks on benchmarks 6 and 14, result-fetch error handling, empty-result / schema crash); code not changed.
* **Requests:** R1-14 item 3 (AC-2b-10 timings, query history evidence, artifact template / single payload / smaller first render), item 6 (session instruction fixes); R1-15 paths updated for the runner move.

## Decisions (owner)

* Keep the warehouse at **Small / up to 2 clusters / 30 min auto-stop** for demo days (Large reverted: no faster, about 4x cost).
* Runner lives in the agent bundle; adding it as a post-deploy task is a build 1 item (R1-15 item 3).
* Demo handling for Step 5 until the artifact template exists: fill the wait with the exception story or Steps 7 and 9; switch to the backup artifact at about 4.5 minutes.

## Observations

* **`bundle validate` / `plan` / `deploy` work from Genie Code through the Databricks CLI tool** (working directory = bundle root). The PROJECT_MEMORY note that bundle deploy is blocked on serverless applies to running the CLI inside `executeCode`, not to the CLI tool.
* Genie One's queries on the agent warehouse are tiny; warehouse size matters only for cold starts and queuing.

## Files modified

* `uw-genie-infra/resources/sql_warehouses/uw_genie.sql_warehouse.yml`
* `uw-genie-agent/tests/run_genie_benchmarks.ipynb` (new; old `tests/genie_benchmarks/run_genie_benchmarks.py` removed)
* `docs/requests/build-1/R1-14_demo-readiness-carryovers.md`, `R1-15_genie-agent-benchmarks.md`
* `docs/sessions/2026-11-16_genie-agent-benchmarks.md`, this file, `docs/sessions/INDEX.md`
* `PROJECT_MEMORY.md`

## Reset Demo run (after the demo, owner go-ahead)

First ever run of `[dev matthew_giglia] Underwriting Genie: Reset Demo` (job `1105533136205325`, run `597932389562387`, `job_parameters` catalog / schema / domain_tag passed explicitly): **SUCCESS in about 1.5 minutes** (`reset_state` 41 s, `build_nb_quote_scenarios` 55 s, `run_tests` 10 s; target < 5 min).

* `reset_state` output: `submission_findings` 0 rows removed (none were written during the demo), `broker_submissions` restored to 25.
* Before / after snapshot: all 25 table and view row counts identical; Northwind base scenario ($625.32, Z 0.7483, Family $2,290.21, $540,000 pooled), the 18-scenario premium total and the renewal pipeline action total identical; 8 BLOCKED submissions.
* `mkgs_underwriting` tags survive the `CREATE OR REPLACE` rebuild (totals still 18 core / 2 intake_quote / 5 uw_finance); table comments kept.
* Agent benchmarks after the reset: **15/15 on values**, names missing on 7 (unchanged).
* Not checked: UC wikis pasted under R1-12 on `nb_quote_scenarios`, `renewal_scenarios` or `nb_quote_waterfall` may be removed by `CREATE OR REPLACE`; re-paste from R1-12 if so.

## Not done / open

* Gmail draft (AC-2-4): closed by owner decision (tested in other setups); pre-demo permission check only (R1-08 item 5).
* Owner's local widget state in `run_genie_benchmarks.ipynb` (a saved `space_id` value) intentionally left uncommitted.
