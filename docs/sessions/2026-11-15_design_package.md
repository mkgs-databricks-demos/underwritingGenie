# 2026-11-15 — Design package v1.0-draft

## Goal
Document the generic large group experience-rated underwriting Genie One demo end to end (research → semantics → pitch → diagrams → L100–L400), including Genie session instructions and acceptance criteria.

## Changes
- Created project folder with 53 files: research 6, semantics 3, pitch 2, Mermaid diagrams 7, design 16 (L100, 7×L200, 5×L300, 3×L400), demo assets 19 (broker packages v1/v2, 4 skills, golden CSV), README, session log + index.
- Computed the 18-scenario golden result set independently in Python.
- Generated broker packages v1 (5 seeded gaps) and v2 (complete); 4 skills.

## Decisions
12 decisions assumed (research/06). Notable: Northwind sized at 420 EEs so credibility stays partial; rating as a UC SQL table function (Python UDFs can't read tables); artifact data precomputed because artifacts are snapshot-based.

## Verification
- Base case: premium $625.32 PMPM, Family $2,290.21, Z 0.748, +2.2% vs current.
- Neutrality grep over docs: no account, customer or colleague names (vendor names only in research/05; one public state filing cited in research/02).

## Observations
- Artifact form controls are not documented; fallback comparison panel defined.

## Follow-ups
- Review gate artifact → SVG/HTML rendering.
- Build waves 1–4 (L400-01); record benchmark ★7/★8 values after S5.
