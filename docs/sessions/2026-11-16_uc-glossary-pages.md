# 2026-11-16 — UC glossary pages for the Underwriting domain

Branch: `mg-genie-uw-genie-build-1` · Domain: `mkgs_underwriting` (governed tag) · Data: `hls_fde_dev.uw_genie` (synthetic, Lakeside Health Plan)

## Summary

Created 30 UC glossary pages as **drafts** in the `mkgs_underwriting` domain from `docs/semantics/01_*`, `02_*` and `03_*`:

* 13 priority pages (bulk): Credibility (Z), Pooling Point, Pooling Charge, Manual Rate, Completion Factor, Incurred Claims, Submission Completeness, Blocking Item, Census, Tier Rate, Projected Loss Ratio, Target Loss Ratio, Premium at Risk.
* 1 page via the new-page form: Experience Period.
* 16 pages (bulk): Rating Period, IBNR (Incurred But Not Reported), Large Claimant, Member Months, Trend Factor, Plan Relativity, Broker Submission, Lag Report, Warning Item, Coverage Tier, Composite Rate (PEPM), Rate Change vs Current, Retention, Medical Loss Ratio (MLR), Persistency, Rate Action.

Every page carries a "Synthetic demo content" banner and Definition / Business context / Data in the demo / Related terms sections.

## Problems

1. UC functions `rate_new_business` and `rate_renewal` could not be linked as related assets (12 failed links on the first 13 pages).
2. Page-to-page related links render as "Inaccessible" on draft pages.
3. The first 13 pages credited renewal measures to `rate_renewal()` and included external actuarial claims (web sources) not present in `docs/semantics/`.
4. Source-file errors in `01_rating_and_experience_terms.md`: Experience Period listed as a "parameter of `rate_new_business()`"; Rating Period referenced a non-existent `quotes` table; Trend Factor source named a real company.
5. No API or tool is available to edit or delete existing glossary pages.

## Root causes

1. The related-asset resolver looks up every name as a UC table (`/unity-catalog/tables/...`), so functions return 404. The functions are also not tagged `mkgs_underwriting`.
2. Related links between draft pages resolve as inaccessible assets until/unless the target pages are viewable.
3. `mv_renewal_book` is built on the view `renewal_book_scenarios` (`renewal_pipeline` joined to `persistency_curve` on `band_min`/`band_max`, uncapped and +12% capped). It does not use `rate_renewal()` or `renewal_scenarios` (which holds only the Lakeview Logistics renewal). Verified from `information_schema.views`.
4. `rate_new_business()` parameters are only `p_group_id, p_pooling_point, p_trend_scenario, p_plan_option, p_assumption_version` (verified in `information_schema.parameters`); there is no `quotes` table in `hls_fde_dev.uw_genie`.

## Changes

* `docs/semantics/01_rating_and_experience_terms.md`:
  * Experience Period data usage → `claims_monthly.incurred_month` (removed the `rate_new_business()` parameter claim).
  * Rating Period data usage → `groups.effective_date`.
  * Trend Factor source → "Public industry trend projection".

## Decisions

* Link only tables, views and metric views tagged `mkgs_underwriting` (all 24 tagged objects in `uw_genie` verified via `information_schema.table_tags`). No function links.
* The later 17 pages use plain-text related terms only (no page-to-page links).
* Only include claims from `docs/semantics/`; no unverified external actuarial claims or web sources.
* Do not credit a renewal number to `rate_renewal()` unless it is read directly from `rate_renewal()` or `renewal_scenarios`.
* Metric view measure names used as-is: "Projected Loss Ratio", "Projected Loss Ratio (Uncapped)", "Projected Loss Ratio (12% Cap)", "Premium at Risk (Uncapped)", "Premium at Risk (12% Cap)".

## Outstanding manual edits (existing pages; no page-edit API)

* **Projected Loss Ratio** — Data in the demo: replace the Renewals bullet with "Renewals: measures Projected Loss Ratio (Uncapped) and Projected Loss Ratio (12% Cap) in mv_renewal_book, calculated from renewal_pipeline through renewal_book_scenarios."
* **Premium at Risk** — Data in the demo: delete "Renewal scenarios from `rate_renewal()`"; replace the Inputs bullet with "Inputs: renewal_pipeline (current_annual_premium, recommended_rate_action) and persistency_curve (rate_action_band, band_min, band_max, persistency), combined in the view renewal_book_scenarios."
* **Pooling Point** — Business context: remove the "roughly 5–15% of a group's projected annual claims" sentence.
* **First 13 pages** — remove the "Inaccessible" related items.
* **Optional** — remove unsourced sentences on Incurred Claims, Tier Rate, Census, Credibility (Z), Manual Rate, Completion Factor, Projected Loss Ratio, Target Loss Ratio.

## Files modified

* `docs/semantics/01_rating_and_experience_terms.md`
* `docs/sessions/2026-11-16_uc-glossary-pages.md` (new)
* `docs/sessions/INDEX.md`
