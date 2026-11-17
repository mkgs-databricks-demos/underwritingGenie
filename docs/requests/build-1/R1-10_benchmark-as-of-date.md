# R1-10 Pin a governed as-of date for time-window questions (benchmark ★7)

**Status:** Open
**Origin:** Owner request, 2026-11-16, after computing benchmarks ★7 / ★8 (recorded in L300-03 §5)
**Related:** R1-04 (parameterization), beat 1 (Morning Brief, L200-06 / L200-07 AC-1-4), R1-08 (intake recency used today's date instead of the received date)

## Problem

"Next 90 days" questions are evaluated against `current_date()`, while the synthetic book has fixed renewal dates (`renewal_pipeline.renewal_date` from 2027-01-01 to 2027-06-01). So the expected answer depends on the day the demo or test runs, and a benchmark cannot have one expected value.

## Current state (evidence, 2026-11-16)

* L300-03 example SQL 5 and the deployed Genie space (`uw-genie-agent/underwriting_genie.geniespace.json`, example question "Renewals in the next 90 days likely above 15%") use `WHERE renewal_date <= date_add(current_date(), 90) AND recommended_rate_action > 0.15`. There is **no lower bound**, so renewals that have already passed keep counting.
* The Genie space also has the sample question "Which renewals in the next 90 days have a rate action above 15%?"; `uw-morning-brief/SKILL.md` step 1 and L200-06 use "next 90 and 120 days"; L200-07 beat 1 asks the same question (AC-1-4: at most 5 groups).
* The book has 7 renewals above 15%: Jan 1, Feb 1 (x2), Mar 1, Apr 1, May 1 and Jun 1, 2027. With the current SQL, ★7 is:

| Run date | Expected ★7 |
| --- | --- |
| 2026-11-03 to 2026-11-30 | 3 (Yarrow Software +16.3%, Cedar Ridge Contractors +16.2%, Birchwood Wholesale +15.4%) |
| from 2026-12-01 | 4 |
| from 2027-01-01 | 5 (and Cedar Ridge, already renewed, still counts) |
| from 2027-01-31 | 6 |
| from 2027-03-03 | 7 |

* After 2027-06-01 every renewal is in the past, so the book stops being a credible "upcoming renewals" demo at all.
* ★8 (`2027-Q1` premium at risk) uses a fixed quarter and is not affected.

## Requested change

1. **One governed as-of date.** Add a demo as-of date as configuration, not code: for example a one-row table `demo_calendar(as_of_date)` (or a column on an existing config table), written by `setup_demo` / `reset_demo` from a bundle variable `demo_as_of_date` (R1-04: required, no literal default in code; per-target value in `databricks.yml`). Default meaning for the current book: `2026-11-16`.
2. **Use it everywhere a relative window is evaluated:** Genie space example SQL and instructions ("next N days" means `renewal_date BETWEEN as_of_date AND date_add(as_of_date, N)`), `uw-morning-brief` steps, `lg-intake-checklist` recency (use `broker_submissions.received_ts`, R1-08), and any metric view that needs "upcoming" filters.
3. **Add the missing lower bound** (`renewal_date >= as_of_date`) so past renewals never count.
4. **Optional, keeps the book fresh:** have `generate_synthetic_book` place renewal dates relative to `demo_as_of_date` (for example the next 1-6 months), so the demo works whenever it runs. This changes generated dates, so re-record ★7 / ★8 and the golden files that depend on dates (renewal rows only; the Northwind new business numbers do not depend on renewal dates).
5. **Record benchmarks against the pinned date:** L300-03 §5 ★7 becomes "N as of `demo_as_of_date`", and the setup tests assert it.

## Files affected

* `uw-genie-infra/databricks.yml` (variable), `uw-genie-infra/src/sql/00_ddl.sql` (config table), `setup_demo.job.yml` / `reset_demo.job.yml`
* `uw-genie-infra/src/notebooks/generate_synthetic_book.py` (optional relative dates)
* `uw-genie-agent/underwriting_genie.geniespace.json` (or its R1-04 template): example SQL and instructions
* `docs/demo-assets/skills/uw-morning-brief/SKILL.md`, `lg-intake-checklist/SKILL.md`
* `docs/design/L300-03_metric_views_and_genie_agent_config.md` (example SQL 5, §5), `L200-06_scheduled_morning_brief.md`, `L200-07_demo_script_and_acceptance.md`

## Acceptance criteria

* The same ★7 question gives the same count on any run date, equal to the value recorded for the pinned as-of date.
* No query, example SQL or skill step uses `current_date()` for a business window (grep).
* A renewal dated before the as-of date never appears in a "next N days" answer.
* Changing `demo_as_of_date` per target (and re-running setup) moves the windows without code changes.
