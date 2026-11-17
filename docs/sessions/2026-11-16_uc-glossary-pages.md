# 2026-11-16 — UC glossary pages for the Underwriting domain

Branch: `mg-genie-uw-genie-build-1` · Domain: `mkgs_underwriting` (governed tag, domain ID `61901539-1958-4b2e-8266-070462db8291`) · Data: `hls_fde_dev.uw_genie` (synthetic, Lakeside Health Plan)

## Summary

Created 30 UC glossary pages as **drafts** in the `mkgs_underwriting` domain from `docs/semantics/01_*`, `02_*` and `03_*`, then reworked all of them by hand (one page at a time in the page editor) into a general, reusable format.

* 13 priority pages (bulk): Credibility (Z), Pooling Point, Pooling Charge, Manual Rate, Completion Factor, Incurred Claims, Submission Completeness, Blocking Item, Census, Tier Rate, Projected Loss Ratio, Target Loss Ratio, Premium at Risk.
* 16 pages (bulk): Rating Period, IBNR (Incurred But Not Reported), Large Claimant, Member Months, Trend Factor, Plan Relativity, Broker Submission, Lag Report, Warning Item, Coverage Tier, Composite Rate (PEPM), Rate Change vs Current, Retention, Medical Loss Ratio (MLR), Persistency, Rate Action.
* Experience Period: first filled via the new-page form but never saved (not found in the page inventory); recreated via a new page form with domain preselected and saved as a draft (verified: page `d3b9c1b2-b62e-4b79-bb5c-45cd6d8fd46d`, single page, no duplicate).

### Final page format (all 30 pages)

* No "Synthetic demo content" banner; one closing line: *Linked data assets contain synthetic data.* (no `---` rule — the editor renders it as literal text).
* Sections: Definition · Business context · **Where to find it** (renamed from "Data in the demo") · Related terms (plain text, ending "*Other pages in the Underwriting domain may also be related.*") · External references (where present).
* General, reusable wording: no "(demo: …)" values or storyline beats in descriptions, definitions or business context. Workspace-specific values (e.g. 88% target loss ratio, 12% retention, tier factors 1.00/2.00/1.85/2.85, trend scenarios 7.5%/9.0%/10.5%, pooling points 150K/250K/500K) moved to "Where to find it" and labelled "in the linked data".
* Body claims come only from `docs/semantics/` or are verified against code (`rate_renewal()` definition, `renewal_book_scenarios` view, `mv_renewal_book` / `mv_intake_ops` measure expressions, `information_schema.parameters`).

## Problems

1. UC functions `rate_new_business` and `rate_renewal` could not be linked as related assets (12 failed links on the first 13 pages).
2. Page-to-page related links showed as "Inaccessible" on draft pages, and draft pages did not appear in the editor's **Add related asset → Pages** picker.
3. Linking pages through the Genie Code page-form tool linked the wrong assets — three attempts (plain page names, `mkgs_underwriting.<page>`, page UUIDs) all resolved to unrelated dashboards (`3879888900662873`, `3902169163100391`) on Premium at Risk.
4. The first 13 pages credited renewal measures to `rate_renewal()`, included external actuarial claims not in `docs/semantics/` (e.g. "5–15% pooling point" guideline), and were framed around the demo.
5. Source-file errors in `01_rating_and_experience_terms.md`: Experience Period listed as a "parameter of `rate_new_business()`"; Rating Period referenced a non-existent `quotes` table; Trend Factor source named a real company.
6. No API or bulk tool can edit or delete existing glossary pages.
7. Some related page links disappeared from saved pages without being edited (Credibility (Z) lost 4, Manual Rate lost 3).

## Root causes

1. The related-asset resolver looks up names as UC tables, so functions return 404; the functions are also not tagged `mkgs_underwriting`.
2. Draft pages are not yet listed by the Pages picker (published-only or indexing delay — not confirmed). "Inaccessible" rows are valid page links (IDs matched the inventory, e.g. Incurred Claims `65ea1d16…`, Pooling Charge `cb469521…`) that resolve over time — Credibility (Z) resolved first.
3. The page-form tool only supports tables, notebooks, dashboards, Genie spaces and queries; anything else is fuzzy-matched to an unrelated asset.
4. `mv_renewal_book` is built on `renewal_book_scenarios` (`renewal_pipeline` joined to `persistency_curve` on `band_min`/`band_max`, uncapped and +12% capped); it does not use `rate_renewal()` or `renewal_scenarios` (Lakeview Logistics only). Verified from `information_schema.views`.
5. `rate_new_business()` parameters are only `p_group_id, p_pooling_point, p_trend_scenario, p_plan_option, p_assumption_version`; there is no `quotes` table in `hls_fde_dev.uw_genie`.
6. Unknown for problem 7 (not caused by Genie Code updates, which omitted related assets on those pages).

## Changes

* `docs/semantics/01_rating_and_experience_terms.md` (commit `6179bd7`):
  * Experience Period data usage → `claims_monthly.incurred_month`.
  * Rating Period data usage → `groups.effective_date`.
  * Trend Factor source → "Public industry trend projection".
* All 30 pages rewritten to the final format above (manual page-editor session). Specific fixes:
  * **Projected Loss Ratio** — renewals bullet now "calculated from `renewal_pipeline` through `renewal_book_scenarios`"; added target comparison bullet; removed ASOP No. 8 sentence from body.
  * **Premium at Risk** — removed "Renewal scenarios from `rate_renewal()`"; inputs bullet now names `persistency_curve` (rate_action_band, band_min, band_max, persistency) combined in `renewal_book_scenarios`; related assets reset to the 3 tables after the dashboard mis-links.
  * **Pooling Point** — removed the "5–15%" sentence and credibility aside.
  * Removed unsourced practice sentences on Credibility (Z), Manual Rate, Completion Factor, Incurred Claims, Tier Rate, Census, Pooling Charge, Blocking Item, Submission Completeness and Target Loss Ratio ("or pay rebates").
  * Descriptions de-demoed on Target Loss Ratio, Rating Period, Plan Relativity and Retention.
* External references:
  * Restored (sections had been removed earlier in the day) on Pooling Point, Credibility (Z), Manual Rate and Projected Loss Ratio; kept on Target Loss Ratio, Completion Factor, Incurred Claims, Tier Rate and Pooling Charge.
  * Added on Composite Rate (PEPM) — Academy *Standard Community Rating Model*, CMS *Market Rating Reforms*; Retention — SOA CP 321 Fall 2025 solutions, Academy *Regulatory Filings for Health Benefits*, CMS 2018 URR Instructions; Medical Loss Ratio (MLR) — CMS MLR, CMS MLR data resources, 45 CFR Part 158; Experience Period — ASOP No. 25, ASOP No. 23, SOA credibility paper.

## Decisions

* Link only tables, views and metric views tagged `mkgs_underwriting` (24 tagged objects verified via `information_schema.table_tags`), passed as full names (`hls_fde_dev.uw_genie.<table>`). No function links.
* Never pass page names or IDs to the page-form tool. Add page links manually from **Add related asset → Pages** once pages appear there; keep existing page links (including "Inaccessible" ones). Updates omit related assets so page links are preserved.
* Keep "External references" sections and their Sources; add new references only on request, as references only (no new body claims), preferring ASB/SOA/Academy/CMS/eCFR and skipping links without confirmed citations.
* Body claims only from `docs/semantics/` or verified code. Do not credit a renewal number to `rate_renewal()` unless read directly from it or `renewal_scenarios` (stored `renewal_pipeline` rate actions match `rate_renewal()` for 1 of 59 groups — R1-11).
* Metric view measure names used as-is: "Projected Loss Ratio", "Projected Loss Ratio (Uncapped)", "Projected Loss Ratio (12% Cap)", "Premium at Risk (Uncapped)", "Premium at Risk (12% Cap)".

## Page inventory (30 of 30 found via search)

Rating & Experience: Experience Period `d3b9c1b2-b62e-4b79-bb5c-45cd6d8fd46d` · Credibility (Z) `0b28eb0b-cd56-486f-8384-023a452de192` · Pooling Point `77b23304-940f-448f-8752-904d9b2479d9` · Pooling Charge `cb469521-2f6f-4ac0-a959-f2b7f616b90d` · Manual Rate `8eade729-ac48-454f-9b93-2ead0d6f4122` · Completion Factor `23210099-be92-40ce-ac49-db645790fdc6` · Incurred Claims `65ea1d16-b004-46a1-94a8-0922203bda32` · Rating Period `b3be4167-8179-466d-8ef3-82a09504aaa0` · IBNR `2acec396-2a5c-4cc8-8289-9dcfa3d74c12` · Large Claimant `f691c72f-009d-4d20-bb09-ddd0947111e4` · Member Months `20472cf5-1326-43a2-8bb0-6812c7988947` · Trend Factor `86de2277-1993-4db0-b585-c0dd4d99b7d0` · Plan Relativity `a7697e25-44e4-4ec6-86e9-2fe84959e4c1`

Intake & Quote: Broker Submission `dcd239b2-b7ab-40bc-85e2-ac9a099aa41c` · Submission Completeness `69d70526-39bd-4206-9a05-bfccfe0b47e0` · Blocking Item `26622478-42dc-4fd6-93eb-d66f39720caa` · Warning Item `63f6c423-5a6e-43da-85cc-ffe30e83e8e5` · Lag Report `d560ba05-87aa-4e68-826f-814fc28d3d4f` · Census `b51a8df3-2569-471a-80ec-d7e6b44387f4` · Coverage Tier `8ac80703-9ade-427e-9ec2-25e415ca2a5c` · Tier Rate `66449c74-2b78-4060-af18-69cb2470bf2c` · Composite Rate (PEPM) `c4279766-3aa9-4749-8bf3-9480bcd79324` · Rate Change vs Current `6db4d265-af65-4df1-8a69-6a565a60b81e`

Underwriting Finance: Projected Loss Ratio `58627e38-d598-43a1-aaaa-8406b04a56e4` · Target Loss Ratio `3a498a7d-867d-4e6a-83e5-d4a7806017cd` · Premium at Risk `15fa37fd-9749-43c8-ac46-52ed3da335e7` · Retention `4637a097-be49-40fc-8d7a-41af726ce1d5` · Medical Loss Ratio (MLR) `dbd1c657-611e-44c8-8b00-00353ff293b9` · Persistency `76cdf7e3-9661-482b-bae0-e04f3ad7c4a5` · Rate Action `13c6f168-a569-427a-9b70-0d99525dff54`

## Outstanding

* Re-add page-to-page links manually once draft pages appear in the Pages picker (lost on Credibility (Z) and Manual Rate; never added on the later 17).
* Confirm each page edit was saved (several updates were sent while pages were in view mode).

## Files modified

* `docs/semantics/01_rating_and_experience_terms.md` (commit `6179bd7`)
* `docs/sessions/2026-11-16_uc-glossary-pages.md`
* `docs/sessions/INDEX.md` (commit `6179bd7`)
* `PROJECT_MEMORY.md` ("UC glossary pages" section updated to the decisions above)
