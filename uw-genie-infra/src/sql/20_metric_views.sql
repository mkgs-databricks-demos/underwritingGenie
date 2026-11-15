-- 20_metric_views.sql — Underwriting Genie: renewal_book_scenarios view + 3 certified metric views (L300-03 sections 1-2).
-- Runs as a SQL file task on the bundle warehouse after build_nb_quote_scenarios
-- (nb_quote_scenarios comes from 10_rate_new_business.sql; the other sources from 00_ddl.sql).
-- Parameters (from the job): :catalog, :schema (default hls_fde_dev / uw_genie).
-- Metric view YAML cannot take parameter markers and its table source must be a three-part name,
-- so each metric view DDL is a template whose __FQ__ token is replaced with the backtick-quoted
-- catalog.schema (double-quoted in YAML: a plain scalar cannot start with a backtick) and run with EXECUTE IMMEDIATE. All text inside the templates avoids apostrophes;
-- SQL string literals inside YAML expressions are escaped as \'.
-- CREATE OR REPLACE keeps setup idempotent (setup_demo rebuilds everything; grants are reapplied by the bundle/job).
-- Tags applied via EXECUTE IMMEDIATE (:domain_tag SQL named parameter as tag key).
-- certified=true on the three metric views.
-- Measure and column comments follow docs/semantics/01-03.

USE CATALOG IDENTIFIER(:catalog);
USE SCHEMA IDENTIFIER(:schema);

-- Backtick-quoted catalog.schema for the metric view sources (embedded backticks doubled).
DECLARE OR REPLACE VARIABLE uw_fq STRING;
SET VAR uw_fq = '`' || replace(:catalog, '`', '``') || '`.`' || replace(:schema, '`', '``') || '`';
DECLARE OR REPLACE VARIABLE uw_sql STRING;

-- 1. renewal_book_scenarios: renewal pipeline with uncapped and 12%-capped rate actions,
--    persistency for each (persistency_curve band lookup) and the resulting renewal premium.
CREATE OR REPLACE VIEW renewal_book_scenarios (
  group_id COMMENT 'Group key',
  industry COMMENT 'Industry of the employer group',
  renewal_date COMMENT 'Renewal effective date',
  renewal_quarter COMMENT 'Renewal quarter, e.g. 2027-Q1',
  size_band COMMENT 'Group size band',
  current_annual_premium COMMENT 'Current annual premium',
  projected_annual_claims COMMENT 'Projected annual claims for the renewal period',
  recommended_rate_action COMMENT 'Rate Action: recommended renewal premium change for an existing group (uncapped)',
  new_large_claimant_flag COMMENT 'True if a new large claimant emerged',
  prebuilt COMMENT 'True if the renewal is prebuilt',
  quote_due_date COMMENT 'Renewal quote due date',
  owner COMMENT 'Assigned underwriter (fictional)',
  capped_rate_action COMMENT 'Recommended rate action capped at +12% (LEAST(recommended_rate_action, 0.12))',
  persistency_uncapped COMMENT 'Persistency: probability the group renews at the uncapped rate action band',
  persistency_capped COMMENT 'Persistency: probability the group renews at the 12%-capped rate action band',
  renewal_premium_uncapped COMMENT 'Current annual premium x (1 + recommended rate action)',
  renewal_premium_capped COMMENT 'Current annual premium x (1 + capped rate action)'
)
COMMENT 'Renewal book scenarios (synthetic): renewal pipeline joined to the persistency curve at the uncapped and 12%-capped rate actions. Source of mv_renewal_book.'
AS
SELECT r.*,
       LEAST(r.recommended_rate_action, 0.12) AS capped_rate_action,
       pu.persistency AS persistency_uncapped,
       pc.persistency AS persistency_capped,
       r.current_annual_premium * (1 + r.recommended_rate_action) AS renewal_premium_uncapped,
       r.current_annual_premium * (1 + LEAST(r.recommended_rate_action, 0.12)) AS renewal_premium_capped
FROM renewal_pipeline r
JOIN persistency_curve pu
  ON r.recommended_rate_action >= pu.band_min AND r.recommended_rate_action < pu.band_max
JOIN persistency_curve pc
  ON LEAST(r.recommended_rate_action, 0.12) >= pc.band_min AND LEAST(r.recommended_rate_action, 0.12) < pc.band_max;

DECLARE OR REPLACE VARIABLE _dt   STRING DEFAULT :domain_tag;
DECLARE OR REPLACE VARIABLE _cat  STRING DEFAULT :catalog;
DECLARE OR REPLACE VARIABLE _sch  STRING DEFAULT :schema;
DECLARE OR REPLACE VARIABLE _t    STRING;
SET VAR _t = '`' || _cat || '`.`' || _sch || '`';
DECLARE OR REPLACE VARIABLE _sql  STRING;
SET VAR _sql = 'ALTER VIEW ' || _t || '.`renewal_book_scenarios` SET TAGS (''' || _dt || ''' = ''uw_finance'')'; EXECUTE IMMEDIATE _sql;

-- 2. mv_renewal_book (over renewal_book_scenarios)
SET VAR uw_sql = replace('
CREATE OR REPLACE VIEW mv_renewal_book
WITH METRICS
LANGUAGE YAML
AS $$
version: 1.1
comment: "Large group renewal book outcomes (synthetic). Loss ratio = completed incurred, pooled claims / premium; target 88%."
source: "__FQ__.renewal_book_scenarios"
dimensions:
  - name: Renewal Quarter
    expr: renewal_quarter
    comment: "Renewal quarter, e.g. 2027-Q1"
  - name: Size Band
    expr: size_band
    comment: "Group size band"
  - name: Industry
    expr: industry
measures:
  - name: Renewing Premium
    expr: SUM(current_annual_premium)
    comment: "Current annual premium of the groups up for renewal"
    format:
      type: currency
      currency_code: USD
      abbreviation: compact
  - name: Projected Loss Ratio (Uncapped)
    expr: SUM(projected_annual_claims) / SUM(renewal_premium_uncapped)
    comment: "Projected Loss Ratio: projected claims / renewal premium at recommended rate actions (uncapped). Compare to the 88% target loss ratio."
    synonyms: ["projected loss ratio", "loss ratio uncapped"]
    format:
      type: percentage
      decimal_places: {type: exact, places: 1}
  - name: Projected Loss Ratio (12% Cap)
    expr: SUM(projected_annual_claims) / SUM(renewal_premium_capped)
    comment: "Projected Loss Ratio: projected claims / renewal premium with rate actions capped at +12%"
    synonyms: ["loss ratio capped", "capped loss ratio"]
    format:
      type: percentage
      decimal_places: {type: exact, places: 1}
  - name: Target Loss Ratio
    expr: ANY_VALUE(0.88)
    comment: "Target Loss Ratio: 1 - retention; expected claims share of premium (demo 88%, retention 12%). Must respect large group MLR >= 85%."
    synonyms: ["target LR"]
    format:
      type: percentage
      decimal_places: {type: exact, places: 1}
  - name: Premium at Risk (Uncapped)
    expr: SUM(renewal_premium_uncapped * (1 - persistency_uncapped))
    comment: "Premium at Risk: renewal premium expected to lapse, persistency-weighted, at recommended (uncapped) rate actions"
    synonyms: ["premium at risk", "lapse premium"]
    format:
      type: currency
      currency_code: USD
      abbreviation: compact
  - name: Premium at Risk (12% Cap)
    expr: SUM(renewal_premium_capped * (1 - persistency_capped))
    comment: "Premium at Risk: renewal premium expected to lapse, persistency-weighted, with rate actions capped at +12%"
    synonyms: ["capped premium at risk"]
    format:
      type: currency
      currency_code: USD
      abbreviation: compact
  - name: Avg Recommended Rate Action
    expr: AVG(recommended_rate_action)
    comment: "Rate Action: average recommended renewal premium change (uncapped)"
    synonyms: ["rate action", "average rate increase"]
    format:
      type: percentage
      decimal_places: {type: exact, places: 1}
$$', '__FQ__', uw_fq);
EXECUTE IMMEDIATE uw_sql;

-- 3. mv_quote_outcomes (over nb_quote_scenarios, the 18 governed rate_new_business() scenarios)
SET VAR uw_sql = replace('
CREATE OR REPLACE VIEW mv_quote_outcomes
WITH METRICS
LANGUAGE YAML
AS $$
version: 1.1
comment: "New business quote outcomes (synthetic): the 18 precomputed scenarios (3 pooling points x 3 trend scenarios x 2 plan options) from the governed rate_new_business() function. The only approved source of quoted rates."
source: "__FQ__.nb_quote_scenarios"
dimensions:
  - name: Group
    expr: group_id
    comment: "Group key, e.g. GRP-NW-001"
  - name: Pooling Point
    expr: pooling_point
    comment: "Pooling Point: per-claimant annual threshold above which claims are removed from the experience (150000, 250000 or 500000)"
  - name: Trend Scenario
    expr: trend_scenario
    comment: "Trend scenario: low (7.5%), base (9.0%) or high (10.5%) annual trend"
  - name: Plan Option
    expr: plan_option
    comment: "requested or alternate plan design (alternate-deductible relativity 0.94)"
measures:
  - name: Premium PMPM
    expr: AVG(premium_pmpm)
    comment: "Quoted premium per member per month from rate_new_business(): blended claims loaded for 12% retention"
    synonyms: ["rate PMPM", "premium per member per month"]
    format:
      type: currency
      currency_code: USD
      decimal_places: {type: exact, places: 2}
  - name: Composite PEPM
    expr: AVG(composite_pepm)
    comment: "Composite Rate (PEPM): average premium per enrolled employee per month across tiers; basis for tier rates"
    synonyms: ["composite rate", "PEPM"]
    format:
      type: currency
      currency_code: USD
      decimal_places: {type: exact, places: 2}
  - name: Credibility
    expr: AVG(credibility)
    comment: "Credibility (Z): weight (0-1) on projected experience vs the manual rate; Z = min(1, sqrt(member months / full-credibility standard))"
    synonyms: ["Z", "credibility factor"]
    format:
      type: number
      decimal_places: {type: exact, places: 4}
  - name: Rate Change vs Current
    expr: AVG(rate_change_vs_incumbent)
    comment: "Rate Change vs Current: quoted premium PMPM / incumbent current premium PMPM - 1"
    synonyms: ["premium change vs current", "rate change vs incumbent"]
    format:
      type: percentage
      decimal_places: {type: exact, places: 1}
  - name: Projected Loss Ratio
    expr: AVG(projected_loss_ratio)
    comment: "Projected Loss Ratio: expected blended claims / quoted premium for the rating period; compare to the 88% target loss ratio"
    synonyms: ["loss ratio", "projected LR"]
    format:
      type: percentage
      decimal_places: {type: exact, places: 1}
$$', '__FQ__', uw_fq);
EXECUTE IMMEDIATE uw_sql;

-- 4. mv_intake_ops (over broker_submissions)
SET VAR uw_sql = replace('
CREATE OR REPLACE VIEW mv_intake_ops
WITH METRICS
LANGUAGE YAML
AS $$
version: 1.1
comment: "New business intake operations (synthetic): broker submissions and submission completeness against the intake checklist."
source: "__FQ__.broker_submissions"
dimensions:
  - name: Broker
    expr: broker_name
    comment: "Fictional broker firm"
  - name: Status
    expr: completeness_status
    comment: "Submission Completeness: READY, READY_WITH_WARNINGS or BLOCKED against the intake checklist"
    synonyms: ["completeness status", "ready to quote"]
  - name: Week
    expr: date_trunc(\'WEEK\', received_ts)
    comment: "Week the package was received"
    format:
      type: date
      date_format: year_week
measures:
  - name: Submissions
    expr: COUNT(1)
    comment: "Broker Submission: number of packages received (each package version counts once)"
  - name: Pct Complete First Pass
    expr: AVG(CASE WHEN package_version = \'v1\' AND completeness_status <> \'BLOCKED\' THEN 1.0 ELSE 0.0 END)
    comment: "Share of submissions whose first package (v1) was not BLOCKED, i.e. ready to quote on first pass"
    synonyms: ["first pass completeness", "first pass rate"]
    format:
      type: percentage
      decimal_places: {type: exact, places: 1}
  - name: Blocked Submissions
    expr: SUM(CASE WHEN completeness_status = \'BLOCKED\' THEN 1 ELSE 0 END)
    comment: "Submissions with at least one missing Blocking Item (must be present before rating)"
    synonyms: ["blocked"]
$$', '__FQ__', uw_fq);
EXECUTE IMMEDIATE uw_sql;

-- 5. Certified + governance tags on the metric views.
SET VAR _sql = 'ALTER VIEW ' || _t || '.`mv_renewal_book` SET TAGS (''certified'' = ''true'', ''' || _dt || ''' = ''uw_finance'')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER VIEW ' || _t || '.`mv_quote_outcomes` SET TAGS (''certified'' = ''true'', ''' || _dt || ''' = ''intake_quote'')'; EXECUTE IMMEDIATE _sql;
SET VAR _sql = 'ALTER VIEW ' || _t || '.`mv_intake_ops` SET TAGS (''certified'' = ''true'', ''' || _dt || ''' = ''intake_quote'')'; EXECUTE IMMEDIATE _sql;
