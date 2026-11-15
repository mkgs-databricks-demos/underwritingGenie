# L100 — Underwriting Cockpit: Large Group Experience Rating with Genie One (Demo Constitution)

Matthew Giglia | Field Engineering · v1.0-draft · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


> Supersedes canvas design v0.3. Decisions marked **ASSUMED** are recorded in [research/06](../research/06_design_decisions_assumed.md).

## 1. Purpose
A 12–15 minute, carrier-neutral, synthetic-data demo that shows **underwriting of the future** for fully insured, experience-rated large group business: intake completeness at the front door, a governed experience-rated new business quote delivered as an **interactive Genie Artifact**, and a direct line from underwriting decisions to financial outcomes.

## 2. Story and principles
"Underwriting is a document and data-assembly problem posing as a math problem."
1. People, not plumbing (no code on screen). 2. Move underwriting to intake. 3. **Governed math, explained by AI** — rates come only from a UC function. 4. The underwriter decides. 5. Ontology makes answers *correct*, not just accurate. 6. Genie One is a coworker, not a dashboard.

## 3. Demo beats → components
| Beat | Persona | Prompt (abridged) | Components |
|---|---|---|---|
| 1 Morning brief | UW leader | (scheduled) | C6 scheduled task, C3 Genie Agent, C1 data |
| 2 Ready to quote? | AE / UW | "Is this ready to quote? Draft a reply." | C4 intake skill, C1 checklist, Gmail MCP, package v1 |
| 2b Interactive NB quote | UW → AE → broker | "Rate Northwind… build an interactive New Business Quote" | C2 rating function, C5 artifact skill, package v2 |
| 3 Renewal (optional) | UW | "Build the renewal for Lakeview Logistics" | C2, C3 |
| 4 Decisions → dollars | CFO / actuarial | "Projected loss ratio vs target… premium at risk at 12% cap" | C3 metric views, Pages |

> See [diagrams/mermaid/02_future_state_cockpit.md](../diagrams/mermaid/02_future_state_cockpit.md) and [03_demo_architecture.md](../diagrams/mermaid/03_demo_architecture.md).

## 4. Component inventory
| ID | Component | L200 | Owner (build session) |
|---|---|---|---|
| C1 | Synthetic data foundation (tables, volume, broker packages) | L200-01 | S1, S2, S4 |
| C2 | Governed rating engine (assumption tables, `rate_new_business` SQL table function, `nb_quote_scenarios`, renewal view) | L200-02 | S3 |
| C3 | Semantics + Genie Agent (metric views, UC Pages, agent, trusted assets, benchmarks) | L200-03 | S5, S6 |
| C4 | Genie One skills (intake checklist, rating explainer, morning brief) | L200-04 | S7 |
| C5 | Interactive New Business Quote artifact (skill + backup artifact) | L200-05 | S8 |
| C6 | Scheduled Morning Brief | L200-06 | S7 |
| C7 | Demo script, Genie One session instructions & acceptance criteria | L200-07 | S8 |

All components can be built in 4 waves; within a wave, sessions run in parallel ([07_build_waves_gantt](../diagrams/mermaid/07_build_waves_gantt.md)).

## 5. Interface contracts
| From → To | Contract |
|---|---|
| C1 → C2 | Tables in `${catalog}.${schema}` per L300-01; keys `group_id`, `incurred_month`, `claimant_id` |
| C2 → C3/C5 | `nb_quote_scenarios` — one row per (group_id, pooling_point, trend_scenario, plan_option, assumption_version); columns per L300-02 |
| C3 → Genie One | Genie Agent "Large Group Underwriting Cockpit"; trusted asset `rate_new_business`; metric views `mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops` |
| C4/C5 → Genie One | UC Skills `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief` (published + workspace copy) |
| C5 → audience | Artifact "Northwind Manufacturing — New Business Quote" (8 sections, L200-05) |

## 6. Technology decisions
| Decision | Choice | Why |
|---|---|---|
| Rating math | UC SQL table function + materialized scenarios | Deterministic, testable, lineage, verified answers |
| Artifact data | Precomputed snapshot (18 scenarios) | Artifacts have no live queries yet |
| Document handling (demo) | Chat upload | Lowest risk; production uses `ai_parse_document` pipeline |
| Deployment | DAB with variables `catalog`, `schema`, `warehouse_id` | Portable; reset job |
| Build method | 8 Genie Code sessions, 4 waves | Repeatable by any FDE |

## 7. Cross-cutting patterns
- **Governance:** everything in one schema; tags `domain=underwriting`, `data_class=synthetic`; EXECUTE on function granted to demo users; synthetic label on every artifact.
- **Determinism:** golden expected file `demo-assets/nb_quote_scenarios_expected.csv`; tests assert function output = golden within $0.01.
- **Observability:** Genie One traces and Genie Agent benchmarks; dry-run log in `sessions/`.
- **Safety:** skills forbid freehand rate math; email = draft only; no sending.
- **Neutrality:** no carrier, customer, vendor or employee names anywhere in data, prompts, artifacts or slides.

## 8. Reference numbers (base scenario, all synthetic)
Northwind Manufacturing — 420 enrolled employees, 980 members, 23,520 member months, 1/1/2027 effective; pooling point $250K, base trend 9.0%, requested plan:
| Step | Value |
|---|---|
| Completed incurred claims (24 mo) | $10,590,477 (IBNR $110,477) |
| Excess over $250K removed | $540,000 → pooled $10,050,477 |
| Experience PMPM (historical) | $427.32 |
| × trend 1.1881 × demo 1.010 + pooling charge $24.00 | Projected experience $536.77 |
| Manual rate | $590.45 |
| Credibility Z | 0.748 |
| Blended claims PMPM | $550.28 |
| Premium PMPM (12% retention) | $625.32 → composite $1,459.07 PEPM |
| Tier rates (EE / ES / EC / EF) | $803.58 / $1,607.16 / $1,486.63 / $2,290.21 |
| vs incumbent current ($612.00 PMPM) | **+2.2%** (broker says incumbent renewal offer was +14.2%) |
Full grid: 18 scenarios, premium change range −7.8% to +7.3%.

## 9. Operational standards (demo)
- Dry-run 3× end-to-end within 24h of delivery; artifact generation ≤ 3 min or switch to backup.
- Reset job restores package state and deletes chat-generated drafts/artifacts (manual for artifacts).
- Incident: if Genie Agent or Artifacts degraded, run backup recording + backup artifact.

## 10. Reuse roadmap
Stop-loss / ASO quoting (same pooling + intake), small group manual-rated variant, broker front-door app (Databricks App over the same function), production document pipeline (`ai_parse_document` → `ai_extract`).

## 11. Review gate
Before rendering SVG/HTML, produce the review Genie Artifact (prompt in L400-02 §6) with diagrams, this outline and open questions; save in shared `genie_artifacts`.
