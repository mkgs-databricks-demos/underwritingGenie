# Research 02 — Experience Rating Methodology (Demo Reference Method)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## Key thesis
The rating model is simple, transparent arithmetic over governed factor tables. Encoding it once as a **Unity Catalog function** — and letting Genie call and explain it — is what makes AI-assisted underwriting defensible.

## 1. Standard structure
1. Start with the group's historical claims (incurred basis).
2. **Complete** paid claims to ultimate using completion factors (IBNR).
3. **Pool** claims above a per-claimant pooling point; add back an expected **pooling charge**.
4. **Trend** from the experience-period midpoint to the rating-period midpoint.
5. Adjust for **plan design** and **demographic** change.
6. Blend projected experience with an adjusted **manual rate** using **credibility** Z.
7. Load **retention** (admin, commission, risk/profit, taxes) to reach premium; check against target loss ratio.
8. Convert PMPM premium to **composite PEPM** and **tier rates**.

## 2. Formulas used in the demo
```
completed_claims   = Σ paid_to_date[m] × completion_factor[lag(m)]
pooled_claims      = completed_claims − Σ max(0, claimant_total − pooling_point)
experience_pmpm    = pooled_claims / member_months
trend_factor       = (1 + trend_rate) ^ trend_years          -- 2.0 years in demo
projected_exp_pmpm = experience_pmpm × trend_factor × plan_relativity × demographic_change + pooling_charge_pmpm
manual_pmpm        = base_manual × area × demographic × industry × plan_relativity   (rating-period dollars)
Z                  = min(1, sqrt(member_months / full_credibility_mm[pooling_point]))
blended_claims     = Z × projected_exp_pmpm + (1 − Z) × manual_pmpm
premium_pmpm       = blended_claims / (1 − retention)          -- retention 12% ⇒ target loss ratio 88%
composite_pepm     = premium_pmpm × members / enrolled_employees
tier_rate[t]       = composite_pepm × EE × tier_factor[t] / Σ(enrolled[t] × tier_factor[t])
```

## 3. Key actuarial controls (built into the function and tests)
| Control | Why | Demo implementation |
|---|---|---|
| Same basis on both sides of the blend | Experience and manual must be comparable (rating-period dollars, same plan) | Plan relativity applied to both sides |
| Don't double count pooled claims | Excess removed ⇒ pooling charge added | Unit test: charge>0 whenever excess removed |
| Pooling point consistent with credibility | Lower pooling point ⇒ more stable ⇒ lower full-credibility standard | `pooling_points.full_credibility_mm` keyed by pooling point |
| Independence of manual from the group's own experience | ASOP 25 / CMS URR guidance | Manual built from book factors only (documented) |
| Document judgment | ASOP 25 | `underwriter_adjustment` column, defaults 0, requires note |

## 4. Why credibility is *partial* in the demo
SOA describes the ~100–300 member range as where blending is common; thresholds vary widely by carrier. The demo group (~980 members, 23,520 member months) gives Z = 0.89 / 0.75 / 0.63 at pooling points $150K / $250K / $500K with full-credibility standards of 30K / 42K / 60K member months — **a visible blend that changes when the audience moves the pooling-point lever.**

## 5. What ASOP 25 does and doesn't say
ASOP 25 governs selection and documentation of credibility procedures; it **does not mandate** a formula, pooling point or full-credibility standard. The demo's square-root rule is a common, explainable choice — presented as "your method, your parameters," not as a standard.

## 6. Gaps / honest notes
- Multi-year recursive credibility weighting (used in some filed methodologies) is out of scope for the demo; noted as an extension.
- Medical vs Rx pooled together; separate pooling is an extension.
- Stop-loss / ASO variant reuses the same intake and pooling logic (see L100 "Reuse").

## Sources
- Actuarial Standards Board — ASOP No. 25, Credibility Procedures: https://www.actuarialstandardsboard.org/asops/credibility-procedures/
- SOA — A Practical Approach to Assigning Credibility for Group Medical Insurance Pricing (2015): https://www.soa.org/globalassets/assets/files/research/research-2015-practical-approach-assigning-credibility-group-medical.pdf
- Vermont DFR — public large group rating program actuarial memorandum (filed methodology example: pooling-dependent credibility bounds, recursive blending): https://ratereview.vermont.gov/sites/dfr/files/documents/COMBINED_Actuarial%20Memo_2023BCBS%20LG%20Rating%20Program_0.pdf
- CMS — Unified Rate Review Instructions (credibility / independence note): https://www.cms.gov/CCIIO/Programs-and-Initiatives/Health-Insurance-Marketplaces/Downloads/Unified-Rate-Review-Instructions.pdf
