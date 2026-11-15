# Research 04 — Genie One and Platform Capabilities Used by the Demo

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## Capability inventory (as documented, Nov 2026)
| Capability | What it does | Demo use | Status / limits |
|---|---|---|---|
| **Genie One chat** | Workspace-wide AI coworker; reads uploaded files, queries governed data, calls tools over MCP | All beats | GA |
| **Skills (Genie One)** | Text-only skill folders (≤3 levels, ≤50 files), auto-loaded when relevant or invoked with `/name`; shareable; available in scheduled tasks; up to 50 active in chat | Intake checklist, rating explainer, quote artifact, morning brief | Text files only — no PDFs/images inside skills |
| **Artifacts (Beta)** | Genie builds slide decks and custom visual pages from data, saved to workspace; editable (text, charts, images); viewers can **Ask Genie** about any chart or number | New Business Quote artifact (Beat 2b) | Admin must enable in Previews. Artifacts hold a **snapshot** of data; **no live queries yet** (roadmap) |
| **Scheduled tasks** | Recurring prompts that produce a chat; shared skills apply | Morning brief (Beat 1) | GA |
| **Genie Agents (formerly spaces)** | Curated tables, instructions, example SQL, **trusted assets** (parameterized queries + UC SQL functions → "verified answers"), benchmarks | "Large Group Underwriting Cockpit" agent | Users need EXECUTE on functions |
| **UC functions** | Governed SQL/Python functions; SQL table functions return tables and can read governed tables (Python UDFs/UDTFs cannot query tables) | `rate_new_business()` SQL table function returns the full rating result | Register in UC; usable as Genie trusted asset |
| **Metric views** | Governed measures/dimensions (YAML) | Loss ratio, premium at risk, cycle time | GA |
| **UC Pages / glossary** | Governed business definitions | ~20 terms (semantics/) | — |
| **Gmail MCP** | Draft (not send) broker reply | Beat 2 | Requires user connection |

## Design consequences
1. **Artifact snapshot ⇒ precompute.** Because artifacts store data snapshots, the rating function precomputes all 18 lever combinations (3 pooling × 3 trend × 2 plan) into `nb_quote_scenarios`. The artifact switches between governed results; nothing is calculated in the browser.
2. **Interactivity risk.** Docs describe editable charts/text and Ask Genie, not form controls. **Recommendation (assumed today):** ask Genie for a scenario selector (tabs or toggle buttons); acceptance fallback = a scenario comparison panel (small multiples) + Ask Genie on any number. Both satisfy the story.
3. **Skills can't hold PDFs** ⇒ broker documents live in a UC Volume and are uploaded to chat during the demo; skills hold checklists and instructions as markdown.
4. **Verified answers** — registering the rating function as a trusted asset in the Genie Agent gives the "verified" badge, reinforcing "governed math."

## Sources
- Artifacts in Genie One: https://learn.microsoft.com/en-us/azure/databricks/genie-one/artifacts/
- Chat in Genie One (skills, artifacts, limits): https://learn.microsoft.com/en-us/azure/databricks/genie-one/chat/
- Tune Genie Agent quality (example SQL, trusted assets, parameters): https://learn.microsoft.com/en-us/azure/databricks/genie-agents/tune-quality/
- Python UDTFs in Unity Catalog: https://learn.microsoft.com/en-us/azure/databricks/udf/udtf-unity-catalog/
- SQL and Python UDFs in Unity Catalog: https://learn.microsoft.com/en-us/azure/databricks/udf/unity-catalog/
- Genie Code scheduled tasks: https://learn.microsoft.com/en-us/azure/databricks/genie-code/scheduled-tasks/
