# R1-06 `nb-quote-artifact` skill fixes from the Genie One test

**Status:** Open
**Origin:** Owner's Genie One test of `nb-quote-artifact`, 2026-11-16 (chat `04e80baad93c48fc9dfcfe4f9ffda27a`)
**Related:** R1-05 (rule text, renewal KPI), R1-08 (item-level findings)

## Test results (all values checked against the governed tables)

| Test | Result |
| --- | --- |
| Build at default $250K / Base / Requested | Pass: 8 sections in order; $625.32 PMPM, $1,459.07 PEPM, +2.2%, Z 0.7483, EE $803.58 / ES $1,607.16 / EC $1,486.63 / EF $2,290.21; 10 build-up steps; AV-2027.1; badge; 111-word notes |
| Levers $150K and $500K | Pass (owner checked): $613.84 / Z 0.8854 / $875,000 pooled; $639.06 / Z 0.6261 / $112,000 pooled |
| Lever Alternate at $250K / Base | Pass: $589.02, $1,374.39, -3.8%, EE $756.94 / ES $1,513.88 / EC $1,400.34 / EF $2,157.28; build-up 506.01 / 555.02 / 518.34 |
| Reset to recommended | Pass |
| Broker proposal view | Pass: Requested and Alternate tier rates side by side, composite, "Rates subject to final underwriting", badge twice, no internal detail |
| PDF export | Pass (owner): single letter page `Northwind Manufacturing - Broker Proposal.pdf` in the chat outputs, no view toggle |
| Plan comparison prompt | Pass: from `plan_designs` (PPO 1000: $1,000 / $4,000 / 20% / 1.00; PPO 2500: $2,500 / $6,000 / 20% / 0.94); relativity on the workbench only |
| Guardrail "Lower the Family rate to $2,200" | Pass: refused; offered governed options (see R1-07 for the list-completeness nit) |

## Requested fixes

1. **Add `plan_designs` to the skill's data list.** Before the owner prompted for it, the artifact never queried `plan_designs`, so it could not say what "Alternate deductible" means. Required by the skill:
   * Plan names (Choice PPO 1000 = requested, Choice PPO 2500 = alternate) on the lever buttons, the scenario label, section 3 and the broker proposal columns, with "Requested" / "Alternate deductible" as subtitles.
   * A plan comparison (deductible, out-of-pocket max, coinsurance) in section 3 of the workbench and on the broker proposal; plan relativity (0.94) on the workbench only.
   * The line "Copays and Rx are the same on both plans; only the deductible and out-of-pocket max differ." Genie correctly noted it could not verify this from governed data; it is true per `docs/demo-assets/broker_packages/northwind_v2/benefit_summary_*.md` (PCP / specialist $25 / $50, ER $300, Rx $10 / $40 / $70 / 20% to $250 on both).
2. **Data model (L300-01).** `plan_designs` has only `deductible_ind`, `oop_max_ind`, `coinsurance`, `relativity`. Add `deductible_fam`, `oop_max_fam` and copay / Rx columns (values from the v2 benefit summaries: family deductible $2,000 / $5,000, family OOP $8,000 / $12,000) so the broker page shows the full benefit summary from governed data.
3. **Section 4 wording.** Replace "waterfall chart of the 10 steps" with "10-step build-up: step list plus a PMPM bar chart". The steps mix USD, PMPM, a ratio and PEPM, so a stacked waterfall is not meaningful, and step deltas would be tier-2 values (R1-05).
4. **Section 6 claimant excess.** "Amount above the selected pooling point" per claimant is a calculation (LC-01 $362,000, LC-02 $160,000, LC-03 $18,000, LC-04 $0 at $250K). Under R1-05, provide it as a governed output or as tier-2 SQL labeled derived.
5. **Section 2 readiness.** Started cold, Genie marked 13 items green because the v2 package "wasn't flagged" for them, and "source file" showed the package, not files. Root cause: `lg-intake-checklist` never writes `submission_findings` (0 rows). Read item-level findings from `submission_findings` (written per R1-08); with no findings, label the rows "package-level status" instead of per-item green/amber.
6. **Section 3 KPI box 5.** "Change vs incumbent renewal offer" from the governed renewal comparison (R1-05).
7. **Broker proposal footnote.** Replace "Rates are per enrolled employee per month by coverage tier. Composite rate shown for reference." with "Tier rates are per enrolled employee per month; composite = average per enrolled employee." Keep the PDF behavior Genie used (separate single-page PDF, no view toggle).
8. **Section 8.** Underwriter notes stay on the recommended scenario when levers move. Document this as intended in the skill and L200-05.
9. **Governed tier relationship.** In the guardrail answer Genie explained Family = 2.85 x EE (`tier_factors`, AV-2027.1: EE 1.00, ES 2.00, EC 1.85, EF 2.85). Consider stating the tier factors in the audit section.

## Files affected

* `docs/demo-assets/skills/nb-quote-artifact/SKILL.md`
* `docs/design/L200-05_nb_quote_artifact.md`, `L300-01_data_model_and_generation_spec.md`
* `uw-genie-infra/src/sql/00_ddl.sql`, `uw-genie-infra/src/notebooks/generate_synthetic_book.py` (plan_designs columns)
* `uw-genie-agent` Genie space data sources (ensure `plan_designs` is included)

## Acceptance criteria

* A cold Genie One run builds the artifact with plan names and the plan comparison without being prompted.
* The broker proposal shows family deductible / OOP and copays from governed data.
* Readiness rows cite files when findings exist and say "package-level status" when they do not.
* KPI box 5 shows -10.5% at the default scenario and updates with the levers.
