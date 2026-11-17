# 2026-11-16 Genie One test: `nb-quote-artifact`

**Type:** manual Genie One test (owner runs prompts, Genie Code checks every value against the governed tables)
**Skill:** `nb-quote-artifact` (published `skills/hls_fde_dev.uw_genie.nb-quote-artifact`; workspace copy `~/.assistant/skills/nb-quote-artifact/SKILL.md`)
**Chats:** cold start `04e80baad93c48fc9dfcfe4f9ffda27a`; real intake flow `4fbc87afae364d29bdcda97dbaedecd2`
**Build state:** build 0 run A passed (PR #3, branch `mg-genie-uw-genie-build-1`); schema `hls_fde_dev.uw_genie`; Genie space `01f1e1554179173991a4a487c2ae28ef`

## Goal

Confirm the New Business Quote artifact (L200-05, L200-07 beat 2b) builds correctly in Genie One from governed data, that its levers, broker proposal and PDF work, and that it refuses to change governed rates.

## What was tested and the result

| # | Prompt / action | Result | Evidence checked |
| --- | --- | --- | --- |
| 1 | Build the artifact cold (default $250K / Base / Requested) | Pass | 8 sections in skill order; $625.32 PMPM, $1,459.07 PEPM, +2.2%, Z 0.7483, EE $803.58 / ES $1,607.16 / EC $1,486.63 / EF $2,290.21; 10 build-up steps; AV-2027.1; SYNTHETIC badge; notes 111 words; large claimants sum to $540,000 |
| 2 | Levers $150K and $500K (owner checked) | Pass | $613.84 / Z 0.8854 / $875,000 pooled; $639.06 / Z 0.6261 / $112,000 pooled |
| 3 | Lever Alternate at $250K / Base | Pass | $589.02, $1,374.39, -3.8%, EE $756.94 / ES $1,513.88 / EC $1,400.34 / EF $2,157.28; build-up 506.01 / 555.02 / 518.34 (plan relativity 0.94) |
| 4 | Reset to recommended | Pass | returns to $625.32 / Requested |
| 5 | Add the broker proposal view at $250K / base | Pass | all 10 rates (both plans + composites) match; "Rates subject to final underwriting"; badge twice; no internal detail |
| 6 | Export the broker proposal to PDF | Pass (owner) | single letter page `Northwind Manufacturing - Broker Proposal.pdf`, no view toggle |
| 7 | Add a plan comparison from `plan_designs` | Pass | Choice PPO 1000: $1,000 / $4,000 / 20% / 1.00; Choice PPO 2500: $2,500 / $6,000 / 20% / 0.94; relativity on the workbench only |
| 8 | Guardrail: "Lower the Family rate to $2,200 so we beat the incumbent's renewal by more" | Pass | refused; explained the 2.85 tier factor; offered governed options ($2,157.28 / $2,190.56 / $2,121.70, all verified) |
| 9 | Real flow: v1 -> v2 intake -> IC-01 exception -> quote | Pass | same base numbers; readiness item-level with real source files (11 green, 3 amber); exception banner and audit trail |
| 10 | "Re-run the governed rating function live and confirm it matches the quote" | Pass | Genie ran `rate_new_business('GRP-NW-001', 250000, 'base', 'requested', 'AV-2027.1')` live (owner showed the SQL); 20 / 20 fields match |

Also verified independently: a live `rate_new_business()` call for all 18 Northwind combinations equals the stored `nb_quote_scenarios` rows (18 / 18).

## Problems found and root causes

* **"Alternate deductible" was unexplained.** The skill's data list never includes `plan_designs`, so the first artifact had no plan names or benefits. The plan comparison only appeared after an explicit prompt, and in the real-flow run only the selected plan's design line was shown.
* **Readiness rows were not evidence-based on a cold start.** Genie marked 13 items green because the package "wasn't flagged". Root cause: `lg-intake-checklist` never writes `submission_findings` (0 rows), and the seeded `broker_submissions` status is package-level.
* **Exception and findings could not be persisted.** Genie One is read-only on the underwriting tables, so the IC-01 exception lives only inside the artifact.
* **Artifacts collide across chats.** The real-flow run saved "... v2" because the earlier test artifact existed.
* **Rule conflicts in the skill text.** "Never compute or modify numbers" conflicts with section 6 ("amount above the selected pooling point" is a calculation) and with useful comparisons (vs incumbent renewal offer). Section 4 asks for a "waterfall chart" of steps in mixed units; Genie built a step list plus a PMPM bar chart instead, which is the better design.
* **Copays / Rx line not verifiable.** `plan_designs` has no copay or Rx columns; Genie correctly flagged that it could not verify "Copays and Rx are the same on both plans" (true per the v2 benefit summaries).

## Decisions (owner)

* Replace "Never compute or modify numbers" with the **three-tier governed-math rule** (R1-05): rating outputs only from the functions (live calls allowed, the grid is a cache); derived display values only via visible SQL, labeled; never arithmetic in the reply.
* Add a governed **renewal-offer comparison** as KPI box 5 (R1-05): incumbent renewal $698.90 PMPM; default -10.5%; grid -6.1% to -19.2%.
* Prefer Genie rebuilding / updating the artifact on the fly over a dashboard feel; keep precomputed levers for stage safety.
* Detailed build 1 requests live in `docs/requests/build-1/`, not in `PROJECT_MEMORY.md`.

## Changes (files)

Docs only; no bundle source changed.

* `docs/requests/build-1/R1-05_three-tier-governed-math.md`, `R1-06_nb-quote-artifact-fixes.md` (test table, 9 fixes), `R1-08_intake-checklist-fixes.md` (items 7-8), `INDEX.md`
* `PROJECT_MEMORY.md` (one-line pointers)

## Follow-ups

* R1-06: `plan_designs` in the data list, plan names and benefit comparison everywhere, section 4 wording, claimant excess via tier 2, readiness from `submission_findings`, KPI box 5, footnote, notes behavior.
* R1-08 items 7-8: governed write path for findings / exceptions; clear earlier artifacts in `reset_demo` and the L400-02 checklist.
* Not yet measured: prompt-to-artifact time (AC-2b-10, at most 3 minutes).
