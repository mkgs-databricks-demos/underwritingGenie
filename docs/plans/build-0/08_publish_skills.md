# Session 08 — Publish UC Skills (4 skills)

**Wave:** 0-4 (converge)
**Mode:** converge
**Depends on:** 06
**Max attempts:** 3
**Timeout:** 60 minutes

## Goal

Publish the four project skills from `docs/demo-assets/skills/` to UC Skills at `hls_fde_dev.uw_genie` using the same method as the genie-build-waves setup job. Copy each SKILL.md to the workspace skills folder.

## Context files to read first

* `docs/design/L300-04_skill_files.md` — skill specs, file structure, placeholders
* `docs/design/L200-04_genie_one_skills.md` — skill design
* `PROJECT_MEMORY.md` — skills catalog/schema: hls_fde_dev.dev_matthew_giglia_build_waves

## Files to create/modify (owned_paths)

* `docs/demo-assets/skills/**` (replace placeholders in source files)

## Steps

1. Replace `<catalog>.<schema>` placeholders with `hls_fde_dev.uw_genie` in all 4 skill SKILL.md files.
2. For each skill (`lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief`):
   a. `w.ai_gateway.create_skill(parent=schemas/hls_fde_dev.uw_genie, skill_id=<name>, skill=Skill(comment=<description from SKILL.md>))`
   b. Upload all files in the skill directory to `/Skills/hls_fde_dev/uw_genie/<name>/<relpath>` using `w.files.upload`
   c. `w.ai_gateway.finalize_skill(name=skills/hls_fde_dev.uw_genie.<name>)`
3. Copy each SKILL.md to `/Workspace/Users/matthew.giglia@databricks.com/.assistant/skills/<name>/SKILL.md`.
4. Verify each skill is visible in UC and invocable with `/<name>`.

## Acceptance criteria

* All 4 skills published to `hls_fde_dev.uw_genie` and finalized
* All 4 SKILL.md files copied to workspace skills folder
* No `<catalog>.<schema>` placeholders remain in any skill file
* Each skill is invocable by name in Genie One
* Session status is `pass`
