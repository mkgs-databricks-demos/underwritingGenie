# L300-04 — Genie One Skill Files (full text)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

Publish each folder to UC Skills at `${catalog}.${schema}` and keep a workspace copy under `/Workspace/Users/<you>/.assistant/skills/<name>/SKILL.md`.

## `lg-intake-checklist/SKILL.md`
```markdown
---
name: lg-intake-checklist
description: Use when a user uploads a large group broker submission (census, claims experience, large claimant report, benefit summary, RFP, broker email) or asks whether a group is "ready to quote". Checks completeness against the governed intake checklist and drafts a broker request.
---
# Large Group Intake Checklist

## When to use
- User uploads broker package files or asks "is this ready to quote?", "what's missing?".

## Steps
1. Identify the group (name, effective date, enrolled employees, broker, contact) from the email/RFP.
2. Read the governed checklist: `SELECT item_id, item_name, severity, rule_text, broker_ask_template FROM <catalog>.<schema>.intake_checklist` (via the Underwriting Genie agent).
3. For EACH item, inspect the uploaded files and decide PRESENT / MISSING / PARTIAL with evidence (file name + location, e.g. "census.csv rows 41, 77…").
   - Experience: count incurred months; require 24. Check basis is INCURRED or a lag report is present.
   - Census: every employee row needs birth_date, gender, tier, zip3. Report the count of failing rows.
   - Large claimants: every claimant needs status ACTIVE/ONGOING/RESOLVED.
   - Benefit summary: one per requested plan.
4. Status: BLOCKED if any BLOCKING item is MISSING/PARTIAL; READY_WITH_WARNINGS if only warnings; else READY.
5. Output (short): status line → table of findings (item, severity, evidence, broker ask) → one-sentence next step.
6. If asked to draft a reply: create a Gmail DRAFT (never send) to the broker contact; warm, concise, numbered list of asks using broker_ask_template; sign off as the underwriting team.

## Rules
- Do not quote or estimate any rate during intake.
- Do not invent missing data; say what is missing.
- Data is synthetic (Lakeside Health Plan).
```

## `experience-rating-explainer/SKILL.md`
```markdown
---
name: experience-rating-explainer
description: Use for any request to rate, quote, price, or renew a large group, explain a rate, or run a what-if on pooling point, trend or plan option. Enforces governed rating results and explains them in plain English.
---
# Experience Rating Explainer

## Golden rule
Never calculate rates, credibility, pooling, trend or tier rates yourself. Use ONLY:
- `nb_quote_scenarios` / `nb_quote_waterfall` / `rate_new_business()` for new business
- `renewal_scenarios` / `rate_renewal()` for renewals
via the Underwriting Genie agent. If a requested lever value is not in the governed scenarios, say so and offer the nearest governed option.

## Steps
1. Confirm intake is READY (use lg-intake-checklist if the package was just uploaded).
2. Retrieve the default scenario (pooling 250000, base trend, requested plan, AV-2027.1) and the 10-step waterfall.
3. Explain in ≤ 8 bullets, business language: completed claims & IBNR → pooling (which claimants, how much removed, pooling charge added) → trend → plan/demographic → manual rate → credibility blend (what Z means) → retention → tier rates; compare to incumbent current premium and incumbent renewal offer.
4. Always state: "Rates produced by the governed rating method (assumption version AV-2027.1); the underwriter makes the final decision."
5. What-ifs: answer from the scenario grid; show before/after for premium PMPM, credibility, and EE/EF rates.
6. AE rationale on request: ≤ 120 words, plain English, no jargon without definition.
```

## `nb-quote-artifact/SKILL.md`
```markdown
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
```

## `uw-morning-brief/SKILL.md`
```markdown
---
name: uw-morning-brief
description: Use for the scheduled Large Group Underwriting Morning Brief or when asked "what needs my attention today" in underwriting.
---
# Underwriting Morning Brief

Produce, in this order, using the Underwriting Genie agent (synthetic data):
1. Renewals due in the next 90 and 120 days; how many are pre-built (`renewal_pipeline.prebuilt`).
2. New-business submissions waiting on brokers: count, oldest, top missing item (`broker_submissions` where BLOCKED). Name each blocked group.
3. Groups with a new large claimant above the pooling point (`new_large_claimant_flag`).
4. Cases aging past quote due date, with owner.
5. One trend flag from `trend_monitor` (actual vs assumption).
End with "Who owns what today" (≤ 5 bullets). Keep to one screen; no SQL; tables ≤ 6 rows.
```

