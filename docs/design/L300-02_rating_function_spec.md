# L300-02 — Rating Function and Scenario Build Spec

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


Implemented as a **Unity Catalog SQL table function** (SQL table functions can read governed tables; UC Python UDFs cannot query tables). (Decision D8.)

## 1. Function
```sql
CREATE OR REPLACE FUNCTION ${catalog}.${schema}.rate_new_business(
  p_group_id STRING COMMENT 'Group key, e.g. GRP-NW-001',
  p_pooling_point INT COMMENT 'Per-claimant pooling point: 150000, 250000 or 500000',
  p_trend_scenario STRING COMMENT 'low | base | high',
  p_plan_option STRING COMMENT 'requested | alternate',
  p_assumption_version STRING DEFAULT 'AV-2027.1' COMMENT 'Governed assumption set')
RETURNS TABLE (
  group_id STRING, pooling_point INT, trend_scenario STRING, plan_option STRING, assumption_version STRING,
  paid_to_date DOUBLE, completed_claims DOUBLE, ibnr DOUBLE, excess_pooled DOUBLE, pooled_claims DOUBLE,
  member_months BIGINT, experience_pmpm DOUBLE, trend_factor DOUBLE, plan_relativity DOUBLE,
  demographic_change DOUBLE, pooling_charge_pmpm DOUBLE, projected_experience_pmpm DOUBLE,
  manual_pmpm DOUBLE, credibility DOUBLE, blended_claims_pmpm DOUBLE, retention DOUBLE,
  premium_pmpm DOUBLE, composite_pepm DOUBLE, rate_ee DOUBLE, rate_es DOUBLE, rate_ec DOUBLE, rate_ef DOUBLE,
  rate_change_vs_incumbent DOUBLE, projected_loss_ratio DOUBLE)
COMMENT 'Governed large group experience-rating method (synthetic demo). Completes, pools, trends, blends with manual by square-root credibility, loads retention, converts to tier rates. The ONLY approved source of quoted rates.'
RETURN
WITH g   AS (SELECT * FROM ${catalog}.${schema}.groups WHERE group_id = p_group_id),
clm AS (
  SELECT SUM(c.paid_to_date) AS paid,
         SUM(c.paid_to_date * COALESCE(cf.factor, 1.0)) AS completed
  FROM ${catalog}.${schema}.claims_monthly c
  LEFT JOIN ${catalog}.${schema}.completion_factors cf
    ON cf.assumption_version = p_assumption_version
   AND cf.lag_months = CAST(months_between(c.paid_through, c.incurred_month) AS INT)
  WHERE c.group_id = p_group_id),
lc  AS (SELECT COALESCE(SUM(GREATEST(total_claims - p_pooling_point, 0)), 0) AS excess
        FROM ${catalog}.${schema}.large_claimants WHERE group_id = p_group_id AND package_version = 'v2'),
pp  AS (SELECT * FROM ${catalog}.${schema}.pooling_points WHERE assumption_version = p_assumption_version AND pooling_point = p_pooling_point),
tr  AS (SELECT * FROM ${catalog}.${schema}.trend_assumptions WHERE assumption_version = p_assumption_version AND trend_scenario = p_trend_scenario),
trb AS (SELECT * FROM ${catalog}.${schema}.trend_assumptions WHERE assumption_version = p_assumption_version AND trend_scenario = 'base'),
pl  AS (SELECT relativity FROM ${catalog}.${schema}.plan_designs WHERE group_id = p_group_id AND plan_option = p_plan_option),
mf  AS (SELECT * FROM ${catalog}.${schema}.manual_rate_factors WHERE assumption_version = p_assumption_version AND group_id = p_group_id),
rt  AS (SELECT retention FROM ${catalog}.${schema}.retention_targets WHERE assumption_version = p_assumption_version),
tf  AS (SELECT MAX(CASE WHEN tier='EE' THEN tier_factor END) f_ee, MAX(CASE WHEN tier='ES' THEN tier_factor END) f_es,
               MAX(CASE WHEN tier='EC' THEN tier_factor END) f_ec, MAX(CASE WHEN tier='EF' THEN tier_factor END) f_ef
        FROM ${catalog}.${schema}.tier_factors WHERE assumption_version = p_assumption_version),
tw  AS (SELECT SUM(t.enrolled * f.tier_factor) AS wsum
        FROM ${catalog}.${schema}.group_tier_counts t
        JOIN ${catalog}.${schema}.tier_factors f ON f.tier = t.tier AND f.assumption_version = p_assumption_version
        WHERE t.group_id = p_group_id),
s1 AS (
  SELECT g.*, clm.paid, clm.completed, lc.excess, pp.pooling_charge_pmpm, pp.full_credibility_mm,
         POWER(1 + tr.annual_rate, tr.trend_years) AS trend_factor,
         POWER((1 + tr.annual_rate) / (1 + trb.annual_rate), tr.trend_years) AS manual_trend_adj,
         pl.relativity, mf.base_manual_pmpm * mf.area_factor * mf.demographic_factor * mf.industry_factor AS manual_base,
         rt.retention, tf.*, tw.wsum
  FROM g, clm, lc, pp, tr, trb, pl, mf, rt, tf, tw),
s2 AS (
  SELECT *, (completed - excess) / member_months AS experience_pmpm,
         (completed - excess) / member_months * trend_factor * relativity * demographic_change + pooling_charge_pmpm AS proj_exp,
         manual_base * relativity * manual_trend_adj AS manual_pmpm,
         LEAST(1.0, SQRT(member_months / full_credibility_mm)) AS z
  FROM s1),
s3 AS (
  SELECT *, z * proj_exp + (1 - z) * manual_pmpm AS blended FROM s2),
s4 AS (
  SELECT *, blended / (1 - retention) AS premium FROM s3)
SELECT group_id, p_pooling_point, p_trend_scenario, p_plan_option, p_assumption_version,
       ROUND(paid,2), ROUND(completed,2), ROUND(completed - paid,2), ROUND(excess,2), ROUND(completed - excess,2),
       member_months, ROUND(experience_pmpm,2), ROUND(trend_factor,4), relativity, demographic_change, pooling_charge_pmpm,
       ROUND(proj_exp,2), ROUND(manual_pmpm,2), ROUND(z,4), ROUND(blended,2), retention,
       ROUND(premium,2), ROUND(premium * members / enrolled_employees,2),
       ROUND(premium * members / wsum * f_ee,2), ROUND(premium * members / wsum * f_es,2),
       ROUND(premium * members / wsum * f_ec,2), ROUND(premium * members / wsum * f_ef,2),
       ROUND(premium / incumbent_premium_pmpm - 1,4), ROUND(blended / premium,4)
FROM s4;
```
> Tier-rate algebra: unit = composite_pepm × EE / Σ(enrolled×factor) = premium × members / wsum.

## 2. Scenario materialization (job task `build_nb_quote_scenarios`)
```sql
CREATE OR REPLACE TABLE ${catalog}.${schema}.nb_quote_scenarios AS
SELECT r.*, current_timestamp() AS generated_at, 'rate_new_business v1' AS method_version
FROM (SELECT 'GRP-NW-001' g) x
CROSS JOIN (VALUES (150000),(250000),(500000)) AS p(pp)
CROSS JOIN (VALUES ('low'),('base'),('high')) AS t(ts)
CROSS JOIN (VALUES ('requested'),('alternate')) AS o(po),
LATERAL ${catalog}.${schema}.rate_new_business(x.g, p.pp, t.ts, o.po, 'AV-2027.1') r;

CREATE OR REPLACE VIEW ${catalog}.${schema}.nb_quote_waterfall AS
SELECT group_id, pooling_point, trend_scenario, plan_option, assumption_version, step_order, step_name, step_value, unit FROM (
  SELECT *, stack(10,
    1,'Paid-to-date claims (24 mo)', paid_to_date,'USD',
    2,'IBNR from completion factors', ibnr,'USD',
    3,'Excess over pooling point removed', -excess_pooled,'USD',
    4,'Historical experience PMPM', experience_pmpm,'PMPM',
    5,'Projected experience incl. trend, plan, demo + pooling charge', projected_experience_pmpm,'PMPM',
    6,'Manual rate', manual_pmpm,'PMPM',
    7,'Credibility (Z)', credibility,'ratio',
    8,'Blended claims PMPM', blended_claims_pmpm,'PMPM',
    9,'Premium PMPM after retention', premium_pmpm,'PMPM',
    10,'Composite rate PEPM', composite_pepm,'PEPM') AS (step_order, step_name, step_value, unit)
  FROM ${catalog}.${schema}.nb_quote_scenarios);
```
If `LATERAL` with a table function over a cross join is not accepted by the warehouse version, fall back to a `UNION ALL` of 18 explicit calls generated by the setup notebook.

## 3. Golden results (18 rows)
`demo-assets/nb_quote_scenarios_expected.csv` — computed independently in Python with the same method. Selected rows:
| Pooling | Trend | Plan | Z | Premium PMPM | vs current | EE | EF |
|---|---|---|---|---|---|---|---|
| 150K | base | requested | 0.8854 | 613.84 | +0.3% | 788.84 | 2,248.19 |
| **250K** | **base** | **requested** | **0.7483** | **625.32** | **+2.2%** | **803.58** | **2,290.21** |
| 500K | base | requested | 0.6261 | 639.06 | +4.4% | 821.24 | 2,340.54 |
| 250K | base | alternate | 0.7483 | 589.02 | −3.8% | 756.94 | 2,157.28 |
| 500K | high | requested | 0.6261 | 656.55 | +7.3% | 843.72 | 2,404.60 |
| 150K | low | alternate | 0.8854 | 564.52 | −7.8% | 725.45 | 2,067.53 |

## 4. Tests (`tests/test_rating.sql`, run in job)
1. 18 rows; all scenario keys distinct.
2. |actual − golden| ≤ 0.01 for premium_pmpm and the four tier rates.
3. credibility(150K) > credibility(250K) > credibility(500K).
4. excess_pooled > 0 ⇒ pooling_charge_pmpm > 0.
5. ROUND(premium_pmpm × (1 − retention), 2) = blended_claims_pmpm (±0.01).
6. Weighted tier rates reproduce composite: Σ(enrolled × rate) / EE = composite_pepm (±0.05).

## 5. Renewal variant
`rate_renewal(p_group_id, p_pooling_point, p_trend_scenario, p_assumption_version)` reuses the same CTEs with plan_option='current' and returns `recommended_rate_action = premium / incumbent_premium_pmpm − 1`; materialized for Lakeview into `renewal_scenarios`.
