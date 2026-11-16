# R1-08 Intake checklist, broker package and demo-setup fixes

**Status:** Open. Item 1 is a design bug, **confirmed by the v2 test**: beat 2b (AC-2b-1) cannot pass until it is fixed.
**Origin:** Owner's Genie One test of `lg-intake-checklist` with the `northwind_v1` package (zip), then `northwind_v2` in the same chat, 2026-11-16 (chat `4fbc87afae364d29bdcda97dbaedecd2`)
**Related:** R1-06 (artifact readiness reads the findings)

## v2 test result (confirms item 1)

Genie returned **BLOCKED** on IC-01 alone: "24 consecutive incurred months (Jul 2024 - Jun 2026), but the last incurred month is about 5 months before submission (limit is 3)". Every other blocking item moved to PRESENT. Evidence verified against `northwind_v2/`:

* IC-01: `claims_experience_incurred.csv` has 24 rows, Jul 2024 - Jun 2026, all `basis = INCURRED`, `paid_through = 2026-08-01`.
* IC-02: present; `lag_report.csv` shows Jan - Jun 2026 at 99.4% down to 89.3% paid.
* IC-03: 420 of 420 employees complete (EE 168 / ES 76 / EC 59 / EF 117); 560 dependents.
* IC-04: LC-01 RESOLVED, LC-02 ACTIVE, LC-03 ONGOING, LC-04 RESOLVED.
* IC-05: both benefit summaries. IC-07: $612.00 PMPM in the email.
* Warnings open: IC-08 (renewal +14.2% reported, no exhibit) and IC-10 (prior plan changes not stated), as predicted in items 3 and 5 below.

Genie handled it well: it applied the rule as written, did not quote a rate, and offered two paths (ask the broker for later incurred months, or an underwriting exception because claims are paid through Aug 2026 with a lag report). For the demo, the exception path gets to READY_WITH_WARNINGS.

Two more inconsistencies this exposed:

* **Seeded status contradicts the rule.** `broker_submissions` stores `SUB-NW-001-V2` as `READY_WITH_WARNINGS`, but the governed `intake_checklist` rule makes it BLOCKED. After fixing IC-01 (item 1), re-check that the seeded statuses match what the rule produces for v1 and v2.
* **Submission date source.** Genie measured recency from today (2026-11-16) instead of the submission's received date (2026-11-13 15:40 UTC in `broker_submissions.received_ts`). The result is the same here, but the skill should use the received date (or the email date) so the check is reproducible.

## v1 test result

BLOCKED, with all 5 seeded gaps and exact file evidence, and no rate quoted. Verified against the files in `/Volumes/hls_fde_dev/uw_genie/broker_packages/northwind_v1/` and `intake_checklist`:

* IC-01: `claims_experience_paid.csv` has 15 months (Apr 2025 - Jun 2026); ends 5 months before the 2026-11-09 submission (rule: no more than 3).
* IC-02: all rows `basis = PAID`, no paid-through date, no lag report.
* IC-03: 22 of 420 employees fail (11 missing tier, census lines 52, 63, 176, 360, 544, ...; 11 missing birth date, lines 207, 248, 275, 310, 451, ...); 560 dependents complete.
* IC-04: LC-02 / LC-03 / LC-04 have no status; LC-01 RESOLVED.
* IC-05: only `benefit_summary_alternate.md` (Choice PPO 2500).

| ID | Criterion | Result |
| --- | --- | --- |
| AC-2-1 | Status Blocked | Pass |
| AC-2-2 | >= 4 of 5 seeded gaps | Pass (5/5, plus 1 extra true blocking gap) |
| AC-2-3 | Each gap cites its file | Pass |
| AC-2-4 | Gmail draft created, not sent | Not met as written (connector read-only; draft shown in chat, the §7 fallback) |
| AC-2-5 | No rate quoted | Pass |

## Requested fixes

1. **IC-01 rule vs v2 data (design bug).** Rule text in `intake_checklist`: "Claims experience covers 24 consecutive incurred months ending no more than 3 months before the submission." v2 incurred months end Jun 2026 (paid through Aug 2026) and v2 was received 2026-11-13, so v2 strictly fails IC-01 as well. That contradicts L300-05's expected `READY_WITH_WARNINGS` and AC-2b-1.
   * **Preferred:** reword IC-01 to measure recency from the paid-through date: "24 consecutive incurred months with a paid-through date no more than 3 months before the submission." v2 (paid through Aug 2026) then passes with no data change.
   * Alternative: shift the v2 incurred window 2-3 months later in the generator. Rates would not change (monthly claims are flat at $436,666.67 and lags are preserved), but it touches the generator and golden-file inputs.
2. **v1 has 6 blocking findings, not 5.** IC-07 "Current rates" is also missing: the v1 email gives the +14.2% renewal offer but no current premium; $612.00 PMPM first appears in the v2 email. Update L300-05 ("BLOCKED with 6 blocking findings") and AC-2-2 (6 gaps; pass at >= 5 of 6 with a note), or add the current premium to the v1 email if 5 was intended.
3. **IC-10 Prior plan changes (warning).** The rule is "Benefit changes during the experience period are listed (or none stated)". Neither v1 nor v2 says anything, so Genie correctly flags it. Either add "No plan design changes during the experience period" to the v2 email or RFP, or list IC-10 as an expected v2 warning in L300-05 next to IC-08.
4. **v1 file count.** `northwind_v1/` has 6 files (`benefit_summary_alternate.md`, `broker_email.txt`, `census.csv`, `claims_experience_paid.csv`, `large_claimant_report.csv`, `rfp_questionnaire.md`); L200-07 beat 2 says "drag all 5 files". Fix the count or say "all files".
5. **Gmail draft scope (AC-2-4, Must).** The Genie One Gmail connector in this workspace is read-only. L200-07 §1 must require a Gmail connection that can create drafts; L400-02 should check it at T-30 min.
6. **IC-01 broker ask wording.** Genie asked for experience "through at least Aug 2026", mixing incurred months and paid-through date. The broker-ask template (`intake_checklist.broker_ask_template` and the skill) should say "24 consecutive incurred months with a paid-through date no earlier than <submission - 3 months>".
7. **Write item-level findings.** `lg-intake-checklist` never writes `submission_findings` (0 rows), so later steps (the artifact readiness section, R1-06) cannot cite files. The intake answer already contains the needed evidence. Have the skill (or a governed job it triggers) write one row per checklist item with status, evidence and source file.

## Files affected

* `intake_checklist` seed (`uw-genie-infra/src/sql/00_ddl.sql` or the generator), `submission_findings` usage
* `docs/demo-assets/broker_packages/northwind_v1/broker_email.txt`, `northwind_v2/broker_email.txt` or `rfp_questionnaire.md` (if items 2-3 are fixed in data)
* `docs/demo-assets/skills/lg-intake-checklist/SKILL.md`
* `docs/design/L300-05_broker_documents.md`, `L200-07_demo_script_and_acceptance.md`, `L400-02_demo_runbook.md`

## Acceptance criteria

* v1 -> BLOCKED with the documented number of blocking findings; v2 -> READY_WITH_WARNINGS with the documented warnings only (IC-08, and IC-10 if kept).
* `submission_findings` has one row per checklist item after an intake run, each with a source file.
* A Gmail draft (not sent) is created in the demo workspace.
