-- 00_ddl.sql — Underwriting Genie: all 18 base objects (17 tables + 1 view) from L300-01.
-- Runs as the setup_demo create_tables SQL file task on the bundle warehouse.
-- Parameters (from the job): :catalog, :schema (default hls_fde_dev / uw_genie).
-- CREATE OR REPLACE makes setup idempotent: every run rebuilds empty tables, then
-- generate_synthetic_book reloads them. Derived objects (rate_new_business,
-- nb_quote_scenarios, nb_quote_waterfall, renewal_book_scenarios, metric views)
-- live in 10_rate_new_business.sql and 20_metric_views.sql.
-- Tags applied via EXECUTE IMMEDIATE at the end (domain_tag is a SQL named parameter;
-- do not put double-curly param placeholders in this file, even in comments: the SQL file
-- task substitutes them as raw text, which broke quoting in setup_demo run 663765351824011).

USE CATALOG IDENTIFIER(:catalog);
USE SCHEMA IDENTIFIER(:schema);

-- 1. groups
CREATE OR REPLACE TABLE groups (
  group_id STRING NOT NULL COMMENT 'Group key, e.g. GRP-NW-001',
  group_name STRING COMMENT 'Fictional employer name',
  status STRING COMMENT 'PROSPECT | IN_FORCE',
  industry STRING COMMENT 'Industry of the employer group',
  sic_code STRING COMMENT 'Standard Industrial Classification code',
  state STRING COMMENT 'Situs state',
  zip3 STRING COMMENT 'First three digits of the situs ZIP code',
  enrolled_employees INT COMMENT 'Enrolled employees',
  members INT COMMENT 'Enrolled members (employees and dependents)',
  member_months BIGINT COMMENT 'Experience-period member months',
  demographic_change DOUBLE COMMENT 'Current census demo factor / experience-period demo factor',
  incumbent_premium_pmpm DOUBLE COMMENT 'Current premium PMPM with incumbent (prospects) or current plan (in force)',
  incumbent_renewal_offer_pct DOUBLE COMMENT 'Incumbent renewal offer reported by broker (prospects)',
  effective_date DATE COMMENT 'Requested or current effective date',
  broker_name STRING COMMENT 'Fictional broker firm',
  broker_contact STRING COMMENT 'Fictional broker contact',
  broker_email STRING COMMENT 'Broker email (.example domain only)'
)
COMMENT 'Employer groups in the synthetic Lakeside Health Plan book';

-- 2. census_members
CREATE OR REPLACE TABLE census_members (
  group_id STRING COMMENT 'Group key',
  member_id STRING COMMENT 'Synthetic member key',
  relationship STRING COMMENT 'EMPLOYEE|SPOUSE|CHILD',
  tier STRING COMMENT 'EE|ES|EC|EF (employee rows only)',
  gender STRING COMMENT 'Member gender',
  birth_date DATE COMMENT 'Synthetic birth date',
  zip3 STRING COMMENT 'First three digits of the member ZIP code',
  census_version STRING COMMENT 'v1 (broker original) | v2 (corrected)'
)
COMMENT 'Member-level census per group and census version (synthetic)';

-- 3. group_tier_counts (view)
CREATE OR REPLACE VIEW group_tier_counts
COMMENT 'Enrolled employees by coverage tier from the corrected (v2) census'
AS
SELECT group_id, tier, COUNT(*) AS enrolled
FROM census_members
WHERE relationship = 'EMPLOYEE' AND census_version = 'v2'
GROUP BY ALL;

-- 4. claims_monthly
CREATE OR REPLACE TABLE claims_monthly (
  group_id STRING COMMENT 'Group key',
  incurred_month DATE COMMENT 'First of month',
  paid_through DATE COMMENT 'First of paid-through month',
  service_category STRING COMMENT 'MEDICAL|RX|ALL (ALL = medical + Rx total)',
  paid_to_date DOUBLE COMMENT 'Claims paid to date for the incurred month',
  basis STRING COMMENT 'INCURRED|PAID'
)
COMMENT 'Monthly claims experience per group (synthetic)';

-- 5. large_claimants
CREATE OR REPLACE TABLE large_claimants (
  group_id STRING COMMENT 'Group key',
  claimant_id STRING COMMENT 'Synthetic large claimant key, e.g. LC-01',
  condition_category STRING COMMENT 'Clinical condition category',
  status STRING COMMENT 'ACTIVE|ONGOING|RESOLVED|UNKNOWN',
  total_claims DOUBLE COMMENT 'Experience-period total paid',
  package_version STRING COMMENT 'Broker package version the row came from (v1|v2)'
)
COMMENT 'Large claimant report per group and package version (synthetic)';

-- 6. plan_designs
CREATE OR REPLACE TABLE plan_designs (
  group_id STRING COMMENT 'Group key',
  plan_option STRING COMMENT 'requested|alternate',
  plan_name STRING COMMENT 'Plan name',
  deductible_ind INT COMMENT 'Individual deductible',
  oop_max_ind INT COMMENT 'Individual out-of-pocket maximum',
  coinsurance DOUBLE COMMENT 'Member coinsurance',
  relativity DOUBLE COMMENT 'Benefit relativity vs the requested plan'
)
COMMENT 'Requested and alternate plan designs per group';

-- 7. completion_factors
CREATE OR REPLACE TABLE completion_factors (
  assumption_version STRING COMMENT 'Assumption set, e.g. AV-2027.1',
  lag_months INT COMMENT 'Months between incurred month and paid-through month',
  factor DOUBLE COMMENT 'Completion (IBNR) factor'
)
COMMENT 'Claims completion factors by lag (assumption table)';

-- 8. trend_assumptions
CREATE OR REPLACE TABLE trend_assumptions (
  assumption_version STRING COMMENT 'Assumption set, e.g. AV-2027.1',
  trend_scenario STRING COMMENT 'low|base|high',
  annual_rate DOUBLE COMMENT 'Annual medical trend rate',
  trend_years DOUBLE COMMENT 'Years of trend from experience midpoint to rating midpoint'
)
COMMENT 'Trend scenarios (assumption table)';

-- 9. pooling_points
CREATE OR REPLACE TABLE pooling_points (
  assumption_version STRING COMMENT 'Assumption set, e.g. AV-2027.1',
  pooling_point INT COMMENT 'Large claim pooling point (per claimant)',
  pooling_charge_pmpm DOUBLE COMMENT 'Pooling charge PMPM added back',
  full_credibility_mm BIGINT COMMENT 'Member months for full credibility at this pooling point'
)
COMMENT 'Pooling points, pooling charges and full-credibility standards (assumption table)';

-- 10. manual_rate_factors
CREATE OR REPLACE TABLE manual_rate_factors (
  assumption_version STRING COMMENT 'Assumption set, e.g. AV-2027.1',
  group_id STRING COMMENT 'Group key',
  base_manual_pmpm DOUBLE COMMENT 'Base manual rate PMPM',
  area_factor DOUBLE COMMENT 'Area factor',
  demographic_factor DOUBLE COMMENT 'Demographic factor',
  industry_factor DOUBLE COMMENT 'Industry factor'
)
COMMENT 'Manual rate inputs per group (assumption table)';

-- 11. retention_targets
CREATE OR REPLACE TABLE retention_targets (
  assumption_version STRING COMMENT 'Assumption set, e.g. AV-2027.1',
  retention DOUBLE COMMENT 'Retention (administration, risk and margin) as share of premium',
  target_loss_ratio DOUBLE COMMENT 'Target loss ratio = 1 - retention'
)
COMMENT 'Retention and target loss ratio (assumption table)';

-- 12. tier_factors
CREATE OR REPLACE TABLE tier_factors (
  assumption_version STRING COMMENT 'Assumption set, e.g. AV-2027.1',
  tier STRING COMMENT 'EE|ES|EC|EF',
  tier_factor DOUBLE COMMENT 'Tier rating factor relative to EE'
)
COMMENT 'Coverage tier factors (assumption table)';

-- 13. persistency_curve
CREATE OR REPLACE TABLE persistency_curve (
  rate_action_band STRING COMMENT 'Rate action band label, e.g. 0-5%',
  band_min DOUBLE COMMENT 'Band lower bound (rate action)',
  band_max DOUBLE COMMENT 'Band upper bound (rate action)',
  persistency DOUBLE COMMENT 'Expected share of groups that renew at this rate action'
)
COMMENT 'Renewal persistency by rate action band (assumption table)';

-- 14. renewal_pipeline
CREATE OR REPLACE TABLE renewal_pipeline (
  group_id STRING COMMENT 'Group key',
  industry STRING COMMENT 'Industry of the employer group',
  renewal_date DATE COMMENT 'Renewal effective date',
  renewal_quarter STRING COMMENT 'Renewal quarter, e.g. 2027-Q1',
  size_band STRING COMMENT 'Group size band',
  current_annual_premium DOUBLE COMMENT 'Current annual premium',
  projected_annual_claims DOUBLE COMMENT 'Projected annual claims for the renewal period',
  recommended_rate_action DOUBLE COMMENT 'Recommended renewal rate action',
  new_large_claimant_flag BOOLEAN COMMENT 'True if a new large claimant emerged',
  prebuilt BOOLEAN COMMENT 'True if the renewal is prebuilt',
  quote_due_date DATE COMMENT 'Renewal quote due date',
  owner STRING COMMENT 'Assigned underwriter (fictional)'
)
COMMENT 'In-force renewal pipeline (synthetic)';

-- 15. broker_submissions
CREATE OR REPLACE TABLE broker_submissions (
  submission_id STRING COMMENT 'Submission key',
  group_id STRING COMMENT 'Group key',
  broker_name STRING COMMENT 'Fictional broker firm',
  received_ts TIMESTAMP COMMENT 'Time the package was received',
  package_version STRING COMMENT 'Broker package version (v1|v2)',
  completeness_status STRING COMMENT 'READY|READY_WITH_WARNINGS|BLOCKED',
  top_missing_item STRING COMMENT 'Most important missing checklist item',
  owner STRING COMMENT 'Assigned intake owner (fictional)'
)
COMMENT 'New business broker submissions and intake completeness status (synthetic)';

-- 16. submission_findings
CREATE OR REPLACE TABLE submission_findings (
  submission_id STRING COMMENT 'Submission key',
  item_id STRING COMMENT 'Intake checklist item key',
  finding STRING COMMENT 'PRESENT|MISSING|PARTIAL',
  evidence STRING COMMENT 'Evidence for the finding (file, page, field)',
  created_ts TIMESTAMP COMMENT 'Time the finding was recorded'
)
COMMENT 'Intake checklist findings per submission (written during the demo; truncated by reset_demo)';

-- 17. trend_monitor
CREATE OR REPLACE TABLE trend_monitor (
  metric STRING COMMENT 'Monitored metric, e.g. Rx PMPM trend',
  period STRING COMMENT 'Observation period',
  actual_annual_trend DOUBLE COMMENT 'Observed annual trend',
  assumed_annual_trend DOUBLE COMMENT 'Annual trend in the assumption set',
  assumption_version STRING COMMENT 'Assumption set, e.g. AV-2027.1'
)
COMMENT 'Actual vs assumed trend signals for the morning brief (synthetic)';

-- 18. intake_checklist
CREATE OR REPLACE TABLE intake_checklist (
  item_id STRING COMMENT 'Checklist item key',
  item_name STRING COMMENT 'Checklist item name',
  severity STRING COMMENT 'BLOCKING|WARNING',
  rule_text STRING COMMENT 'Rule used to judge the item',
  broker_ask_template STRING COMMENT 'Template for the broker follow-up ask'
)
COMMENT 'Large group new business intake checklist (14 items)';

-- Unity Catalog governed tags — EXECUTE IMMEDIATE builds the SQL so :domain_tag
-- (a SQL named parameter) becomes the tag key name after string substitution.
DECLARE OR REPLACE VARIABLE _dt   STRING DEFAULT :domain_tag;
DECLARE OR REPLACE VARIABLE _cat  STRING DEFAULT :catalog;
DECLARE OR REPLACE VARIABLE _sch  STRING DEFAULT :schema;
DECLARE OR REPLACE VARIABLE _t    STRING;
SET VAR _t = '`' || _cat || '`.`' || _sch || '`';
DECLARE OR REPLACE VARIABLE _sql  STRING;

SET VAR _sql = 'ALTER TABLE ' || _t || '.`groups` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`census_members` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER VIEW '  || _t || '.`group_tier_counts` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`claims_monthly` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`large_claimants` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`plan_designs` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`completion_factors` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`trend_assumptions` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`pooling_points` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`manual_rate_factors` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`retention_targets` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`tier_factors` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`persistency_curve` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`renewal_pipeline` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`broker_submissions` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`submission_findings` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`trend_monitor` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER TABLE ' || _t || '.`intake_checklist` SET TAGS (\'' || _dt || '\' = \'core\')'; EXECUTE IMMEDIATE _sql;
