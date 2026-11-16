# R1-09 Governed path for benefit changes (new plan designs)

**Status:** Open (needs an actuarial decision on the relativity source)
**Origin:** Owner question, 2026-11-16, after the Genie One live-call test: "what would happen if the customer asks to change the deductible level or some other benefit?"
**Related:** R1-05 (tier 1 live calls, off-grid decision), R1-06 (plan comparison), R1-08 item 7 (governed write path)

## Problem

A broker or customer asking for a different benefit design (for example a $1,500 deductible, a $35 copay or 80% coinsurance) cannot be priced today. Nothing in the governed data turns a benefit design into a plan relativity, and there is no governed way to add a plan option.

## Current state (evidence, 2026-11-16)

* **The plan lever is a lookup, not a formula.** `rate_new_business()` takes `p_plan_option` and reads one `relativity` from `plan_designs` for the group. It is applied to both the projected experience and the manual rate: Choice PPO 2500 = 0.94 x Choice PPO 1000 on projected ($506.01 vs $536.77) and manual ($555.02 vs $590.45).
* **Northwind has two plan rows:** `requested` = Choice PPO 1000 ($1,000 / $4,000 / 20%, relativity 1.00) and `alternate` = Choice PPO 2500 ($2,500 / $6,000 / 20%, relativity 0.94).
* **There is no benefit pricing model behind the 0.94.** It is a hand-set value relative to each group's requested plan. The 59 in-force groups (`plan_option = current`) all have relativity 1.00, whatever their deductible ($500 to $2,500; Choice PPO 500 / 1000 / 1500 / 2500).
* **Unknown inputs fail safely.** A live call with `p_plan_option = 'buyup_1500'` returns 0 rows; so does an off-grid pooling point (`200000`). Nothing is invented.
* **The live path works in Genie One.** The owner's test ran `SELECT * FROM hls_fde_dev.uw_genie.rate_new_business('GRP-NW-001', 250000, 'base', 'requested', 'AV-2027.1')` live and matched the stored scenario on all 20 fields. A new plan row would therefore be priced live with no function change.
* **Renewals are worse.** `rate_renewal()` has no plan parameter at all: it always uses the group's `current` plan (`COALESCE(MAX(CASE WHEN plan_option = 'current' THEN relativity END), 1.0)`), so a benefit change at renewal cannot be priced, and a missing relativity silently becomes 1.0 instead of failing.

## Expected Genie behavior today (to test)

The `experience-rating-explainer` skill says: "If a requested lever value is not in the governed scenarios, say so and offer the nearest governed option." The correct answer to a new design is: not a governed plan; here are Choice PPO 1000 ($625.32) and Choice PPO 2500 ($589.02); an actuary needs to price the new design. The risk is Genie interpolating between 1.00 and 0.94, which is arithmetic in the reply (tier 3 of R1-05, never allowed).

Test prompt (not yet run):

> The client wants a $1,500 deductible version of the plan. What would that cost?

Pass: no price for the new design; the governed alternatives are offered; it says a priced plan design is needed. Fail: any estimated rate or relativity for the new design.

## Requested change

1. **A governed relativity source** (actuarial decision, owner or actuaries): benefit relativity factors by deductible, out-of-pocket max, coinsurance and copay / Rx tier in the assumption set (for example `benefit_relativities` keyed by `assumption_version`), or an approved actuarial value calculation exposed as a UC function (`plan_relativity(design)`). It returns the relativity for a design, relative to a stated base plan.
2. **A governed way to add a plan option**, for example a stored procedure `add_plan_option(group_id, plan_option, plan_name, design, approved_by)` that computes the relativity from item 1, writes a `plan_designs` row with approver and timestamp, and is granted EXECUTE to underwriters. Share the write-path design with R1-08 item 7 (intake findings and exceptions).
3. **Data model:** extend `plan_designs` with the full benefit design (family deductible / OOP, copays, Rx tiers; overlaps R1-06 item 2), plus `source` (seeded / added), `approved_by`, `approved_at`.
4. **Rating:** no change to `rate_new_business()` beyond reading the new row. `rate_renewal()` needs a `p_plan_option` parameter (default `current`) and should fail (no rows) instead of defaulting a missing relativity to 1.0; new plans are priced by live calls (R1-05 tier 1). Decide whether added plans are also materialized into `nb_quote_scenarios` (cache refresh) or stay live-only.
5. **Skills:** `experience-rating-explainer` and `nb-quote-artifact` handle a new plan as a third lever option once it exists; until then they refuse to estimate and offer the governed plans. `lg-intake-checklist` IC-05 then needs a benefit summary for the new plan too.

## Files affected

* `uw-genie-infra/src/sql/00_ddl.sql` (new table / columns), `10_rate_new_business.sql` (only if the relativity becomes a function), new procedure SQL
* `uw-genie-infra/src/notebooks/generate_synthetic_book.py` (seed relativities)
* `docs/design/L300-01`, `L300-02`, `L200-02`
* `docs/demo-assets/skills/experience-rating-explainer/SKILL.md`, `nb-quote-artifact/SKILL.md`
* Genie space data sources and functions (add the new function / procedure)

## Acceptance criteria

* The test prompt above passes before any build 1 change (current behavior is safe).
* After the change: an underwriter adds a $1,500 deductible plan through the governed path; `plan_designs` has the row with approver and timestamp; a live `rate_new_business(..., '<new plan>', ...)` returns rates; the artifact shows it as a third plan; golden tests still pass for the original 18 scenarios.
* No Genie answer ever states a rate or relativity for a plan that is not in `plan_designs`.

## Open decision

Who approves benefit relativities and new plan options, and which factor source is authoritative (actuarial owner). Same decision family as the off-grid pooling question in R1-05.
