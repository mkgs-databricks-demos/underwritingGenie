# Research 01 — Large Group Underwriting: Market and Problem Context

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## Key thesis
Large group experience rating is a **document and data-assembly problem posing as a math problem**. The rating arithmetic is well documented and fits in a single spreadsheet formula; the cost, delay and inconsistency come from collecting, validating, normalizing and explaining the inputs — and from finding out late that inputs are missing.

## 1. What "large group" means
| Item | Fact | Source |
|---|---|---|
| Market definition | Federal default: large group = 51+ employees; states may set small group at 1–100, making large group 101+ | HealthCare.gov glossary |
| Medical loss ratio | Large group MLR standard is 85% (some states higher); rebates owed if below | CMS MLR resources; HealthCare.gov 80/20 rule |
| Rating basis | Larger groups are partly or fully rated on their own claims experience, blended with a manual rate by credibility | ASOP 25; SOA credibility paper |

**Design implication:** the demo uses a fully insured, experience-rated group (420 enrolled employees, ~980 members) — large enough to be experience rated, small enough that credibility is *partial*, so the manual/experience blend is visible on screen.

## 2. Cost pressure: why speed and accuracy matter now
- PwC projects **2027 group medical cost trend at 9.0%**, the highest in 17 years, and revised 2026 to 9.0% from 8.5%. Drivers: AI-enabled provider coding, provider reimbursement pressure, pharmacy (GLP-1s roughly doubling Dec-24 → Dec-25 fills), behavioral health utilization, and No Surprises Act arbitration outcomes.
- At 9% trend, a renewal priced with stale or incomplete inputs is materially mispriced. A 1-point error in trend on a $7M premium group is ~$70K/year.

## 3. Where the time goes today
| Benchmark | Value | Source / caveat |
|---|---|---|
| Group underwriting turnaround after a **complete** submission | 3–5 business days | Industry broker material; directional |
| Complex or **incomplete** submissions | 1–3+ weeks | Directional |
| Broker RFP-to-presentation labor, 250+ employee groups | 12.7 hours manual vs 6.7 with CPQ tooling | Vendor-sponsored broker survey (>100 brokers) — directional |
| Group medical underwriting top challenge: peak volume | 91% of participants; inefficient systems 78%; technology deficiencies 61% | Gen Re U.S. benchmarking survey (2023) |

**Honest gap:** there is no neutral, authoritative industry benchmark for large group quote cycle time. The demo therefore does not claim a specific "industry" number; it shows *submission-complete-at-intake* and *minutes-to-explained-quote* and invites the audience to supply their own baseline (discovery question).

## 4. The five failure modes the demo targets
1. **Late discovery of missing inputs** — e.g., paid-only claims with no lag report, missing months of experience, census gaps, large-claimant status unknown. Found days later by the underwriter.
2. **Re-keying** — census, experience exhibits and benefit summaries typed into rating spreadsheets.
3. **Inconsistent method** — pooling point, credibility and trend applied differently across underwriters/spreadsheet versions.
4. **Unexplainable output** — the rate action is a number; the *why* lives in the underwriter's head.
5. **Disconnected from finance** — underwriting decisions aren't visible as projected loss ratio / premium at risk until after the fact.

## 5. Quantified value hypotheses (to validate in discovery)
| Lever | Hypothesis | How the demo shows it |
|---|---|---|
| Intake completeness | Catch 100% of checklist gaps at submission vs. days later | Beat 2 |
| Underwriter time per new business quote | Hours → minutes for standard cases | Beat 2b |
| Consistency | One governed rating function, versioned assumptions | Beat 2b audit panel |
| Finance visibility | Projected loss ratio vs target available at quote time | Beat 4 |

## Sources
- HealthCare.gov — Large Group Health Plan glossary: https://www.healthcare.gov/glossary/large-group-health-plan/
- CMS — Medical Loss Ratio data & resources: https://www.cms.gov/marketplace/resources/data/medical-loss-ratio-data-systems-resources
- HealthCare.gov — Rate Review & the 80/20 Rule: https://www.healthcare.gov/health-care-law-protections/rate-review/
- PwC — Medical cost trend 2027: https://www.pwc.com/us/medicalcosttrends
- Gen Re — Group Medical EOI Underwriting benchmarking survey: https://www.genre.com/us/knowledge/publications/2023/october/group-medical-eoi-underwriting-en
- Threeflow — Speed up and simplify the insurance RFP: https://www.threeflow.com/resources/blogs/speed-up-simplify-insurance-rfp
