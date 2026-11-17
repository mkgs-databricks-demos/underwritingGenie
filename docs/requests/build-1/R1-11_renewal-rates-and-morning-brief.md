# R1-11 Governed renewal rate actions and Morning Brief fixes

**Status:** Open (part A is a design bug; needs a calibration decision)
**Origin:** Owner's Genie One test of `uw-morning-brief`, 2026-11-16 (chat `06ea9987eb034f349bfaf73782c5f71a`), and Genie Code's check of the renewal data behind it
**Related:** R1-05 (three-tier rule), R1-07 (explainer), R1-09 (`rate_renewal` plan parameter), R1-10 (as-of date)
**Owner decision (2026-11-16):** do not fix outside the build; land parts A and B together in build 1.

## Test results

| Test | Result | Evidence |
| --- | --- | --- |
| Morning Brief, sections 1, 3, 4, 5 and "Who owns what" | Pass | 25 renewals in 90 days (12 pre-built), 31 in 120 (16); 6 new-large-claimant groups with premiums and owners; 13 past quote due (all due 2026-11-02, 14 days late; A 5 / B 5 / C 3); Rx trend 13.4% vs 11.0% (+2.4 pts) |
| Morning Brief, section 2 (blocked submissions) | **Fail** | Reported 1 (Northwind); governed answer is 8. AC-1-2 still met (Northwind shown as Blocked) |
| Probe: "How many blocked in total, including groups not in the groups table?" | Pass | All 8 with correct IDs, brokers, dates; oldest `SUB-2026-0118` (Summit Ridge Benefits Group, 2026-10-08); top missing item "24 months of claims experience" x3; Intake Desk 1 owns 6. Genie explained the cause itself |
| AC-1-4: "Which renewals in the next 90 days are most likely to need a rate action above 15%, and why?" | Pass on the criterion; drivers not governed | Right 3 groups and stored actions (Yarrow Software +16.3%, Cedar Ridge Contractors +16.2%, Birchwood Wholesale +15.4%); every cited fact verified; but see part B errors |

## Part A: stored renewal rate actions are not governed outputs (design bug)

### Evidence

A live `rate_renewal(group_id, 250000, 'base', 'AV-2027.1')` call for all 59 renewals matches `renewal_pipeline.recommended_rate_action` for **1 of 59** (Lakeview Logistics `GRP-LV-002`, 9.4%, the hand-pinned golden group).

| | `renewal_pipeline` (stored, from `uw_seed`) | Live `rate_renewal()` |
| --- | --- | --- |
| Renewals above 15% | 7 | 26 |
| Renewals above 12% (the ★8 cap) | 14 (9 of them in 2027-Q1) | 31 |
| Mean rate action | 9.0% | 14.4% |
| Range | -0.45% to +19.3% | -16.0% to +50.2% |

Same current premiums in both; the generator projects about 10-13% less claims than the governed method (AV-2027.1 trend 9.0% over 2 years = 1.1881, credibility blend with the manual rate, 12% retention):

| Group | Current PMPM | Pipeline projected claims | Function implied claims | Pipeline action | Function action |
| --- | --- | --- | --- | --- | --- |
| Yarrow Software | $499.13 | $5.09M | $5.64M | +16.3% | +28.4% |
| Cedar Ridge Contractors | $512.06 | $1.10M | $1.24M | +16.2% | +31.9% |
| Birchwood Wholesale | $487.85 | $8.41M | $9.32M | +15.4% | +30.3% |
| Lakeview Logistics (pinned) | $548.00 | $20.26M | $20.25M | +9.4% | +9.4% |

### Impact

`renewal_pipeline` feeds `renewal_book_scenarios`, `mv_renewal_book`, benchmarks ★7 and ★8 (L300-03 §5), the Morning Brief and beat 4. None of them is a governed-function output, which breaks "rates come only from the function" for renewals. Today the demo only avoids a visible contradiction because Genie did not call `rate_renewal()` when explaining.

### Requested change

1. **Calibration decision first (owner / actuarial).** Copying function outputs into the pipeline as-is gives an unrealistic book (26 of 59 above 15%, mean 14.4%). Decide the target distribution (for example mean about 9% with 5-8 renewals above 15%), then calibrate the generator inputs (`claims_monthly` levels and / or `current_annual_premium`) so the governed function produces it. Keep Lakeview pinned.
2. **Generate the pipeline from the function.** In `setup_demo` (after the rating function exists), populate `renewal_pipeline.recommended_rate_action` and `projected_annual_claims` from `rate_renewal()` at the default scenario, instead of the `uw_seed` formula. Add a test: stored action = live function for every group (tolerance 0.01 pts).
3. **Re-record** ★7 and ★8, the Morning Brief expected values and the renewal golden files; re-run beat 4.

## Part B: renewal "why" answers and Morning Brief skill fixes

### AC-1-4 explanation errors

* False summary: "All three have loss ratios at or above 95%"; Birchwood is 94.5%.
* Invented drivers: claimed the observed book Rx trend (13.4%) and "9.2% total" are applied forward. Rating uses the AV-2027.1 assumption (9.0% base over 2 years); `trend_monitor` is a monitoring signal, not a rating input.
* Wrong loss-ratio definition: used 24-month paid claims / (2 x current premium) (96.8% / 110.3% / 94.5%). The Genie space instruction defines loss ratio as completed incurred, pooled claims / premium.
* Never called `rate_renewal()` or `renewal_scenarios`; the "why" was reasoned from loss ratios and trend signals.

### Morning Brief section 2 undercount

Seven blocked submissions (`GRP-NB-104` to `GRP-NB-119`) have no row in `groups`. The brief joined to `groups` for names and silently dropped them (1 of 8 shown).

### Requested change

1. `experience-rating-explainer` (and R1-07): renewal "why" answers come from the `rate_renewal()` / `renewal_scenarios` build-up (experience, trend factor, plan / demographic, pooling, credibility blend with the manual rate, retention). Observed trend from `trend_monitor` may be mentioned only as a risk signal, labeled as not a rating input. Use the governed loss-ratio definition. Summary statements must be checked against the rows shown.
2. `uw-morning-brief`: count from `broker_submissions`; look up names with a left join and keep every row (show group ID / broker when no name exists). State totals before any name-based detail.
3. Seed data (generator): either add `groups` rows for the 7 `GRP-NB-1xx` prospects, or document that prospects without a group record are expected.
4. Minor: reply-text arithmetic ("still need build" 13 / 15, 48% / 52%, "39 days old") should be tier-2 SQL (R1-05); keep the brief to one screen.
5. **Land with part A.** Fixing only the skill would make Genie explain +28.4% next to a listed +16.3%.

## Interim demo guidance (until build 1)

Beat 1: show the brief and the "above 15%" list; avoid the renewal "why" follow-up. If asked, keep to facts (loss ratio, large claimants, pre-built status). Beat 3 (Lakeview) is safe: its stored and governed actions match.

## Files affected

* `uw-genie-infra/src/notebooks/uw_seed.py`, `generate_synthetic_book.py`; `setup_demo.job.yml` (populate from `rate_renewal()`); `uw-genie-infra/src/sql/90_tests.sql` (new test)
* `docs/demo-assets/skills/uw-morning-brief/SKILL.md`, `experience-rating-explainer/SKILL.md`
* `docs/design/L300-01`, `L300-02`, `L300-03` (§5 benchmarks), `L200-06`, `L200-07`

## Acceptance criteria

* For every renewal, stored action = live `rate_renewal()` at the default scenario (test in `90_tests.sql`).
* The book distribution matches the owner's calibration target; Lakeview unchanged at 9.4%.
* Morning Brief section 2 reports every blocked submission (8 today).
* A renewal "why" answer quotes the `rate_renewal()` build-up and matches the listed rate action.
