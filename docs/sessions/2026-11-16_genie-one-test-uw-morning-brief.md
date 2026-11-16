# 2026-11-16 Genie One test: `uw-morning-brief`

**Type:** manual Genie One test (owner runs prompts, Genie Code computes expected values from the governed tables first and checks every value)
**Skill:** `uw-morning-brief` (published `skills/hls_fde_dev.uw_genie.uw-morning-brief`; workspace copy `~/.assistant/skills/uw-morning-brief/SKILL.md`)
**Chat:** `06ea9987eb034f349bfaf73782c5f71a` (new chat; skill added in Genie One). The scheduled task (C6) does not exist yet, so the brief was run on demand.

## Goal

Run L200-07 beat 1: produce the Morning Brief (5 sections + "Who owns what today") and answer the AC-1-4 follow-up, with values that match the governed book as of 2026-11-16.

## What was tested and the result

| # | Prompt | Result | Evidence checked |
| --- | --- | --- | --- |
| 1 | "What needs my attention today in underwriting? Give me the Large Group Underwriting Morning Brief." | Sections 1, 3, 4, 5 and owners: Pass. Section 2: **Fail** | 25 / 12 pre-built (90 days), 31 / 16 (120 days); 6 new-large-claimant groups with premiums ($21.04M Lakeview down to $0.74M) and owners; 13 past quote due, all due 2026-11-02, 14 days late (A 5 / B 5 / C 3, size bands correct); Rx 13.4% vs 11.0% (+2.4 pts). Section 2 said 1 blocked (Northwind); governed answer is 8 |
| 2 | "How many broker submissions are blocked in total, including any whose group isn't in the groups table?..." | Pass | All 8 submissions with IDs, brokers and dates; oldest `SUB-2026-0118` (Summit Ridge Benefits Group, 2026-10-08, 39 days); top missing item "24 months of claims experience" x3; Intake Desk 1 owns 6. Genie explained the dropped-join cause itself |
| 3 | "Which renewals in the next 90 days are most likely to need a rate action above 15%, and why?" (AC-1-4) | Pass on the criterion; drivers not governed | Right 3 groups and stored actions (Yarrow Software +16.3%, Cedar Ridge Contractors +16.2%, Birchwood Wholesale +15.4%) = benchmark ★7. Facts verified: owners, pre-built status, 86 / 654 employees, demographic factor 0.985, Birchwood claimants ($514,841 dialysis resolved, $307,595 trauma active), recent claims -4.05% |

## Problems found and root causes

* **Section 2 undercount.** Seven blocked submissions (`GRP-NB-104` to `GRP-NB-119`) have no `groups` row; the brief joined to `groups` for names and silently dropped them. Root cause: seed data plus a skill that does not say "count from `broker_submissions`, keep every row".
* **Renewal rate actions are not governed (design bug).** While preparing expected values, Genie Code called `rate_renewal()` live for all 59 renewals: it matches `renewal_pipeline.recommended_rate_action` for 1 of 59 (only the pinned Lakeview, 9.4%). Pipeline: 7 above 15%, mean 9.0%; function: 26 above 15%, mean 14.4% (the three groups above: +28.4% / +31.9% / +30.3%). Root cause: `uw_seed` projects claims with a simpler formula (about 10-13% lower than the governed method) instead of populating the pipeline from the function.
* **AC-1-4 explanation not from the method.** Genie never called `rate_renewal()`. It claimed observed book trend (Rx 13.4%, total 9.2%) is applied forward (rating uses the AV-2027.1 9.0% / 2-year assumption; `trend_monitor` is not a rating input), used paid-to-date / premium as "loss ratio" (the governed definition is completed incurred, pooled / premium), and stated "all three at or above 95%" when Birchwood is 94.5%.
* **Minor:** reply-text arithmetic (13 / 15 "still need build", 48% / 52%, "39 days"); longer than one screen; emoji header.

## Decisions (owner)

* Do **not** fix the data or skills outside the build. Record as R1-11 and land the calibration / data fix (part A) and skill fix (part B) together in build 1. Fixing only the skill would make Genie explain +28.4% next to a listed +16.3%.
* Interim demo guidance: show the brief and the "above 15%" list; avoid the renewal "why" follow-up; beat 3 (Lakeview) is safe.

## Changes (files)

Docs only; no bundle source or data changed.

* `docs/requests/build-1/R1-11_renewal-rates-and-morning-brief.md` (new), `docs/requests/build-1/INDEX.md`
* `PROJECT_MEMORY.md` (pointer)

## Follow-ups

* R1-11 part A: calibration target (owner / actuarial), populate `renewal_pipeline` from `rate_renewal()` in `setup_demo`, new test in `90_tests.sql`, re-record ★7 / ★8 and Morning Brief expected values, re-run beat 4.
* R1-11 part B: renewal "why" from the governed build-up and loss-ratio definition (also R1-07); Morning Brief left join and totals first; seed `groups` rows for prospects or document them.
* R1-10: pinned as-of date for the 90 / 120-day windows.
* Not yet tested: the scheduled task (C6) itself, beat 3 (Lakeview renewal), beat 4 (decisions to dollars).
