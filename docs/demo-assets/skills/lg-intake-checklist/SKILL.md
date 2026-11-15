---
name: lg-intake-checklist
description: Use when a user uploads a large group broker submission (census, claims experience, large claimant report, benefit summary, RFP, broker email) or asks whether a group is "ready to quote". Checks completeness against the governed intake checklist and drafts a broker request.
---
# Large Group Intake Checklist

## When to use
- User uploads broker package files or asks "is this ready to quote?", "what's missing?".

## Steps
1. Identify the group (name, effective date, enrolled employees, broker, contact) from the email/RFP.
2. Read the governed checklist: `SELECT item_id, item_name, severity, rule_text, broker_ask_template FROM <catalog>.<schema>.intake_checklist` (via the Large Group Underwriting Cockpit Genie Agent).
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
