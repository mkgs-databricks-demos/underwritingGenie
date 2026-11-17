# Naming Sweep: Underwriting Cockpit → Underwriting Genie

**Date:** 2026-11-15
**Branch:** `mg-genie-naming-sweep`

## Goal

Replace all references to "Underwriting Cockpit" with "Underwriting Genie" across the repo, update bundle names, catalog/schema defaults, and Genie Agent title to reflect decisions made for the genie-build-waves build 0 plan.

## Changes

### Name replacements (27+ files)
- "Underwriting Cockpit" → "Underwriting Genie" (README, PROJECT_MEMORY, L100, L200-07, L400-01, L400-02, render_diagrams.py, pitch, all HTML files)
- "Large Group Underwriting Cockpit" → "Underwriting Genie" (L200-03, L300-03, L300-04, L400-01, research/04, mermaid/03, skill files, L100 HTML, 03_demo_architecture HTML)
- "Underwriting Genie Genie Agent" → "Underwriting Genie agent" (fixed redundancy in 5 files: L200-07, L300-04, 3 skill SKILL.md files)

### Bundle name updates
- `lg-underwriting-cockpit` → `uw-genie-infra` (L400-03, PROJECT_MEMORY, README)
- Added `uw-genie-agent` as second bundle (README deployment section, PROJECT_MEMORY)

### Catalog/schema updates
- `lg_underwriting_dev` → `hls_fde_dev` (L400-01, L400-03, L300-01, research/06, README, PROJECT_MEMORY)
- `demo` (schema default) → `uw_genie` (L400-01, L400-03, L300-01, research/06, README, PROJECT_MEMORY)
- `lg_uw_demo` (fallback) → `uw_genie` (L400-01, research/06, PROJECT_MEMORY)

### File name updates
- `large_group_underwriting_cockpit.json` → `underwriting_genie.geniespace.json` (L400-01, L400-03, PROJECT_MEMORY)
- `02_future_state_cockpit.md` title → "Future State Underwriting Genie" (mermaid source + HTML title/h1)

### Build plan updates
- "8 Genie Code sessions in 4 waves" → "Genie Build Waves (build 0)" (README, PROJECT_MEMORY)
- Updated README build plan table to reference `docs/plans/build-0/`
- Updated PROJECT_MEMORY status to reference build 0 and `docs/plans/build-0/`
- Added Devin level 4 monitor note to README exit criteria

### Files NOT changed (intentional)
- `02_future_state_cockpit.md` filename kept (avoids breaking links; same convention as L400-03)
- `L400-03_dab_deployment_and_reset.md` filename kept (avoids breaking links)
- Historical session logs left as written
- PROJECT_MEMORY.md:81 documents the change itself (intentional "Underwriting Cockpit" reference)
- L100_demo_overview.md:24 references the file path `02_future_state_cockpit.md` (filename, not display name)

## Decisions
- Genie Agent title: "Underwriting Genie" (not "Large Group Underwriting Genie")
- Two bundles: `uw-genie-infra` and `uw-genie-agent` (not single `lg-underwriting-cockpit`)
- Catalog/schema: `hls_fde_dev.uw_genie` (not `lg_underwriting_dev.demo`)
- Genie space serialized file: `underwriting_genie.geniespace.json` (not `large_group_underwriting_cockpit.json`)
- Use lowercase "agent" in "Underwriting Genie agent" to avoid "Genie Genie Agent" stutter

## Verification
- Final grep confirms no remaining "Underwriting Cockpit" in display text (only in PROJECT_MEMORY naming-sweep note and L100 file path link)
- No remaining "Large Group Underwriting Cockpit" anywhere
- No remaining `lg_underwriting_dev`, `lg_uw_demo`, `large_group_underwriting_cockpit`, `lg-underwriting-cockpit`
- No remaining "Genie Genie Agent" redundancy
- HTML files: all titles and subtitles updated

## Observations
- 27 files modified across docs/design, docs/diagrams, docs/demo-assets/skills, docs/pitch, docs/research, README, PROJECT_MEMORY
- HTML diagram files have large SVG content; only text labels were changed, SVG structure untouched
- The render_diagrams.py template was fixed so future regenerations will use "Underwriting Genie"

## Follow-ups
- Commit and push this branch
- Start build 0 planning: session plans, waves.json, build-waves.vars.json, Devin monitor prompt
- Grant mkgs-devin CAN_READ on the underwritingGenie Git folder
- Verify Devin OAuth secret, IP allow list, and GitHub token scope before build 0