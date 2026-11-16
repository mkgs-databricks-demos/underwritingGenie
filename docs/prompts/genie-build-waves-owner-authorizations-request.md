# Request to the genie-build-waves owner: first-class owner authorizations for sessions

**From:** underwritingGenie project owner (Build 0, run A)
**To:** genie-build-waves maintainer (`mbp/genie-build-waves`)
**Date:** 2026-11-15
**Goal:** let the Devin monitor (level 4) and Genie Code session tasks finish converge waves without the owner stepping in for every privileged action.

---

## Prompt

You maintain `genie-build-waves`. Please make owner authorizations a first-class, explicit part of the manifest and the session prompt, so Genie Code Auto Mode inside a session task can see that the owner approved an action, and the Devin monitor can rely on that instead of escalating.

Today the only way to authorize a privileged action is to put free text in a session's `context_notes` and hope Auto Mode reads it as authorization. That worked, but only after three failed runs. Please do the following.

### 1. Document `context_notes` and render it as an authorization block

* Add `context_notes` to the manifest schema docs (`waves.json` reference), with its purpose: owner-provided context and approvals that reach the session prompt verbatim.
* In the session prompt template, render it under a fixed heading such as `## Owner authorizations (approved by the build owner)` near the top of the prompt, not buried after the scope. Auto Mode should see it before it sees the action.

### 2. Add a structured `authorizations` field per session

Free text is fragile. Add an optional list that the runner renders as explicit, named approvals:

```json
"authorizations": [
  {"action": "jobs.run_now", "target": "runtime_target:setup_demo_job", "reason": "session must run setup_demo after deploy"},
  {"action": "uc_skills.publish", "target": "hls_fde_dev.uw_genie", "reason": "publish 4 demo skills"},
  {"action": "workspace.write", "target": "/Workspace/Users/<owner>/.assistant/skills/**"}
]
```

* `target` may reference a runtime target key; the runner resolves it to the concrete resource ID (see 3) before rendering.
* Render each entry as one sentence: "The owner explicitly authorizes `<action>` on `<resolved target>` (`<reason>`), including reruns after a fix in this session."
* Keep `context_notes` for free-form context; `authorizations` is the approval channel.

### 3. Resolve runtime target IDs and inject them into the prompt

The main failure was that the session prompt named the job by bundle resource key, not by job ID, and Auto Mode refused `run-now` on an ID it had never seen.

* After `deploy_commands` run (or from `bundle summary`), resolve each runtime target in the session's `runtime_targets` to its deployed ID (job ID, Genie space ID, warehouse ID) and add them to the prompt: "Resolved targets: setup_demo_job = job 989657833792246 ...".
* For a `job` runtime target, default-authorize `run-now` on its resolved job ID unless the manifest opts out (`"authorize_run": false`). Running the target is the whole point of a converge session.

### 4. Pre-flight check for missing authorizations

In the setup job (or a manifest lint step), warn when a converge session's scope implies a privileged action with no matching authorization. Simple keyword heuristics are enough:

| Scope mentions | Expected authorization |
| --- | --- |
| `run-now`, `bundle run`, "trigger ... job" | `jobs.run_now` on that target |
| `create_skill`, `finalize_skill`, `/Skills/` | `uc_skills.publish` |
| `files.upload`, writes under `.assistant/` or `/Volumes/` | `workspace.write` / `volume.write` |
| `GRANT`, permissions, `set-permissions` | `permissions.change` |

Warnings go into the setup job output and the `build_verdict` text, so the owner fixes the manifest before run A instead of after a blocked wave.

### 5. Give the monitor an owner-approved channel that does not require editing `waves.json`

`waves.json` is outside the monitor's allowed fix paths, so every authorization gap became a stop condition and a manual owner commit. Options (pick one):

* A sidecar file, e.g. `docs/plans/authorizations.json`, merged into each session's prompt at run time. The owner edits it; the monitor reads it and may propose diffs but never writes it.
* Or a job parameter `owner_authorizations` (JSON) that the owner sets on `run-now` / repair, so a repair can carry a new approval without a commit.

Either way, re-read authorizations on repair, so a repair after an owner approval actually picks it up.

### 6. Smaller fixes found in the same run

* When the manifest has a `genie_space` runtime target, have setup (or session templates) ensure the space's `parent_path` folder (here `.genie_agents/`) is in `.gitignore`; the deployed `.geniespace.json` was flagged as a stray at the wave 0-3 gate.
* A session that ends `blocked` but whose task ends `SUCCESS` is not rerun by repair. Document this in `repair-failed-wave.md`, or make `w<N>_sessions` rerun blocked sessions on repair.
* State in the session template that SQL file task parameters raw-text substitute `{{param}}` everywhere (comments and literals included), and recommend `:param` with `EXECUTE IMMEDIATE` for dynamic DDL such as `SET TAGS`.

---

## Evidence from underwritingGenie Build 0, run A

| Run | Wave / session | Blocked on | Fix the owner had to make |
| --- | --- | --- | --- |
| `1060969502993602` | 0-2 / 06 | Auto Mode refused `jobs/run-now` on setup_demo `989657833792246` (job ID not in prompt) | Commit `context_notes` naming the job ID |
| `121608533170151` | 0-2 / 06 | Same refusal; the owner's chat authorization to Devin never reached session 06 | Same, and repair budget (3) exhausted |
| `197898696497677` | 0-3 / 07 | Stray `.genie_agents/...geniespace.json` | Commit `.gitignore` entry |
| `197898696497677` | 0-4 / 08 | Auto Mode refused `create_skill` / `files.upload` to `/Skills/` | Commit `context_notes` authorizing UC Skills publish |

In each case Devin diagnosed the cause correctly but had to stop, because the fix sat in `waves.json`. With items 2, 3 and 5, every one of these would have been a monitor-handled repair or would not have happened.

## Acceptance criteria

* A converge session with a `job` runtime target can run that job with no `context_notes` entry.
* An `authorizations` entry appears in the rendered session prompt under the owner-authorizations heading, with target IDs resolved.
* The setup job warns on the underwritingGenie Build 0 manifest as it was before the owner added `context_notes` to sessions 06 and 08 (both gaps flagged).
* A repair started after the owner updates the authorization channel (item 5) picks up the new approval without a `waves.json` commit.
