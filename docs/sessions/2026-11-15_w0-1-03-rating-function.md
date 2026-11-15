# Session 03 (wave 0-1): rating function and golden CSV tests

Run `581746600380456` · branch `mg-genie-uw-genie-build-1` · mode `edit` · status **pass**

## Changes

* `uw-genie-infra/src/sql/10_rate_new_business.sql` (setup_demo / reset_demo task `build_nb_quote_scenarios`):
  * `rate_new_business()` SQL table function. The body, signature, parameter COMMENTs and function COMMENT are L300-02 section 1 verbatim. I added a COMMENT to every return column (the plan asks for them; L300-02 has none).
  * `nb_quote_scenarios`: CTAS of the 18 Northwind scenarios (3 pooling x 3 trend x 2 plan), plus `generated_at` and `method_version`.
  * `nb_quote_waterfall` view: L300-02 `stack(10, ...)`, so 10 steps per scenario.
  * `rate_renewal()` (section 5): same method on the in-force plan (`plan_option` 'current'). Returns `current_premium_pmpm` and `recommended_rate_action` = premium / incumbent_premium_pmpm - 1.
  * `renewal_scenarios`: CTAS of 9 Lakeview Logistics rows (`GRP-LV-002`, 3 pooling x 3 trend).
  * Tables and the view get TBLPROPERTIES and `SET TAGS` domain=underwriting, data_class=synthetic.
* `uw-genie-infra/src/sql/90_tests.sql` (task `run_tests`): the golden CSV goes into the temp view `golden`, then tests T0-T8 run. Each test is a SELECT that calls `raise_error()` on failure, so a failing test fails the job task.
  * T0: the golden view has 18 rows.
  * T1: 18 distinct scenarios.
  * T2: matches golden within 0.01 for premium and the 4 tier rates, and within 0.0001 for Z. A missing or NULL row also fails.
  * T2b: the base row is 625.32 / 2290.21 / 0.7483.
  * T3: Z(150K) > Z(250K) > Z(500K).
  * T4: pooled excess implies a pooling charge.
  * T5: premium x (1 - retention) = blended.
  * T6: enrollment-weighted tier rates = composite within 0.05.
  * T7: the waterfall has 180 rows / 10 steps.
  * T8: renewal_scenarios has 9 complete rows.

## Decisions

* **UNION ALL fallback is active; the LATERAL form is a comment.** I can't run SQL in this session, so I couldn't check that the warehouse decorrelates a LATERAL call to a SQL table function over a cross join. That function's body aggregates and filters on its arguments. The 18 literal calls always plan and give the same rows. L300-02 names this fallback.
* **Name resolution:** both files use the 00_ddl.sql convention (`USE CATALOG/SCHEMA IDENTIFIER(:catalog/:schema)`, unqualified names). Per the Databricks name-resolution docs, a persistent SQL UDF resolves the unqualified names in its body against the path captured at CREATE FUNCTION time. So the functions keep reading `hls_fde_dev.uw_genie` when Genie calls them from another schema.
* **Golden CSV inline:** a SQL warehouse file task cannot read a repo file, so the CSV values are inlined as `VALUES`. Check: a Python parse of the CSV against the VALUES block gave 18/18 rows and 0 mismatches.
* **Tolerance** is 0.010001 instead of 0.01, so binary floating point error does not fail a cent-exact difference.
* **rate_renewal robustness:** if there is no 'current' plan row, the relativity is 1.00. Large claimants come from the group's latest package_version. When Z = 1, the blend is projected experience only. These match session 05's seed: Lakeview has a 'current' plan with relativity 1.00, claimants with `package_version` v2, a manual-factor row and a v2 census.
* **Functions are not tagged.** UC tags are set on the tables and the view only.

## Checks

* `databricks bundle validate --strict --target dev` (uw-genie-infra): **pass**, "Validation OK!". The first try failed with `notebook src/notebooks/generate_synthetic_book.py not found`, because session 05 had not written its notebooks yet. I re-ran it after they appeared.
* Golden VALUES vs `docs/demo-assets/nb_quote_scenarios_expected.csv`: 18 rows, 0 mismatches (Python).
* I recomputed the base scenario in Python from the L300-01 pinned inputs with the function's formulas: completed 10,590,477, excess 540,000, experience 427.32, projected 536.77, manual 590.45, Z 0.7483, blended 550.28, premium 625.32, composite 1459.07, EF 2290.21. All match PROJECT_MEMORY.
* Static: 18 distinct `rate_new_business` calls, 9 `rate_renewal` calls, 10 waterfall steps.
* **Not run** (out of scope): the SQL itself. The functions, CTAS statements and tests are first executed by session 06 (wave 0-2).

## Requests / notes for later sessions

* 06: if the warehouse rejects anything in 10_, the likely spots are:
  * RETURNS TABLE type coercion: `relativity` and `retention` are DOUBLE as in the DDL, and ROUND returns DOUBLE.
  * `stack()` alongside `*` in the waterfall view.
  * T8 depends on the Lakeview seed rows being complete.
* 06: `20_metric_views.sql` is not in setup_demo yet (session 01 noted this). nb_quote_scenarios is built before run_tests, so the metric views over it can run between the two.

## Files modified

* `uw-genie-infra/src/sql/10_rate_new_business.sql` (new)
* `uw-genie-infra/src/sql/90_tests.sql` (new)
