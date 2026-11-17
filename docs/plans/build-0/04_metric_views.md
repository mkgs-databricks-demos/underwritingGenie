# Session 04 — Metric Views (3 views + renewal_book_scenarios)

**Wave:** 0-1 (edit, parallel)
**Mode:** edit
**Depends on:** 01

## Goal

Write `20_metric_views.sql` with the `renewal_book_scenarios` view and three metric views using `WITH METRICS LANGUAGE YAML`. Do not deploy or run SQL.

## Context files to read first

* `docs/design/L300-03_metric_views_and_genie_agent_config.md` — sections 1-2: supporting view + metric view YAML
* `docs/semantics/01_rating_and_experience.md`, `02_intake_and_quote.md`, `03_financial_outcomes.md` — business term definitions for column/measure comments
* `PROJECT_MEMORY.md` — non-negotiable rules

## Files to create (owned_paths)

* `uw-genie-infra/src/sql/20_metric_views.sql`

## Steps

1. Write `renewal_book_scenarios` view (L300-03 section 1):
   - Join `renewal_pipeline` with `persistency_curve` (uncapped and capped)
   - Add `capped_rate_action` (LEAST 0.12), persistency columns, renewal premium (uncapped and capped)
2. Write `mv_renewal_book` (L300-03 section 2):
   - Source: `${catalog}.${schema}.renewal_book_scenarios`
   - Dimensions: Renewal Quarter, Size Band, Industry
   - Measures: Renewing Premium, Projected Loss Ratio (Uncapped/Capped), Target Loss Ratio, Premium at Risk (Uncapped/Capped), Avg Recommended Rate Action
   - Each measure has a comment matching the semantics definition
3. Write `mv_quote_outcomes` (L300-03 section 2):
   - Source: `${catalog}.${schema}.nb_quote_scenarios`
   - Dimensions: Group, Pooling Point, Trend Scenario, Plan Option
   - Measures: Premium PMPM, Composite PEPM, Credibility, Rate Change vs Current, Projected Loss Ratio
4. Write `mv_intake_ops` (L300-03 section 2):
   - Source: `${catalog}.${schema}.broker_submissions`
   - Dimensions: Broker, Status, Week
   - Measures: Submissions, Pct Complete First Pass, Blocked Submissions
5. Tag all metric views `certified=true` via ALTER VIEW
6. Run `databricks bundle validate --strict --target dev` in `uw-genie-infra/`.

## Acceptance criteria

* `databricks bundle validate --strict --target dev` passes in `uw-genie-infra/`
* `20_metric_views.sql` creates `renewal_book_scenarios` view and 3 metric views
* Each measure has a comment matching semantics/ definitions
* Metric views tagged `certified=true`
