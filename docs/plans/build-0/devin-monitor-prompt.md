# Build 0: Devin monitor instruction (owner, 2026-11-15)

The owner's standing instruction for build 0. Genie Code sends it to the Devin monitor session once setup has created the build job and published the skill.

**Standing instruction (owner):** complete build 0 on `mg-genie-uw-genie-build-1`.

## Skill

Follow the published UC skill `hls_fde_dev.dev_matthew_giglia_build_waves.genie_build_monitor` (mbp `53bdaea`) at **level 4, act for the owner** (section 8), with `max_repairs` 3. The skill defines the first run, monitoring, the decide table, session-owned fixes, repair limits, the fresh run after a refused repair, the stop conditions and the guardrails. This file adds only what is specific to this project.

## Inputs

| Input | Value |
|---|---|
| `job_id` | `309617019935041` |
| `build_root` | `/Workspace/Users/matthew.giglia@databricks.com/underwritingGenie` |
| `manifest_path` | `<build_root>/docs/plans/waves.json` |
| `repo`, `build_branch` | `mkgs-databricks-demos/underwritingGenie`, `mg-genie-uw-genie-build-1` |
| `level` | 4 |
| `max_repairs` | 3 |
| Monitor principal | `72bab3e9-303d-4443-b43e-9eaab474d8bb` (mkgs-devin) |

## Project specifics

1. Run A is the build 0 run (skill section 8). Commit prefix `devin:` plus the skill's `Build-Run:` trailer.
2. Allowed fix paths (bundle source only): `uw-genie-infra/**`, `uw-genie-agent/**`. Anything else (including `docs/plans/**` and `waves.json`) is a stop condition.
3. No run B for this project (owner, 2026-11-16). The disabled-waves / `BUILD_WARNING` run came from the `devin-genie-build-waves-test` monitor prompt, where it was an acceptance test of the level 4 monitor; that test has already passed, and it is not part of the skill. This is a real project build, so do not disable waves or start a run to produce `BUILD_WARNING`.
4. Run C (only once `GH_TOKEN` has Pull requests write): open the PR `mg-genie-uw-genie-build-1` -> `main` and post one review (event COMMENT). Never approve or merge.
5. Run C is the owner's explicit instruction (the only run besides run A and its repairs). Report run A's final result (skill section 8, step 6) before run C.
6. Build 0 is a combined build: waves 0-0 and 0-1 are `edit` (parallel, static gates), waves 0-2 through 0-4 are `converge` (sequential, runtime gates), wave 0-5 is `edit` (docs). Devin monitors all waves in one continuous run.
