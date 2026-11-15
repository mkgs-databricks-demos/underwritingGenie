# Semantics 02 — Intake and Quote Terms (UC Pages candidates)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view

Subdomain: **Intake & Quote**

### Broker Submission
- **Definition:** The package a broker sends to request a quote: email, census, experience, large claimant report, benefit summary, RFP.
- **Business context:** Unit of work for intake.
- **Data usage:** `broker_submissions`, UC Volume `broker_packages/`
- **Related terms:** Submission Completeness
- **Source:** L200-01

### Census
- **Definition:** Member-level enrollment file: DOB, gender, coverage tier, ZIP, employee/dependent.
- **Business context:** Drives demographic and tier factors.
- **Data usage:** `census_members`
- **Related terms:** Coverage Tier, Demographic Factor
- **Source:** L200-01

### Lag Report
- **Definition:** Paid claims by incurred month × paid month, enabling completion.
- **Business context:** Paid-only experience without a lag report is a blocker.
- **Data usage:** Broker package document
- **Related terms:** Completion Factor
- **Source:** Research 02

### Submission Completeness
- **Definition:** Status of a submission against the intake checklist: Ready, Ready with warnings, Blocked.
- **Business context:** The "ready to quote?" answer.
- **Data usage:** `intake_checklist`, `broker_submissions.completeness_status`
- **Related terms:** Blocking Item, Warning Item
- **Source:** L200-04

### Blocking Item
- **Definition:** Checklist item that must be present before rating (e.g., 24 months incurred experience).
- **Business context:** Generates broker request.
- **Data usage:** `intake_checklist.severity = BLOCKING`
- **Related terms:** Warning Item
- **Source:** L200-04

### Warning Item
- **Definition:** Checklist item that can proceed with a documented assumption.
- **Business context:** Shown in artifact readiness panel.
- **Data usage:** `intake_checklist.severity = WARNING`
- **Related terms:** Blocking Item
- **Source:** L200-04

### Coverage Tier
- **Definition:** EE, EE+Spouse, EE+Child(ren), Family.
- **Business context:** Rates quoted per tier.
- **Data usage:** `census_members.tier`; tier factors 1.00/2.00/1.85/2.85
- **Related terms:** Tier Rate
- **Source:** L300-02

### Composite Rate (PEPM)
- **Definition:** Average premium per enrolled employee per month across tiers.
- **Business context:** Basis for tier rates.
- **Data usage:** `nb_quote_scenarios.composite_pepm`
- **Related terms:** Tier Rate, PMPM
- **Source:** L300-02

### Tier Rate
- **Definition:** Monthly premium for a coverage tier.
- **Business context:** What the broker presents.
- **Data usage:** `nb_quote_scenarios.rate_ee` … `rate_ef`
- **Related terms:** Composite Rate
- **Source:** L300-02

### Rate Change vs Current
- **Definition:** Quoted premium PMPM divided by the incumbent's current premium PMPM, minus 1.
- **Business context:** Competitive position.
- **Data usage:** `nb_quote_scenarios.rate_change_vs_incumbent`
- **Related terms:** Incumbent Renewal
- **Source:** L300-02

## Tagging strategy
`subdomain=intake_quote`; PII-like census columns tagged `pii=synthetic` to demonstrate ABAC patterns.

## Implementation priority
P1: Submission Completeness, Blocking Item, Census, Tier Rate. P2: remainder.
