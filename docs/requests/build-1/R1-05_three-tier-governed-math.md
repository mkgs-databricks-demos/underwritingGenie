# R1-05 Three-tier governed-math rule and governed renewal comparison

**Status:** Open (rule decided by the owner, 2026-11-16)
**Origin:** Owner question during the Genie One `nb-quote-artifact` test: should "Never compute or modify numbers" be revisited so Genie can recreate values on the fly and update the artifact, rather than the artifact feeling like a dashboard?
**Related:** R1-06, R1-07

## Problem

The skill rule "Never compute or modify numbers" (`nb-quote-artifact/SKILL.md`) mixes two concerns:

1. **Governance** (L100 principle 3, "Governed math, explained by AI"): rates come only from the UC function, so they are deterministic, golden-tested and traceable. This must stay strict.
2. **An artifact limitation** (L100 §6): "Artifact data: Precomputed snapshot (18 scenarios). Why: Artifacts have no live queries yet." The no-compute rule kept the artifact from drifting off the snapshot.

In practice the rule was already broken by small derived values the skill itself asks for (per-claimant amount above the pooling point), and it blocks useful comparisons such as "vs incumbent renewal offer".

## Decision: three tiers

1. **Rating outputs** (rates, credibility, pooling, trend, premium, retention) come only from `rate_new_business()` / `rate_renewal()`. Live calls are allowed: Genie may call the function for any combination the governed assumption tables support and rebuild or update the artifact from the result. The precomputed `nb_quote_scenarios` grid is a fast cache, not a limit.
2. **Derived display values** (differences, % vs incumbent renewal offer, per-claimant amount above the pooling point, step deltas, PMPM / PEPM / tier conversions) are allowed only when computed in SQL from governed values through the Underwriting Genie agent, so the query is visible and traceable. Never in the response text. Labeled "Derived from governed values (not a rating output)".
3. **Never:** change assumptions, override or adjust a governed rate, or do arithmetic in the response text.

### Pros and cons considered

| Approach | Pros | Cons |
| --- | --- | --- |
| Live governed function calls | Coworker feel; any supported combination, any group; same governed math | Slower (function call + artifact rebuild vs the 3-minute AC-2b-10); less deterministic on stage |
| Genie derived arithmetic | Fits the conversation (for example the renewal KPI) | Model arithmetic can be wrong and is hard to audit; weakens "AI explains only" |
| Precomputed grid only (build 0) | Deterministic, instant, golden-tested, stage-safe | Rigid; off-grid needs a rebuild; small derived values break the rule anyway |

### Demo stance

Keep the precomputed levers for speed and stage safety. Show one live off-grid governed request as the "coworker" moment and let Genie update the artifact.

## Governed renewal comparison (tier 1)

The most common broker question is "how do we compare with the incumbent's renewal?" The owner asked for a fifth KPI box. Make it a governed output instead of an artifact calculation:

* `rate_new_business()` returns `incumbent_renewal_pmpm` = `incumbent_premium_pmpm` x (1 + `incumbent_renewal_offer_pct`) and `rate_change_vs_renewal_offer` = `premium_pmpm` / `incumbent_renewal_pmpm` - 1.
* Materialized in `nb_quote_scenarios`; added to `docs/demo-assets/nb_quote_scenarios_expected.csv` and its tests.
* Shown as KPI box 5 "Change vs incumbent renewal offer" in artifact section 3 (skill + L200-05).

Reference values (computed 2026-11-16 from `groups` + `nb_quote_scenarios`; Northwind incumbent $612.00 x 1.142 = **$698.90 PMPM**):

| Scenario | Premium PMPM | vs renewal offer |
| --- | --- | --- |
| $250K / Base / Requested (default) | $625.32 | -10.5% |
| $150K / Base / Requested | $613.84 | -12.2% |
| $500K / Base / Requested | $639.06 | -8.6% |
| $250K / Base / Alternate | $589.02 | -15.7% |
| $500K / High / Requested (highest) | $656.55 | -6.1% |
| $150K / Low / Alternate (lowest) | $564.52 | -19.2% |

All 18 scenarios are below the renewal offer (-6.1% to -19.2%).

Interim (before the governed column exists): Genie may show the box only as a tier-2 value computed in SQL and labeled derived.

## Open actuarial decision

Should `rate_new_business()` accept inputs outside the governed assumption sets? Today `pooling_points` and `trend_assumptions` each hold 3 rows (AV-2027.1: trend low 7.5% / base 9.0% / high 10.5%, 2 trend years), so off-grid inputs return nothing. Keeping that is arguably a governance feature; changing it is an actuarial decision, not a technical one.

## Files affected

* `docs/demo-assets/skills/nb-quote-artifact/SKILL.md`, `experience-rating-explainer/SKILL.md` (rule text)
* `docs/design/L100_demo_overview.md` (principle 3, §6: "governed computation, cached or live"), `L200-05_nb_quote_artifact.md`, `L300-02_rating_function_spec.md`
* `uw-genie-infra/src/sql/10_rate_new_business.sql`, golden CSV and tests
* `docs/design/L200-07_demo_script_and_acceptance.md` (new acceptance check)

## Acceptance criteria

* Skill rule text states the three tiers verbatim.
* New Genie One check: a tier-2 value (for example the loss ratio at the incumbent's rate) is produced by a visible SQL query, not computed in the reply text.
* `nb_quote_scenarios` has the two renewal columns; golden CSV matches for all 18 rows; the artifact shows box 5 with -10.5% at the default scenario.
* An off-grid request (for example "$200K pooling") gets a clear governed answer: either a live function result (if allowed by the actuarial decision) or "not a governed option" plus the nearest governed choices.
