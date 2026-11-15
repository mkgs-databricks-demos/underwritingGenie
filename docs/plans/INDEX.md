# Build Plans Index

## Build 0 — Genie Build Waves (combined edit + converge)

**Branch:** `mg-genie-uw-genie-build-1`
**Manifest:** `waves.json`
**Vars:** `build-waves.vars.json`
**Monitor:** Devin level 4 (`mkgs-devin`, `CAN_MANAGE_RUN`)

### Wave summary

| Wave | Type | Sessions | Gate |
| --- | --- | --- | --- |
| 0-0 | edit (parallel) | 01 Infra bundle + DDL, 02 Agent bundle | static: bundle validate + files exist |
| 0-1 | edit (parallel) | 03 Rating function + tests, 04 Metric views, 05 Notebooks | static: bundle validate + files exist |
| 0-2 | converge | 06 Deploy infra + run setup_demo | runtime: job SUCCESS + row counts |
| 0-3 | converge | 07 Deploy agent + verify Genie Agent | runtime: genie space + example SQL |
| 0-4 | converge | 08 Publish UC Skills | runtime: skills exist in UC + workspace |
| 0-5 | edit | 09 Docs (README deployed IDs, architecture) | static: files exist + bundle validate |

### Session plans

| ID | Title | Plan file |
| --- | --- | --- |
| 01 | Infra bundle: databricks.yml, schema, warehouse, jobs, DDL | `build-0/01_infra_bundle.md` |
| 02 | Agent bundle: databricks.yml, genie space serialized file | `build-0/02_agent_bundle.md` |
| 03 | Rating function + golden CSV tests | `build-0/03_rating_function.md` |
| 04 | Metric views (3 views + renewal_book_scenarios) | `build-0/04_metric_views.md` |
| 05 | Notebooks (generate_synthetic_book, upload_packages, reset_demo) | `build-0/05_notebooks.md` |
| 06 | Deploy infra + run setup_demo | `build-0/06_deploy_infra.md` |
| 07 | Deploy agent + verify Genie Agent | `build-0/07_deploy_agent.md` |
| 08 | Publish UC Skills (4 skills) | `build-0/08_publish_skills.md` |
| 09 | Docs (README deployed IDs, architecture) | `build-0/09_docs.md` |

### Devin monitor prompt

`build-0/devin-monitor-prompt.md`
