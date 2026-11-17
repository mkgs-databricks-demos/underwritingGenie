# R1-15 Genie Agent benchmarks: load them into the space, and show group names

**Status:** Open
**Origin:** Genie Code run of the 15 L300-03 §5 benchmarks against the deployed dev agent, 2026-11-16 (Genie Conversation API, one new conversation per question; runner: `uw-genie-agent/tests/run_genie_benchmarks.ipynb`)
**Related:** R1-04 (Genie space template), R1-10 (as-of date for benchmark 7), R1-11 (renewal values for benchmarks 7-8), R1-14 item 1 (names in the Morning Brief)

## Test result

The agent alone (no skills) answered **15 of 15 correctly on values**, each from a governed table or metric view with the right filters and default scenario (about 18 seconds per question).

| # | Expected | Agent | Source used |
| --- | --- | --- | --- |
| ★1 | $2,290.21 | $2,290.21 | `nb_quote_scenarios` |
| ★2 | 0.885 / 0.748 / 0.626 | same | `nb_quote_scenarios` |
| ★3 | +2.2% | +2.2% | `nb_quote_scenarios` |
| ★4 | $589.02 | $589.02 | `nb_quote_scenarios` |
| ★5 | $540,000 | $540,000 | `nb_quote_scenarios` |
| ★6 | Blocked | BLOCKED (24 months of claims experience) | `broker_submissions` |
| ★7 | 3 (as of 2026-11-16) | 3 (+16.2%, +16.3%, +15.4%), **shown as group IDs** | `renewal_pipeline` |
| ★8 | $25,303,698.74 vs $23,031,131.29 | $25.30M vs $23.03M | `MEASURE()` on `mv_renewal_book` |
| 9 | $110,477 | $110,476.67 | `nb_quote_scenarios` |
| 10 | 23,520 | 23,520 | `groups` |
| 11 | $590.45 | $590.45 | `nb_quote_scenarios` |
| 12 | $1,459.07 | $1,459.07 | `nb_quote_scenarios` |
| 13 | from book | Harbor Benefits Partners (3) | `broker_submissions` |
| 14 | 88% | 88% | `retention_targets` |
| 15 | $500K / high / requested, $656.55 | same | `nb_quote_scenarios` |

Conclusion: the issues seen in Genie One beats 1-4 (undercount, wrong causes, reply arithmetic) come from the skills and Genie One orchestration, not from the agent's data, instructions or example SQL.

## Problems found

1. **Group IDs instead of names (benchmark 7).** The agent queried `renewal_pipeline` without joining `groups`, so it answered `GRP-BK-035` instead of Cedar Ridge Contractors. Same root cause as the Morning Brief routine quirk (R1-14 item 1).
2. **No benchmarks in the Genie space.** `uw-genie-agent/underwriting_genie.geniespace.json` has sample questions and example SQL but no benchmarks, so the space's Benchmarks tab is empty and nobody can re-run these checks from the UI after a deploy.
3. **Odd follow-up (benchmark 7).** After answering, the agent asked "Would you prefer to see renewals from the last 90 days or a different 90-day period instead?" It did add a lower bound (`renewal_date >= current_date()`), which example SQL 5 lacks (R1-10).
4. **Expected values in L300-03 §5 use mixed precision** (for example benchmark 9 is $110,477 while the governed value is $110,476.67; benchmarks 2 and 8 round). Fine for people; benchmark SQL answers need exact values.

## Requested change

1. **Agent instruction:** "Whenever a result lists groups, show `groups.group_name` (left join on `group_id`, so prospects without a `groups` row are kept and shown by ID)." Add example SQL for benchmark 7 that joins names and uses the pinned as-of date (R1-10) with a lower bound.
2. **Load the 15 benchmarks into the space definition** (the R1-04 template), each with its question and an exact SQL answer against the governed objects; benchmark 7 uses the as-of date. Re-run them from the Benchmarks tab (Chat mode) after each deploy, and record accuracy in the session log.
3. **Keep the API runner** `uw-genie-agent/tests/run_genie_benchmarks.ipynb` (a notebook in the agent bundle, deployed with it) as the scripted check (it also reports the names check); optionally add it as a post-deploy task in `uw-genie-agent` that fails the deploy job when a values check fails.
4. **Make L300-03 §5 the single source** for questions and expected values, with exact values; have the runner and the space benchmarks read from it (or from one shared fixture file).
5. Remove the clarifying follow-up behaviour for fully specified questions (instruction: "Do not ask a follow-up question when the question is fully specified").

## Files affected

* `uw-genie-agent/underwriting_genie.geniespace.json` (or its R1-04 template): instructions, example SQL, benchmarks
* `uw-genie-agent/tests/run_genie_benchmarks.ipynb` (new, this request; a post-deploy task would reference it as `tests/run_genie_benchmarks.ipynb`)
* `docs/design/L300-03_metric_views_and_genie_agent_config.md` §5 (exact values)
* Optional: `uw-genie-agent/resources/*.job.yml` (post-deploy benchmark task)

## Acceptance criteria

* The deployed space's Benchmarks tab lists the 15 benchmarks with SQL answers, and a Chat-mode run scores 15/15.
* The runner reports `values` 15/15 and `names` 3/3 on benchmark 7.
* No group-listing answer shows a bare group ID when a name exists.

## Dependencies

* Re-record benchmarks 7 and 8 after R1-10 and R1-11.
