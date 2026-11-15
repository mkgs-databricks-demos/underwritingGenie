# L200-07 — Demo Script, Genie One Session Instructions and Acceptance Criteria (C7)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## Overview
Exact Genie One session setup, prompts, expected behavior and pass/fail criteria for each beat. "Must" criteria are demo-blocking; "Should" criteria are polish.

## 1. Genie One session setup (do 30 min before)
1. Workspace with **Artifacts** preview on; signed in as presenter; Gmail connector connected.
2. Skills active (Settings → Skills): `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief`. Turn off unrelated skills to stay well under the 50-skill limit and avoid misrouting.
3. Open **three tabs**: (a) the completed Morning Brief chat, (b) a **new, empty Genie One chat** titled "Underwriting Genie — live", (c) backup artifact "Northwind Manufacturing — New Business Quote".
4. Local folder with `northwind_v1/` and `northwind_v2/` files (downloaded from the Volume) ready to drag.
5. Run the reset job (L400-03) so no prior drafts/artifacts confuse Genie.
6. Font zoom 125%; notifications off.

### Session-level instruction (paste as first message in tab b, before the audience joins)
```
For this session you are my underwriting coworker for Lakeside Health Plan (synthetic demo data).
Use the Underwriting Genie agent for all data. Never calculate rates yourself:
rates, credibility, pooling and trend come only from nb_quote_scenarios / rate_new_business().
Keep answers short and business-focused, no SQL unless I ask. Draft emails only — never send.
Reply "Ready." and nothing else.
```
**AC-0-1 (Must):** Genie replies "Ready." (or equivalent single line).

## 2. Beat 1 — Morning brief (tab a)
**Show:** the completed scheduled run. **Follow-up prompt:**
> Which renewals in the next 90 days are most likely to need a rate action above 15%, and why?

| ID | Criterion | Level |
|---|---|---|
| AC-1-1 | Brief lists the 5 sections in L200-06 order | Must |
| AC-1-2 | Northwind appears as a new-business submission "Blocked — waiting on broker" | Must |
| AC-1-3 | Rx-trend flag present with a number vs assumption | Must |
| AC-1-4 | Follow-up returns ≤ 5 groups with drivers (large claimant, trend, plan change) from `renewal_pipeline` | Must |
| AC-1-5 | No dashboard links or SQL shown | Should |

## 3. Beat 2 — Ready to quote? (tab b)
**Action:** drag all 5 files from `northwind_v1/`. **Prompt:**
> A broker just sent this new business request for Northwind Manufacturing. Is it ready to quote? If not, tell me exactly what's missing and draft a reply to the broker.

| ID | Criterion | Level |
|---|---|---|
| AC-2-1 | Status = **Blocked** | Must |
| AC-2-2 | Identifies all 5 seeded gaps: 15 of 24 months; paid-only/no lag report; 22 census rows missing DOB or tier; 3 claimants missing status; requested-plan benefit summary missing | Must (≥4 of 5 = pass with note) |
| AC-2-3 | Each gap cites the file it came from | Should |
| AC-2-4 | Gmail **draft** created (not sent), addressed to the broker contact in the email, polite, lists the items | Must |
| AC-2-5 | No rate is quoted | Must |

Talk track while it runs: "This kind of gap usually shows up days later…"

## 4. Beat 2b — Interactive New Business Quote (tab b, same thread)
**Action:** drag all files from `northwind_v2/`. **Prompt:**
> The broker sent the missing items. Rate Northwind Manufacturing for a 1/1/2027 effective date and build me an interactive New Business Quote I can review and share with the account executive.

**Then (live interactions):**
1. In the artifact, select pooling point **$150K** → narrate rates down / pooling charge up / credibility up.
2. Select plan **alternate** → narrate impact.
3. Click a tier rate → **Ask Genie**: "Why is the Family rate higher than the incumbent's current rate?"
4. Back in chat: > Add a one-page broker proposal view to the artifact using the $250K pooling point and base trend, then I'll export it to PDF.

| ID | Criterion | Level |
|---|---|---|
| AC-2b-1 | Readiness re-check = Ready (warnings allowed) before rating | Must |
| AC-2b-2 | Genie states rates come from the governed function/scenarios (no freehand math) | Must |
| AC-2b-3 | Artifact created with the 8 sections of L200-05 | Must (≥7 of 8) |
| AC-2b-4 | Base scenario numbers match golden file: premium $625.32 PMPM; EE $803.58; ES $1,607.16; EC $1,486.63; EF $2,290.21; Z 0.748; +2.2% vs current | Must |
| AC-2b-5 | Scenario selector **or** fallback comparison panel present; $150K/requested/base shows premium $613.84 and Z 0.885 | Must |
| AC-2b-6 | Waterfall shows 10 steps with assumption version AV-2027.1 | Must |
| AC-2b-7 | SYNTHETIC DEMO DATA badge visible | Must |
| AC-2b-8 | Ask Genie answer references large claimants, manual rate and trend | Should |
| AC-2b-9 | Broker proposal view added; PDF export succeeds | Should |
| AC-2b-10 | Total time from prompt to artifact ≤ 3 min; else switch to backup tab | Must (operational) |

## 5. Beat 3 — Renewal explained (optional)
> Build the renewal for Lakeview Logistics (1/1/2027) and recommend a rate action. Then: what happens if we pool at $150K instead of $250K?

AC-3-1 waterfall from `rate_renewal`; AC-3-2 what-if answered from precomputed levers; AC-3-3 AE rationale ≤ 120 words.

## 6. Beat 4 — Decisions to dollars
> Across all large group renewals effective Q1 2027, what's the projected loss ratio vs target, and how much premium is at risk if we cap rate actions at 12%?

| ID | Criterion | Level |
|---|---|---|
| AC-4-1 | Uses `mv_renewal_book` (verified/metric view), not ad-hoc SQL over raw tables | Must |
| AC-4-2 | Defines loss ratio as completed incurred, pooled, vs 88% target | Must |
| AC-4-3 | Premium at risk shown with and without the 12% cap, persistency-weighted | Must |
| AC-4-4 | Chart produced | Should |

## 7. Failure handling
| Symptom | Action |
|---|---|
| Genie computes a rate itself | Say "Use the governed scenarios only" (skill should prevent) |
| Artifact > 3 min / error | Narrate waterfall from chat; switch to backup artifact tab |
| Gmail connector error | Show draft text in chat; "in production this lands in your drafts" |
| Wrong gap count | Accept ≥4/5; mention the remaining item yourself |
