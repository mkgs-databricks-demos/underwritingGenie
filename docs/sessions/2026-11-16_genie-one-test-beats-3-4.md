# 2026-11-16 Genie One test: beats 3 (Lakeview renewal) and 4 (decisions to dollars)

**Type:** manual Genie One test (owner runs prompts, Genie Code checks every value against the governed tables)
**Skills:** `experience-rating-explainer` (beat 3); Underwriting Genie agent and glossary pages (beat 4)
**Chats:** beat 3 `942324e816bd45aa92ea0e10d54c0cba`; beat 4 `de1a09587c2a47db843d18ae3735e275` (no `@` agent mention; Genie found the agent)

## Goal

Run the last two untested demo beats from L200-07 (beat 3 optional renewal; beat 4 CFO view) and turn any findings into build 1 requests.

## Results

| Beat / criterion | Result | Notes |
| --- | --- | --- |
| 3 / AC-3-1 renewal build-up from the governed scenarios | Pass | Every value matches `renewal_scenarios` (GRP-LV-002); stored pipeline action agrees (+9.4%) |
| 3 / AC-3-2 $150K what-if | Pass | +11.6% with the correct reason (charge +$14 > experience -$2.61; Z already 1.0) |
| 3 / AC-3-3 AE rationale <= 120 words | Pass | 109 words; plan Choice PPO 1500 from `plan_designs` |
| 4 / AC-4-1 uses `mv_renewal_book` | Probably | Used the curated example query; result has `group_count`, which the metric view does not define (check "Show generated code") |
| 4 / AC-4-2 loss-ratio definition | Not met as written | Used the glossary page wording, not "completed incurred, pooled" |
| 4 / AC-4-3 premium at risk with and without the cap | Pass | Benchmark ★8 exactly |
| 4 / AC-4-4 chart | Not produced | Should |

## Problems and root causes

* **Wrong cause in the $500K what-if** ("only $45K removed"): the skill does not require naming the component that moves.
* **Reply-text arithmetic** in every answer ($23.01M, +$1.97M, +$475K vs actual $473K; 0.4 vs 0.45 points): the three-tier rule (R1-05) is not yet in the skills, and the governed rows have no annual-premium column.
* **Loss-ratio definition mismatch**: the Genie space instruction, the glossary page and AC-4-2 use three wordings; Genie One follows the page.
* **Number formatting**: raw result tables in scientific notation; no formatting rule in the skills.
* **Rationale wording**: trend and retention described loosely; strongest drivers omitted; no rationale template.

## Observations

* Genie One used the UC glossary pages created earlier that day (Projected Loss Ratio, Premium at Risk), and the corrected Projected Loss Ratio page no longer credits renewals to `rate_renewal()`.
* Without an `@` mention the agent was still found when the prompt did not name it; the earlier failure happened when the prompt named "the Underwriting Genie agent" (R1-04).
* Lakeview is fully credible, so a lower pooling point raises its rate, the opposite of Northwind. Useful talk track; easy to get wrong.

## Decisions

* Record beat 3-4 findings as **R1-13**; record beat 1-2 items not yet covered as **R1-14** (after checking R1-04..R1-13).

## Changes (files)

Docs only.

* `docs/requests/build-1/R1-13_renewal-explainer-and-decisions-to-dollars.md` (new)
* `docs/requests/build-1/R1-14_demo-readiness-carryovers.md` (new)
* `docs/requests/build-1/INDEX.md`, `PROJECT_MEMORY.md` (pointers)
* `docs/sessions/2026-11-16_genie-one-test-beats-3-4.md`, `docs/sessions/INDEX.md`

## Follow-ups

* Confirm AC-4-1 from "Show generated code" in the beat 4 chat.
* Still untested from build 0: Genie Agent benchmarks ★1-★15, AC-0-1 session instruction, AC-2b-10 timing (R1-14), Gmail draft-capable connector (R1-08), Reset Demo re-run.
