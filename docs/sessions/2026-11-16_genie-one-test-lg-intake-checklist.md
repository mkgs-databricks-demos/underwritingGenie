# 2026-11-16 Genie One test: `lg-intake-checklist`

**Type:** manual Genie One test (owner uploads broker packages and runs prompts, Genie Code checks every finding against the package files and `intake_checklist`)
**Skill:** `lg-intake-checklist` (published `skills/hls_fde_dev.uw_genie.lg-intake-checklist`; workspace copy `~/.assistant/skills/lg-intake-checklist/SKILL.md`)
**Chat:** `4fbc87afae364d29bdcda97dbaedecd2` (new chat, packages uploaded as zips from `/Volumes/hls_fde_dev/uw_genie/broker_packages/`)

## Goal

Run L200-07 beat 2 (v1 "ready to quote?") and the beat 2b readiness re-check (v2) in Genie One, and confirm Genie applies the 14 governed checklist rules with file evidence, quotes no rate, and drafts (never sends) the broker reply.

## What was tested and the result

| # | Prompt / action | Result | Evidence checked |
| --- | --- | --- | --- |
| 1 | Upload `northwind_v1` (6 files) + "Is it ready to quote? ... draft a reply to the broker." | Pass (AC-2-1, 2-2, 2-3, 2-5) | BLOCKED; all 5 seeded gaps with exact evidence: IC-01 15 months (Apr 2025 - Jun 2026), IC-02 PAID basis / no lag report, IC-03 22 of 420 employees (11 missing tier at census lines 52, 63, 176, 360, 544...; 11 missing birth date at lines 207, 248, 275, 310, 451...), IC-04 LC-02 / 03 / 04 without status, IC-05 only the PPO 2500 summary. No rate quoted |
| 1b | Broker reply | Not met as written (AC-2-4) | Gmail connector is read-only, so the draft was shown in chat (the L200-07 §7 fallback). Addressed to jordan.ellis@harborbenefits.example, polite, lists every item |
| 2 | Upload `northwind_v2` + re-check | BLOCKED on IC-01 only (design bug, see below) | 24 incurred months Jul 2024 - Jun 2026, all INCURRED, paid through 2026-08-01; lag report Jan - Jun 2026 at 99.4% to 89.3%; 420 / 420 census complete (EE 168 / ES 76 / EC 59 / EF 117); LC-01 RESOLVED, LC-02 ACTIVE, LC-03 ONGOING, LC-04 RESOLVED; both benefit summaries; $612.00 PMPM. Warnings IC-08 and IC-10 open. Genie offered two paths: ask for later months, or an underwriting exception |
| 3 | "Underwriting approves an exception for IC-01 ... rate Northwind ... build the quote" | Pass | READY_WITH_WARNINGS with the exception; quote built (see the `nb-quote-artifact` summary) with item-level readiness and real source files |

## Problems found and root causes

* **IC-01 rule vs v2 data (design bug).** The rule is "24 consecutive incurred months ending no more than 3 months before the submission". v2 incurred months end Jun 2026 and v2 was received 2026-11-13, so v2 strictly fails. L300-05 and the seeded `broker_submissions` row (`SUB-NW-001-V2` = READY_WITH_WARNINGS) both assume it passes. Root cause: the rule measures recency from the last incurred month instead of the paid-through date.
* **v1 has 6 blocking findings, not 5.** IC-07 Current rates is missing in v1 (the +14.2% renewal offer is there, the $612.00 premium only arrives in v2). L300-05 and AC-2-2 say 5.
* **IC-10 prior plan changes** is not stated in either package, so it stays a warning in v2; L300-05 lists only IC-08.
* **L200-07 says "drag all 5 files"**; `northwind_v1/` has 6.
* **Recency measured from today** (2026-11-16) instead of `broker_submissions.received_ts` (2026-11-13).
* **Broker ask mixes dates:** "through at least Aug 2026" combines incurred months and the paid-through date.
* **No persistence.** The skill never writes `submission_findings` (0 rows), and Genie One is read-only, so findings and the exception exist only in the chat / artifact.

## Decisions (owner)

* **Interim demo path:** keep Genie's "approve an exception" option for IC-01 in the live demo until build 1 fixes the rule (presenter prompt recorded in R1-08). A dry run that does not offer the exception is a demo blocker.

## Changes (files)

Docs only; no bundle source or data changed.

* `docs/requests/build-1/R1-08_intake-checklist-fixes.md` (v1 and v2 results, interim decision, items 1-8), `INDEX.md`
* `PROJECT_MEMORY.md` (pointer)

## Follow-ups

* R1-08 item 1 (preferred fix): measure IC-01 recency from the paid-through date; then re-check seeded statuses.
* R1-08 items 2-6: 6 blocking findings in L300-05 / AC-2-2, IC-10 expectation, v1 file count, Gmail draft scope in L200-07 §1 and L400-02, broker-ask wording.
* R1-08 item 7: governed write path for findings and exceptions (shared design with R1-09).
* R1-10: use the received date (and a pinned as-of date) for recency windows.
