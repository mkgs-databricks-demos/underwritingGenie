# L300-03 — Metric Views, UC Pages and Genie Agent Configuration

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## 1. Supporting view for renewal finance
```sql
CREATE OR REPLACE VIEW ${catalog}.${schema}.renewal_book_scenarios AS
SELECT r.*, LEAST(r.recommended_rate_action, 0.12) AS capped_rate_action,
       pu.persistency AS persistency_uncapped, pc.persistency AS persistency_capped,
       r.current_annual_premium * (1 + r.recommended_rate_action) AS renewal_premium_uncapped,
       r.current_annual_premium * (1 + LEAST(r.recommended_rate_action, 0.12)) AS renewal_premium_capped
FROM ${catalog}.${schema}.renewal_pipeline r
JOIN ${catalog}.${schema}.persistency_curve pu ON r.recommended_rate_action >= pu.band_min AND r.recommended_rate_action < pu.band_max
JOIN ${catalog}.${schema}.persistency_curve pc ON LEAST(r.recommended_rate_action,0.12) >= pc.band_min AND LEAST(r.recommended_rate_action,0.12) < pc.band_max;
```

## 2. Metric views (YAML)
```yaml
# mv_renewal_book
version: 1.1
comment: "Large group renewal book outcomes (synthetic). Loss ratio = completed incurred, pooled claims / premium; target 88%."
source: ${catalog}.${schema}.renewal_book_scenarios
dimensions:
  - name: Renewal Quarter
    expr: renewal_quarter
  - name: Size Band
    expr: size_band
  - name: Industry
    expr: industry
measures:
  - name: Renewing Premium
    expr: SUM(current_annual_premium)
  - name: Projected Loss Ratio (Uncapped)
    expr: SUM(projected_annual_claims) / SUM(renewal_premium_uncapped)
    comment: "Projected claims / renewal premium at recommended rate actions"
  - name: Projected Loss Ratio (12% Cap)
    expr: SUM(projected_annual_claims) / SUM(renewal_premium_capped)
  - name: Target Loss Ratio
    expr: ANY_VALUE(0.88)
  - name: Premium at Risk (Uncapped)
    expr: SUM(renewal_premium_uncapped * (1 - persistency_uncapped))
    comment: "Renewal premium expected to lapse, persistency-weighted"
  - name: Premium at Risk (12% Cap)
    expr: SUM(renewal_premium_capped * (1 - persistency_capped))
  - name: Avg Recommended Rate Action
    expr: AVG(recommended_rate_action)
```
```yaml
# mv_quote_outcomes
version: 1.1
source: ${catalog}.${schema}.nb_quote_scenarios
dimensions:
  - {name: Group, expr: group_id}
  - {name: Pooling Point, expr: pooling_point}
  - {name: Trend Scenario, expr: trend_scenario}
  - {name: Plan Option, expr: plan_option}
measures:
  - {name: Premium PMPM, expr: AVG(premium_pmpm)}
  - {name: Composite PEPM, expr: AVG(composite_pepm)}
  - {name: Credibility, expr: AVG(credibility)}
  - {name: Rate Change vs Current, expr: AVG(rate_change_vs_incumbent)}
  - {name: Projected Loss Ratio, expr: AVG(projected_loss_ratio)}
```
```yaml
# mv_intake_ops
version: 1.1
source: ${catalog}.${schema}.broker_submissions
dimensions:
  - {name: Broker, expr: broker_name}
  - {name: Status, expr: completeness_status}
  - {name: Week, expr: "date_trunc('WEEK', received_ts)"}
measures:
  - {name: Submissions, expr: COUNT(1)}
  - {name: Pct Complete First Pass, expr: "AVG(CASE WHEN package_version='v1' AND completeness_status<>'BLOCKED' THEN 1.0 ELSE 0.0 END)"}
  - {name: Blocked Submissions, expr: "SUM(CASE WHEN completeness_status='BLOCKED' THEN 1 ELSE 0 END)"}
```

## 3. UC Pages
Publish every term in `semantics/01–03` as a UC Page under domain **Underwriting**, subdomains Rating & Experience / Intake & Quote / Underwriting Finance; link each to its table/column/measure.

## 4. Genie Agent — "Underwriting Genie"
**Description:** Underwriting coworker for Lakeside Health Plan large group business (synthetic). Answers questions about broker submissions, new business quotes, renewals and book outcomes using governed rating results.

**Data:** all C1 tables (except raw volume), `nb_quote_scenarios`, `nb_quote_waterfall`, `renewal_scenarios`, three metric views. **Trusted assets:** `rate_new_business`, `rate_renewal`, example SQL below.

**General instructions**
```
- All data is synthetic for Lakeside Health Plan. Say "synthetic" if asked about data origin.
- Quoted rates, credibility, pooling and trend results come ONLY from nb_quote_scenarios / rate_new_business
  or renewal_scenarios / rate_renewal. Never derive rates with ad-hoc arithmetic.
- Default scenario: pooling_point 250000, trend_scenario 'base', plan_option 'requested', assumption_version 'AV-2027.1'.
- "Loss ratio" = completed incurred, pooled claims / premium. Target loss ratio = 88%. Large group MLR floor = 85% (book level).
- "Premium at risk" = persistency-weighted lapsing renewal premium (mv_renewal_book).
- "Rate change" for prospects compares to incumbent current premium; also mention incumbent_renewal_offer_pct when relevant.
- Tier codes: EE=Employee only, ES=Employee+Spouse, EC=Employee+Child(ren), EF=Family.
- Format money with $ and 2 decimals for rates; percentages with 1 decimal.
```
**Example SQL (titles = typical questions)**
1. *What are the recommended tier rates for {group} at a {pooling_point} pooling point?* → `SELECT rate_ee, rate_es, rate_ec, rate_ef, composite_pepm, premium_pmpm FROM nb_quote_scenarios WHERE group_id=:group_id AND pooling_point=:pooling_point AND trend_scenario='base' AND plan_option='requested'`
2. *Show the rating waterfall for {group}* → `SELECT step_order, step_name, step_value, unit FROM nb_quote_waterfall WHERE group_id=:group_id AND pooling_point=250000 AND trend_scenario='base' AND plan_option='requested' ORDER BY step_order`
3. *Compare pooling points for {group}* → scenarios filtered to base trend, grouped by pooling_point, plan_option.
4. *Which submissions are blocked and why?* → `SELECT broker_name, group_id, top_missing_item, received_ts FROM broker_submissions WHERE completeness_status='BLOCKED' ORDER BY received_ts`
5. *Renewals in the next 90 days likely above 15%* → `renewal_pipeline WHERE renewal_date <= date_add(current_date(), 90) AND recommended_rate_action > 0.15`
6. *Q1 projected loss ratio and premium at risk with a 12% cap* → `SELECT MEASURE(`Projected Loss Ratio (Uncapped)`), MEASURE(`Projected Loss Ratio (12% Cap)`), MEASURE(`Premium at Risk (Uncapped)`), MEASURE(`Premium at Risk (12% Cap)`) FROM mv_renewal_book WHERE `Renewal Quarter`='2027-Q1'`

## 5. Benchmarks (minimum set; demo-critical marked ★)
| # | Question | Expected |
|---|---|---|
| ★1 | Family rate for Northwind at $250K pooling, base trend, requested plan | $2,290.21 |
| ★2 | Northwind credibility at $150K / $250K / $500K | 0.885 / 0.748 / 0.626 |
| ★3 | Northwind premium change vs current, base case | +2.2% |
| ★4 | Northwind premium PMPM on the alternate plan, base case | $589.02 |
| ★5 | How much was removed by pooling at $250K? | $540,000 |
| ★6 | Is Northwind's v1 submission ready to quote? | Blocked |
| ★7 | Renewals in next 90 days with rate action > 15% | (count from generated book — record after S2) |
| ★8 | Q1 2027 premium at risk with 12% cap vs uncapped | (record after S2) |
| 9 | IBNR for Northwind | $110,477 |
| 10 | Northwind member months | 23,520 |
| 11 | Northwind manual rate, base | $590.45 |
| 12 | Composite PEPM base case | $1,459.07 |
| 13 | Which brokers have the most blocked submissions? | from book |
| 14 | Target loss ratio | 88% |
| 15 | Highest-premium scenario for Northwind | 500K / high / requested, $656.55 |
