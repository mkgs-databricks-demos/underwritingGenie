# Session 03 — Rating Function + Golden CSV Tests

**Wave:** 0-1 (edit, parallel)
**Mode:** edit
**Depends on:** 01

## Goal

Write the `rate_new_business` SQL table function, the `nb_quote_scenarios` materialization, the `nb_quote_waterfall` view, `rate_renewal` for Lakeview, and the golden CSV test suite. Do not deploy or run SQL.

## Context files to read first

* `docs/design/L200-02_governed_rating_engine.md` — rating engine design
* `docs/design/L300-02_rating_function_spec.md` — exact function signature, inputs, outputs, 10-step waterfall
* `docs/demo-assets/nb_quote_scenarios_expected.csv` — golden 18-scenario results
* `PROJECT_MEMORY.md` — reference numbers (base scenario)

## Files to create (owned_paths)

* `uw-genie-infra/src/sql/10_rate_new_business.sql`
* `uw-genie-infra/src/sql/90_tests.sql`

## Steps

1. Write `10_rate_new_business.sql` per L300-02:
   - Section 1: `CREATE OR REPLACE FUNCTION ${catalog}.${schema}.rate_new_business(...)` SQL table function with COMMENTs on every parameter and return column
   - Inputs: group_id, pooling_point, trend_scenario, plan_option, assumption_version
   - Returns: the full rating result (premium_pmpm, composite_pepm, credibility, rate_ee, rate_es, rate_ec, rate_ef, etc.)
   - Section 2: Scenario materialization — INSERT INTO nb_quote_scenarios for all 18 scenarios (3 pooling points × 3 trend scenarios × 2 plan options), and the nb_quote_waterfall view (10 steps)
   - Section 5: `rate_renewal` for Lakeview Logistics
   - If LATERAL over the cross join fails, generate the 18-call UNION ALL fallback
2. Write `90_tests.sql`:
   - Load `docs/demo-assets/nb_quote_scenarios_expected.csv` to a temp view
   - Compare `nb_quote_scenarios` to the golden CSV: assert base row premium_pmpm = 625.32, rate_ef = 2290.21, credibility = 0.7483
   - All 6 tests must pass within $0.01 tolerance
3. Run `databricks bundle validate --strict --target dev` in `uw-genie-infra/`.

## Acceptance criteria

* `databricks bundle validate --strict --target dev` passes in `uw-genie-infra/`
* `10_rate_new_business.sql` defines `rate_new_business` with COMMENTs matching L300-02
* `90_tests.sql` loads the golden CSV and asserts the 6 key values
* Base row: premium_pmpm 625.32, rate_ef 2290.21, credibility 0.7483
* 18 scenarios materialized (3×3×2)
* `nb_quote_waterfall` view has 10 steps
