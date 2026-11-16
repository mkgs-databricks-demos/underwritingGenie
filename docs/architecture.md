# Underwriting Genie — Architecture

All data is synthetic and carrier-neutral. This page describes how the repo is split into two Declarative Automation Bundles, how data flows from DDL to the Genie Agent, the deploy order, and how build 0 was produced with Genie Build Waves. Deployed IDs are in [README.md](../README.md#deployed-resources-target-dev-2026-11-16).

## Two-bundle split

| Bundle | Folder | Owns | Does not own |
| --- | --- | --- | --- |
| `uw-genie-infra` | `uw-genie-infra/` | UC schema `uw_genie`, managed volume `broker_packages`, serverless SQL warehouse `uw_genie_warehouse`, jobs `setup_demo` and `reset_demo`, SQL sources (`src/sql/`) and notebooks (`src/notebooks/`) | the Genie Agent |
| `uw-genie-agent` | `uw-genie-agent/` | the Genie Agent "Underwriting Genie" (`resources/genie_spaces/underwriting_genie.genie_space.yml`, serialized space file `underwriting_genie.geniespace.json`) | the schema, tables and warehouse it reads |

The split keeps data and compute lifecycle (slow, stateful) apart from the agent definition (fast to iterate). The agent bundle only *uses* the infra objects; it never defines or deploys them.

Targets in both bundles: `dev` (default, catalog `hls_fde_dev`) and `demo` (production mode, catalog `hls_fde`); schema `uw_genie` in both.

* **infra `dev`** does not use `mode: development`, because development mode would rename the schema to `dev_<user>_uw_genie` and break the `hls_fde_dev.uw_genie` contract. Instead it sets `var.name_prefix = "[dev <short_name>] "` on job and warehouse names, pauses triggers, and adds tags. Variable `domain_tag` (dev/demo: `mkgs_underwriting`) is the governed tag key used by the SQL files.
* **agent `dev`** uses `mode: development`, which prefixes the space title with `[dev <short_name>] `.

## Data flow

```
00_ddl.sql            create tables + tags in ${catalog}.${schema}
   |
generate_synthetic_book.py   synthetic groups, census, claims (shared module uw_seed.py)
upload_packages.py           broker packages (docs/demo-assets) -> volume broker_packages
   |
10_rate_new_business.sql     rate_new_business() + rate_renewal() table functions,
                             nb_quote_scenarios (18-scenario grid), waterfall, renewal scenarios
   |
20_metric_views.sql          renewal_book_scenarios + metric views
                             mv_quote_outcomes, mv_renewal_book, mv_intake_ops
   |
90_tests.sql                 golden-CSV and invariant tests (raise_error on failure)
   |
Genie Agent "Underwriting Genie"   tables, metric views and the two rating functions as trusted assets
   |
Genie One + UC Skills        lg-intake-checklist, experience-rating-explainer, nb-quote-artifact, uw-morning-brief
```

The `setup_demo` job runs these steps as six tasks in order: `create_tables` -> `generate_synthetic_book` -> `upload_packages` -> `build_nb_quote_scenarios` -> `create_metric_views` -> `run_tests`. SQL tasks run on the bundle warehouse with `catalog`, `schema` and `domain_tag` parameters. `reset_demo` (`src/notebooks/reset_demo.py`) restores the demo state.

Governed math rule: rates, credibility, pooling and trend come only from `rate_new_business()` / `nb_quote_scenarios`. The Genie Agent calls the function; skills forbid freehand rate math.

## Deploy order

1. `uw-genie-infra`: `bundle deploy --target <t>`, then run `setup_demo` (the deploy starts no run).
2. `uw-genie-agent`: `bundle deploy --target <t>`. Deploy writes the Genie space from the serialized file. Its warehouse lookup fails if the infra warehouse does not exist yet, so infra must come first.
3. UC Skills: publish the four skills from `docs/demo-assets/skills/` to `${catalog}.${schema}` with `w.ai_gateway.create_skill` + `w.files.upload(/Skills/...)` + `w.ai_gateway.finalize_skill` (there is no bundle resource for skills), and copy them to `~/.assistant/skills/<name>/`.

## How the agent bundle finds the infra objects

* **Schema:** bundle variables `catalog` / `schema` are set per target to the same values as the infra bundle (`hls_fde_dev` / `uw_genie` in dev). The serialized space refers to tables by these fully qualified names.
* **Warehouse:** variable `warehouse_id` is a `lookup` by warehouse name per target: `[dev ${workspace.current_user.short_name}] uw_genie_warehouse` in dev, `uw_genie_warehouse` in demo. Renaming the infra warehouse or its prefix breaks this lookup.
* Open item: the `demo` target still needs a rendered serialized space (or per-target space file) for `hls_fde.uw_genie`.

## Build method: Genie Build Waves (build 0)

Build 0 was produced by the genie-build-waves framework (`docs/plans/waves.json`, plan index `docs/plans/INDEX.md`), run by the `uw-genie: Build Waves` job on branch `mg-genie-uw-genie-build-1`, with a Devin monitor at level 4.

* **Waves** run in order; **sessions** inside a wave run in parallel as Genie Code tasks. Each session owns a set of paths (`owned_paths`) and writes a summary in `docs/sessions/` plus a status file in `.build-status/<run_id>/`.
* Session modes: `edit` (author files), `converge` (deploy + run + diagnose + fix runtime targets in a bounded loop).
* After each wave an **integrator** checks ownership and strays, commits and pushes; a **gate** checks static criteria (bundle validate, files) or runtime targets (job success, table row counts, Genie space, skills).

| Wave | Type | Sessions |
| --- | --- | --- |
| 0-0 | edit | 01 infra bundle + DDL, 02 agent bundle |
| 0-1 | edit | 03 rating function + tests, 04 metric views, 05 notebooks |
| 0-2 | converge | 06 deploy infra + run setup_demo |
| 0-3 | converge | 07 deploy agent + verify Genie Agent |
| 0-4 | converge | 08 publish UC Skills |
| 0-5 | edit | 09 docs (this page, README, PROJECT_MEMORY) |
