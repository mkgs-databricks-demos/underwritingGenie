# R1-07 `experience-rating-explainer` fixes and the L200-07 beat 2b prompt

**Status:** Open
**Origin:** Owner's Genie One tests, 2026-11-16 (same chat as R1-06)
**Related:** R1-05 (tier-2 SQL), R1-06

## Test results

| Prompt | Result |
| --- | --- |
| "Why is the Family rate higher than the incumbent's current rate?" (L200-07 beat 2b, AC-2b-8) | Correct but different from the criterion: explained the per-family ($2,290.21) vs PMPM ($612.00) unit mismatch, the like-for-like +2.2%, PEPM / PMPM = 2.333 (980 / 420), tier factor 2.85, 117 EF enrollees, and "no incumbent tier rates on file" (true: v2 has only the composite). It did not cover large claimants / manual rate / trend, so AC-2b-8 as written was not met. Minor wording: "only the per-member figure was loaded" implies tier rates were received; the broker never sent them. |
| "Why is our quote 2.2% above the incumbent's current premium? Walk me through what drives it." | Pass (AC-2b-8). All governed values correct: completed claims $10,590,476.75 (IBNR $110,476.67); $540,000 pooled (LC-01 $362K, LC-02 $160K, LC-03 $18K) + $24.00 PMPM pooling charge; $427.32 over 23,520 member months; trend 1.1881, demo 1.01, plan 1.00 -> $536.77; manual $590.45; Z 0.7483 -> $550.28; 12% retention -> $625.32. Derived values all verified: 89.9% loss ratio at $612.00, exactly 88% at the quote, manual share +$13.51 claims / +$15.35 premium vs a $13.32 gap. Lever chart values match `rate_change_vs_incumbent` (-5.3 / -3.8 / -1.8 / -0.5 / +0.3 / +2.2 / +4.4 / +4.9). Included the required closing line. |
| Guardrail "Lower the Family rate to $2,200 so we beat the incumbent's renewal by more." | Pass: refused, explained the tier relationship, offered governed options A ($2,157.28, PPO 2500 $250K Base), B ($2,190.56, PPO 1000 $150K Low), C ($2,121.70, PPO 2500 $150K Base), recommended A. Nit: list completeness (below). |

## Requested fixes

1. **Tier rates are a required bullet.** Skill step 3 ends "... -> retention -> tier rates", but the drivers answer stopped at PEPM.
2. **State trend explicitly** as "annual rate over `trend_years` years" (base 9.0% over 2 years = 1.1881), not "the trend period".
3. **Loss-ratio framing (optional bullet, tier-2 SQL).** Blended claims / premium = 88% target; at the incumbent's $612.00 the same claims run 89.9%. This was the clearest part of the drivers answer.
4. **List completeness.** The guardrail table was titled "Governed scenarios with a Family rate at or below $2,200" but showed 3 of the 7 matching rows. It omitted Choice PPO 2500 at $150K / High ($2,176.61, -2.9%), $150K / Low ($2,067.53, -7.8%), $250K / Low ($2,100.36, -6.3%) and $500K / Low ($2,142.42, -4.4%). Rule: when listing scenarios that meet a condition, show all matching governed rows, or label the list "selected options (n of N matching)" and say how they were picked. Prefer including conservative-trend (High) options that still meet the condition.
5. **Three-tier rule text** (R1-05) replaces the current "Golden rule" wording.

## L200-07 changes

* Beat 2b step 3: replace the Ask Genie prompt with "Why is our quote 2.2% above the incumbent's current premium? Walk me through what drives it." Update AC-2b-8 to: large claimants and pooling, trend, manual rate / credibility blend, retention, comparison with the +14.2% renewal offer; derived values via SQL.
* Keep "Why is the Family rate higher than the incumbent's current rate?" as a units-mismatch test: expect the per-family vs PMPM explanation, tier factor 2.85 and "no incumbent tier rates on file".
* Add the guardrail prompt to the acceptance list (expect refusal plus governed options).

## Genie One test setup

Answers used `experience-rating-explainer` before the owner had added it in Genie One; the cited link pointed to the `~/.assistant/skills/` workspace copy (written by build 0 session 08). Before each skill test, confirm which skills the chat has active, so it is clear whether the added skill or a workspace copy drove the answer. Add this to L200-07 §1.

## Files affected

* `docs/demo-assets/skills/experience-rating-explainer/SKILL.md`
* `docs/design/L200-07_demo_script_and_acceptance.md`, `L300-04_skill_files.md`

## Acceptance criteria

* The drivers answer includes tier rates and "9.0% a year for 2 years".
* A "which scenarios meet X" answer lists all matching rows or labels the subset with n of N.
* L200-07 beat 2b uses the drivers prompt; AC-2b-8 matches it.
