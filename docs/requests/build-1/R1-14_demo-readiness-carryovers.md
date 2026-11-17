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
3. **AC-2b-10 (prompt to artifact <= 3 minutes): FAILED, measured 5:35** (owner stopwatch, 2026-11-16, Step 5 exception-and-quote prompt in the real v1 -> v2 flow; first output after about 1 second). Likely split: about 1 minute of agent queries (the comparable exception run that morning ran all its queries between 07:37:59 and 07:38:51 UTC, about 1.4 seconds each, several in parallel) and about 4.5 minutes of Genie writing the artifact HTML (8 sections plus 18 lever scenarios and their build-ups).
   * **Re-measured after sizing up the warehouse (2026-11-16):** `uw_genie_warehouse` changed from 2X-Small / 1 cluster / 10 min auto-stop to Small / up to 2 clusters / 30 min auto-stop (YAML and live; warehouse already running). Same flow and prompt: **3:40, still FAILED** (1:55 faster than 5:35). The saving is larger than the query estimate above, so queries queuing on one small cluster (and possibly a cold start in the first run) were a bigger share than estimated; single runs vary, so treat both numbers as samples. The remaining time is mostly artifact generation.
   * **Third run on a Large warehouse** (same flow, warehouse running): **4:17, FAILED**, slower than Small. Sizing beyond Small does not help; run-to-run variation in artifact generation (about 3:40 to 4:17 on a warm warehouse) is larger than any further query saving. Keep the warehouse at Small for demos and fix the artifact itself.

   | Warehouse | Prompt to artifact |
   | --- | --- |
   | 2X-Small, 1 cluster (stopped before the run) | 5:35 |
   | Small, up to 2 clusters (running) | 3:40 |
   | Large, up to 2 clusters (running) | 4:17 |

   Requested:
   * **Artifact template:** ship a fixed HTML / JS template with `nb-quote-artifact` (skill file or Volume) so Genie fills in data instead of writing the page from scratch.
   * **One data payload:** a governed view that returns the whole artifact data set in one query (18 scenarios, 180 build-up rows, claimants, plan designs, readiness), so the template reads one compact JSON block.
   * **Smaller first render:** draw the recommended scenario first and load the other 17 lever scenarios as data, not as pre-written HTML.
   * **Demo handling until then:** start the Step 5 prompt early and fill the wait with Step 7 (drivers) and Step 9 (guardrail) in the same chat, or switch to the backup artifact after 3 minutes as L200-07 §7 says. Re-measure after the fix and record T1 / T2 in L200-07.
4. **Domain tagging in the setup job.** Today the schema and the `broker_packages` Volume were tagged by hand, and the Genie Agent was tagged by hand in its settings. Have setup tag the schema and Volume with `domain_tag` (`core`), tag the Genie space after deploy (workspace entity-tag API, entity type `geniespaces`), and document the governed-tag prerequisite. Steps in `docs/setup/uc-domain-and-pages/README.md`.
5. **Demo prompt file per target.** `docs/prompts/genie-one-demo-briefing-artifact.md` hard-codes the dev agent title, space ID, schema and expected numbers. Render it per target with the other skills and prompts (R1-04), and re-check its numbers after R1-10 / R1-11 / R1-13 change the data.
6. **Session-level instruction (L200-07 §1).** AC-0-1 **passed** on 2026-11-16 (new Genie One chat, four skills on, no `@` mention): Genie replied exactly "Ready.". Genie did not resolve the agent at that point, so the agent-title risk (R1-04) still applies to the first data question. Update the instruction text: name the agent by its rendered per-target title or `@`-mention it; extend the rate rule to renewals (`renewal_scenarios` / `rate_renewal()`) and state the three-tier rule (R1-05); add "show group names, not IDs". Also fix §1 step 5 ("Run the reset job"), which conflicts with keeping the backup artifact (item 2).

## Files affected

* `docs/demo-assets/skills/uw-morning-brief/SKILL.md`; `docs/design/L200-06_scheduled_morning_brief.md`; `docs/design/L400-02_demo_runbook.md` (dry-run checklist); `docs/design/L200-05_nb_quote_artifact.md` (backup artifact); `docs/design/L200-07_demo_script_and_acceptance.md` (AC-2b-10; §1 session instruction and step 5)
* `uw-genie-infra` setup job / SQL (schema and volume tags); `uw-genie-agent` post-deploy step (Genie space tag)
* `docs/prompts/genie-one-demo-briefing-artifact.md`

## Acceptance criteria

* The routine's instructions are a single line that names the skill; a run shows 8 blocked submissions and group names (IDs only for prospects).
* A backup artifact exists before every demo, and the reset step does not remove it.
* AC-2b-10 has a measured time recorded.
* After a fresh deploy, the schema, Volume and Genie space carry the domain tag without manual steps.
* The demo prompt file for each target names that target's agent and schema.
