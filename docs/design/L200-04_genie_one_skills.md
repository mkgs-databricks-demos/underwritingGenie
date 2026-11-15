# L200-04 — Genie One Skills (C4)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

## Overview
Four skills make Genie One behave like a disciplined underwriting coworker: `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact` (L200-05), `uw-morning-brief` (L200-06). Full SKILL.md text in L300-04.

## Dependencies
- C1 checklist table; C2 function; C3 agent

## Design
### lg-intake-checklist
Triggers on "ready to quote", uploaded broker packages. Reads `intake_checklist`; inspects each uploaded file; returns Ready / Ready with warnings / Blocked with item, evidence (file + location) and suggested broker ask; drafts Gmail reply (**draft only**) on request.
### experience-rating-explainer
Triggers on rate/renewal/quote requests. **Never computes rates**; queries `nb_quote_scenarios` / calls `rate_new_business()` via the Genie Agent; explains each waterfall step in plain English; cites `assumption_version`; answers what-ifs only from precomputed levers, otherwise says the lever isn't in the governed method.
### Publishing
Publish to UC Skills (`${catalog}.${schema}`) **and** keep a workspace copy (Genie One reads UC Skills; Genie Code uses workspace skills).

## Non-functional requirements
- Text-only files; ≤50 files; each skill < 400 lines.
- Consistent terminology with UC Pages.

## Testing
Skill acceptance prompts in L200-07 §4.

## Deployment
Session S7.

## Open questions
- None.
