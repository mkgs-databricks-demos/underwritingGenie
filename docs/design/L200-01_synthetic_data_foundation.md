# L200-01 — Synthetic Data Foundation (C1)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

## Overview
Creates the fictional plan "Lakeside Health Plan" book of business: groups, census, monthly claims, large claimants, plan designs, renewal pipeline, broker submissions, intake checklist, and the two broker packages (v1 incomplete, v2 complete) in a UC Volume.

## Dependencies
- L100 §5 contracts
- Bundle + catalog from session S1

## Design
### Entities (detail in L300-01)
| Table | Grain | Rows (approx.) | Notes |
|---|---|---|---|
| `groups` | group | 60 | Northwind (prospect, NB), Lakeview Logistics (in force, renewal), 58 in-force groups for book views |
| `census_members` | member | ~42K | Northwind census exactly 980 members / 420 EEs, tier mix 168/76/59/117 |
| `claims_monthly` | group × incurred_month × paid_through | ~3K | Northwind paid-to-date $10.48M across 24 incurred months |
| `large_claimants` | claimant | ~150 | Northwind: 4 claimants ($612K resolved, $410K active, $268K ongoing, $185K resolved) |
| `plan_designs` | plan | 12 | Northwind requested (relativity 1.00) + alternate deductible (0.94) |
| `renewal_pipeline` | group × renewal date | 58 | Q1-2027 renewals with recommended rate actions |
| `persistency_curve` | rate-action band | 6 | Renewal probability by band |
| `broker_submissions` | submission | 25 | incl. Northwind v1 (Blocked) and v2 (Ready) |
| `intake_checklist` | item | 14 | Severity BLOCKING / WARNING |
| `submission_findings` | submission × item | — | Written by the intake skill (optional) or precomputed for the morning brief |

### Volume `broker_packages/`
`northwind_v1/` (incomplete) and `northwind_v2/` (complete) — contents in L300-05. Deliberate v1 gaps: 15 of 24 months; paid-only, no lag report; 22 census rows missing DOB or tier; 3 claimants missing status; benefit summary for requested plan missing.

### Generation
Seeded Python (seed 2027) in a notebook job `generate_synthetic_book`; Northwind and Lakeview values are **pinned** (not random) so demo numbers are stable.

## Non-functional requirements
- Fully synthetic; no real names/ZIPs beyond 3-digit ZIP prefixes.
- Regeneration idempotent (CREATE OR REPLACE) < 3 min serverless.
- All tables tagged `data_class=synthetic`.

## Testing
- Row-count and pinned-value assertions (e.g., Northwind member months = 23,520; paid-to-date sum = $10,480,000).
- v1 package fails ≥5 checklist items; v2 passes all BLOCKING items.

## Deployment
Job `generate_synthetic_book` in bundle; run by S2; re-runnable by reset job.

## Open questions
- None blocking. Optional: add a dental/vision line for multi-line intake.
