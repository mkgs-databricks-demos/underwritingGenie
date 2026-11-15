# L200-05 — Interactive New Business Quote Artifact (C5)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

## Overview
The hero moment: Genie One generates an interactive Genie Artifact "Northwind Manufacturing — New Business Quote" from the governed scenario snapshot, then adds a broker-proposal view and exports PDF.

## Dependencies
- Artifacts Beta enabled (workspace Previews)
- C2 `nb_quote_scenarios`, `nb_quote_waterfall`
- Skill `nb-quote-artifact` (L300-04)

## Design
### Layout (8 sections)
1. **Quote header** — group, 1/1/2027, 420 EEs / 980 members, broker "Harbor Benefits Partners", status "Ready for underwriter review", **SYNTHETIC DEMO DATA** badge.
2. **Readiness check** — all BLOCKING items green; warnings with documented assumptions; each linked to package v2 file.
3. **Recommended rates** — tier table (EE/ES/EC/EF), composite PEPM, change vs incumbent current (+2.2% base) and vs incumbent renewal offer (+14.2%).
4. **How we got here** — waterfall chart (10 steps) for the selected scenario.
5. **Levers** — scenario selector: pooling point ($150K/$250K/$500K) × trend (low/base/high) × plan (requested/alternate). Fallback: comparison panel of the 6 pooling×plan combinations at base trend.
6. **Large claimants** — 4 claimants, status, excess pooled at selected point.
7. **Assumptions & audit** — AV-2027.1, function name/version, source tables, documents used, generation timestamp, "rates produced by governed function; AI explains only".
8. **Underwriter notes** — Genie's AE rationale (editable) + decision placeholder (Approve / Adjust / Decline — human).

### Data binding
Artifact snapshot = all 18 rows of `nb_quote_scenarios` + 180 rows of `nb_quote_waterfall` + 4 claimants + checklist results. No browser-side calculation.

### Broker proposal view
One page: tier rates for requested + alternate plan at the underwriter-selected scenario, effective date, rate guarantee language placeholder, synthetic badge. Export PDF.

### Backup
Pre-generate once; keep in shared `genie_artifacts` as "Northwind Manufacturing — New Business Quote".

## Non-functional requirements
- Generation ≤ 3 min; every number in the artifact matches the golden file.
- Readable on a projector (min 14pt equivalent).

## Testing
Acceptance criteria AC-2b-1…AC-2b-10 in L200-07.

## Deployment
Session S8 builds skill + backup artifact; dry-run 3×.

## Open questions
- If the Beta renders controls inconsistently, use fallback panel (assumed acceptable — D7).
