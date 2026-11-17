# R1-13 Renewal explainer (beat 3) and decisions to dollars (beat 4) fixes

**Status:** Open
**Origin:** Owner's Genie One tests of L200-07 beats 3 and 4, 2026-11-16 (chats `942324e816bd45aa92ea0e10d54c0cba` and `de1a09587c2a47db843d18ae3735e275`)
**Related:** R1-05 (three-tier rule), R1-07 (explainer), R1-11 (renewal rate actions), R1-03 (metric view fixtures)

## Test results

| Test | Result | Evidence |
| --- | --- | --- |
| Beat 3: "Build the renewal for Lakeview Logistics (1/1/2027) and recommend a rate action." (AC-3-1) | Pass | Every value matches `renewal_scenarios` (GRP-LV-002): +9.4%, $599.33 vs $548.00, 88.0% projected loss ratio; paid $32,519,313.97 + IBNR $0.33M = $32.85M over 76,800 member months; $435K pooled (LC-01 cardiac $545K resolved, LC-02 oncology $390K active), $24 charge; experience $422.02, trend 1.1881, demographic 1.004, projected $527.41, Z 1.0, manual $524.95 unused; composite $1,379.74; tiers $755.22 / $1,510.44 / $1,397.16 / $2,152.37; all 9 what-if bars; persistency 90% / 82%; broker Summit Ridge Benefits Group (Morgan Reyes) |
| Beat 3: "What happens if we pool at $150K instead of $250K?" (AC-3-2) | Pass | +11.6%, $611.70; $635K pooled; charge $38; experience $419.41; Z 1.0 (full credibility 30,000 member months); correct reason (charge +$14 outweighs experience -$2.61) |
| Beat 3: "Write the rationale for the account executive in 120 words or less." (AC-3-3) | Pass | 109 words; plan Choice PPO 1500 (from `plan_designs`) |
| Beat 4: "Across all large group renewals effective Q1 2027, what's the projected loss ratio vs target, and how much premium is at risk if we cap rate actions at 12%?" | Values pass; AC-4-2 and AC-4-4 not met | Benchmark ★8 exactly: 31 groups, $147,589,959.48; 88.2% vs 88.7% (target 88%); premium at risk $25,303,698.74 vs $23,031,131.29 ($2.27M kept). Used the curated example query; cited the Projected Loss Ratio and Premium at Risk glossary pages; did not credit `rate_renewal()`. Found the agent without an `@` mention |

Note: the beat 4 values come from `renewal_pipeline`, which is not yet the governed function's output (R1-11). Re-record after R1-11.

## Problems found

### Beat 3 (renewal explainer)

1. **Wrong cause in a what-if.** "Moving to $500K lowers the base action to +7.9%, because only $45K would be removed." Removing less raises experience ($422.02 -> $427.10); the rate falls because the pooling charge drops ($24 -> $11). The later $150K answer got the cause right.
2. **Reply-text arithmetic on dollar impacts** in every answer: annual premium $23.01M, "+$1.97M", "about $0.6M", "+$475K" (actual $473K: $21,043,200 x 2.25 pts). Also compares one year of premium ($475K) with $200K pooled from 24 months of experience (unlike periods).
3. **Rationale wording.** "9% annual medical and pharmacy inflation" (the assumption is one 9.0% total trend over 2 years); "our standard 12% for administration" (retention also covers commission, risk margin, taxes and fees). It omits the two strongest drivers: the active oncology claimant and staying under 10% (persistency 90% vs 82%).

### Beat 4 (decisions to dollars)

4. **Loss-ratio definition mismatch (AC-4-2).** Genie used the glossary page wording "expected blended claims divided by quoted premium". The Genie space instruction (L300-03) and AC-4-2 say "completed incurred, pooled claims / premium". Genie One follows the glossary page, so the three sources must agree.
5. **No chart (AC-4-4, Should).**
6. **Count outside the metric view (AC-4-1 to confirm).** The result has `group_count`, but `mv_renewal_book` has no count measure, so the query probably counted outside the metric view or read `renewal_book_scenarios`. Confirm with "Show generated code" in the chat.
7. **Number formatting.** Raw result table in scientific notation (`1.4758995948000002E8`); rendered as "$147.58995948000002M". Same issue as the live-call table in the explainer test.
8. **Text arithmetic inconsistency.** "Rises about 0.4 points" while the table shows +0.2 and +0.7 vs target (actual change 0.45 points).
9. **Missing CFO line.** Both scenarios stay above the 85% large group MLR floor; not mentioned.

## Requested change

1. `experience-rating-explainer`: what-if answers must name the component that moves (experience, pooling charge, credibility) from the governed build-up, comparing the two scenarios' rows; no causal claim that the rows do not show.
2. Dollar impacts (annual premium, change in annual premium) come from SQL over the governed rows (R1-05 tier 2), or from new columns: add `renewal_annual_premium` (and for new business `annual_premium`) to `renewal_scenarios` / `nb_quote_scenarios` via the rating functions. Never compare figures over different periods.
3. Account executive rationale template in the skill: rate action and premium, the 1-2 main drivers from the build-up (for example an active large claimant), the persistency trade-off when near a band edge, and accurate trend / retention wording ("9.0% a year over 2 years"; "12% retention for administration, commission, risk margin, taxes and fees").
4. One loss-ratio definition: align the Genie space instruction (`underwriting_genie.geniespace.json` / L300-03), the Projected Loss Ratio and Target Loss Ratio glossary pages, `docs/semantics/03_financial_outcome_terms.md` and AC-4-2. Suggested: "Projected loss ratio = projected completed incurred, pooled claims (with pooling charge) / premium for the rating period; compare with the 88% target."
5. `mv_renewal_book`: add a **Renewal Count** measure (`COUNT(1)`) and a **Renewal Premium (Uncapped / 12% Cap)** measure pair, so beat 4 needs no SQL outside the metric view (do this in the R1-03 YAML fixtures).
6. Beat 4 answer pattern (skill or example SQL title): KPI table, a bar chart of premium at risk and projected loss ratio uncapped vs capped, the 88% target and 85% MLR floor, and percentages formatted to 1 decimal.
7. Number formatting rule for every skill: currency $ with 2 decimals for rates and $#,##0 (or $X.XM) for totals; never scientific notation; applies to tables Genie shows.

## Files affected

* `docs/demo-assets/skills/experience-rating-explainer/SKILL.md` (items 1-3, 6, 7)
* `uw-genie-agent/underwriting_genie.geniespace.json` (instructions, example SQL titles: items 4, 6)
* `uw-genie-infra/src/sql/20_metric_views.sql` or the R1-03 fixtures (item 5); optional new columns in `10_rate_new_business.sql` (item 2)
* `docs/semantics/03_financial_outcome_terms.md`, glossary pages Projected Loss Ratio / Target Loss Ratio (item 4)
* `docs/design/L200-07_demo_script_and_acceptance.md` (AC-4-2 wording), `L300-03` (example SQL 6)

## Acceptance criteria

* Beat 3 what-if answers cite the moving component correctly for $150K and $500K.
* No dollar impact in a reply that is not traceable to a governed row or visible SQL.
* The AE rationale names the active claimant and the persistency trade-off, in 120 words or fewer.
* Beat 4 uses only `MEASURE()` on `mv_renewal_book` (including the count), states the aligned loss-ratio definition, shows a chart, and mentions the 85% MLR floor; no scientific notation.

## Dependencies

* Re-record ★8 and the beat 4 values after R1-11 changes how `renewal_pipeline` is produced.
