# R1-14 Demo-readiness carryovers (beats 1-2 and demo setup)

**Status:** Open
**Origin:** Review on 2026-11-16 of the beat 1-2 Genie One tests and the manual demo setup done that day, against R1-01..R1-13. These items were not covered by an existing request.
**Related:** R1-04 (parameterization), R1-11 (Morning Brief skill), R1-08 (intake), `docs/prompts/genie-one-demo-briefing-artifact.md`, `docs/setup/uc-domain-and-pages/README.md`

## Already covered elsewhere (no new request)

| Finding | Request |
| --- | --- |
| Morning Brief undercount (1 of 8 blocked), renewal "why" from the build-up, reply arithmetic | R1-11 part B, R1-05 |
| "Next N days" depends on the run date | R1-10 |
| Agent title `[dev matthew_giglia] Underwriting Genie` not found by name | R1-04 change 5 |
| Artifact plan details, readiness from findings, KPI box 5 | R1-06 |
| Explainer tier rates, trend years, list completeness | R1-07 |
| IC-01 rule, v1 has 6 blockers, IC-10, Gmail draft scope, findings and exception write path, artifact name collision | R1-08 |
| Benefit changes / new plan designs | R1-09 |
| Number formatting (scientific notation) | R1-13 item 7 |

## Requested change

1. **Morning Brief routine as code, not chat.** The weekday 7:00 AM Genie One routine "Large Group Underwriting Morning Brief" was created by hand on 2026-11-16 from Prompt A, which adds rules the skill lacks: count every BLOCKED submission including prospects with no `groups` row; show the group **name wherever one exists** and the ID only for prospects (the first run showed `GRP-BK-021` etc. instead of names for all 6 large-claimant groups); no renewal "why"; take numbers from the agent or the governed tables. Move these rules into `uw-morning-brief/SKILL.md` so the routine's instructions are one line ("Use the uw-morning-brief skill ..."), and document the routine's creation and owner check in L200-06 / L400-02 (the original plan had session S7 create it).
2. **Backup quote artifact (L200-05).** Never built; the demo uses the Northwind quote from test chat `04e80baad93c48fc9dfcfe4f9ffda27a` as the backup. Build the purpose-made backup, or record that a pre-built artifact from a dry run is the official backup, with the reset step that keeps it.
3. **Measure AC-2b-10 (prompt to artifact <= 3 minutes)** in the L400-02 dry run, and record the time in L200-07; it was never measured.
4. **Domain tagging in the setup job.** Today the schema and the `broker_packages` Volume were tagged by hand, and the Genie Agent was tagged by hand in its settings. Have setup tag the schema and Volume with `domain_tag` (`core`), tag the Genie space after deploy (workspace entity-tag API, entity type `geniespaces`), and document the governed-tag prerequisite. Steps in `docs/setup/uc-domain-and-pages/README.md`.
5. **Demo prompt file per target.** `docs/prompts/genie-one-demo-briefing-artifact.md` hard-codes the dev agent title, space ID, schema and expected numbers. Render it per target with the other skills and prompts (R1-04), and re-check its numbers after R1-10 / R1-11 / R1-13 change the data.

## Files affected

* `docs/demo-assets/skills/uw-morning-brief/SKILL.md`; `docs/design/L200-06_scheduled_morning_brief.md`; `docs/design/L400-02_demo_runbook.md` (dry-run checklist); `docs/design/L200-05_nb_quote_artifact.md` (backup artifact); `docs/design/L200-07_demo_script_and_acceptance.md` (AC-2b-10)
* `uw-genie-infra` setup job / SQL (schema and volume tags); `uw-genie-agent` post-deploy step (Genie space tag)
* `docs/prompts/genie-one-demo-briefing-artifact.md`

## Acceptance criteria

* The routine's instructions are a single line that names the skill; a run shows 8 blocked submissions and group names (IDs only for prospects).
* A backup artifact exists before every demo, and the reset step does not remove it.
* AC-2b-10 has a measured time recorded.
* After a fresh deploy, the schema, Volume and Genie space carry the domain tag without manual steps.
* The demo prompt file for each target names that target's agent and schema.
