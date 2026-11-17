# R1-04 100% parameterized, including the Genie Agent

**Status:** Open
**Origin:** Owner request, 2026-11-16. "Required parameters, no literal defaults" confirmed by the owner the same day.
**Related:** R1-01, R1-02, R1-03

## Problem

Catalog, schema, warehouse, tag keys and object names are hard-coded in several places, so a rename (R1-01) or a new target (`demo` = `hls_fde.uw_genie`) needs hand edits. The Genie space's table and metric view list is a literal file.

## Rules

1. No catalog, schema, warehouse or object name is hard-coded in source: SQL, notebooks, job YAML, skills, `waves.json`, Genie space definition. (Documentation examples are the only exception.) Values come only from the bundle per target: `${resources...}` inside a bundle, `${var...}` for cross-bundle values (R1-02).
2. **Required parameters, no literal defaults.** Notebook widgets and job parameters for catalog, schema, warehouse, paths and tag keys default to `""` and fail fast when blank.
3. **The Genie Agent is parameterized too.** Its tables, metric views, functions, example SQL and instructions are rendered per target from config, not literal `hls_fde_dev.uw_genie.*` identifiers. Adding or removing a table or metric view is a config change.
4. **Skills are rendered at publish time.** Source `SKILL.md` files keep `<catalog>.<schema>` placeholders; the publish step substitutes the target's values. (Build 0 session 08 replaced the placeholder in the committed source of `lg-intake-checklist/SKILL.md`; revert that to the placeholder.)
5. When copying reference code (for example `ground-truth-infra` notebooks for R1-03), drop its hard-coded fallbacks and literal widget defaults.

## Current state (evidence, grep 2026-11-16)

Files with literal `hls_fde_dev` / `hls_fde` / `uw_genie` / tag-key values (counts per file; some hits are legitimate, such as the resource key `uw_genie` in `${resources.schemas.uw_genie.*}` or per-target values in `databricks.yml`):

| File | Hits | What to do |
| --- | --- | --- |
| `uw-genie-agent/underwriting_genie.geniespace.json` | 32 | Template: render per target from a config of tables / metric views / functions / example SQL |
| `uw-genie-infra/databricks.yml` | 11 | Per-target variable values are fine; check defaults and comments |
| `docs/plans/waves.json` | 9 | Runtime targets, scopes and `context_notes`: reference variables or the deployed names written by setup |
| `uw-genie-agent/databricks.yml` | 7 | Per-target values only; no defaults that point at dev |
| `uw-genie-infra/src/notebooks/generate_synthetic_book.py` | 2 | Widgets default to `hls_fde_dev` / `uw_genie` / `underwriting` (lines 36-38): make required, empty default |
| `uw-genie-infra/src/notebooks/upload_packages.py`, `reset_demo.py` | 2 each | Same: required widgets |
| `uw-genie-infra/src/sql/00_ddl.sql`, `10_rate_new_business.sql`, `20_metric_views.sql` | 1 each | Check (likely comments or defaults); SQL takes `:catalog` / `:schema` / `:domain_tag` |
| `uw-genie-agent/resources/genie_spaces/underwriting_genie.genie_space.yml` | 1 | Comment about dev identifiers; goes away with the template |
| `docs/demo-assets/skills/lg-intake-checklist/SKILL.md` | 1 | Revert to `<catalog>.<schema>`; render at publish |

The other three skills use unqualified table names (for example `nb_quote_scenarios`); that works only through the Underwriting Genie agent. Decide whether skills should always use `<catalog>.<schema>.` prefixes rendered at publish.

### Genie agent title differs per target (found 2026-11-16)

In Genie One, the owner's Morning Brief routine prompt failed with "can't find the Underwriting Genie agent". In the dev deployment the Genie space (`01f1e1554179173991a4a487c2ae28ef`) is titled **`[dev matthew_giglia] Underwriting Genie`** (the bundle's development-mode name prefix), while all four skills, the L300-03 instructions and the demo prompts say "the Underwriting Genie agent". Genie One looks the agent up by name, so nothing matches. The skill tests earlier that day only passed because Genie One queried the tables directly instead of using the agent. Workaround in `docs/prompts/genie-one-demo-briefing-artifact.md`: `@`-mention the exact title, give the space ID, and fall back to the governed tables.

## Requested change

1. Make all widgets / job parameters for catalog, schema, warehouse, paths and tag keys required with empty defaults and a clear error.
2. Genie space: replace the literal `geniespace.json` with a template plus a per-target render step (bundle variables or a small render script run before deploy), covering the per-target `demo` render that session 07 asked for. The list of data sources lives in one config file.
3. Skills: keep placeholders in source; the publish step (session 08's method) substitutes per target. Optionally qualify every table reference.
4. `waves.json`: avoid literal deployed names where the framework allows; otherwise have setup write them.
5. **Agent title per target.** Treat the deployed Genie space title as a per-target value: render it into each skill and the demo prompts at publish time (for example an `<agent_title>` placeholder, filled from the deployed space), or keep a stable title on every target if the bundle allows overriding the development-mode prefix for the Genie space. Skills should also name the agent by its rendered title and say to `@`-mention it, with the governed tables as an explicit fallback.

## Acceptance criteria

* `grep -rn -E "hls_fde_dev|hls_fde\b"` in `uw-genie-infra/src`, `uw-genie-infra/resources`, `uw-genie-agent/resources`, the Genie space template and `docs/demo-assets/skills` returns nothing (per-target values in `databricks.yml` excepted).
* Running any notebook without parameters fails fast with a message naming the missing parameter.
* Deploying `dev` and `demo` produces Genie spaces whose data sources all resolve in their own catalog/schema.
* Published skills contain the target's schema; source skills contain only placeholders.
* On every target, a Genie One prompt that names the agent as the published skills do (for example "Use the uw-morning-brief skill and the Underwriting Genie agent") attaches the deployed Genie space without a manual `@`-mention.
