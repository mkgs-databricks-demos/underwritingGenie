# Research 06 — Open Decisions: Recommendations Assumed for Today

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


Matt asked: where input is needed, research, recommend, and assume the recommendation. Each decision below is **ASSUMED** until Matt overrides it. Overrides should be logged in `sessions/`.

| # | Decision | Options considered | **Recommendation (assumed)** | Rationale |
|---|---|---|---|---|
| D1 | Project folder | reuse an existing underwriting folder vs new | New folder `underwritingGenie/` (Git folder; originally proposed as `genie-one-large-group-underwriting/`) | Existing folders contain account-specific material; this package must be carrier-neutral |
| D2 | Catalog / schema | dedicated catalog vs home catalog | Declarative Automation Bundle variables `catalog` / `schema`; default **`lg_underwriting_dev`.`demo`** (follows `<function>_<env>` convention); fallback `home_<user>.lg_uw_demo` if catalog creation isn't permitted | Portable to any workspace with Artifacts beta on |
| D3 | Group size for hero quote | 1,850 EEs (v0.2 canvas) vs smaller | **Northwind Manufacturing: 420 enrolled employees, ~980 members** | At 1,850 EEs credibility would be 100% and the blend disappears; 420 EEs keeps Z between 0.63 and 0.89 |
| D4 | Credibility rule | square-root, Bühlmann, recursive multi-year | **Square-root, full-credibility standard keyed by pooling point (30K/42K/60K MM)** | Simplest explainable rule; pooling-dependent standard mirrors filed practice |
| D5 | Trend scenarios | single vs 3 scenarios | **Low 7.5% / Base 9.0% / High 10.5% blended annual, 2.0 trend years** | Base anchored to public 2027 group trend projection |
| D6 | Retention / target loss ratio | 10–15% | **12% retention ⇒ 88% target loss ratio** | Clears the 85% large group MLR floor with margin |
| D7 | Artifact interactivity | live controls vs precomputed | **Precompute 18 scenarios; ask Genie for a scenario selector; fallback = comparison panel + Ask Genie** | Artifacts are snapshot-based (no live queries yet) |
| D8 | Where rating logic lives | LLM, notebook, UC function | **UC SQL table function `rate_new_business()` + materialized `nb_quote_scenarios`**; registered as Genie Agent trusted asset | "Governed math, explained by AI"; verified-answer badge |
| D9 | Document ingestion in demo | `ai_parse_document` pipeline vs chat upload | **Chat upload for the demo**; production design uses `ai_parse_document` → `ai_extract` pipeline (L200-01 extension) | Lowest-risk live moment; pipeline story kept for architecture |
| D10 | Build tooling | hand-built vs Genie Code | **Genie Code interactive sessions in a Declarative Automation Bundle repo** (Rapid Ontology Standup style), 8 sessions in 4 waves | Repeatable, reviewable, reusable by any FDE |
| D11 | Incumbent comparison | none vs incumbent renewal | **Broker email says incumbent offered +14.2%; our base quote is +2.2% vs current** | Gives the business audience a "win" moment without naming carriers |
| D12 | Review gate | skip vs Genie artifact review | **Produce a review Genie Artifact before SVG/HTML rendering** (prompt in L400-02) | Matches standard practice |
