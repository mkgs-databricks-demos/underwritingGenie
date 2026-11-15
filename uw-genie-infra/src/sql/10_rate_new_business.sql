-- 10_rate_new_business.sql — Underwriting Genie: governed rating engine (L300-02).
-- Runs as the setup_demo / reset_demo build_nb_quote_scenarios SQL file task on the bundle warehouse.
-- Parameters (from the job): :catalog, :schema (default hls_fde_dev / uw_genie).
--
-- Objects (all CREATE OR REPLACE, so setup and reset are idempotent):
--   1. rate_new_business()   SQL table function (L300-02 section 1). The ONLY approved source of quoted rates.
--   2. nb_quote_scenarios    18 Northwind scenarios = 3 pooling points x 3 trend scenarios x 2 plan options (section 2)
--   3. nb_quote_waterfall    10-step rating waterfall per scenario (section 2)
--   4. rate_renewal()        renewal variant, plan_option 'current' (section 5)
--   5. renewal_scenarios     Lakeview Logistics renewal grid: 3 pooling points x 3 trend scenarios (section 5)
--
-- Name resolution: the USE statements below set the current schema. Unqualified table names in a
-- persistent SQL function body resolve against the path captured at CREATE FUNCTION time, so the
-- functions always read ${catalog}.${schema} tables, whatever schema the caller (e.g. Genie) is in.

USE CATALOG IDENTIFIER(:catalog);
USE SCHEMA IDENTIFIER(:schema);

-- =====================================================================================
-- 1. rate_new_business (L300-02 section 1)
-- =====================================================================================
CREATE OR REPLACE FUNCTION rate_new_business(
  p_group_id STRING COMMENT 'Group key, e.g. GRP-NW-001',
  p_pooling_point INT COMMENT 'Per-claimant pooling point: 150000, 250000 or 500000',
  p_trend_scenario STRING COMMENT 'low | base | high',
  p_plan_option STRING COMMENT 'requested | alternate',
  p_assumption_version STRING DEFAULT 'AV-2027.1' COMMENT 'Governed assumption set')
RETURNS TABLE (
  group_id STRING COMMENT 'Group key',
  pooling_point INT COMMENT 'Per-claimant pooling point used',
  trend_scenario STRING COMMENT 'Trend scenario used (low | base | high)',
  plan_option STRING COMMENT 'Plan option rated (requested | alternate)',
  assumption_version STRING COMMENT 'Governed assumption set used',
  paid_to_date DOUBLE COMMENT 'Step 1: experience-period claims paid to date (USD)',
  completed_claims DOUBLE COMMENT 'Paid to date completed with completion factors (USD)',
  ibnr DOUBLE COMMENT 'Step 2: IBNR from completion factors = completed - paid (USD)',
  excess_pooled DOUBLE COMMENT 'Step 3: large-claimant dollars above the pooling point removed (USD)',
  pooled_claims DOUBLE COMMENT 'Completed claims net of pooled excess (USD)',
  member_months BIGINT COMMENT 'Experience-period member months',
  experience_pmpm DOUBLE COMMENT 'Step 4: historical pooled experience PMPM',
  trend_factor DOUBLE COMMENT 'Trend factor = (1 + annual trend) ^ trend years',
  plan_relativity DOUBLE COMMENT 'Benefit relativity of the rated plan option',
  demographic_change DOUBLE COMMENT 'Current census demo factor / experience-period demo factor',
  pooling_charge_pmpm DOUBLE COMMENT 'Pooling charge PMPM added back for the pooling point',
  projected_experience_pmpm DOUBLE COMMENT 'Step 5: projected experience incl. trend, plan, demo + pooling charge (PMPM)',
  manual_pmpm DOUBLE COMMENT 'Step 6: manual rate PMPM (base x area x demo x industry, plan and trend adjusted)',
  credibility DOUBLE COMMENT 'Step 7: square-root credibility Z = min(1, sqrt(member months / full-credibility standard))',
  blended_claims_pmpm DOUBLE COMMENT 'Step 8: Z x projected experience + (1 - Z) x manual (PMPM)',
  retention DOUBLE COMMENT 'Retention as share of premium',
  premium_pmpm DOUBLE COMMENT 'Step 9: premium PMPM after retention = blended / (1 - retention)',
  composite_pepm DOUBLE COMMENT 'Step 10: composite rate per enrolled employee per month',
  rate_ee DOUBLE COMMENT 'Monthly tier rate, employee only',
  rate_es DOUBLE COMMENT 'Monthly tier rate, employee + spouse',
  rate_ec DOUBLE COMMENT 'Monthly tier rate, employee + child(ren)',
  rate_ef DOUBLE COMMENT 'Monthly tier rate, family',
  rate_change_vs_incumbent DOUBLE COMMENT 'Premium PMPM / incumbent premium PMPM - 1',
  projected_loss_ratio DOUBLE COMMENT 'Blended claims / premium')
COMMENT 'Governed large group experience-rating method (synthetic demo). Completes, pools, trends, blends with manual by square-root credibility, loads retention, converts to tier rates. The ONLY approved source of quoted rates.'
RETURN
WITH g   AS (SELECT * FROM groups WHERE group_id = p_group_id),
clm AS (
  SELECT SUM(c.paid_to_date) AS paid,
         SUM(c.paid_to_date * COALESCE(cf.factor, 1.0)) AS completed
  FROM claims_monthly c
  LEFT JOIN completion_factors cf
    ON cf.assumption_version = p_assumption_version
   AND cf.lag_months = CAST(months_between(c.paid_through, c.incurred_month) AS INT)
  WHERE c.group_id = p_group_id),
lc  AS (SELECT COALESCE(SUM(GREATEST(total_claims - p_pooling_point, 0)), 0) AS excess
        FROM large_claimants WHERE group_id = p_group_id AND package_version = 'v2'),
pp  AS (SELECT * FROM pooling_points WHERE assumption_version = p_assumption_version AND pooling_point = p_pooling_point),
tr  AS (SELECT * FROM trend_assumptions WHERE assumption_version = p_assumption_version AND trend_scenario = p_trend_scenario),
trb AS (SELECT * FROM trend_assumptions WHERE assumption_version = p_assumption_version AND trend_scenario = 'base'),
pl  AS (SELECT relativity FROM plan_designs WHERE group_id = p_group_id AND plan_option = p_plan_option),
mf  AS (SELECT * FROM manual_rate_factors WHERE assumption_version = p_assumption_version AND group_id = p_group_id),
rt  AS (SELECT retention FROM retention_targets WHERE assumption_version = p_assumption_version),
tf  AS (SELECT MAX(CASE WHEN tier='EE' THEN tier_factor END) f_ee, MAX(CASE WHEN tier='ES' THEN tier_factor END) f_es,
               MAX(CASE WHEN tier='EC' THEN tier_factor END) f_ec, MAX(CASE WHEN tier='EF' THEN tier_factor END) f_ef
        FROM tier_factors WHERE assumption_version = p_assumption_version),
tw  AS (SELECT SUM(t.enrolled * f.tier_factor) AS wsum
        FROM group_tier_counts t
        JOIN tier_factors f ON f.tier = t.tier AND f.assumption_version = p_assumption_version
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
-- Tier-rate algebra: unit = composite_pepm x EE / sum(enrolled x factor) = premium x members / wsum.

-- =====================================================================================
-- 2. Scenario materialization: nb_quote_scenarios (L300-02 section 2)
-- =====================================================================================
-- L300-02 form (LATERAL table-function call over a cross join of the scenario keys):
--
--   SELECT r.*, current_timestamp() AS generated_at, 'rate_new_business v1' AS method_version
--   FROM (SELECT 'GRP-NW-001' g) x
--   CROSS JOIN (VALUES (150000),(250000),(500000)) AS p(pp)
--   CROSS JOIN (VALUES ('low'),('base'),('high')) AS t(ts)
--   CROSS JOIN (VALUES ('requested'),('alternate')) AS o(po),
--   LATERAL rate_new_business(x.g, p.pp, t.ts, o.po, 'AV-2027.1') r;
--
-- That needs the warehouse to decorrelate a SQL table function whose body aggregates and filters on
-- its arguments. L300-02 names the fallback: 18 explicit calls with literal arguments. This file uses
-- the fallback because it always plans and returns the same 18 rows. To try the LATERAL form, swap
-- the SELECT below for the block above.
CREATE OR REPLACE TABLE nb_quote_scenarios
COMMENT 'Governed new business quote scenarios for Northwind Manufacturing: 3 pooling points x 3 trend scenarios x 2 plan options = 18 rows, materialized from rate_new_business() (synthetic)'
AS
SELECT r.*, current_timestamp() AS generated_at, 'rate_new_business v1' AS method_version
FROM (
  SELECT * FROM rate_new_business('GRP-NW-001', 150000, 'low',  'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 150000, 'low',  'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 150000, 'base', 'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 150000, 'base', 'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 150000, 'high', 'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 150000, 'high', 'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 250000, 'low',  'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 250000, 'low',  'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 250000, 'base', 'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 250000, 'base', 'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 250000, 'high', 'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 250000, 'high', 'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 500000, 'low',  'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 500000, 'low',  'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 500000, 'base', 'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 500000, 'base', 'alternate', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 500000, 'high', 'requested', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_new_business('GRP-NW-001', 500000, 'high', 'alternate', 'AV-2027.1')
) r;

-- =====================================================================================
-- 3. nb_quote_waterfall: 10 rating steps per scenario (L300-02 section 2)
-- =====================================================================================
CREATE OR REPLACE VIEW nb_quote_waterfall
COMMENT 'Ten-step rating waterfall (paid -> IBNR -> pooling -> experience -> projection -> manual -> credibility -> blend -> premium -> composite) for every nb_quote_scenarios row (synthetic)'
AS
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
  FROM nb_quote_scenarios);

-- =====================================================================================
-- 4. rate_renewal (L300-02 section 5)
-- =====================================================================================
-- Same method as rate_new_business, for an in-force group on its current plan (plan_option 'current'):
--   * plan relativity: the group's plan_designs row with plan_option 'current' if there is one, else 1.00
--     (the current plan is the relativity base);
--   * large claimants: the group's latest package_version (in-force groups have no broker v1/v2 split);
--   * manual rate: aggregated so a missing row yields NULL instead of dropping the result; at full
--     credibility (Z = 1) the blend is the projected experience alone, so the manual rate is not needed;
--   * recommended_rate_action = premium / current premium (incumbent_premium_pmpm) - 1.
CREATE OR REPLACE FUNCTION rate_renewal(
  p_group_id STRING COMMENT 'In-force group key, e.g. GRP-LV-002',
  p_pooling_point INT COMMENT 'Per-claimant pooling point: 150000, 250000 or 500000',
  p_trend_scenario STRING COMMENT 'low | base | high',
  p_assumption_version STRING DEFAULT 'AV-2027.1' COMMENT 'Governed assumption set')
RETURNS TABLE (
  group_id STRING COMMENT 'Group key',
  pooling_point INT COMMENT 'Per-claimant pooling point used',
  trend_scenario STRING COMMENT 'Trend scenario used (low | base | high)',
  plan_option STRING COMMENT 'Always current (renewal on the in-force plan)',
  assumption_version STRING COMMENT 'Governed assumption set used',
  paid_to_date DOUBLE COMMENT 'Experience-period claims paid to date (USD)',
  completed_claims DOUBLE COMMENT 'Paid to date completed with completion factors (USD)',
  ibnr DOUBLE COMMENT 'IBNR from completion factors = completed - paid (USD)',
  excess_pooled DOUBLE COMMENT 'Large-claimant dollars above the pooling point removed (USD)',
  pooled_claims DOUBLE COMMENT 'Completed claims net of pooled excess (USD)',
  member_months BIGINT COMMENT 'Experience-period member months',
  experience_pmpm DOUBLE COMMENT 'Historical pooled experience PMPM',
  trend_factor DOUBLE COMMENT 'Trend factor = (1 + annual trend) ^ trend years',
  plan_relativity DOUBLE COMMENT 'Benefit relativity of the current plan',
  demographic_change DOUBLE COMMENT 'Current census demo factor / experience-period demo factor',
  pooling_charge_pmpm DOUBLE COMMENT 'Pooling charge PMPM added back for the pooling point',
  projected_experience_pmpm DOUBLE COMMENT 'Projected experience incl. trend, plan, demo + pooling charge (PMPM)',
  manual_pmpm DOUBLE COMMENT 'Manual rate PMPM (NULL if the group has no manual rate factors)',
  credibility DOUBLE COMMENT 'Square-root credibility Z = min(1, sqrt(member months / full-credibility standard))',
  blended_claims_pmpm DOUBLE COMMENT 'Z x projected experience + (1 - Z) x manual (PMPM)',
  retention DOUBLE COMMENT 'Retention as share of premium',
  premium_pmpm DOUBLE COMMENT 'Renewal premium PMPM after retention',
  composite_pepm DOUBLE COMMENT 'Renewal composite rate per enrolled employee per month',
  rate_ee DOUBLE COMMENT 'Renewal monthly tier rate, employee only',
  rate_es DOUBLE COMMENT 'Renewal monthly tier rate, employee + spouse',
  rate_ec DOUBLE COMMENT 'Renewal monthly tier rate, employee + child(ren)',
  rate_ef DOUBLE COMMENT 'Renewal monthly tier rate, family',
  current_premium_pmpm DOUBLE COMMENT 'Current in-force premium PMPM',
  recommended_rate_action DOUBLE COMMENT 'Recommended renewal rate action = renewal premium PMPM / current premium PMPM - 1',
  projected_loss_ratio DOUBLE COMMENT 'Blended claims / premium')
COMMENT 'Governed large group renewal rating (synthetic demo). Same experience-rating method as rate_new_business on the in-force plan; returns the recommended rate action. The ONLY approved source of renewal rate actions.'
RETURN
WITH g   AS (SELECT * FROM groups WHERE group_id = p_group_id),
clm AS (
  SELECT SUM(c.paid_to_date) AS paid,
         SUM(c.paid_to_date * COALESCE(cf.factor, 1.0)) AS completed
  FROM claims_monthly c
  LEFT JOIN completion_factors cf
    ON cf.assumption_version = p_assumption_version
   AND cf.lag_months = CAST(months_between(c.paid_through, c.incurred_month) AS INT)
  WHERE c.group_id = p_group_id),
lcv AS (SELECT MAX(COALESCE(package_version, '')) AS v FROM large_claimants WHERE group_id = p_group_id),
lc  AS (SELECT COALESCE(SUM(GREATEST(l.total_claims - p_pooling_point, 0)), 0) AS excess
        FROM large_claimants l CROSS JOIN lcv
        WHERE l.group_id = p_group_id AND COALESCE(l.package_version, '') = lcv.v),
pp  AS (SELECT * FROM pooling_points WHERE assumption_version = p_assumption_version AND pooling_point = p_pooling_point),
tr  AS (SELECT * FROM trend_assumptions WHERE assumption_version = p_assumption_version AND trend_scenario = p_trend_scenario),
trb AS (SELECT * FROM trend_assumptions WHERE assumption_version = p_assumption_version AND trend_scenario = 'base'),
pl  AS (SELECT COALESCE(MAX(CASE WHEN plan_option = 'current' THEN relativity END), 1.0) AS relativity
        FROM plan_designs WHERE group_id = p_group_id),
mf  AS (SELECT MAX(base_manual_pmpm * area_factor * demographic_factor * industry_factor) AS manual_base
        FROM manual_rate_factors WHERE assumption_version = p_assumption_version AND group_id = p_group_id),
rt  AS (SELECT retention FROM retention_targets WHERE assumption_version = p_assumption_version),
tf  AS (SELECT MAX(CASE WHEN tier='EE' THEN tier_factor END) f_ee, MAX(CASE WHEN tier='ES' THEN tier_factor END) f_es,
               MAX(CASE WHEN tier='EC' THEN tier_factor END) f_ec, MAX(CASE WHEN tier='EF' THEN tier_factor END) f_ef
        FROM tier_factors WHERE assumption_version = p_assumption_version),
tw  AS (SELECT SUM(t.enrolled * f.tier_factor) AS wsum
        FROM group_tier_counts t
        JOIN tier_factors f ON f.tier = t.tier AND f.assumption_version = p_assumption_version
        WHERE t.group_id = p_group_id),
s1 AS (
  SELECT g.*, clm.paid, clm.completed, lc.excess, pp.pooling_charge_pmpm, pp.full_credibility_mm,
         POWER(1 + tr.annual_rate, tr.trend_years) AS trend_factor,
         POWER((1 + tr.annual_rate) / (1 + trb.annual_rate), tr.trend_years) AS manual_trend_adj,
         pl.relativity, mf.manual_base,
         rt.retention, tf.*, tw.wsum
  FROM g, clm, lc, pp, tr, trb, pl, mf, rt, tf, tw),
s2 AS (
  SELECT *, (completed - excess) / member_months AS experience_pmpm,
         (completed - excess) / member_months * trend_factor * relativity * demographic_change + pooling_charge_pmpm AS proj_exp,
         manual_base * relativity * manual_trend_adj AS manual_pmpm,
         LEAST(1.0, SQRT(member_months / full_credibility_mm)) AS z
  FROM s1),
s3 AS (
  SELECT *, CASE WHEN z >= 1.0 THEN proj_exp ELSE z * proj_exp + (1 - z) * manual_pmpm END AS blended FROM s2),
s4 AS (
  SELECT *, blended / (1 - retention) AS premium FROM s3)
SELECT group_id, p_pooling_point, p_trend_scenario, 'current', p_assumption_version,
       ROUND(paid,2), ROUND(completed,2), ROUND(completed - paid,2), ROUND(excess,2), ROUND(completed - excess,2),
       member_months, ROUND(experience_pmpm,2), ROUND(trend_factor,4), relativity, demographic_change, pooling_charge_pmpm,
       ROUND(proj_exp,2), ROUND(manual_pmpm,2), ROUND(z,4), ROUND(blended,2), retention,
       ROUND(premium,2), ROUND(premium * members / enrolled_employees,2),
       ROUND(premium * members / wsum * f_ee,2), ROUND(premium * members / wsum * f_es,2),
       ROUND(premium * members / wsum * f_ec,2), ROUND(premium * members / wsum * f_ef,2),
       ROUND(incumbent_premium_pmpm,2), ROUND(premium / incumbent_premium_pmpm - 1,4), ROUND(blended / premium,4)
FROM s4;

-- =====================================================================================
-- 5. renewal_scenarios: Lakeview Logistics renewal grid (L300-02 section 5)
-- =====================================================================================
CREATE OR REPLACE TABLE renewal_scenarios
COMMENT 'Governed renewal scenarios for Lakeview Logistics (GRP-LV-002, renewal 2027-01-01): 3 pooling points x 3 trend scenarios = 9 rows, materialized from rate_renewal() for the Lakeview renewal beat (synthetic)'
AS
SELECT r.*, current_timestamp() AS generated_at, 'rate_renewal v1' AS method_version
FROM (
  SELECT * FROM rate_renewal('GRP-LV-002', 150000, 'low',  'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 150000, 'base', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 150000, 'high', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 250000, 'low',  'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 250000, 'base', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 250000, 'high', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 500000, 'low',  'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 500000, 'base', 'AV-2027.1') UNION ALL
  SELECT * FROM rate_renewal('GRP-LV-002', 500000, 'high', 'AV-2027.1')
) r;

-- Unity Catalog governed tags (functions take no tags).
-- EXECUTE IMMEDIATE builds the SQL so :domain_tag becomes the tag key name.
DECLARE OR REPLACE VARIABLE _dt   STRING DEFAULT :domain_tag;
DECLARE OR REPLACE VARIABLE _cat  STRING DEFAULT :catalog;
DECLARE OR REPLACE VARIABLE _sch  STRING DEFAULT :schema;
DECLARE OR REPLACE VARIABLE _t    STRING;
SET VAR _t = '`' || _cat || '`.`' || _sch || '`';
DECLARE OR REPLACE VARIABLE _sql  STRING;

SET VAR _sql = 'ALTER TABLE ' || _t || '.`nb_quote_scenarios` SET TAGS (\'' || _dt || '\' = \'uw_finance\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER VIEW '  || _t || '.`nb_quote_waterfall` SET TAGS (\'' || _dt || '\' = \'uw_finance\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`renewal_scenarios` SET TAGS (\'' || _dt || '\' = \'uw_finance\')'; EXECUTE IMMEDIATE _sql;
