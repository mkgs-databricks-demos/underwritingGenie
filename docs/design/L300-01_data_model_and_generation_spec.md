# L300-01 — Data Model and Synthetic Generation Spec

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


All objects in `${catalog}.${schema}` (default `hls_fde_dev.uw_genie`). All tables tagged `domain=underwriting`, `data_class=synthetic`.

> See [diagrams/mermaid/06_data_model_er.md](../diagrams/mermaid/06_data_model_er.md).

## DDL
```sql
CREATE TABLE IF NOT EXISTS groups (
  group_id STRING NOT NULL COMMENT 'Group key, e.g. GRP-NW-001',
  group_name STRING COMMENT 'Fictional employer name',
  status STRING COMMENT 'PROSPECT | IN_FORCE',
  industry STRING, sic_code STRING, state STRING, zip3 STRING,
  enrolled_employees INT, members INT, member_months BIGINT COMMENT 'Experience-period member months',
  demographic_change DOUBLE COMMENT 'Current census demo factor / experience-period demo factor',
  incumbent_premium_pmpm DOUBLE COMMENT 'Current premium PMPM with incumbent (prospects) or current plan (in force)',
  incumbent_renewal_offer_pct DOUBLE COMMENT 'Incumbent renewal offer reported by broker (prospects)',
  effective_date DATE, broker_name STRING, broker_contact STRING, broker_email STRING
) COMMENT 'Employer groups in the synthetic Lakeside Health Plan book';

CREATE TABLE IF NOT EXISTS census_members (
  group_id STRING, member_id STRING, relationship STRING COMMENT 'EMPLOYEE|SPOUSE|CHILD',
  tier STRING COMMENT 'EE|ES|EC|EF (employee rows only)', gender STRING, birth_date DATE, zip3 STRING,
  census_version STRING COMMENT 'v1 (broker original) | v2 (corrected)'
);

CREATE OR REPLACE VIEW group_tier_counts AS
SELECT group_id, tier, COUNT(*) AS enrolled
FROM census_members WHERE relationship='EMPLOYEE' AND census_version='v2' GROUP BY ALL;

CREATE TABLE IF NOT EXISTS claims_monthly (
  group_id STRING, incurred_month DATE COMMENT 'First of month', paid_through DATE COMMENT 'First of paid-through month',
  service_category STRING COMMENT 'MEDICAL|RX', paid_to_date DOUBLE, basis STRING COMMENT 'INCURRED|PAID'
);

CREATE TABLE IF NOT EXISTS large_claimants (
  group_id STRING, claimant_id STRING, condition_category STRING, status STRING COMMENT 'ACTIVE|ONGOING|RESOLVED|UNKNOWN',
  total_claims DOUBLE COMMENT 'Experience-period total paid', package_version STRING
);

CREATE TABLE IF NOT EXISTS plan_designs (group_id STRING, plan_option STRING COMMENT 'requested|alternate',
  plan_name STRING, deductible_ind INT, oop_max_ind INT, coinsurance DOUBLE, relativity DOUBLE);

CREATE TABLE IF NOT EXISTS completion_factors (assumption_version STRING, lag_months INT, factor DOUBLE);
CREATE TABLE IF NOT EXISTS trend_assumptions (assumption_version STRING, trend_scenario STRING, annual_rate DOUBLE, trend_years DOUBLE);
CREATE TABLE IF NOT EXISTS pooling_points (assumption_version STRING, pooling_point INT, pooling_charge_pmpm DOUBLE, full_credibility_mm BIGINT);
CREATE TABLE IF NOT EXISTS manual_rate_factors (assumption_version STRING, group_id STRING, base_manual_pmpm DOUBLE,
  area_factor DOUBLE, demographic_factor DOUBLE, industry_factor DOUBLE);
CREATE TABLE IF NOT EXISTS retention_targets (assumption_version STRING, retention DOUBLE, target_loss_ratio DOUBLE);
CREATE TABLE IF NOT EXISTS tier_factors (assumption_version STRING, tier STRING, tier_factor DOUBLE);
CREATE TABLE IF NOT EXISTS persistency_curve (rate_action_band STRING, band_min DOUBLE, band_max DOUBLE, persistency DOUBLE);

CREATE TABLE IF NOT EXISTS renewal_pipeline (
  group_id STRING, industry STRING, renewal_date DATE, renewal_quarter STRING, size_band STRING,
  current_annual_premium DOUBLE, projected_annual_claims DOUBLE, recommended_rate_action DOUBLE,
  new_large_claimant_flag BOOLEAN, prebuilt BOOLEAN, quote_due_date DATE, owner STRING);

CREATE TABLE IF NOT EXISTS broker_submissions (
  submission_id STRING, group_id STRING, broker_name STRING, received_ts TIMESTAMP, package_version STRING,
  completeness_status STRING COMMENT 'READY|READY_WITH_WARNINGS|BLOCKED', top_missing_item STRING, owner STRING);

CREATE TABLE IF NOT EXISTS submission_findings (
  submission_id STRING, item_id STRING, finding STRING COMMENT 'PRESENT|MISSING|PARTIAL', evidence STRING, created_ts TIMESTAMP);

CREATE TABLE IF NOT EXISTS trend_monitor (
  metric STRING, period STRING, actual_annual_trend DOUBLE, assumed_annual_trend DOUBLE, assumption_version STRING);

CREATE TABLE IF NOT EXISTS intake_checklist (
  item_id STRING, item_name STRING, severity STRING COMMENT 'BLOCKING|WARNING', rule_text STRING, broker_ask_template STRING);
```

## Pinned values (must match exactly)
| Object | Pinned content |
|---|---|
| groups / Northwind | `GRP-NW-001`, "Northwind Manufacturing", PROSPECT, Manufacturing, SIC 3599, 420 EEs, 980 members, 23,520 MM, demographic_change 1.010, incumbent_premium_pmpm 612.00, incumbent_renewal_offer_pct 0.142, effective 2027-01-01, broker "Harbor Benefits Partners", contact "Jordan Ellis" |
| census v2 tiers | EE 168, ES 76, EC 59, EF 117 |
| claims_monthly / Northwind | 24 rows (incurred 2024-07-01 … 2026-06-01, paid_through 2026-08-01), paid_to_date 436,666.67 each (sum 10,480,000), basis INCURRED in v2 (PAID, only 15 months, in v1 file) |
| large_claimants / Northwind | LC-01 Neonatal intensive care RESOLVED 612,000 · LC-02 Oncology ACTIVE 410,000 · LC-03 Hemophilia (specialty Rx) ONGOING 268,000 · LC-04 Orthopedic surgery RESOLVED 185,000 (v1: LC-02..04 status UNKNOWN) |
| plan_designs / Northwind | requested "Choice PPO 1000" relativity 1.00; alternate "Choice PPO 2500" relativity 0.94 |
| completion_factors AV-2027.1 | lag 2:1.120, 3:1.060, 4:1.035, 5:1.020, 6:1.012, 7:1.006 (others 1.000) |
| trend_assumptions AV-2027.1 | low 0.075, base 0.090, high 0.105; trend_years 2.0 |
| pooling_points AV-2027.1 | 150000: 38.00 / 30000 · 250000: 24.00 / 42000 · 500000: 11.00 / 60000 |
| manual_rate_factors | Northwind: 520.00, 1.04, 1.06, 1.03 |
| retention_targets | 0.12 / 0.88 |
| tier_factors | EE 1.00, ES 2.00, EC 1.85, EF 2.85 |
| persistency_curve | <0%:0.97, 0–5%:0.94, 5–10%:0.90, 10–15%:0.82, 15–20%:0.70, >20%:0.55 |
| Lakeview Logistics | `GRP-LV-002`, IN_FORCE, 3,200 lives, renewal 2027-01-01, two large claimants (one resolved) |

## Random book (seed 2027)
58 additional in-force groups 60–2,500 EEs; renewal dates spread across Q1–Q2 2027; recommended_rate_action ~ N(0.085, 0.05) clipped [−0.05, 0.30]; 6 groups with new_large_claimant_flag; one signal row in `trend_monitor` (Rx PMPM trend 13.4% vs 11.0% assumption).

## Intake checklist (14 items)
BLOCKING: 24 months experience; incurred basis or lag report; census with DOB, gender, tier, ZIP for all employees; large claimant report with status; benefit summary for requested plan(s); requested effective date; current rates. WARNING: renewal offer from incumbent; contribution strategy; prior plan changes; COBRA/retiree counts; RFP questionnaire; network preference; Rx carve-out status.
