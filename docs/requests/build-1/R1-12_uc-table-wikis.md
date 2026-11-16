# R1-12 Unity Catalog table wikis for `hls_fde_dev.uw_genie`

**Status:** Open (drafts ready; paste into each table's wiki and publish)
**Origin:** Owner request in Genie Code, 2026-11-16, while writing the `broker_submissions` wiki in Catalog Explorer
**Related:** R1-03 (metric view fixtures), R1-11 (renewal rate actions), R1-04 (parameterization)

## Problem

None of the 25 objects in `hls_fde_dev.uw_genie` have a wiki. Several have traps that column comments do not explain: values that the comments list but the data never contains, rows filtered by version, groups missing from `groups`, and stored values that are not governed outputs. Genie and human readers hit these traps in testing.

## Current state (evidence)

* Wiki tool in Genie Code only fills the wiki editor on the open table page; there is no public API for table wikis. Each draft below has to be pasted (or filled by Genie Code on that table's page).
* `broker_submissions` draft was filled in the editor on 2026-11-16 (not yet saved). It is repeated below so this file is the single source.
* Every number below comes from queries Genie Code ran on 2026-11-16 (serverless). Data is rebuilt by `setup_demo` / `reset_demo`, so numbers can change after a reseed.
* UC lineage is not recorded for these tables, so only views and metric views (whose source SQL is known) get a Lineage section.

## Requested change

1. Paste each draft into the table's wiki (Description and Body), review, and publish.
2. Optional, build 1: keep these drafts as source-controlled fixtures alongside the metric view YAML (R1-03) so they survive a schema rename (R1-01).

## Files affected

* None in the bundles. UC wikis on 25 objects. This file is the source of the drafts.

## Acceptance criteria

* All 25 objects have a published wiki with a description.
* No wiki lists columns; only real caveats are under **Column caveats**.
* Numbers in each wiki match the data at publish time (re-check after any reseed).

## Dependencies

* If R1-01 renames the schema, re-apply the wikis to the new schema.
* If R1-11 changes how `renewal_pipeline.recommended_rate_action` is produced, update the `renewal_pipeline`, `renewal_book_scenarios` and `mv_renewal_book` caveats.

---

# Wiki drafts

Conventions used: one or two sentence description; body sections Overview, Column caveats (only real gotchas), Lineage (views and metric views only), Usage, Caveats. All data is synthetic.

---

## broker_submissions

**Description:** Synthetic new business broker submissions for the Underwriting Genie demo, one row per received broker package, with a seeded intake completeness status and the top missing checklist item.

**Body:** (same text that was filled in the Catalog Explorer wiki editor on 2026-11-16)

### Overview

Synthetic intake queue for large group new business. Each row is one broker package received for a group (`submission_id` is unique). A group can have more than one row when the broker resends its package. Only Northwind (`GRP-NW-001`) has two versions: v1 is `BLOCKED` and v2 is `READY_WITH_WARNINGS`. All other groups have a single submission.

The table lets the Underwriting Genie demo answer intake questions such as "which submissions are blocked and why", "who owns them", and "what came in recently". It also provides the intake queue for the underwriting morning brief.

As of 2026-11-16 it holds 25 submissions across 24 groups and 6 broker firms, with 3 intake owners. Status split: 9 `READY`, 8 `READY_WITH_WARNINGS`, 8 `BLOCKED`. `received_ts` ranges from 2026-10-01 to 2026-11-13.

### Column caveats

* `completeness_status`: a value set by the seed script, not computed live by the intake checklist. Treat it as the queue's recorded status. A live checklist run on the actual package files can return a different result.
* `top_missing_item`: names only the single most important gap, not the full list. It is NULL for `READY` submissions. Get item-level gaps from a checklist run on the package files.
* `received_ts`: judge recency and readiness against this timestamp, not the current date. The data is fixed, so "days since received" computed from today keeps increasing.
* `package_version`: values are `v1` or `v2`. To get a group's current status, take its latest version, or the latest `received_ts`, instead of counting every row.
* `group_id`: only `GRP-NW-001` exists in `hls_fde_dev.uw_genie.groups`. The 23 `GRP-NB-*` groups exist only in this table as queue filler. An inner join to `groups` drops them, so use a LEFT JOIN when counting the queue.

### Usage

* Most often joined with `hls_fde_dev.uw_genie.groups` on `group_id` to get group attributes (Northwind only; see the caveat above).
* Source of `mv_intake_ops`.
* Used by the Underwriting Genie space and by the intake checklist and morning brief features in Genie One.
* Example question: "Show blocked submissions with their top missing item and owner, newest first."

### Caveats

* Fully synthetic: groups, brokers, and owners are fictional. Contains no PHI or real customer data.
* Built by the `generate_synthetic_book` notebook in the uw-genie-infra bundle's setup_demo job. The reset_demo job overwrites it, so do not hand-edit rows you need to keep.
* Read-only in Genie One. Intake exceptions or status changes are not written back to this table.

---

## groups

**Description:** Employer groups in the synthetic Lakeside Health Plan book: one row per group with status, size, broker and current premium.

**Body:**

### Overview

One row per employer group (`group_id` is unique). As of 2026-11-16 there are 60 groups: 1 `PROSPECT` (Northwind Manufacturing, `GRP-NW-001`, effective 2027-01-01, 420 enrolled employees, 980 members, 23,520 member months) and 59 `IN_FORCE` groups, including the renewal demo group Lakeview Logistics (`GRP-LV-002`, 1,390 employees, 3,200 members).

### Column caveats

* `member_months`: experience-period member months, not current enrollment x 12. Use it for credibility, not for current membership.
* `incumbent_premium_pmpm`: premium with the incumbent carrier for prospects, current plan premium for in-force groups. Do not compare the two populations directly.
* `incumbent_renewal_offer_pct`: broker-reported, prospects only.
* `demographic_change`: a ratio (current census demo factor / experience-period demo factor), not a percent.
* `broker_email`: `.example` domain only; not deliverable.

### Usage

* The group dimension for every other table (join on `group_id`).
* Does not contain the 23 `GRP-NB-*` groups from `broker_submissions`.

### Caveats

* Fully synthetic; names, brokers and contacts are fictional. Rebuilt by `setup_demo` / `reset_demo`.

---

## census_members

**Description:** Synthetic member-level census per group and census version (employees and dependents), used for tier counts and demographic rating.

**Body:**

### Overview

One row per member per group per census version (unique on `group_id`, `census_version`, `member_id`). 42,715 rows across 60 groups. `v2` (corrected) covers all 60 groups (41,735 rows). `v1` (broker original) exists only for Northwind (`GRP-NW-001`, 980 rows). Northwind has 420 employees, 193 spouses and 367 children in each version.

### Column caveats

* `census_version`: always filter. Without a filter, Northwind members are counted twice. Use `v2` for current enrollment.
* `member_id`: not unique across versions; count distinct on (`group_id`, `census_version`, `member_id`).
* `tier`: populated on employee rows only (NULL for spouses and children). 11 employee rows also have a NULL tier.
* `birth_date`, `zip3`: synthetic; `zip3` is the first three digits only.

### Usage

* Source of `group_tier_counts` (v2 employees by tier).

### Caveats

* Fully synthetic member data; no PHI. Rebuilt by `setup_demo` / `reset_demo`.

---

## claims_monthly

**Description:** Synthetic monthly incurred claims experience per group, 24 incurred months, paid through 2026-08-01.

**Body:**

### Overview

One row per group per incurred month per service category and basis. 1,440 rows: 60 groups x 24 incurred months (2024-07-01 to 2026-06-01). Every row has `paid_through` = 2026-08-01.

### Column caveats

* `basis`: the comment lists `INCURRED|PAID`, but only `INCURRED` is present.
* `service_category`: the comment lists `MEDICAL|RX|ALL`, but only `ALL` (medical + Rx total) is present. Medical vs Rx splits cannot be answered from this table.
* `paid_to_date`: not completed. Apply `completion_factors` by lag (months from `incurred_month` to `paid_through`) before using it as incurred claims.

### Usage

* Experience input for the governed rating functions. Join `completion_factors` on lag and `assumption_version`.

### Caveats

* Fully synthetic. Rebuilt by `setup_demo` / `reset_demo`.

---

## completion_factors

**Description:** Claims completion (IBNR) factors by lag in months for assumption set AV-2027.1.

**Body:**

### Overview

Assumption table with 37 rows: lags 0 to 36 months, factors from 1.00 to 1.12, all for `AV-2027.1`. Multiply paid-to-date claims by the factor for their lag to estimate completed incurred claims.

### Column caveats

* `lag_months`: months between the incurred month and the paid-through month, not between incurred and today.
* `assumption_version`: always filter or join on it so a future assumption set does not double the rows.

### Usage

* Used with `claims_monthly` by the governed rating functions (IBNR step in `nb_quote_waterfall`).

### Caveats

* Demo assumption values, not a real carrier's factors.

---

## group_tier_counts

**Description:** View of enrolled employees by coverage tier per group, from the corrected (v2) census.

**Body:**

### Overview

240 rows: 60 groups x 4 tiers (EE, ES, EC, EF). Total enrolled is 19,462. Northwind totals 420, matching `groups.enrolled_employees`.

### Column caveats

* `enrolled`: employees only (dependents are not counted). Do not compare it to `groups.members`.

### Lineage

* `census_members`, filtered to `relationship = 'EMPLOYEE'` and `census_version = 'v2'`, grouped by group and tier.

### Usage

* Tier mix for composite and tier rates; pair with `tier_factors`.

### Caveats

* Always reflects v2. For the broker's original (v1) Northwind census, query `census_members` directly.

---

## intake_checklist

**Description:** Governed large group new business intake checklist: 14 items, each with a severity, the rule used to judge it and a broker follow-up template.

**Body:**

### Overview

14 rows, `IC-01` to `IC-14`: 7 `BLOCKING` and 7 `WARNING`. A submission with a missing blocking item cannot be rated.

### Column caveats

* `rule_text`: the governed rule. Judge each item by this text, not by the item name.
* `broker_ask_template`: a template; fill in group and broker details before sending.

### Usage

* Read by the intake checklist feature to judge broker packages and draft broker requests.
* `submission_findings.item_id` references `item_id`.

### Caveats

* Reference data; changes affect every intake result. Rebuilt by `setup_demo` / `reset_demo`.

---

## large_claimants

**Description:** Synthetic large claimant report per group and broker package version, with condition category, status and experience-period paid claims.

**Body:**

### Overview

74 rows across 38 groups (unique on `group_id`, `package_version`, `claimant_id`). Groups not listed have no reported large claimants. Northwind has 4 claimants in each of v1 and v2.

### Column caveats

* `package_version`: filter to one version per group. Without a filter, Northwind claimants are counted twice.
* `status`: four values (`ACTIVE`, `ONGOING`, `RESOLVED`, `UNKNOWN`). Treat `UNKNOWN` separately rather than as resolved.
* `total_claims`: experience-period total paid per claimant. Pooling against `pooling_points` is done by the rating functions, not in this table.

### Usage

* Pooling inputs for rating; large claimant review in intake and renewal conversations.

### Caveats

* Fully synthetic; condition categories are not linked to real members. Rebuilt by `setup_demo` / `reset_demo`.

---

## manual_rate_factors

**Description:** Manual rate inputs per group (base manual PMPM plus area, industry and demographic factors) for assumption set AV-2027.1.

**Body:**

### Overview

60 rows, one per group, all `AV-2027.1`. The manual rate is the non-experience side of the credibility blend.

### Column caveats

* `base_manual_pmpm` and the factors: do not multiply them yourself to quote a rate. The governed rating functions apply them; use their outputs (`nb_quote_scenarios`, `renewal_scenarios`).

### Usage

* Input to `rate_new_business()` and `rate_renewal()` (manual rate step in `nb_quote_waterfall`).

### Caveats

* Demo assumption values.

---

## nb_quote_scenarios

**Description:** Governed new business quote scenarios for Northwind Manufacturing: 18 rows (3 pooling points x 3 trend scenarios x 2 plan options) materialized from rate_new_business().

**Body:**

### Overview

18 rows for `GRP-NW-001` only, one per (`pooling_point`, `trend_scenario`, `plan_option`). `method_version` = `rate_new_business v1`, `assumption_version` = `AV-2027.1`. Current rows were generated 2026-11-16 00:22 UTC. Each row holds the full rating build-up from paid claims to tier rates.

### Column caveats

* `premium_pmpm`, `composite_pepm`, `rate_ee` / `rate_es` / `rate_ec` / `rate_ef`: the only approved quoted rates. Do not recompute or adjust them by hand.
* `rate_change_vs_incumbent`: quoted premium PMPM / incumbent current premium PMPM - 1, stored as a decimal (0.05 = +5%).
* `generated_at`: check it after changing any assumption table; rows are stale until regenerated.

### Usage

* Source of `nb_quote_waterfall` and `mv_quote_outcomes`. Used by the experience rating explainer and the new business quote artifact.

### Caveats

* Northwind only. Other groups have no new business scenarios. Regenerated by `setup_demo`.

---

## nb_quote_waterfall

**Description:** View of the ten-step rating waterfall (paid claims to composite rate) for every nb_quote_scenarios row.

**Body:**

### Overview

180 rows: 18 scenarios x 10 steps (`step_order` 1 to 10). Steps: paid-to-date claims, IBNR, excess over pooling point removed, historical experience PMPM, projected experience, manual rate, credibility (Z), blended claims PMPM, premium PMPM after retention, composite rate PEPM.

### Column caveats

* `step_value`: units differ by step (`unit` = USD, PMPM, ratio or PEPM). Never sum or average across steps.
* Step 3 (excess over pooling point) is stored as a negative value.

### Lineage

* `nb_quote_scenarios`, unpivoted to one row per step.

### Usage

* Explaining how a quoted rate was built ("why is the rate X"). Filter to one scenario (group, pooling point, trend scenario, plan option) and order by `step_order`.

### Caveats

* Inherits `nb_quote_scenarios` scope (Northwind only) and freshness.

---

## persistency_curve

**Description:** Renewal persistency assumption: expected share of groups that renew, by rate action band.

**Body:**

### Overview

6 bands: `<0%`, `0-5%`, `5-10%`, `10-15%`, `15-20%`, `>20%`.

### Column caveats

* `band_min` / `band_max`: rate actions are decimals (0.12 = 12%). `band_min` is inclusive and `band_max` exclusive, as joined in `renewal_book_scenarios`.

### Usage

* Joined to `renewal_pipeline` in `renewal_book_scenarios` to estimate premium at risk.

### Caveats

* Demo assumption values.

---

## plan_designs

**Description:** Plan designs per group: deductible, coinsurance, out-of-pocket maximum and benefit relativity.

**Body:**

### Overview

61 rows across 60 groups. Northwind has two rows: `requested` (relativity 1.00) and `alternate` (relativity 0.94). The other 59 groups each have one `current` plan (relativity 1.00).

### Column caveats

* `plan_option`: the comment lists `requested|alternate`, but the 59 in-force groups use `current`. Filter accordingly.
* `relativity`: relative to the group's requested or current plan, not a market benchmark.

### Usage

* `plan_option` matches `nb_quote_scenarios.plan_option` (Northwind) and `renewal_scenarios.plan_option` (`current`).

### Caveats

* Synthetic plan designs. Rebuilt by `setup_demo` / `reset_demo`.

---

## pooling_points

**Description:** Large claim pooling points with their pooling charges and full-credibility standards for assumption set AV-2027.1.

**Body:**

### Overview

3 rows, all `AV-2027.1`:

| pooling_point | pooling_charge_pmpm | full_credibility_mm |
| --- | --- | --- |
| 150,000 | 38.00 | 30,000 |
| 250,000 | 24.00 | 42,000 |
| 500,000 | 11.00 | 60,000 |

### Column caveats

* `full_credibility_mm`: credibility Z = min(1, sqrt(member months / this value)), per the `mv_quote_outcomes` definition.

### Usage

* Rating input for pooling and credibility; the `pooling_point` dimension in the scenario tables.

### Caveats

* Demo assumption values.

---

## renewal_book_scenarios

**Description:** View of the renewal pipeline joined to the persistency curve at the uncapped and 12%-capped rate actions; source of mv_renewal_book.

**Body:**

### Overview

59 rows, one per renewing group. Adds the capped rate action (LEAST(recommended, 0.12)), persistency at both rate actions, and renewal premium at both.

### Column caveats

* `recommended_rate_action`: carried from `renewal_pipeline`; see the caveat there (not a governed `rate_renewal()` output).
* Rate actions are decimals (0.12 = 12%).

### Lineage

* `renewal_pipeline` inner-joined twice to `persistency_curve`. A rate action outside every band would drop the row; today all 59 rows survive.

### Usage

* Source of `mv_renewal_book` (premium at risk, projected loss ratio, capped vs uncapped).

### Caveats

* Inherits `renewal_pipeline` freshness and caveats.

---

## renewal_pipeline

**Description:** Synthetic in-force renewal pipeline: one row per renewing group with renewal date, quote due date, owner, premium, projected claims and recommended rate action.

**Body:**

### Overview

59 rows, one per in-force group (Northwind is a prospect and is not here). Renewal quarters 2027-Q1 and 2027-Q2. 4 underwriters own the book. 32 renewals are pre-built and 6 have a new large claimant. Quote due dates range from 2026-11-02 to 2027-04-02.

### Column caveats

* `recommended_rate_action`: a stored seed value, not a governed output. A live `rate_renewal()` call matches it for 1 of 59 groups (Lakeview Logistics). See R1-11.
* `quote_due_date`: compare against the demo as-of date, not today (R1-10).
* Rate actions are decimals (0.12 = 12%).

### Usage

* Source of `renewal_book_scenarios`. Used by the morning brief for renewals due, late quotes and new large claimants.

### Caveats

* Fully synthetic; owners are fictional. Rebuilt by `setup_demo` / `reset_demo`.

---

## renewal_scenarios

**Description:** Governed renewal scenarios for Lakeview Logistics (GRP-LV-002, renewal 2027-01-01): 9 rows (3 pooling points x 3 trend scenarios) materialized from rate_renewal().

**Body:**

### Overview

9 rows for `GRP-LV-002` only, one per (`pooling_point`, `trend_scenario`), all with `plan_option` = `current`. Same build-up columns as `nb_quote_scenarios`, plus `current_premium_pmpm` and `recommended_rate_action`.

### Column caveats

* `recommended_rate_action`: the governed renewal rate action for Lakeview. Use this, not `renewal_pipeline`, when explaining Lakeview's renewal.

### Usage

* The Lakeview renewal beat of the demo and the experience rating explainer.

### Caveats

* Lakeview only. Regenerated by `setup_demo`.

---

## retention_targets

**Description:** Retention and target loss ratio for assumption set AV-2027.1.

**Body:**

### Overview

1 row: `AV-2027.1`, retention 0.12, target loss ratio 0.88.

### Column caveats

* `target_loss_ratio`: always 1 - `retention`. Large group MLR must stay at or above 85%.

### Usage

* Retention load in the rating functions; the 88% target in `mv_quote_outcomes` and `mv_renewal_book`.

### Caveats

* Demo assumption values.

---

## submission_findings

**Description:** Item-level intake checklist findings per broker submission, written during the demo and cleared by reset_demo.

**Body:**

### Overview

One row per checklist item judged for a submission, with `finding` = `PRESENT`, `MISSING` or `PARTIAL` and the evidence location. Empty as of 2026-11-16 (0 rows); rows appear only after a demo run writes them.

### Column caveats

* An empty table means no findings have been recorded yet, not that every submission is complete.
* `evidence`: free text (file, page, field), not a structured reference.

### Usage

* Join `submission_id` to `broker_submissions` and `item_id` to `intake_checklist`.

### Caveats

* `reset_demo` truncates this table. Do not keep anything here you need after a reset.

---

## tier_factors

**Description:** Coverage tier rating factors relative to employee-only (EE).

**Body:**

### Overview

4 rows: EE 1.00, ES 2.00, EC 1.85, EF 2.85.

### Column caveats

* `tier_factor`: relative to EE; it is not a premium. Tier rates come from the scenario tables (`rate_ee` to `rate_ef`).

### Usage

* With `group_tier_counts` to turn a composite rate into tier rates.

### Caveats

* Demo assumption values.

---

## trend_assumptions

**Description:** Annual medical trend scenarios (low, base, high) for assumption set AV-2027.1.

**Body:**

### Overview

3 rows, all `AV-2027.1` with 2.0 trend years: low 7.5%, base 9.0%, high 10.5%.

### Column caveats

* `trend_years`: years from experience midpoint to rating midpoint. The trend factor is (1 + `annual_rate`) ^ `trend_years` (base: 1.1881).

### Usage

* The `trend_scenario` dimension in `nb_quote_scenarios` and `renewal_scenarios`.

### Caveats

* Demo assumption values. Compare actual trend in `trend_monitor`.

---

## trend_monitor

**Description:** Actual vs assumed annual trend signals (medical, Rx, total) for the underwriting morning brief.

**Body:**

### Overview

3 rows for the rolling 12 months ending 2026-09:

| metric | assumed | actual |
| --- | --- | --- |
| Medical PMPM trend | 8.3% | 8.1% |
| Rx PMPM trend | 11.0% | 13.4% |
| Total PMPM trend | 9.0% | 9.2% |

### Column caveats

* `assumed_annual_trend` is broken out by component, so it does not match `trend_assumptions.annual_rate` except for the total (9.0% base).

### Usage

* Trend section of the morning brief (Rx is 2.4 points above assumption).

### Caveats

* Synthetic signals. Rebuilt by `setup_demo` / `reset_demo`.

---

## mv_intake_ops

**Description:** Metric view of new business intake operations: broker submissions and completeness against the intake checklist, by broker, status and week received.

**Body:**

### Overview

Dimensions: `Broker`, `Status`, `Week` (week of `received_ts`). Measures: `Submissions` (each package version counts once), `Pct Complete First Pass`, `Blocked Submissions`. Query with `MEASURE()`.

### Column caveats

* `Submissions`: counts package versions, so Northwind counts twice (v1 and v2).
* `Pct Complete First Pass`: averages over all submissions, and v2 rows count as 0. With current data the denominator includes Northwind's v2.
* `Status`: inherits the seeded `completeness_status` (see `broker_submissions`).

### Lineage

* Source: `broker_submissions`.

### Usage

* Intake KPIs in the Underwriting Genie space and the morning brief.

### Caveats

* No join to `groups`, so all 25 submissions are counted, including the 23 `GRP-NB-*` groups.

---

## mv_quote_outcomes

**Description:** Metric view of the 18 governed new business quote scenarios from rate_new_business(); the only approved source of quoted rates.

**Body:**

### Overview

Fields: `Group`, `Pooling Point`, `Trend Scenario`, `Plan Option`, `Premium PMPM`, `Composite PEPM`, `Credibility`, `Rate Change vs Current`, `Projected Loss Ratio`. Query with `MEASURE()`.

### Column caveats

* `Projected Loss Ratio`: compare to the 88% target (`retention_targets`).
* `Rate Change vs Current`: quoted premium PMPM / incumbent current premium PMPM - 1.
* `Plan Option`: `alternate` is the alternate-deductible design (relativity 0.94).

### Lineage

* Source: `nb_quote_scenarios`.

### Usage

* Quote questions in the Underwriting Genie space, the experience rating explainer and the quote artifact.

### Caveats

* Northwind only, because the source is.

---

## mv_renewal_book

**Description:** Metric view of large group renewal book outcomes: renewing premium, projected loss ratio and premium at risk at uncapped and 12%-capped rate actions.

**Body:**

### Overview

Dimensions: `Renewal Quarter`, `Size Band`, `Industry`. Measures: `Renewing Premium` (sum of current annual premium), `Projected Loss Ratio (Uncapped)`, `Projected Loss Ratio (12% Cap)`, `Target Loss Ratio`, `Premium at Risk (Uncapped)`, `Premium at Risk (12% Cap)`, `Avg Recommended Rate Action`. Query with `MEASURE()`.

### Column caveats

* `Avg Recommended Rate Action` and every capped/uncapped measure are built on `renewal_pipeline.recommended_rate_action`, which is not a governed output (R1-11).
* `Target Loss Ratio`: 1 - retention (88%); large group MLR must stay at or above 85%.

### Lineage

* Source: `renewal_book_scenarios` (from `renewal_pipeline` and `persistency_curve`).

### Usage

* Renewal book questions in the Underwriting Genie space and the morning brief.

### Caveats

* Covers the 59 in-force renewals; Northwind is not included.
