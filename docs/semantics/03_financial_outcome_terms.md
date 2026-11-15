# Semantics 03 — Financial Outcome Terms (UC Pages candidates)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

Subdomain: **Underwriting Finance**

### Retention
- **Definition:** Portion of premium for admin, commission, risk/profit, taxes and fees (demo 12%).
- **Business context:** Premium = claims / (1 − retention).
- **Data usage:** `retention_targets`
- **Related terms:** Target Loss Ratio
- **Source:** Research 02

### Target Loss Ratio
- **Definition:** 1 − retention; expected claims share of premium (demo 88%).
- **Business context:** Must respect large group MLR ≥ 85%.
- **Data usage:** `retention_targets.target_loss_ratio`
- **Related terms:** Medical Loss Ratio
- **Source:** CMS MLR

### Projected Loss Ratio
- **Definition:** Expected blended claims ÷ quoted premium for the rating period.
- **Business context:** Underwriting-to-finance link; shown in artifact and Beat 4.
- **Data usage:** metric view `mv_quote_outcomes.projected_loss_ratio`
- **Related terms:** Target Loss Ratio
- **Source:** L300-03

### Medical Loss Ratio (MLR)
- **Definition:** Regulatory ratio of claims + quality spend to premium; large group floor 85%.
- **Business context:** Book-level, not per group.
- **Data usage:** Not computed per group in demo
- **Related terms:** Target Loss Ratio
- **Source:** CMS

### Premium at Risk
- **Definition:** Renewal premium expected to lapse given a rate action, using historical persistency by rate-action band.
- **Business context:** Beat 4 finance question.
- **Data usage:** metric view `mv_renewal_book.premium_at_risk`
- **Related terms:** Persistency
- **Source:** L300-03

### Persistency
- **Definition:** Probability a group renews at a given rate-action band.
- **Business context:** Feeds premium at risk.
- **Data usage:** `persistency_curve(rate_action_band, persistency)`
- **Related terms:** Premium at Risk
- **Source:** L300-01

### Rate Action
- **Definition:** Recommended renewal premium change for an existing group.
- **Business context:** Beat 1/3/4.
- **Data usage:** `renewal_pipeline.recommended_rate_action`
- **Related terms:** Premium at Risk
- **Source:** L300-01

## Tagging strategy
`subdomain=uw_finance`; certified metric views tagged `certified=true`.

## Implementation priority
P1: Projected Loss Ratio, Target Loss Ratio, Premium at Risk.
