# L200-06 — Scheduled Morning Brief (C6)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

## Overview
A Genie One scheduled task "Large Group Underwriting Morning Brief" (weekdays 7:00 AM) using skill `uw-morning-brief` and the Genie Agent; run the evening before the demo so a completed run exists.

## Dependencies
- C3 metric views; C1 renewal_pipeline, broker_submissions, large_claimants

## Design
### Content contract (in order)
1. Renewals due next 90/120 days; # pre-built.
2. New-business submissions waiting on brokers (count, oldest, top missing item) — must include Northwind v1 "Blocked".
3. Groups with a new large claimant above pooling point.
4. Cases aging past quote due date.
5. One flagged trend: Rx trend running ahead of pricing assumption (pinned synthetic signal).
6. "Who owns it" line per item. No tables > 6 rows.

## Non-functional requirements
- Runs < 5 min; output ≤ 1 screen + follow-ups.

## Testing
Acceptance AC-1-1…AC-1-5 in L200-07.

## Deployment
Session S7 creates the task; manual "Run now" the night before.

## Open questions
- None.
