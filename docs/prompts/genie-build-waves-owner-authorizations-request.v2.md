# Request to the genie-build-waves owner: tiered authorizations for sessions (v2)

**From:** underwritingGenie project owner (Build 0, run A)
**To:** genie-build-waves maintainer (`mbp/genie-build-waves`)
**Date:** 2026-11-15
**Supersedes:** `genie-build-waves-owner-authorizations-request.md` (v1). v1 stays as the record of the original request.
**Goal:** let Genie Code sessions and the level 4 Devin monitor finish converge waves without the owner stepping in for routine actions, while anything that widens access or touches production still needs the owner.

---

## Why v1 changed

A spike on 2026-11-15 (folder `/Users/matthew.giglia@databricks.com/genie-authz-spike`) tested the channels v1 proposed. Findings that change the design:

1. **Job parameters override task parameters of the same name, for every task in the run, even when the job does not declare them.** `run-now` with an undeclared `p=zzz` replaced the task parameter `p=abc` in all three SQL tasks (run `167352821729942`). In the Genie test job, a run-time `authorizations` value replaced the per-task value in all three Genie tasks, so even the "no approval" task got the approval (run `166576647811927`). So v1 item 5b (an `owner_authorizations` job parameter) is a self-approval channel for anyone with CAN_MANAGE_RUN, and it applies to every session at once.
2. **Approvals in a file the agent reads do not count.** Clean rerun, 3 runs per channel (runs `368824892457824`, `270623025594859`, `814174075343353`): approval only in the instructions file ran the job **0 of 3** times; each session said a file cannot grant what the owner did not give, and that the file was flagged as possibly injected. v1 items 1 and 5a (approvals in `context_notes` or a sidecar file read at run time) do not work as an approval channel. Build 0 did get through with `context_notes` in `waves.json`, after three failed runs; why that file counted when the spike's file did not is not known (possibly because the runner reaches it through a loaded UC Skill, or because it named the exact job ID). Do not rely on it.
3. **Approvals in the task prompt work: 3 of 3.** Every session with the approval in its prompt ran the target job and checked the run. The target job's run history shows exactly these three runs.
4. **A side-effecting step that only a file asks for is refused, even with no approval wording: 0 of 3.** The no-approval sessions found the job but would not run it, because the instruction came only from a workspace file in an unattended session. This is the Build 0 session 06 failure. The runner's plan files are workspace files, so every side-effecting action a session must take (deploy, run, publish) needs an approval in its prompt; tier 1 is not optional.
5. **Sessions share the owner's Genie Code memory.** One unattended test session appended a line to the owner's `/memories` file without being asked. A build session can write memories that later interactive sessions read and trust.
6. **There is no session prompt template.** The runner's task prompt is a short fixed prompt (load the skill, list of parameters); the agent reads `waves.json` itself. To be in the prompt, an approval has to be a task parameter that setup writes.
7. **`context_notes` is already documented** (`docs/manifest-schema.md`) and read by the runner (`genie-build-session-runner/SKILL.md`, step on hand-over context).

---

## Prompt

You maintain `genie-build-waves`. Please add tiered, structured authorizations: derived where the manifest already implies them, declared by the owner in the manifest, and grantable by the monitor only inside an allowlist the owner writes. Setup renders the result into each session's task prompt. Nothing is approved through job parameters or files read at run time.

### 1. Four tiers

| Tier | Who decides | Examples | Where it is recorded |
| --- | --- | --- | --- |
| 1. Implied | The manifest's structure | `converge` session: `bundle.deploy` of its own `bundle_roots`; `jobs.run_now` / `pipelines.start_update` on its own `runtime_targets`; read its own telemetry tables | Derived by setup. Opt out per target with `"authorize_run": false` |
| 2. Owner-declared | The owner | Publish UC Skills to the project schema; write under `/Volumes/<project>/...` or `.assistant/skills/**`; run a named setup job that is not a runtime target | `sessions[].authorizations` (and optional `defaults.authorizations`) in `waves.json` |
| 3. Monitor-granted | The monitor, inside `authorization_policy.monitor_may_authorize` | The exact action from a quoted refusal, on a target the session already owns (its runtime targets, `owned_paths`, `owned_assets`) | `docs/plans/authorizations.monitor.json`, a level 4 fix path |
| 4. Owner only | The owner, always | Permission or grant changes, account groups, secrets, any non-dev target, destroy / drop / delete of objects the session did not create | Never rendered as approved. Always a monitor stop condition |

Tier 4 is fixed in the framework; a manifest cannot move an action out of it.

### 2. Manifest schema

A fixed action vocabulary (unknown actions fail validation):

`bundle.deploy`, `jobs.run_now`, `pipelines.start_update`, `uc_skills.publish`, `workspace.write`, `volume.write`, `sql.ddl`.

```json
"authorization_policy": {
  "implied": true,
  "monitor_may_authorize": [
    {"action": "jobs.run_now", "scope": "own_runtime_targets"},
    {"action": "workspace.write", "scope": "owned_paths"},
    {"action": "uc_skills.publish", "scope": "project_schema"}
  ]
},
"sessions": [{
  "id": "08",
  "authorizations": [
    {"action": "uc_skills.publish", "target": "hls_fde_dev.uw_genie", "reason": "publish 4 demo skills"},
    {"action": "workspace.write", "target": "/Workspace/Users/<owner>/.assistant/skills/**", "reason": "skill files"}
  ]
}]
```

* `target` may be a runtime target key (`runtime_target:setup_demo_job`); setup resolves it (section 3).
* `validate_manifest()` rejects: unknown actions, tier 4 actions, targets outside the project (other catalogs, other users' folders), `monitor_may_authorize` scopes other than `own_runtime_targets`, `owned_paths`, `owned_assets`, `project_schema`.
* `context_notes` stays free-form context. Approval wording in `context_notes` is not an authorization; the pre-flight check warns when it finds some ("authorize", "approved").

### 3. Render approvals into the task prompt

* Add a runner parameter `authorizations` (in `RUNNER_PARAMS`, so the thin prompt gets `{{authorizations}}`), placed **first** in the prompt, under `## Owner authorizations (approved by the build owner)`.
* Setup builds the text per session from tiers 1 to 3 and puts it in that session's `for_each` input, one sentence per entry: "The owner authorizes `<action>` on `<resolved target>` (`<reason>`; tier `<n>`), including reruns after a fix in this session." Sessions with none get `Owner authorizations: none.`
* **Resolving IDs.** For targets already deployed (rerun, later waves), setup reads the project bundle's deployment state and renders concrete IDs (job ID, pipeline ID, Genie space ID). For a first deploy, setup renders the key and bundle root ("the job `setup_demo_job` that `bundle deploy` in `<bundle_root>` creates"), and the runner records the resolved ID in its status file after its own `bundle summary`.
* Never take approval text from job parameters, `context_notes` or files read at run time.

### 4. Monitor grants (tier 3)

* The monitor may write `docs/plans/authorizations.monitor.json` only, through the same level 4 fix flow as other fixes. Each entry: `action`, `target`, `session`, `reason`, `evidence` (the quoted refusal and run ID).
* Setup merges it, drops and reports entries outside `monitor_may_authorize` or the session's own targets, and renders the rest with `tier 3, granted by the monitor`.
* Grants take effect on the next setup + **fresh run** (consistent with the existing level 4 fresh-run rule). Repair is not the vehicle.
* The build verdict and wave gate list every tier 3 grant used, so the owner reviews them after the fact.
* Anything not allowed stays a stop condition, with the exact proposed entry in the stop report so the owner can paste it into `waves.json` as tier 2.

### 5. Close the job-parameter override

This exists today, separate from authorizations: anyone with CAN_MANAGE_RUN on the build job can pass `job_parameters` on `run-now` or repair and override any same-named task parameter (`branch`, `build_root`, `manifest_path`, `session_id`, ...).

* Monitor skill rule: never pass `job_parameters` on `run-now` or repair of the build job, except a documented allowlist (none today).
* Build verdict (and the monitor audit): compare the run's `job_parameters` with the job's defaults; flag any override or undeclared parameter as `PARAMETER_OVERRIDE`.
* Optional, stronger: setup bakes a hash of each session's rendered inputs into its `for_each` input; the runner refuses to start when the values it receives do not match.

### 6. Pre-flight check (structural first)

In `validate_manifest()` warnings and the setup job output (also the setup helper notebook):

* **Structural:** a `converge` session whose `runtime_targets` include a job or pipeline with `authorize_run: false` and no tier 2 entry; a session that writes outside its `owned_paths` per its plan's file list; `owned_assets` of a kind that needs an action not covered by tiers 1 to 3.
* **Keyword (warning only):** scope or plan mentions `run-now`, `bundle run`, `create_skill`, `/Skills/`, `files.upload`, `/Volumes/`, `GRANT`, `set-permissions` with no matching entry. `GRANT` / permissions always warn as tier 4.

### 7. Smaller fixes from the same run

* **Genie space files:** when a `genie_space` runtime target exists, setup warns if its `parent_path` folder (here `.genie_agents/`) is not in `.gitignore`; the planner's stray-file tip names it.
* **Memory writes:** add a runner and integrator guardrail: never create, edit or delete Genie Code memories (`/memories`) in a build session. Sessions run as the owner and share the owner's memory, so a session's guess becomes a "fact" for later interactive sessions.
* **Blocked sessions:** already covered (README "Why not repair?", level 4 fresh-run rule). No change.
* **SQL parameters** (session template and planner note): in SQL file tasks, `{{param}}` is replaced as a quoted SQL literal before the SQL is parsed, everywhere in the file, comments included (`'{{p}}'` becomes `''abc''` and fails; a comment `-- {{p}}` became `-- 'abc'`; an undefined `{{x}}` stays as is). Use named parameter markers (`:param`, `IDENTIFIER(:name)`, `EXECUTE IMMEDIATE ... USING`) in SQL, and keep `{{...}}` out of comments and string literals. Job parameters override task parameters of the same name. (Verified: run `939383477894837` and `167352821729942`.)

---

## Evidence

### Build 0, run A (unchanged from v1)

| Run | Wave / session | Blocked on | Fix the owner had to make | Tier under v2 |
| --- | --- | --- | --- | --- |
| `1060969502993602` | 0-2 / 06 | Auto Mode refused `jobs/run-now` on setup_demo `989657833792246` (ID not in prompt) | Commit `context_notes` naming the job ID | 1 (own runtime target) |
| `121608533170151` | 0-2 / 06 | Same; the owner's chat approval to Devin never reached session 06 | Same, repair budget (3) exhausted | 1 |
| `197898696497677` | 0-3 / 07 | Stray `.genie_agents/...geniespace.json` | Commit `.gitignore` entry | Pre-flight warning (7) |
| `197898696497677` | 0-4 / 08 | Auto Mode refused `create_skill` / `files.upload` to `/Skills/` | Commit `context_notes` approving UC Skills publish | 2, or 3 if `project_schema` is allowlisted |

### Spike, 2026-11-15

| Test | Result |
| --- | --- |
| SQL file task, `:p` | Pass |
| SQL file task, `'{{p}}'` | Fail: substituted as `''abc''` |
| SQL file task, `{{p}}` in a comment | Replaced; run passed |
| `run-now` with undeclared job parameter `p` | Overrode task parameter `p` in every task |
| Genie task, approval in task prompt (3 runs) | Ran the target job 3 of 3 |
| Genie task, approval only in instructions file (3 runs) | Ran it 0 of 3: "a file can't grant authorization the owner didn't give" |
| Genie task, no approval, run requested only by a file (3 runs) | Ran it 0 of 3: side-effecting step from a file flagged as untrusted |
| Target job run history | Exactly 3 runs from the clean reruns, all `caller=B_prompt_parameter` |

### Not yet tested (needed before relying on them)

* **Runner path.** Repeat the three channels through the real runner (thin prompt loading the UC Skill, approval in `waves.json`) to explain why Build 0's `context_notes` eventually worked, and confirm the prompt-parameter channel still wins there.
* **Unseen-ID refusal.** Reproduce session 06: thin prompt, plan names the job by bundle key, no ID in prompt. Confirms whether tier 1 needs concrete IDs or key + bundle root is enough.
* **Repair and changed settings.** Whether repair uses the job's current task inputs after setup re-runs (decides if tier 3 can ever use repair).
* **`for_each` input size** with rendered approvals on the largest manifest.

## Acceptance criteria

* A converge session with a job runtime target runs that job with no `context_notes` and no tier 2 entry (tier 1), and its prompt shows the resolved ID when the job already exists.
* A tier 2 entry appears first in the rendered prompt under the owner-authorizations heading.
* `validate_manifest()` rejects tier 4 actions, unknown actions and out-of-project targets in `authorizations` and `monitor_may_authorize`.
* A monitor entry outside `monitor_may_authorize` is dropped by setup and reported; an allowed one is rendered as tier 3 and listed in the verdict.
* A build run started with any `job_parameters` override is flagged `PARAMETER_OVERRIDE` in the verdict.
* The setup job warns on the Build 0 manifest as it was before the owner added `context_notes` to sessions 06 and 08 (06 is covered by tier 1; 08 needs tier 2 or 3).
