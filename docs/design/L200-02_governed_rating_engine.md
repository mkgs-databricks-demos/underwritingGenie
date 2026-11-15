# L200-02 — Governed Rating Engine (C2)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

## Overview
Encodes the reference experience-rating method (Research 02) as governed assumption tables plus a Unity Catalog SQL table function `rate_new_business()` that returns every waterfall step, and a materialized table `nb_quote_scenarios` holding all 18 lever combinations for the artifact snapshot. A companion `rate_renewal()` (same core) powers Beat 3.

## Dependencies
- C1 tables
- Research 02 formulas; D4–D8 decisions

## Design
### Assumption tables (versioned, `assumption_version = 'AV-2027.1'`)
`completion_factors` (lag 2..7: 1.120, 1.060, 1.035, 1.020, 1.012, 1.006; ≥8: 1.000) · `trend_assumptions` (low 7.5%, base 9.0%, high 10.5%; trend_years 2.0) · `pooling_points` ($150K: charge $38 PMPM, full-cred 30,000 MM; $250K: $24, 42,000; $500K: $11, 60,000) · `manual_rate_factors` (base $520.00 PMPM rating-period dollars; area 1.04; demographic 1.06; industry 1.03) · `retention_targets` (12%) · `tier_factors` (1.00/2.00/1.85/2.85).

### Function contract
`rate_new_business(group_id STRING, pooling_point INT, trend_scenario STRING, plan_option STRING, assumption_version STRING)` → one row per waterfall step **and** a summary row:
`step_order, step_name, step_value, unit, explanation, source_table, assumption_version` + summary columns (credibility, blended_claims_pmpm, premium_pmpm, composite_pepm, rate_ee…rate_ef, rate_change_vs_incumbent, projected_loss_ratio).

### Materialization
Job task `build_nb_quote_scenarios` cross-joins levers and writes `nb_quote_scenarios` (18 rows for Northwind) plus `nb_quote_waterfall` (18 × 10 steps). The artifact reads only these.

### Base-case expected values
See L100 §8; golden file `demo-assets/nb_quote_scenarios_expected.csv`.

> See [diagrams/mermaid/05_rating_waterfall_flow.md](../diagrams/mermaid/05_rating_waterfall_flow.md).

## Non-functional requirements
- Deterministic; no randomness; results to the cent.
- Function documented with COMMENT on function and every parameter (Genie reads these).
- EXECUTE granted to demo users; owner = service principal or Matt.

## Testing
- 18 golden-row comparison (±$0.01).
- Property tests: lower pooling point ⇒ higher Z; pooling charge added whenever excess > 0; Z ≤ 1; premium × (1 − retention) = blended claims.
- Genie Agent benchmark: "What is the recommended Family rate for Northwind at a $250K pooling point?" ⇒ $2,290.21.

## Deployment
Registered by session S3 via bundle SQL file `rating/rate_new_business.sql`; scenarios rebuilt by job.

## Open questions
- Multi-year recursive credibility and separate Rx pooling are documented extensions, not in demo.
