# R1-01 Switch infra `dev` back to real development mode

**Status:** Open
**Origin:** Owner request, 2026-11-16 (after build 0 run A). Correction the same day: no `prevent_destroy` on dev.
**Related:** R1-02, R1-04 (do together)

## Problem

Build 0 removed `mode: development` from the `uw-genie-infra` `dev` target so the UC schema would stay `hls_fde_dev.uw_genie`. Development mode always prefixes UC schemas with `dev_<user>_`, and an empty `presets.name_prefix` is treated as unset, so it cannot be turned off.

This differs from the owner's convention in other projects (for example scAuditor, whose dev schema is `dev_matthew_giglia_sc_auditor`) and gives up what development mode provides.

## Current state (evidence)

* Session 01 (wave 0-0) wrote `mode: development` plus `presets.name_prefix: ""`. Session 05 (wave 0-1) found with `bundle validate -o json` that the empty prefix was ignored: the schema resolved to `hls_fde_dev.dev_matthew_giglia_uw_genie` and job names had a doubled prefix.
* Session 06 (wave 0-2) removed `mode: development` from `uw-genie-infra/databricks.yml` `targets.dev` (comment block at lines 53-56) and set instead:
  * `variables.name_prefix: "[dev ${workspace.current_user.short_name}] "` (jobs and the warehouse only)
  * `presets.trigger_pause_status: PAUSED`
  * per-user `workspace.root_path: ~/.bundle/${bundle.name}/${bundle.target}`
* `uw-genie-agent` `dev` already uses `mode: development`. It owns no schema; its warehouse lookup is `"[dev ${workspace.current_user.short_name}] uw_genie_warehouse"`.
* What is lost without development mode: per-user schema isolation (anyone deploying `dev` writes into the same `hls_fde_dev.uw_genie`), the deployment lock and the dev tagging. Only trigger pausing was re-added by hand.

## Requested change

1. Put `mode: development` back on `uw-genie-infra` `targets.dev`. Accept the prefixed schema `hls_fde_dev.dev_matthew_giglia_uw_genie`.
2. Remove the `var.name_prefix` workaround and any presets that development mode already provides (keep `presets.tags` if still wanted).
3. Make every dependent follow the deployed name (this is where R1-04 applies):
   * `uw-genie-agent/databricks.yml` `catalog` / `schema` variables per target. They are cross-bundle, so they cannot use `${resources...}`; they must match the infra values per target (same rule as scAuditor).
   * Genie space `serialized_space` table and metric view identifiers in `uw-genie-agent/resources/genie_spaces/underwriting_genie.genie_space.yml` (render from variables; R1-04).
   * `docs/plans/waves.json` runtime targets, session scopes and `context_notes`.
   * Skill files and the UC Skills publish location (today `hls_fde_dev.uw_genie`; `lg-intake-checklist/SKILL.md` has the literal name, see R1-04).
4. Re-seed: run `setup_demo` against the new schema; republish the 4 UC Skills to the new schema.
5. **Dev stays destroyable.** Do NOT add `lifecycle.prevent_destroy` to any `dev` resource; `bundle destroy --target dev` must work. Protection, if any, belongs only on non-dev targets.
6. Decide (owner) what to do with the old `hls_fde_dev.uw_genie` schema, the old Genie space `01f1e1554179173991a4a487c2ae28ef` and the 4 skills published there. Deleting them needs explicit owner confirmation.

## Files affected

* `uw-genie-infra/databricks.yml`
* `uw-genie-agent/databricks.yml`, `uw-genie-agent/resources/genie_spaces/underwriting_genie.genie_space.yml`
* `docs/plans/waves.json`, session plans that name the schema
* `docs/demo-assets/skills/*/SKILL.md` (publish-time rendering, R1-04)
* `PROJECT_MEMORY.md`, `README.md`, `docs/architecture.md` (deployed names)

## Acceptance criteria

* `bundle validate --strict --target dev` passes for both bundles; `-o json` shows schema `dev_matthew_giglia_uw_genie` and single-prefixed job names.
* `setup_demo` succeeds against the new schema; golden CSV 18/18; base premium 625.32.
* The Genie space resolves all its tables and metric views in the new schema.
* The 4 UC Skills are listed and finalized in the new schema.
* No `prevent_destroy` on any `dev` resource (grep the bundles).

## Dependencies

R1-04 (no literal names) should land in the same change; otherwise the rename breaks every hard-coded reference.
