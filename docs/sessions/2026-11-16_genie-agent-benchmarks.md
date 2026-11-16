# 2026-11-16 Genie Agent benchmarks (L300-03 §5)

**Type:** automated test by Genie Code (Genie Conversation API against the deployed dev agent `[dev matthew_giglia] Underwriting Genie`, space `01f1e1554179173991a4a487c2ae28ef`)

## Goal

Run the 15 agent benchmarks (8 demo-critical) that build 0 defined but never ran, and check the agent on its own, without Genie One skills.

## Method

* The space has no benchmarks defined (`underwriting_genie.geniespace.json` has sample questions and example SQL only), so the UI Benchmarks tab could not be used.
* Each question was asked as a new conversation with `w.genie.start_conversation_and_wait` (Databricks SDK 0.122, serverless, token from the notebook context because default auth fails on serverless). The answer text, generated SQL and result rows were compared with the expected values.
* The runner is saved as `tests/genie_benchmarks/run_genie_benchmarks.py` (notebook source; required widget `space_id`, optional `only`). Its check logic was tested on benchmarks 7, 8 and 13 and on a blank `space_id`; the full notebook (widgets, display, assertion) has not been run end to end as a notebook.

## Results

* **Values: 15/15 pass.** Every answer came from a governed table or metric view (`nb_quote_scenarios`, `broker_submissions`, `groups`, `retention_targets`, `renewal_pipeline`, and `MEASURE()` on `mv_renewal_book` for benchmark 8). About 18 seconds per question.
* **Names: benchmark 7 failed the presentation check** (0/3 names; group IDs `GRP-BK-035` / `GRP-BK-005` / `GRP-BK-007` instead of Cedar Ridge Contractors / Yarrow Software / Birchwood Wholesale).
* The first automatic comparison flagged benchmarks 7 and 8; manual review showed both were correct (benchmark 8 rounded to $25.30M / $23.03M). The runner now accepts rounded millions and percentages.

## Problems and root causes

* **IDs instead of names:** no agent instruction to join `groups` for names; same cause as the Morning Brief ID quirk.
* **No benchmarks in the space:** build 0 put benchmarks only in L300-03, not in the space definition.
* **Odd follow-up question** after a fully specified question (benchmark 7).

## Decisions

* Record as **R1-15** (load benchmarks into the space, names instruction, runner as a scripted check).
* Conclusion for build 1 planning: the agent layer is sound; the beat 1-4 issues are in the skills and Genie One orchestration (R1-05..R1-14).

## Changes (files)

* `tests/genie_benchmarks/run_genie_benchmarks.py` (new; later moved, see below)
* `docs/requests/build-1/R1-15_genie-agent-benchmarks.md` (new), `docs/requests/build-1/INDEX.md`, `PROJECT_MEMORY.md`
* `docs/sessions/2026-11-16_genie-agent-benchmarks.md`, `docs/sessions/INDEX.md`

## Follow-ups

* **Done (second run, same day):** the runner's cells were executed in order in a serverless notebook session with `space_id` set through the widget cell (as a job's base parameter would). All 15 completed (13-20 seconds each); output `values: 15/15 pass; names missing on: ['7']`; no assertion raised; the results table displayed 15 rows. The `%pip` / restart cells were skipped (SDK 0.122 already installed). In this run benchmark 1 was answered by a live `rate_new_business()` call with no answer text, and passed on the result rows.
* **Moved (same day):** the runner was recreated as a **notebook** inside the agent bundle, `uw-genie-agent/tests/run_genie_benchmarks.ipynb` (5 cells, each verified identical to the original file's cells), so `bundle deploy` uploads it and it can be a job notebook task (R1-15 item 3). The repo-root `tests/` folder was moved to Trash. The Git folder saves new notebooks as `.ipynb`; a job task would use `tests/run_genie_benchmarks.ipynb`.
* Still untested from build 0: AC-0-1 session instruction, AC-2b-10 timing (R1-14), Gmail draft-capable connector (R1-08), Reset Demo re-run.
