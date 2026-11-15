# Research 03 — AI Governance for Underwriting (NAIC Model Bulletin)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## Key thesis
Regulators don't ask insurers to avoid AI in underwriting; they ask insurers to **own** it — documented program, accountability, testing, explainability and audit. A governed platform makes that the default instead of a project.

## 1. The bulletin
- **NAIC Model Bulletin: Use of Artificial Intelligence Systems by Insurers**, adopted Dec 4, 2023.
- Central principle: the insurer remains responsible for decisions made or supported by AI, regardless of whether a human, model or vendor system made them.
- Applies to underwriting, rating/pricing, claims, fraud, marketing, product development and servicing.
- Adoption (NAIC map as of Nov 3, 2026): **27 states / 29 jurisdictions** (incl. DC and Puerto Rico); 2026 adopters include Mississippi, North Dakota, South Carolina and Puerto Rico. California, Colorado, New York and Texas have insurance-specific AI regulation/guidance instead.

## 2. Requirement → demo evidence map
| Bulletin expectation | Platform capability | Where the demo shows it |
|---|---|---|
| Written AIS program, lifecycle governance | Unity Catalog governs tables, functions, skills, Genie Agents; MLflow tracing | L100 governance section |
| Accountability / human decision authority | Genie recommends; underwriter decides; notes captured | Beat 2b "Underwriter notes" |
| Explainability | Waterfall + plain-English rationale, every factor cites assumption version | Beat 2b "How we got here" + "Assumptions & audit" |
| Data governance / lineage | UC lineage from documents → tables → function → artifact | Audit panel; L200-02 |
| Third-party / model risk controls | Rating math in a governed function, not the LLM; Unity AI Gateway for model traffic | Design principle 3 |
| Testing & monitoring | Deterministic unit tests on rating function; Genie benchmarks | L300-02, L300-03 |

## 3. Framing for business audiences
"Governed math, explained by AI": the model never computes rates; it calls the plan's rating method and explains the result. That single design choice answers most model-risk questions before they're asked.

## Sources
- NAIC — AI Model Bulletin adoption map (Nov 3, 2026): https://content.naic.org/sites/default/files/legal-adoption-map-ai-model-bulletin.pdf
- NAIC — Model Bulletin: Use of Artificial Intelligence Systems by Insurers (Dec 4, 2023)
