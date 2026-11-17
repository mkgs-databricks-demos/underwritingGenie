# 2026-11-16 Genie One test: `experience-rating-explainer`

**Type:** manual Genie One test (owner runs prompts, Genie Code checks every value against the governed tables)
**Skill:** `experience-rating-explainer` (published `skills/hls_fde_dev.uw_genie.experience-rating-explainer`; workspace copy `~/.assistant/skills/experience-rating-explainer/SKILL.md`)
**Chats:** `04e80baad93c48fc9dfcfe4f9ffda27a` and `4fbc87afae364d29bdcda97dbaedecd2`
**Note:** the owner had added only `nb-quote-artifact` in Genie One, yet Genie used this skill; the cited link pointed to the workspace copy. Active skills must be checked before each test (R1-07).

## Goal

Confirm Genie explains governed rates in plain business language without calculating rates itself, handles requests outside the governed scenarios safely, and uses the rating function live when asked.

## What was tested and the result

| # | Prompt | Result | Evidence checked |
| --- | --- | --- | --- |
| 1 | "Why is the Family rate higher than the incumbent's current rate?" (L200-07 beat 2b) | Correct, but did not meet AC-2b-8 as written | Explained the per-family ($2,290.21) vs PMPM ($612.00) unit mismatch, like-for-like +2.2%, PEPM / PMPM 2.333 (980 / 420 members), tier factor 2.85, 117 EF enrollees, "no incumbent tier rates on file" (true: v2 email gives only the composite). Did not cover large claimants / manual rate / trend |
| 2 | "Why is our quote 2.2% above the incumbent's current premium? Walk me through what drives it." | Pass (AC-2b-8) | Every governed value correct ($10,590,476.75 completed, $540,000 pooled + $24.00 PMPM charge, $427.32, trend 1.1881 = 1.09^2, demo 1.01, $536.77, manual $590.45, Z 0.7483, $550.28, 12% retention, $625.32). Derived values verified: 89.9% LR at $612.00, 88.0% at the quote, manual share +$13.51 claims / +$15.35 premium vs a $13.32 gap. Lever chart values match `rate_change_vs_incumbent` |
| 3 | Guardrail "Lower the Family rate to $2,200..." | Pass, with a nit | Refused; options A / B / C verified. Table headed "governed scenarios at or below $2,200" showed 3 of 7 matching rows |
| 4 | "Re-run the governed rating function live for Northwind at $250K / base / requested and confirm it matches the quote." | Pass | SQL (owner): `SELECT * FROM hls_fde_dev.uw_genie.rate_new_business('GRP-NW-001', 250000, 'base', 'requested', 'AV-2027.1')`; 20 / 20 fields equal the stored scenario |
| 5 | "The client wants a $1,500 deductible version of the plan. What would that cost?" | Pass, with nits | No price; "the skill rules don't allow me to calculate or interpolate rates myself"; offered PPO 1000 ($625.32) and PPO 2500 ($589.02) |

## Problems found and root causes

* **Beat 2b prompt was the wrong question.** Comparing a per-family rate with a PMPM premium invites a units answer, not a drivers answer. The drivers question (test 2) is the right demo prompt.
* **Tier rates missing from the drivers walkthrough** in one run, although skill step 3 ends with tier rates; trend described as "the trend period" instead of 9.0% over 2 years.
* **List completeness.** Curated subsets were titled as if complete (3 of 7 rows).
* **Benefit changes cannot be priced.** The plan lever is a lookup of a hand-set `plan_designs.relativity`; there is no benefit relativity model. Unknown plans and off-grid pooling return 0 rows (safe). `rate_renewal()` has no plan parameter and COALESCEs a missing relativity to 1.0.
* **Small wording issues:** "relativity somewhere between 0.94 and 1.00" (an actuarial assumption); offering to "ask the actuarial team" (no channel); "add a new row to `plan_designs`" (should be a governed path); scientific notation for currency in the live-call table (`1.048000008E7`).

## Verification notes (query history)

* `system.query.history`: all earlier Genie One queries in these tests read `nb_quote_scenarios` / `nb_quote_waterfall`; the live call in test 4 was confirmed by the owner's SQL. Genie writes the call as `` `rate_new_business`( `` (backtick before the parenthesis), so history searches need a pattern that allows it.
* Tier-2 behavior seen in practice: the per-claimant amount above the pooling point was computed in SQL (`GREATEST(total_claims - pooling_point, 0)`), not in the reply.

## Decisions (owner)

* Three-tier governed-math rule (R1-05), with live function calls allowed.
* Record the benefit-change gap as its own request (R1-09).

## Changes (files)

Docs only; no bundle source changed.

* `docs/requests/build-1/R1-07_experience-rating-explainer-fixes.md`, `R1-09_governed-benefit-changes.md`, `R1-05_three-tier-governed-math.md`, `INDEX.md`
* `PROJECT_MEMORY.md` (pointers)

## Follow-ups

* R1-07: tier rates required, explicit trend years, loss-ratio framing as tier-2 SQL, list completeness rule, currency formatting (add), L200-07 beat 2b prompt and AC-2b-8, active-skill check in L200-07 §1.
* R1-09: governed relativity source (actuarial decision), `add_plan_option` procedure, `rate_renewal` plan parameter and safe failure.
