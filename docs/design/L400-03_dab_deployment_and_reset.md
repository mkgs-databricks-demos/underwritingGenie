# L400-03 — Declarative Automation Bundle Deployment, Reset and Cost

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## 1. Repo layout
```
underwritingGenie/
├── databricks.yml                 # targets: dev (default), demo
├── resources/
│   ├── schema.yml                 # schema + volume broker_packages
│   └── jobs.yml                   # setup_demo, reset_demo
├── src/
│   ├── sql/00_ddl.sql  10_rate_new_business.sql  20_metric_views.sql  90_tests.sql
│   ├── notebooks/generate_synthetic_book.py  upload_packages.py  reset_demo.py
│   └── genie/large_group_underwriting_cockpit.json
└── docs/  (this package; demo-assets/ holds packages, skills, golden CSV)
```
```yaml
# databricks.yml (excerpt)
bundle: {name: lg-underwriting-cockpit}
variables:
  catalog: {default: lg_underwriting_dev}
  schema: {default: demo}
  warehouse_id: {description: Serverless SQL warehouse}
targets:
  dev:  {default: true, mode: development}
  demo: {mode: production}
```

## 2. Jobs
| Job | Tasks | Runtime |
|---|---|---|
| `setup_demo` | create_tables → generate_synthetic_book → upload_packages → build_nb_quote_scenarios → run_tests | serverless, < 10 min |
| `reset_demo` | truncate `submission_findings`; restore `broker_submissions` statuses; rebuild scenarios; run_tests | < 5 min |
Artifacts, Gmail drafts and chats are reset manually (listed in L400-02 §2/§5).

## 3. Permissions
Demo users group: USE CATALOG/SCHEMA, SELECT on all objects, EXECUTE on `rate_new_business` / `rate_renewal`, READ VOLUME on `broker_packages`, CAN RUN on the Genie Agent.

## 4. Neutrality check (CI step)
`grep -rinE "<prohibited-names-list>" docs src demo-assets` must return nothing. Maintain the prohibited list (carrier, customer, vendor and colleague names) outside the repo.

## 5. Cost (directional)
Serverless SQL for setup and tests (minutes per run), Genie One/Agent usage during dry runs and the demo. Expected well under typical demo-workspace budgets; track with system billing tables if the workspace is shared.

## 6. Teardown
`databricks bundle destroy -t demo` removes jobs; drop schema `CASCADE` manually after confirming; delete backup artifact only if retiring the demo.
