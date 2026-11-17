# Build 0 Deploy, waves.json Fixes, and Devin Monitor Session

**Date:** 2026-11-15  
**Branch:** `mg-genie-uw-genie-build-1`  
**Continued from:** Build 0 planning session (same branch, commit `4ad844a`)

## Goal

Deploy the `genie-build-waves` orchestration bundle for the uw-genie instance, run setup to patch the build job, fix manifest validation errors surfaced during setup, and start the Devin monitor session for build 0 run A.

## Changes

### waves.json fixes (2 bugs found during setup job execution)

**Bug 1 — session 08 missing `runtime_targets`:**  
The genie-build-waves manifest validator requires that every `converge` session has a non-empty `runtime_targets` list. `not []` is `True` in Python, so an empty array also fails. Session 08 (publish UC skills) had no `runtime_targets` field at all.
- Fix: added `"runtime_targets": ["genie_space"]` — skill publishing is for the Genie Agent, and verifying the space is live is the natural post-condition.
- Commit: `Fix waves.json: add runtime_targets: [] to session 08 converge` (then corrected to `genie_space`)

**Bug 2 — wave 0-4 missing `runtime_gate`:**  
A second validator rule: every key in a session's `runtime_targets` must also appear in the enclosing wave's `runtime_gate`. Wave 0-4 had no `runtime_gate` defined.
- Fix: added `"runtime_gate": ["genie_space"]` to wave 0-4.
- Commit: `Fix waves.json wave 0-4: add runtime_gate for genie_space`

### genie-build-waves bundle deployed (web terminal)

User ran `deploy_instance.py --vars build-waves.vars.json` from the web terminal.  
Deployed job IDs (instance `genie-build-waves-uw-genie`, target `dev`):

| Job | Name | ID |
|---|---|---|
| build_waves | `uw-genie: Build Waves` | `309617019935041` |
| build_waves_smoke | `uw-genie: Build Waves Smoke Test` | `946512050297997` |
| setup_build_waves | `uw-genie: Build Waves Setup` | `609015504722082` |

**Instance root:** `/Workspace/Users/matthew.giglia@databricks.com/.bundle/genie-build-waves-uw-genie/dev`

### setup_build_waves job ran successfully (REST API)

The Databricks CLI is blocked on serverless compute (`only supported for interactive use from the web terminal`). The setup job was triggered via `WorkspaceClient.jobs.run_now()` using explicit runtime credentials instead.

Setup output:
- Build job patched with **55 tasks** (full wave task graph from waves.json)
- Smoke job patched with 3 tasks
- Skills published: `runner`, `integrator`, `monitor` → `hls_fde_dev.dev_matthew_giglia_build_waves`
- Automations created: runner, integrator, smoke, capability probe
- `mkgs-devin` grants: already held USE_CATALOG, USE_SCHEMA, READ VOLUME on monitor skill; CAN_MANAGE_RUN on build job (from bundle deploy)

### devin-monitor-prompt.md updated

- Filled in `<SETUP_FILLS>` placeholder with `job_id: 309617019935041`
- Commit: `Fill in build job ID in Devin monitor prompt`

### Setup helper notebook rebuilt

The `Genie Code Session Starter - DO NOT EDIT` notebook was rewritten from a placeholder into a full 7-step setup helper:

| Step | Purpose |
|---|---|
| 0 | `%pip install --upgrade databricks-sdk` + restart |
| 1 | Project config vars (single place to edit per new project) |
| 2 | Pre-flight waves.json validation — catches both rules that caused failures today |
| 3 | Prints pre-filled terminal deploy command for copy-paste |
| 4 | Looks up deployed job IDs via REST API |
| 5 | Triggers and polls `setup_build_waves` via SDK (serverless-safe, no CLI) |
| 6 | Displays all IDs (build job, skills, automations, grants) for docs/monitor prompt |
| 7 | Optional build trigger, gated by `TRIGGER_BUILD = True` flag |

### Devin monitor session started

- Session ID: `691668f25c744b66a13d30d15c94f93b`
- URL: `https://databricks-fde.devinenterprise.com/sessions/691668f25c744b66a13d30d15c94f93b`
- Tags: `genie-build-waves`, `uw-genie`, `build-run-0`, `build-0`
- Repos granted: `mkgs-databricks-demos/underwritingGenie`, `mkgs-databricks-demos/mbp`
- Status at creation: `claimed`
- Devin follows: UC skill `hls_fde_dev.dev_matthew_giglia_build_waves.genie_build_monitor`, level 4, `max_repairs` 3

## Decisions

- **Folder grant not required.** `mkgs-devin` does not need CAN_MANAGE on the build_root folder. Devin's fixes go via git commits; the git sync step in each wave pulls them into the workspace. The job runs as the owner's identity, not the monitor SPN.
- **Source-linked deployment.** The genie-build-waves bundle deployed in `mode: development`, which auto-enables source-linked deployment. The uw-genie-infra and uw-genie-agent bundles that Devin's converge sessions deploy should use `workspace.sync_mode: overwrite` (already specified in session 01's plan scope).
- **SDK with explicit credentials.** On serverless, `WorkspaceClient()` default auth fails (no notebook REPL context for runtime auth). Fix: `WorkspaceClient(host=_host, token=_token)` with credentials from `dbutils.notebook.entry_point`. This is the pattern for all SDK use in this notebook.
- **`runtime_targets` must be non-empty on converge sessions.** This is not documented in the genie-build-waves README. A GitHub issue / author prompt was drafted to add a notebook template and document these two validation rules.

## Files modified

| File | Change |
|---|---|
| `docs/plans/waves.json` | Added `runtime_targets: ["genie_space"]` to session 08; added `runtime_gate: ["genie_space"]` to wave 0-4 |
| `docs/plans/build-0/devin-monitor-prompt.md` | Filled `job_id: 309617019935041` |
| `README.md` | Status table updated (Build 0 plan → Done, Build 0 execution → Next) |
| `Genie Code Session Starter - DO NOT EDIT.ipynb` | Rewritten as 7-step setup helper |

## Verification

- Setup job run `412656038226349` returned `TERMINATED SUCCESS` with `patched.build: 55`
- Build job `309617019935041` exists with correct name `uw-genie: Build Waves` (confirmed via REST API)
- `devin-monitor-prompt.md` contains `job_id: 309617019935041` (confirmed by reading file)
- Devin session `691668f25c744b66a13d30d15c94f93b` status `claimed` at creation

## Observations

- The wrong setup job (`818046072228128`, Semantic Ground Truth) was triggered by the first `databricks bundle run setup_build_waves --target dev` command because it was run without `--var` flags. The CLI falls back to the default instance (SGT) when no `instance_suffix` is specified. Always pass the full `--var` flags to `bundle run`, not just to `bundle deploy`.
- The waves.json validation errors only surface at job execution time. A client-side pre-flight check (Step 2 of the setup notebook) catches them before triggering the job. This check has been added to the notebook and the genie-build-waves author has been given an issue prompt.

## Follow-ups

- Monitor Devin session `691668f25c744b66a13d30d15c94f93b` for run A progress
- Once run A passes: run B (disabled waves smoke test), then run C (PR + review) per devin-monitor-prompt.md
- After build 0 completes: record actual deployed IDs (warehouse ID, Genie space ID, UC skill FQNs) in `PROJECT_MEMORY.md`
- File the genie-build-waves GitHub issue for the notebook template and validation documentation
