# Semantics 01 — Experience Rating Terms (UC Pages candidates)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

Subdomain: **Rating & Experience**

### Experience Period
- **Definition:** The span of incurred months whose claims are used to rate a group (demo: 24 months, Jul-2024 → Jun-2026).
- **Business context:** Longer periods add stability; most recent months are least complete.
- **Data usage:** `claims_monthly.incurred_month`
- **Related terms:** Incurred Claims, Completion Factor, Rating Period
- **Source:** Research 02

### Rating Period
- **Definition:** The 12 months the new rates will apply to (demo: 1/1/2027–12/31/2027).
- **Business context:** Trend is projected to its midpoint.
- **Data usage:** `groups.effective_date`
- **Related terms:** Trend Factor, Experience Period
- **Source:** Research 02

### Incurred Claims
- **Definition:** Claims assigned to the month the service occurred, regardless of when paid.
- **Business context:** Standard rating basis; paid-only data must be converted.
- **Data usage:** `claims_monthly.paid_to_date` by `incurred_month`
- **Related terms:** Paid Claims, Completion Factor, IBNR
- **Source:** Research 02

### Completion Factor
- **Definition:** Multiplier that develops paid-to-date claims for an incurred month to estimated ultimate.
- **Business context:** Missing lag information is an intake blocker.
- **Data usage:** `completion_factors(lag_months, factor, assumption_version)`
- **Related terms:** IBNR, Lag Report
- **Source:** Research 02

### IBNR (Incurred But Not Reported)
- **Definition:** Estimated claims incurred but not yet paid; equals completed minus paid-to-date.
- **Business context:** Reported in the audit panel.
- **Data usage:** Derived in `rate_new_business()`
- **Related terms:** Completion Factor
- **Source:** Research 02

### Pooling Point
- **Definition:** Per-claimant annual threshold above which claims are removed from the group's experience.
- **Business context:** Lower pooling point = more stable rate, higher pooling charge.
- **Data usage:** `pooling_points.pooling_point`; demo lever ($150K/$250K/$500K)
- **Related terms:** Pooling Charge, Large Claimant, Credibility
- **Source:** Research 02

### Pooling Charge
- **Definition:** Expected cost (PMPM) of claims above the pooling point, added back after pooling.
- **Business context:** Prevents double counting.
- **Data usage:** `pooling_points.pooling_charge_pmpm`
- **Related terms:** Pooling Point
- **Source:** Research 02

### Large Claimant
- **Definition:** A member whose claims in the experience period exceed a reporting threshold; status Active / Ongoing / Resolved.
- **Business context:** Status determines prospective risk; missing status is an intake warning.
- **Data usage:** `large_claimants`
- **Related terms:** Pooling Point
- **Source:** Research 02

### Manual Rate
- **Definition:** Expected claims PMPM for an average group with the subject group's characteristics, from book factors.
- **Business context:** Used where experience is not fully credible.
- **Data usage:** `manual_rate_factors`; component of waterfall
- **Related terms:** Credibility, Area Factor, Demographic Factor
- **Source:** Research 02

### Credibility (Z)
- **Definition:** Weight (0–1) on the group's projected experience vs the manual rate; demo rule Z = min(1, √(member months / full-credibility standard)).
- **Business context:** Governed by ASOP 25; method is plan-specific.
- **Data usage:** `pooling_points.full_credibility_mm`; output column `credibility`
- **Related terms:** Manual Rate, Member Months
- **Source:** ASOP 25; SOA

### Member Months
- **Definition:** Sum of covered members across each month of the experience period.
- **Business context:** Exposure basis for PMPM and credibility.
- **Data usage:** `census` × months; demo 23,520
- **Related terms:** PMPM, Credibility
- **Source:** Research 02

### Trend Factor
- **Definition:** (1 + annual trend)^(years from experience midpoint to rating midpoint).
- **Business context:** Public 2027 group trend projection ~9%.
- **Data usage:** `trend_assumptions(scenario, annual_rate)`
- **Related terms:** Rating Period
- **Source:** Public industry trend projection

### Plan Relativity
- **Definition:** Ratio of expected cost of the proposed plan to the base plan.
- **Business context:** Alternate-deductible option = 0.94 in demo.
- **Data usage:** `plan_designs.relativity`
- **Related terms:** Manual Rate
- **Source:** Research 02

## Tagging strategy
- Tag all tables/columns with `domain=underwriting`, `subdomain=rating`, `data_class=synthetic`.
- Tag assumption tables `governed_assumption=true` with `assumption_version`.

## Implementation priority
P1: Credibility, Pooling Point, Pooling Charge, Manual Rate, Completion Factor, Incurred Claims. P2: remainder.
