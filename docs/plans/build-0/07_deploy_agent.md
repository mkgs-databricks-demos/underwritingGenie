# Session 07 — Deploy Agent + Verify Genie Agent

**Wave:** 0-3 (converge)
**Mode:** converge
**Depends on:** 02, 06
**Max attempts:** 5
**Timeout:** 120 minutes

## Goal

Deploy `uw-genie-agent` to dev so the Genie Agent "Underwriting Genie" is created or updated. Verify the space is on the infra warehouse, all data sources resolve, every example SQL passes EXPLAIN, and probe questions return correct answers. Never deploy `uw-genie-infra`.

## Context files to read first

* `docs/design/L300-03_metric_views_and_genie_agent_config.md` — sections 4-5: instructions, example SQL, benchmarks
* `docs/design/L200-03_semantics_and_genie_agent.md` — agent design
* `PROJECT_MEMORY.md` — non-negotiable rules

## Runtime targets

* `genie_space` — Genie Agent must exist with correct data sources, warehouse, example SQL, and probe questions

## Steps

1. Run `databricks bundle validate --strict --target dev` in `uw-genie-agent/`.
2. Run `databricks bundle deploy --target dev` in `uw-genie-agent/`.
3. Read back the Genie Agent (warehouse, data sources, column configs).
4. EXPLAIN every example SQL on the agent's warehouse — all must pass.
5. Ask the five probe questions (benchmarks 1-5):
   - "What is the Family rate for Northwind Manufacturing at $250K pooling, base trend, requested plan?" (expected: $2,290.21)
   - "What is Northwind credibility at $150K, $250K, and $500K pooling points?" (expected: 0.6066, 0.7483, 0.8773)
   - "What is Northwind premium change vs current, base case?" (expected: +2.2%)
   - "Is Northwind v1 submission ready to quote?" (expected: No, BLOCKED)
   - "How much was removed by pooling at $250K for Northwind?" (expected: $3,681.20)
6. If any check fails, fix the genie bundle within owned_paths, re-validate, and re-deploy.
7. Record the Genie Agent space ID in the session summary.

## Owned paths

* `uw-genie-agent/**` (all files in the agent bundle)

## Acceptance criteria

* Genie Agent exists with title "Underwriting Genie"
* Agent is on the infra warehouse (uw_genie_warehouse)
* All data sources (tables, metric views) resolve
* Every example SQL passes EXPLAIN
* All 5 probe questions return correct answers (probe_mode: warn — warnings are acceptable, errors are not)
* Session status is `pass` with final attempt classified `stable`
* Space ID recorded in session summary
