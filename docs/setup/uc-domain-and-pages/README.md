# Set up the Underwriting domain and glossary pages in Unity Catalog

How to recreate the **Underwriting** domain in Discover and its UC glossary pages for an Underwriting Genie deployment, using a governed tag key of your choice.

**Status:** manual setup, first done 2026-11-16 on `hls_fde_dev.uw_genie` with the tag key `mkgs_underwriting`. Build 1 should automate the parts that can be automated (see [Automation notes](#automation-notes)).

## What you end up with

* A **governed tag** (tag policy) `<TAG_KEY>` with 3 allowed values: `core`, `intake_quote`, `uw_finance`.
* Every Underwriting Genie table, view, metric view, the schema, the broker-packages Volume and the Genie Agent tagged with it.
* A **Discover domain** "Underwriting" built on that governed tag.
* **UC glossary pages** for the underwriting business terms, linked to their tables, columns, functions and metric view measures.

## Values used in this guide

Replace these placeholders everywhere below.

| Placeholder | Meaning | Value used on 2026-11-16 (dev) |
| --- | --- | --- |
| `<TAG_KEY>` | Governed tag key for the domain | `mkgs_underwriting` |
| `<CATALOG>` | Catalog of the deployment | `hls_fde_dev` |
| `<SCHEMA>` | Schema of the deployment | `uw_genie` |
| `<AGENT_TITLE>` | Deployed Genie Agent title | `[dev matthew_giglia] Underwriting Genie` |

### Choosing `<TAG_KEY>`

* Use a key that **is not already governed with other values**. In the `fevm-hls-fde` account, the governed keys `domain`, `subdomain`, `data_class` and `pii` exist but have no underwriting values (for example `domain` allows only finance, sales, supply_chain, quality, hr, operations). Tagging with them fails unless a tag-policy owner adds values.
* The bundle variable `domain_tag` decides which key the setup job writes: the default is `underwriting`; the dev target overrides it to `mkgs_underwriting`. Set it to your `<TAG_KEY>` so the objects are tagged at deploy time.

## Prerequisites

* The Underwriting Genie bundles are deployed (`uw-genie-infra`, then `uw-genie-agent`) and the **Setup Demo** job has run.
* Permission to **create a governed tag** (account admin, or a user granted tag-policy creation) and to **assign** it (the tag's Assign permission plus `APPLY TAG` on the objects).
* Access to **Discover** to create a domain and glossary pages.

## Step 1: Tag the objects (bundle)

Deploy `uw-genie-infra` with `domain_tag` set to `<TAG_KEY>` (per target in `databricks.yml`, or `--var domain_tag=<TAG_KEY>` on both `bundle deploy` and `bundle run`). The Setup Demo job tags each table and view with one of 3 values:

| Value | Meaning | Objects (2026-11-16) |
| --- | --- | --- |
| `core` | Shared book and rating data | 18 tables (for example `groups`, `census_members`, `claims_monthly`, `renewal_pipeline`, `broker_submissions`) |
| `intake_quote` | Intake and quote metrics | `mv_intake_ops`, `mv_quote_outcomes` |
| `uw_finance` | Quote scenarios and renewal finance | `nb_quote_scenarios`, `nb_quote_waterfall`, `renewal_scenarios`, `renewal_book_scenarios`, `mv_renewal_book` |

Check what is tagged (run in a SQL editor):

```sql
SELECT 'table' AS kind, table_name AS obj, tag_value FROM <CATALOG>.information_schema.table_tags
 WHERE tag_name = '<TAG_KEY>' AND schema_name = '<SCHEMA>'
UNION ALL SELECT 'schema', schema_name, tag_value FROM <CATALOG>.information_schema.schema_tags
 WHERE tag_name = '<TAG_KEY>' AND schema_name = '<SCHEMA>'
UNION ALL SELECT 'volume', volume_name, tag_value FROM <CATALOG>.information_schema.volume_tags
 WHERE tag_name = '<TAG_KEY>' AND schema_name = '<SCHEMA>'
ORDER BY kind, tag_value, obj;
```

Expected after all steps: 25 tables / views (18 `core`, 2 `intake_quote`, 5 `uw_finance`), 1 schema (`core`) and 1 volume (`core`).

## Step 2: Make `<TAG_KEY>` a governed tag

In **Catalog Explorer -> Governed tags -> Create**:

* **Tag key:** `<TAG_KEY>`
* **Allowed values:** `core`, `intake_quote`, `uw_finance`. Use exactly these, so the existing assignments from step 1 stay valid and the setup job keeps working.
* **Description:** "Underwriting Genie demo domain (synthetic). Values: core = shared book and rating data; intake_quote = intake and quote metrics; uw_finance = quote scenarios and renewal finance."
* **Tag propagation (optional):** enable with default value `core`, so new objects in the schema inherit `core`. This was enabled on 2026-11-16.
* **Permissions:** grant Assign to whoever deploys the bundle (or its service principal), or step 1 will fail on the next deploy.

You can do step 2 before step 1; the setup job then writes governed values directly.

## Step 3: Tag the schema and the Volume

The setup job does not tag these today. In a SQL editor:

```sql
ALTER SCHEMA <CATALOG>.<SCHEMA> SET TAGS ('<TAG_KEY>' = 'core');
ALTER VOLUME <CATALOG>.<SCHEMA>.broker_packages SET TAGS ('<TAG_KEY>' = 'core');
```

## Step 4: Tag the Genie Agent

The Genie Agent (Genie space) is not a Unity Catalog object, so the SQL above does not cover it. Open the deployed agent (`<AGENT_TITLE>`) and add the tag `<TAG_KEY>` = `core` in its settings. This was done manually on 2026-11-16 for the dev agent.

Note: in development mode the agent title has a `[dev <user>]` prefix. Genie One finds the agent by title, so use the exact `<AGENT_TITLE>` (or `@`-mention it) in prompts.

## Step 5: Create the domain in Discover

In **Discover**, create a domain:

* **Name:** Underwriting
* **Governed tag:** `<TAG_KEY>` (all 3 values)
* **Description:** "Large group underwriting for Lakeside Health Plan (synthetic demo): intake, experience rating, quotes and renewal finance."

The domain should list the 27 tagged UC assets from steps 1 and 3, plus the Genie Agent from step 4.

## Step 6: Create the glossary pages

In Discover, start a new business-term page in the Underwriting domain, then paste this prompt into its assistant (replace the placeholders first):

```
Create UC glossary pages in the "Underwriting" domain (governed tag <TAG_KEY>) for the Underwriting Genie demo. All data is synthetic for a fictional carrier, Lakeside Health Plan.

Source of truth for each term's definition, business context, data usage and related terms:
- /Workspace/Users/matthew.giglia@databricks.com/underwritingGenie/docs/semantics/01_rating_and_experience_terms.md (section "Rating & Experience")
- /Workspace/Users/matthew.giglia@databricks.com/underwritingGenie/docs/semantics/02_intake_and_quote_terms.md (section "Intake & Quote")
- /Workspace/Users/matthew.giglia@databricks.com/underwritingGenie/docs/semantics/03_financial_outcome_terms.md (section "Underwriting Finance")

Start with these 13 priority terms, one page each:
Rating & Experience: Credibility (Z), Pooling Point, Pooling Charge, Manual Rate, Completion Factor, Incurred Claims
Intake & Quote: Submission Completeness, Blocking Item, Census, Tier Rate
Underwriting Finance: Projected Loss Ratio, Target Loss Ratio, Premium at Risk

For each page: use the term as the title; include Definition, Business context and Related terms from the source file; link the data assets named under "Data usage" in <CATALOG>.<SCHEMA> (tables, columns, the functions rate_new_business and rate_renewal, and the metric views mv_quote_outcomes, mv_renewal_book, mv_intake_ops). Link only objects that exist; if a referenced table, column or measure doesn't exist, skip that link and tell me which ones you skipped. Note: the metric view measures are named "Premium at Risk (Uncapped)" / "Premium at Risk (12% Cap)" and "Projected Loss Ratio" / "Projected Loss Ratio (Uncapped)" / "Projected Loss Ratio (12% Cap)".

Keep the wording business-friendly and carrier-neutral; no real company names. Mark pages as synthetic demo content. When the 13 are done, list them and ask before creating the remaining 17 terms.
```

The source files hold 30 terms (13 + 10 + 7); the 13 above are their priority (P1) terms. Create the other 17 the same way when needed.

If your copy of the repo lives elsewhere, change the three source paths.

## Step 7: Verify

* Re-run the step 1 query: 25 tables / views + 1 schema + 1 volume, all with allowed values.
* The governed tag page (**Catalog Explorer -> Governed tags -> `<TAG_KEY>`**) lists the tagged assets and the 3 values.
* The Underwriting domain shows the assets, the Genie Agent and the glossary pages.
* Each page links to objects that exist; review the list of skipped links the assistant reports.

## Known issues

* **Source references.** Some "Data usage" lines in `docs/semantics/` point to objects or names that do not exist (for example `quotes.effective_date`, `mv_renewal_book.premium_at_risk`); that is why the prompt skips missing links. Fixing the source files is a build 1 item.
* **Renewal numbers.** The definitions of Premium at Risk and Projected Loss Ratio are correct, but the stored renewal rate actions behind `mv_renewal_book` are not yet the governed function's outputs (build 1 request R1-11). Show the pages, not those renewal numbers.
* **Functions.** The rating functions (`rate_new_business`, `rate_renewal`) are linked from pages but were not tagged in this setup.

## Automation notes

For build 1 (see `docs/requests/build-1/INDEX.md`, R1-04 parameterization):

* Tag the schema and Volume in the setup job (step 3), using the same `domain_tag` variable.
* Optionally create the governed tag (step 2) from the bundle or a setup task when the deployer has permission; otherwise keep it as a documented prerequisite.
* Tag the Genie Agent after deploy (step 4) and render the deployed agent title into skills and prompts (R1-04, change 5).
* Keep the glossary prompt (step 6) with placeholders and render it per target.

## Related files

* `docs/semantics/01_rating_and_experience_terms.md`, `02_intake_and_quote_terms.md`, `03_financial_outcome_terms.md`: term definitions
* `docs/design/L300-03_metric_views_and_genie_agent_config.md` §3: UC Pages design
* `docs/requests/build-1/R1-04_full-parameterization.md`: per-target names and the agent title
