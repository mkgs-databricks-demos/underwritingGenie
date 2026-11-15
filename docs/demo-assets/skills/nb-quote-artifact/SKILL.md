---
name: nb-quote-artifact
description: Use when asked to build, create or update an interactive New Business Quote (or quote artifact, quote workbench, broker proposal) for a large group. Builds a Genie Artifact from governed scenario data.
---
# Interactive New Business Quote Artifact

## Data (snapshot all of it into the artifact)
- `nb_quote_scenarios` (all 18 rows for the group)
- `nb_quote_waterfall` (all rows for the group)
- `large_claimants` (package_version v2) and `groups` header fields
- Intake findings from this chat (or `broker_submissions` status)

## Layout — exactly these 8 sections, in order
1. Quote header: group, effective date, enrolled employees / members, broker, status "Ready for underwriter review", and a visible badge "SYNTHETIC DEMO DATA".
2. Readiness check: checklist items with green/amber status and source file.
3. Recommended rates: tier table EE / EE+Spouse / EE+Child(ren) / Family, composite PEPM, premium PMPM, change vs incumbent current, and the incumbent renewal offer for context.
4. How we got here: waterfall chart of the 10 steps for the selected scenario.
5. Levers: a scenario selector for pooling point ($150K / $250K / $500K), trend (Low / Base / High) and plan (Requested / Alternate deductible) that switches sections 3, 4 and 6 between precomputed rows. If selector controls are not available, build a comparison panel: 6 cards (3 pooling points × 2 plans at Base trend) with premium PMPM, credibility, EE and Family rates, and a note that trend scenarios are available on request.
6. Large claimants: claimant, condition category, status, total, amount above the selected pooling point.
7. Assumptions & audit: assumption version, method version, source tables, documents used, generated_at, and the sentence "Rates produced by the governed rating method; AI explains only."
8. Underwriter notes: plain-English rationale for the account executive (≤ 120 words) and a decision line "Underwriter decision: ____ (Approve / Adjust / Decline)".

## Rules
- Default selected scenario: $250K / Base / Requested.
- Never compute or modify numbers; display governed values only (2-decimal currency).
- Title: "<Group name> — New Business Quote".
- Style: clean, executive, large fonts, Databricks-neutral colors; no carrier or vendor names.
- On "broker proposal view": add one page with tier rates for Requested and Alternate plans at the underwriter-selected scenario, effective date, "Rates subject to final underwriting" note, synthetic badge; suitable for PDF export.
