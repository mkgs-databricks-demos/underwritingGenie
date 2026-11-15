# L200-03 — Semantics and Genie Agent (C3)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

## Overview
Publishes UC Pages glossary (~30 terms from semantics/), three metric views, and the Genie Agent "Large Group Underwriting Cockpit" with instructions, example SQL, trusted assets and a benchmark set.

## Dependencies
- C1, C2
- semantics/01–03

## Design
### Metric views
| View | Measures | Dimensions |
|---|---|---|
| `mv_quote_outcomes` | premium_pmpm, composite_pepm, credibility, projected_loss_ratio, rate_change_vs_incumbent | group, pooling_point, trend_scenario, plan_option |
| `mv_renewal_book` | renewal_premium, recommended_rate_action, projected_loss_ratio, premium_at_risk (persistency-weighted), capped_rate_action | renewal_quarter, industry, size_band, rate_action_band |
| `mv_intake_ops` | submissions, pct_complete_first_pass, open_blocking_items, avg_days_waiting | broker, status, week |

### Genie Agent
Name **Large Group Underwriting Cockpit**; tables + metric views above; trusted assets: `rate_new_business`, parameterized example "rate for {group} at {pooling_point}"; instructions in L300-03; ≥15 benchmarks.

## Non-functional requirements
- Benchmark accuracy ≥ 90% before demo (target 100% on the 8 demo-critical questions).
- Every metric view measure has a comment matching the UC Page definition.

## Testing
Benchmarks run after every change; results logged in sessions/.

## Deployment
Session S5 (metric views, Pages) and S6 (agent). Agent config captured as code (serialized space) for reuse.

## Open questions
- Whether to certify metric views in the demo workspace (recommended: yes, tag `certified=true`).
