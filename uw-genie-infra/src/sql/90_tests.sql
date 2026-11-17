-- 90_tests.sql — Underwriting Genie: rating-engine tests (L300-02 section 4).
-- Runs as the setup_demo / reset_demo run_tests SQL file task on the bundle warehouse, after
-- 10_rate_new_business.sql. Parameters (from the job): :catalog, :schema.
-- Every test is one SELECT that calls raise_error() when it fails, so a failing test fails the task
-- (and the job). A passing test returns a single 'PASS ...' row.
--
-- Golden values: docs/demo-assets/nb_quote_scenarios_expected.csv (18 rows, computed independently
-- in Python with the same method). A SQL warehouse task cannot read a repo file, so the CSV is loaded
-- below as an inline VALUES temp view `golden`; its rows are a verbatim copy of the CSV columns used
-- here. If the CSV changes, regenerate the VALUES block from it.
--
-- Tolerances: $0.01 (+1e-6 for binary floating point) on money; 0.0001 on credibility; $0.05 on the
-- composite rebuilt from tier rates (test 6).

USE CATALOG IDENTIFIER(:catalog);
USE SCHEMA IDENTIFIER(:schema);

-- Golden CSV as a temp view (columns renamed to the nb_quote_scenarios names).
CREATE OR REPLACE TEMPORARY VIEW golden AS
SELECT * FROM VALUES
  (150000, 'low',  'requested', 875000, 9715477,  413.07, 1.1556, 520.13, 38.0, 574.31, 0.8854, 526.34, 598.11, 1395.59, -0.0227, 0.88, 768.62, 1537.24, 1421.94, 2190.56),
  (150000, 'low',  'alternate', 875000, 9715477,  413.07, 1.1556, 491.2,  38.0, 539.85, 0.8854, 496.78, 564.52, 1317.21, -0.0776, 0.88, 725.45, 1450.9,  1342.08, 2067.53),
  (150000, 'base', 'requested', 875000, 9715477,  413.07, 1.1881, 533.68, 38.0, 590.45, 0.8854, 540.18, 613.84, 1432.3,   0.003,  0.88, 788.84, 1577.67, 1459.35, 2248.19),
  (150000, 'base', 'alternate', 875000, 9715477,  413.07, 1.1881, 503.94, 38.0, 555.02, 0.8854, 509.79, 579.31, 1351.72, -0.0534, 0.88, 744.46, 1488.91, 1377.24, 2121.7),
  (150000, 'high', 'requested', 875000, 9715477,  413.07, 1.221,  547.42, 38.0, 606.81, 0.8854, 554.22, 629.8,  1469.52,  0.0291, 0.88, 809.34, 1618.67, 1497.27, 2306.61),
  (150000, 'high', 'alternate', 875000, 9715477,  413.07, 1.221,  516.85, 38.0, 570.4,  0.8854, 522.99, 594.3,  1386.7,  -0.0289, 0.88, 763.72, 1527.45, 1412.89, 2176.61),
  (250000, 'low',  'requested', 540000, 10050477, 427.32, 1.1556, 522.76, 24.0, 574.31, 0.7483, 535.73, 608.78, 1420.49, -0.0053, 0.88, 782.33, 1564.67, 1447.32, 2229.65),
  (250000, 'low',  'alternate', 540000, 10050477, 427.32, 1.1556, 492.83, 24.0, 539.85, 0.7483, 504.66, 573.48, 1338.12, -0.0629, 0.88, 736.97, 1473.93, 1363.39, 2100.36),
  (250000, 'base', 'requested', 540000, 10050477, 427.32, 1.1881, 536.77, 24.0, 590.45, 0.7483, 550.28, 625.32, 1459.07,  0.0218, 0.88, 803.58, 1607.16, 1486.63, 2290.21),
  (250000, 'base', 'alternate', 540000, 10050477, 427.32, 1.1881, 506.01, 24.0, 555.02, 0.7483, 518.34, 589.02, 1374.39, -0.0375, 0.88, 756.94, 1513.88, 1400.34, 2157.28),
  (250000, 'high', 'requested', 540000, 10050477, 427.32, 1.221,  550.98, 24.0, 606.81, 0.7483, 565.03, 642.08, 1498.19,  0.0492, 0.88, 825.12, 1650.25, 1526.48, 2351.6),
  (250000, 'high', 'alternate', 540000, 10050477, 427.32, 1.221,  519.36, 24.0, 570.4,  0.7483, 532.21, 604.78, 1411.15, -0.0118, 0.88, 777.19, 1554.38, 1437.8,  2214.99),
  (500000, 'low',  'requested', 112000, 10478477, 445.51, 1.1556, 530.99, 11.0, 574.31, 0.6261, 547.19, 621.81, 1450.88,  0.016,  0.88, 799.07, 1598.14, 1478.28, 2277.35),
  (500000, 'low',  'alternate', 112000, 10478477, 445.51, 1.1556, 499.8,  11.0, 539.85, 0.6261, 514.77, 584.97, 1364.92, -0.0442, 0.88, 751.73, 1503.46, 1390.7,  2142.42),
  (500000, 'base', 'requested', 112000, 10478477, 445.51, 1.1881, 545.61, 11.0, 590.45, 0.6261, 562.37, 639.06, 1491.14,  0.0442, 0.88, 821.24, 1642.48, 1519.3,  2340.54),
  (500000, 'base', 'alternate', 112000, 10478477, 445.51, 1.1881, 513.53, 11.0, 555.02, 0.6261, 529.04, 601.19, 1402.77, -0.0177, 0.88, 772.57, 1545.14, 1429.25, 2201.82),
  (500000, 'high', 'requested', 112000, 10478477, 445.51, 1.221,  560.42, 11.0, 606.81, 0.6261, 577.77, 656.55, 1531.96,  0.0728, 0.88, 843.72, 1687.44, 1560.88, 2404.6),
  (500000, 'high', 'alternate', 112000, 10478477, 445.51, 1.221,  527.46, 11.0, 570.4,  0.6261, 543.51, 617.63, 1441.13,  0.0092, 0.88, 793.7,  1587.4,  1468.35, 2262.05)
AS g(pooling_point, trend_scenario, plan_option, excess_pooled, pooled_claims, experience_pmpm, trend_factor,
     projected_experience_pmpm, pooling_charge_pmpm, manual_pmpm, credibility, blended_claims_pmpm, premium_pmpm,
     composite_pepm, rate_change_vs_incumbent, projected_loss_ratio, rate_ee, rate_es, rate_ec, rate_ef);

-- T0. The golden view itself has the 18 scenario keys (guards against a bad VALUES edit).
SELECT CASE WHEN COUNT(*) = 18 AND COUNT(DISTINCT pooling_point, trend_scenario, plan_option) = 18
            THEN 'PASS T0 golden CSV view has 18 distinct scenarios'
            ELSE raise_error(concat('FAIL T0 golden view rows=', COUNT(*))) END AS result
FROM golden;

-- T1. 18 rows; all scenario keys distinct.
SELECT CASE WHEN COUNT(*) = 18 AND COUNT(DISTINCT group_id, pooling_point, trend_scenario, plan_option, assumption_version) = 18
            THEN 'PASS T1 nb_quote_scenarios has 18 distinct scenarios'
            ELSE raise_error(concat('FAIL T1 nb_quote_scenarios rows=', COUNT(*),
                 ' distinct keys=', COUNT(DISTINCT group_id, pooling_point, trend_scenario, plan_option, assumption_version))) END AS result
FROM nb_quote_scenarios;

-- T2. |actual - golden| <= 0.01 for premium_pmpm and the four tier rates (and credibility <= 0.0001),
--     for every golden scenario. A scenario missing from nb_quote_scenarios also fails.
SELECT CASE WHEN COUNT(*) = 0
            THEN 'PASS T2 all 18 scenarios match the golden CSV'
            ELSE raise_error(concat('FAIL T2 ', COUNT(*), ' scenario(s) differ from golden CSV: ',
                 array_join(collect_list(k), '; '))) END AS result
FROM (
  SELECT concat(g.pooling_point, '/', g.trend_scenario, '/', g.plan_option,
                ' premium ', COALESCE(CAST(s.premium_pmpm AS STRING), 'missing'), ' vs ', g.premium_pmpm,
                ' EF ', COALESCE(CAST(s.rate_ef AS STRING), 'missing'), ' vs ', g.rate_ef,
                ' Z ', COALESCE(CAST(s.credibility AS STRING), 'missing'), ' vs ', g.credibility) AS k
  FROM golden g
  LEFT JOIN nb_quote_scenarios s
    ON s.group_id = 'GRP-NW-001' AND s.assumption_version = 'AV-2027.1'
   AND s.pooling_point = g.pooling_point AND s.trend_scenario = g.trend_scenario AND s.plan_option = g.plan_option
  WHERE s.group_id IS NULL
     OR NOT (ABS(s.premium_pmpm - g.premium_pmpm) <= 0.010001
         AND ABS(s.rate_ee - g.rate_ee) <= 0.010001
         AND ABS(s.rate_es - g.rate_es) <= 0.010001
         AND ABS(s.rate_ec - g.rate_ec) <= 0.010001
         AND ABS(s.rate_ef - g.rate_ef) <= 0.010001
         AND ABS(s.credibility - g.credibility) <= 0.0001)
     OR s.premium_pmpm IS NULL OR s.rate_ee IS NULL OR s.rate_es IS NULL OR s.rate_ec IS NULL
     OR s.rate_ef IS NULL OR s.credibility IS NULL);

-- T2b. Reference (base) scenario: $250K pooling, base trend, requested plan.
--      premium_pmpm 625.32, rate_ef 2290.21, credibility 0.7483 (PROJECT_MEMORY reference numbers).
SELECT CASE WHEN COUNT(*) = 1
             AND ABS(MAX(premium_pmpm) - 625.32) <= 0.010001
             AND ABS(MAX(rate_ef) - 2290.21) <= 0.010001
             AND ABS(MAX(credibility) - 0.7483) <= 0.0001
            THEN 'PASS T2b base scenario premium_pmpm 625.32, rate_ef 2290.21, credibility 0.7483'
            ELSE raise_error(concat('FAIL T2b base scenario rows=', COUNT(*), ' premium_pmpm=', MAX(premium_pmpm),
                 ' rate_ef=', MAX(rate_ef), ' credibility=', MAX(credibility))) END AS result
FROM nb_quote_scenarios
WHERE group_id = 'GRP-NW-001' AND pooling_point = 250000 AND trend_scenario = 'base' AND plan_option = 'requested';

-- T3. credibility(150K) > credibility(250K) > credibility(500K), for every trend scenario and plan option.
-- NULL-safe: a NULL comparison counts as a failure (NOT COALESCE(cond, FALSE)) in T3-T6.
SELECT CASE WHEN COUNT(*) = 6 AND COUNT_IF(NOT COALESCE(z150 > z250 AND z250 > z500, FALSE)) = 0
            THEN 'PASS T3 credibility decreases as the pooling point rises'
            ELSE raise_error(concat('FAIL T3 credibility ordering broken in ',
                 COUNT_IF(NOT COALESCE(z150 > z250 AND z250 > z500, FALSE)),
                 ' of ', COUNT(*), ' trend/plan combinations')) END AS result
FROM (
  SELECT trend_scenario, plan_option,
         MAX(CASE WHEN pooling_point = 150000 THEN credibility END) AS z150,
         MAX(CASE WHEN pooling_point = 250000 THEN credibility END) AS z250,
         MAX(CASE WHEN pooling_point = 500000 THEN credibility END) AS z500
  FROM nb_quote_scenarios
  GROUP BY trend_scenario, plan_option);

-- T4. excess_pooled > 0 implies pooling_charge_pmpm > 0.
SELECT CASE WHEN COUNT_IF(excess_pooled > 0 AND NOT COALESCE(pooling_charge_pmpm > 0, FALSE)) = 0
            THEN 'PASS T4 every pooled scenario carries a pooling charge'
            ELSE raise_error(concat('FAIL T4 ', COUNT_IF(excess_pooled > 0 AND NOT COALESCE(pooling_charge_pmpm > 0, FALSE)),
                 ' scenario(s) pool excess with no pooling charge')) END AS result
FROM nb_quote_scenarios;

-- T5. ROUND(premium_pmpm x (1 - retention), 2) = blended_claims_pmpm (+/- 0.01).
SELECT CASE WHEN COUNT_IF(NOT COALESCE(ABS(ROUND(premium_pmpm * (1 - retention), 2) - blended_claims_pmpm) <= 0.010001, FALSE)) = 0
            THEN 'PASS T5 premium x (1 - retention) reproduces blended claims'
            ELSE raise_error(concat('FAIL T5 ',
                 COUNT_IF(NOT COALESCE(ABS(ROUND(premium_pmpm * (1 - retention), 2) - blended_claims_pmpm) <= 0.010001, FALSE)),
                 ' scenario(s) where premium x (1 - retention) != blended claims')) END AS result
FROM nb_quote_scenarios;

-- T6. Weighted tier rates reproduce the composite: sum(enrolled x rate) / EE = composite_pepm (+/- 0.05).
SELECT CASE WHEN COUNT(*) = 18 AND COUNT_IF(NOT COALESCE(ABS(weighted / ee - composite_pepm) <= 0.05, FALSE)) = 0
            THEN 'PASS T6 enrollment-weighted tier rates reproduce the composite PEPM'
            ELSE raise_error(concat('FAIL T6 ', COUNT_IF(NOT COALESCE(ABS(weighted / ee - composite_pepm) <= 0.05, FALSE)),
                 ' of ', COUNT(*), ' scenario(s): tier rates do not reproduce composite_pepm')) END AS result
FROM (
  SELECT s.pooling_point, s.trend_scenario, s.plan_option, s.composite_pepm, MAX(gr.enrolled_employees) AS ee,
         SUM(t.enrolled * CASE t.tier WHEN 'EE' THEN s.rate_ee WHEN 'ES' THEN s.rate_es
                                      WHEN 'EC' THEN s.rate_ec WHEN 'EF' THEN s.rate_ef END) AS weighted
  FROM nb_quote_scenarios s
  JOIN groups gr ON gr.group_id = s.group_id
  JOIN group_tier_counts t ON t.group_id = s.group_id
  GROUP BY s.pooling_point, s.trend_scenario, s.plan_option, s.composite_pepm);

-- T7. nb_quote_waterfall has the 10 steps for every scenario (180 rows, step_order 1..10).
SELECT CASE WHEN COUNT(*) = 180 AND COUNT(DISTINCT step_order) = 10 AND MIN(step_order) = 1 AND MAX(step_order) = 10
             AND COUNT(DISTINCT group_id, pooling_point, trend_scenario, plan_option) = 18
            THEN 'PASS T7 nb_quote_waterfall has 10 steps for each of 18 scenarios'
            ELSE raise_error(concat('FAIL T7 nb_quote_waterfall rows=', COUNT(*), ' steps=', COUNT(DISTINCT step_order))) END AS result
FROM nb_quote_waterfall;

-- T8. renewal_scenarios (rate_renewal for Lakeview Logistics) has 9 complete rows.
SELECT CASE WHEN COUNT(*) = 9
             AND COUNT(DISTINCT pooling_point, trend_scenario) = 9
             AND COUNT_IF(premium_pmpm IS NULL OR recommended_rate_action IS NULL OR rate_ef IS NULL) = 0
            THEN 'PASS T8 renewal_scenarios has 9 complete Lakeview scenarios'
            ELSE raise_error(concat('FAIL T8 renewal_scenarios rows=', COUNT(*), ' incomplete rows=',
                 COUNT_IF(premium_pmpm IS NULL OR recommended_rate_action IS NULL OR rate_ef IS NULL))) END AS result
FROM renewal_scenarios
WHERE group_id = 'GRP-LV-002';
