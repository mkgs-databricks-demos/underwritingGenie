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
| Build 0 execution (Genie Build Waves: 2 edit + 3 converge + 1 docs wave) | **Next** |

The repo contains documentation, demo assets, and the build 0 plan (`docs/plans/`). Bundle code (`uw-genie-infra/`, `uw-genie-agent/`) is authored by Devin during build 0 per the [wave plan](docs/plans/INDEX.md).

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
└── docs/
    ├── research/              # 01–06: market, experience rating, NAIC AI governance, Genie One, competition, assumed decisions
    ├── semantics/             # business terms: rating & experience, intake & quote, financial outcomes
    ├── pitch/                 # customer vision talk track (md + html), internal field brief
    ├── diagrams/              # 7 diagrams as mermaid/, svg/, html/ + render_diagrams.py
    ├── design/                # L100 overview, L200-01..07, L300-01..05, L400-01..03
    ├── demo-assets/           # broker_packages (northwind_v1, northwind_v2), skills (4), golden CSV
    └── sessions/              # session logs + INDEX.md
```

## Build plan

The demo is built with **Genie Build Waves (build 0)** ([L400-01](docs/design/L400-01_genie_code_build_sessions.md)); sessions within a wave run in parallel. See `docs/plans/` for the build 0 wave plan (genie-build-waves framework).

Exit criteria: all **Must** criteria in L200-07 pass in 3 consecutive dry runs; reset job restores state in < 5 min; neutrality grep is clean. Devin monitors at level 4 (act for the owner).

## Deployment (planned)

Two Declarative Automation Bundles: `uw-genie-infra` (schema, volume, warehouse, jobs, SQL, notebooks) and `uw-genie-agent` (Genie Agent via genie_spaces resource with serialized space file). Targets `dev` (default) and `demo`; variables `catalog` (default `hls_fde_dev`), `schema` (default `uw_genie`) and `warehouse_id`. Jobs: `setup_demo` (create tables, generate synthetic book, upload packages, build scenarios, run tests) and `reset_demo`. See [L400-03](docs/design/L400-03_dab_deployment_and_reset.md) and the presenter runbook [L400-02](docs/design/L400-02_demo_runbook.md).

## Contributing

Work in feature branches named `<initials>-genie-<short-description>`; never commit directly to `main`. Log each working session in [docs/sessions/](docs/sessions/INDEX.md).

## License

[MIT](LICENSE)