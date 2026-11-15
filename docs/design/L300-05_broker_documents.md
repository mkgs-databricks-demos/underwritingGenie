# L300-05 — Broker Package Documents (v1 incomplete, v2 complete)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


Source files are generated and versioned in `demo-assets/broker_packages/` and uploaded by session S4 to the UC Volume `${catalog}.${schema}.broker_packages`. Download them locally before the demo for drag-and-drop.

## northwind_v1 (incomplete — drives Beat 2)
| File | Seeded gap |
|---|---|
| `broker_email.txt` | Mentions incumbent +14.2% renewal; asks for current PPO + higher-deductible alternate |
| `census.csv` | 980 rows; **22 employee rows** missing birth_date (11) or tier (11) |
| `claims_experience_paid.csv` | **Paid basis only, 15 months** (Apr 2025–Jun 2026), no lag report |
| `large_claimant_report.csv` | 4 claimants; **3 missing status** |
| `benefit_summary_alternate.md` | Alternate plan only — **requested plan summary missing** |
| `rfp_questionnaire.md` | Complete |

Expected intake result: **BLOCKED** with 5 blocking findings.

## northwind_v2 (complete — drives Beat 2b)
| File | Content |
|---|---|
| `broker_email.txt` | Reply with missing items; current composite premium $612.00 PMPM |
| `census.csv` | 980 members, 420 employees; tiers EE 168 / ES 76 / EC 59 / EF 117 |
| `claims_experience_incurred.csv` | 24 incurred months Jul 2024–Jun 2026, paid through Aug 2026; $436,666.67/month; total $10,480,000 (24% Rx) |
| `lag_report.csv` | Cumulative paid % for the 6 most recent incurred months (consistent with completion factors) |
| `large_claimant_report.csv` | LC-01 NICU $612K RESOLVED; LC-02 Oncology $410K ACTIVE; LC-03 Hemophilia (specialty Rx) $268K ONGOING; LC-04 Orthopedic $185K RESOLVED |
| `benefit_summary_requested.md` / `benefit_summary_alternate.md` | Choice PPO 1000 (rel. 1.00) / Choice PPO 2500 (rel. 0.94) |
| `rfp_questionnaire.md` | Contribution 80%/65%, broad PPO, 3 COBRA, no Rx carve-out |

Expected intake result: **READY_WITH_WARNINGS** (warning: incumbent renewal exhibit not attached — acceptable).

## Optional PDF rendering
Session S4 may render the experience file and claimant report to PDF (watermark "SYNTHETIC DEMO DATA") for realism; CSV versions remain the source of truth. All names, emails (`.example` domains) and amounts are fictional.
