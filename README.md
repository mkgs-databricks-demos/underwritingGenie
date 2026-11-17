# underwritingGenie

**Underwriting Genie — Large Group Experience Rating with Genie One**

A 12–15 minute, carrier-neutral, synthetic-data Databricks demo showing *underwriting of the future* for fully insured, experience-rated large group health business:

* **Intake completeness at the front door** — Genie One checks a broker package and drafts the reply ("Is this ready to quote?").
* **Governed math, explained by AI** — rates come only from a Unity Catalog SQL table function (`rate_new_business()`), never from the LLM, and are delivered as an interactive **Genie Artifact** New Business Quote.
* **Decisions → dollars** — metric views connect underwriting choices to projected loss ratio and premium at risk for finance / actuarial.

> Story: *"Underwriting is a document and data-assembly problem posing as a math problem."*

All data, names and emails are synthetic (`data_class=synthetic`, `.example` domains). No carrier, customer, vendor or colleague names appear anywhere in data, prompts, artifacts or slides.

## Status

| Phase | State |
| --- | --- |
| Design package v1.0-draft (research, semantics, pitch, L100–L400) | Done — 2026-11-15 |
| Review gate + SVG/HTML rendering | Done — design approved, 12 assumed decisions stand |
| Build 0 plan (waves.json, 9 session plans, Devin monitor prompt) | Done — 2026-11-15 |
| Build 0 execution (Genie Build Waves: 2 edit + 3 converge + 1 docs wave) | Done — 2026-11-16 (waves 0-0..0-5 passed) |
| Build 0 testing (Genie One beats 0-4, agent benchmarks, reset) | Done — 2026-11-17; see the [build 0 final summary](docs/sessions/2026-11-17_build-0-final-summary.md) |
| Build 1 (15 requests, [R1-01..R1-15](docs/requests/build-1/INDEX.md)) | **Next** — after PR #3 merges and the owner decisions are made |

Build 0 ran on branch `mg-genie-uw-genie-build-1` through the `uw-genie: Build Waves` job (`309617019935041`). Passing build runs: `581746600380456` (waves 0-0, 0-1), `197898696497677` (waves 0-2, 0-3), `1025333002364111` (waves 0-4, 0-5). Earlier runs `1076347254049076`, `1060969502993602` and `121608533170151` stopped at blocked gates that the owner fixed. Per-session logs are in [docs/sessions/](docs/sessions/INDEX.md); the architecture is in [docs/architecture.md](docs/architecture.md).

## Demo beats

| Beat | Persona | What happens |
| --- | --- | --- |
| 1 Morning brief | UW leader | Scheduled Genie One task summarizes renewals, submissions and trend flags |
| 2 Ready to quote? | AE / UW | Broker package v1 is checked against the intake checklist → BLOCKED, 5 findings, draft reply |
| 2b Interactive NB quote | UW → AE → broker | Package v2 is rated via the governed function → interactive New Business Quote artifact |
| 3 Renewal (optional) | UW | Renewal build for Lakeview Logistics |
| 4 Decisions → dollars | CFO / actuarial | Projected loss ratio vs target, premium at risk under a 12% cap |

## Components

| ID | Component | Design doc |
| --- | --- | --- |
| C1 | Synthetic data foundation (tables, volume, broker packages) | [L200-01](docs/design/L200-01_synthetic_data_foundation.md) |
| C2 | Governed rating engine (`rate_new_business`, `nb_quote_scenarios`, renewal view) | [L200-02](docs/design/L200-02_governed_rating_engine.md) |
| C3 | Semantics + Genie Agent "Underwriting Genie" (metric views, UC Pages, benchmarks) | [L200-03](docs/design/L200-03_semantics_and_genie_agent.md) |
| C4 | Genie One skills (intake checklist, rating explainer, morning brief) | [L200-04](docs/design/L200-04_genie_one_skills.md) |
| C5 | Interactive New Business Quote artifact | [L200-05](docs/design/L200-05_nb_quote_artifact.md) |
| C6 | Scheduled Morning Brief | [L200-06](docs/design/L200-06_scheduled_morning_brief.md) |
| C7 | Demo script, session instructions, acceptance criteria | [L200-07](docs/design/L200-07_demo_script_and_acceptance.md) |

Start with the demo constitution: [docs/design/L100_demo_overview.md](docs/design/L100_demo_overview.md) (rendered: [HTML](docs/design/L100_demo_overview.html)).

## Reference numbers (base scenario, synthetic)

Northwind Manufacturing — 420 enrolled employees, 980 members, 23,520 member months, 1/1/2027 effective, $250K pooling point, 9.0% base trend, assumption version `AV-2027.1`:

* Credibility Z **0.748**, blended claims PMPM $550.28
* Premium **$625.32 PMPM** (12% retention), Family tier $2,290.21
* **+2.2%** vs current (incumbent renewal offer +14.2%)
* 18-scenario grid (pooling × trend × plan option): −7.8% to +7.3%; golden file [nb_quote_scenarios_expected.csv](docs/demo-assets/nb_quote_scenarios_expected.csv)

## Repository layout

```
underwritingGenie/
├── README.md
├── PROJECT_MEMORY.md          # working memory for Genie Code sessions
├── LICENSE                    # MIT
├── uw-genie-infra/            # bundle: schema, volume, warehouse, setup_demo/reset_demo jobs
│   ├── databricks.yml
│   ├── resources/             # jobs/, schemas/, sql_warehouses/, volumes/
│   └── src/
│       ├── sql/               # 00_ddl, 10_rate_new_business, 20_metric_views, 90_tests
│       └── notebooks/         # uw_seed, generate_synthetic_book, upload_packages, reset_demo
├── uw-genie-agent/            # bundle: the "Underwriting Genie" Genie Agent
│   ├── databricks.yml
│   ├── resources/genie_spaces/
│   ├── tests/                 # run_genie_benchmarks.ipynb (15 agent benchmarks via the Genie Conversation API)
│   └── underwriting_genie.geniespace.json
└── docs/
    ├── research/              # 01–06: market, experience rating, NAIC AI governance, Genie One, competition, assumed decisions
    ├── semantics/             # business terms: rating & experience, intake & quote, financial outcomes
    ├── pitch/                 # customer vision talk track (md + html), internal field brief
    ├── diagrams/              # 7 diagrams as mermaid/, svg/, html/ + render_diagrams.py
    ├── design/                # L100 overview, L200-01..07, L300-01..05, L400-01..03
    ├── demo-assets/           # broker_packages (northwind_v1, northwind_v2), skills (4), golden CSV
    ├── plans/                 # build 0 wave plan: waves.json, INDEX.md, build-0/ session plans
    ├── requests/build-1/      # build 1 requests R1-01..R1-15 + INDEX.md (from build 0 testing)
    ├── prompts/               # Genie One demo prompts (Morning Brief routine, customer artifact)
    ├── setup/                 # manual setup guides (governed tag, Discover domain, glossary pages)
    ├── architecture.md        # two-bundle split, data flow, deploy order
    └── sessions/              # session logs + INDEX.md
```

## Build plan

The demo is built with **Genie Build Waves (build 0)** ([L400-01](docs/design/L400-01_genie_code_build_sessions.md)); sessions within a wave run in parallel. See `docs/plans/` for the build 0 wave plan (genie-build-waves framework).

Exit criteria: all **Must** criteria in L200-07 pass in 3 consecutive dry runs; reset job restores state in < 5 min; neutrality grep is clean. Devin monitors at level 4 (act for the owner).

**Build 0 status against these criteria (2026-11-17):** not met as written. AC-2b-1 (v2 ready to quote) and AC-2b-10 (prompt to artifact <= 3 min; measured 3:40 to 5:35) fail, and no three consecutive dry runs were done; the reset takes about 1.5 minutes. The governed data and the Genie Agent are correct (agent benchmarks 15/15 on values). Fixes are planned as **build 1** from [docs/requests/build-1/](docs/requests/build-1/INDEX.md).

## Deployment

Two Declarative Automation Bundles: `uw-genie-infra` (schema, volume, warehouse, jobs, SQL, notebooks) and `uw-genie-agent` (Genie Agent via genie_spaces resource with serialized space file). Deploy **infra first, then agent**. Targets `dev` (default) and `demo`; variables `catalog` (default `hls_fde_dev`), `schema` (default `uw_genie`) and `warehouse_id`. Jobs: `setup_demo` (create tables, generate synthetic book, upload packages, build scenarios, create metric views, run tests) and `reset_demo`. See [docs/architecture.md](docs/architecture.md), [L400-03](docs/design/L400-03_dab_deployment_and_reset.md) and the presenter runbook [L400-02](docs/design/L400-02_demo_runbook.md).

### Deployed resources (target `dev`, verified 2026-11-17)

| Bundle | Resource | Name | ID |
| --- | --- | --- | --- |
| uw-genie-infra | UC schema | `hls_fde_dev.uw_genie` | `483077d3-6960-4824-9586-30917977d687` |
| uw-genie-infra | UC volume (managed) | `hls_fde_dev.uw_genie.broker_packages` | `bb8d00f0-34a0-4596-b78e-5e9a925a9829` |
| uw-genie-infra | SQL warehouse (serverless Small, 1-2 clusters, 30 min auto-stop) | `[dev matthew_giglia] uw_genie_warehouse` | `dcca64ab7f26cea7` |
| uw-genie-infra | Job | `[dev matthew_giglia] Underwriting Genie: Setup Demo` | `989657833792246` (last good run `35433824231283`, 6/6 tasks) |
| uw-genie-infra | Job | `[dev matthew_giglia] Underwriting Genie: Reset Demo` | `1105533136205325` (first run `597932389562387`, about 1.5 min) |
| uw-genie-infra | UC functions | `hls_fde_dev.uw_genie.rate_new_business`, `hls_fde_dev.uw_genie.rate_renewal` | — |
| uw-genie-infra | Metric views | `hls_fde_dev.uw_genie.mv_quote_outcomes`, `mv_renewal_book`, `mv_intake_ops` | — |
| uw-genie-agent | Genie Agent | `[dev matthew_giglia] Underwriting Genie` (warehouse `dcca64ab7f26cea7`) | `01f1e1554179173991a4a487c2ae28ef` |
| (wave 0-4) | UC Skills | `hls_fde_dev.uw_genie.lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief` | finalized; workspace copies in `~/.assistant/skills/<name>/` |
| (manual) | Governed tag + Discover domain | tag key `mkgs_underwriting` (core / intake_quote / uw_finance); domain `mkgs_underwriting` with 30 glossary pages | see [docs/setup/uc-domain-and-pages/](docs/setup/uc-domain-and-pages/README.md) |
| (manual) | Genie One routine | "Large Group Underwriting Morning Brief", Mon-Fri 07:00 America/New_York | created from Prompt A in [docs/prompts/](docs/prompts/genie-one-demo-briefing-artifact.md) |

Build orchestration (genie-build-waves instance `-uw-genie`): `uw-genie: Build Waves` `309617019935041`, `uw-genie: Build Waves Setup` `609015504722082`, `uw-genie: Build Waves Smoke Test` `946512050297997`.

## Contributing

Work in feature branches named `<initials>-genie-<short-description>`; never commit directly to `main`. Log each working session in [docs/sessions/](docs/sessions/INDEX.md).

## License

[MIT](LICENSE)