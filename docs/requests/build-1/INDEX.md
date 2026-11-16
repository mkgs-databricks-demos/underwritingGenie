# Build 1 requests

Owner requests and decisions collected after build 0 (run A passed 2026-11-16, PR #3). Each file holds the full context: problem, evidence, requested change, files affected and acceptance criteria. `PROJECT_MEMORY.md` keeps only one-line pointers to these files.

The build 1 plan (`docs/plans/waves.json`, session plans) should be written from these requests.

| ID | Request | Area | Status | Raised |
| --- | --- | --- | --- | --- |
| [R1-01](R1-01_dev-development-mode.md) | Switch infra `dev` back to real development mode; dev stays destroyable | Bundles | Open | 2026-11-16 |
| [R1-02](R1-02_resource-references.md) | `${resources...}` for every catalog/schema reference | Bundles | Open (infra compliant) | 2026-11-16 |
| [R1-03](R1-03_metric-views-yaml-for-each.md) | Metric views as YAML fixtures + `list_fixtures` -> `for_each` deploy job | Infra | Open | 2026-11-16 |
| [R1-04](R1-04_full-parameterization.md) | 100% parameterized, required params with no literal defaults, Genie Agent included | All | Open | 2026-11-16 |
| [R1-05](R1-05_three-tier-governed-math.md) | Three-tier governed-math rule; governed renewal-offer comparison | Rating, skills, design docs | Open (decided) | 2026-11-16 |
| [R1-06](R1-06_nb-quote-artifact-fixes.md) | `nb-quote-artifact` skill fixes from the Genie One test | Skills | Open | 2026-11-16 |
| [R1-07](R1-07_experience-rating-explainer-fixes.md) | `experience-rating-explainer` fixes and L200-07 beat 2b prompt | Skills, demo script | Open | 2026-11-16 |
| [R1-08](R1-08_intake-checklist-fixes.md) | Intake checklist, broker package and demo-setup fixes from the Genie One test | Data, skills, demo script | Open (IC-01 is a design bug) | 2026-11-16 |
| [R1-09](R1-09_governed-benefit-changes.md) | Governed path for benefit changes: relativity source, `add_plan_option` procedure, `rate_renewal` plan parameter | Rating, data, skills | Open (needs actuarial decision) | 2026-11-16 |
| [R1-10](R1-10_benchmark-as-of-date.md) | Governed `demo_as_of_date` for "next N days" windows (benchmark ★7), lower bound on past renewals | Data, Genie space, skills | Open | 2026-11-16 |
| [R1-11](R1-11_renewal-rates-and-morning-brief.md) | Renewal rate actions from `rate_renewal()` (1 of 59 match today) with calibration; renewal "why" from the governed build-up; Morning Brief keeps every blocked submission | Data, rating, skills | Open (design bug; calibration decision) | 2026-11-16 |
| [R1-12](R1-12_uc-table-wikis.md) | UC wiki drafts for all 25 objects in `hls_fde_dev.uw_genie` | Data, docs | Open (drafts ready) | 2026-11-16 |
| [R1-13](R1-13_renewal-explainer-and-decisions-to-dollars.md) | Beats 3-4: what-if causes, dollar impacts as governed values, AE rationale template, one loss-ratio definition, `mv_renewal_book` count measure, chart + MLR floor, number formatting | Skills, metric views, Genie space, docs | Open | 2026-11-16 |
| [R1-14](R1-14_demo-readiness-carryovers.md) | Beats 1-2 carryovers: Morning Brief routine rules into the skill, backup artifact, measure AC-2b-10, domain tagging in setup, demo prompt file per target | Skills, setup, docs | Open | 2026-11-16 |

## Suggested grouping for build 1

* **Do together:** R1-01, R1-02 and R1-04. Switching to development mode renames the schema, which is the moment to remove every hard-coded name.
* **Infra wave:** R1-03 (metric view job) and the data/rule parts of R1-05 (renewal comparison columns) and R1-08 (IC-01 rule, v1/v2 package text).
* **Governed write paths:** R1-08 item 7 (intake findings / exceptions) and R1-09 item 2 (add plan option) should share one design (stored procedures with EXECUTE grants, approver and timestamp).
* **Skills and docs wave:** R1-05 rule text, R1-06, R1-07, and the L200-07 / L300-05 / L400-02 parts of R1-08.

## Conventions

* One file per request: `R<build>-<nn>_<slug>.md`.
* Sections: Status, Origin, Problem, Current state (evidence), Requested change, Files affected, Acceptance criteria, Dependencies.
* When a request is done, set Status to `Done (<commit>)` here and in the file; do not delete it.
