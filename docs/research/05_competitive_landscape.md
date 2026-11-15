# Research 05 — Competitive and Adjacent Landscape

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## Key thesis
The market splits into **predictive risk scoring** vendors and **quote/proposal workflow** platforms. Neither owns the carrier's governed rating method, data and semantics. Databricks' position: the governed foundation where intake, rating, explanation and finance meet — and where third-party scores plug in as inputs.

| Category | Examples (public positioning) | What they do | Gap the demo highlights |
|---|---|---|---|
| Predictive underwriting / risk intelligence | Gradient AI (SAIL for New Business, Renewal Analytics) | Group/member risk prediction, high-cost exposure flags | Decision-support input; doesn't own carrier rating method or explanations |
| Quote-to-card / multi-carrier quoting | EbixEnterprise Quote to Card | Census ingestion, multi-carrier quoting, proposals, enrollment | Distribution workflow; not the carrier's experience-rating engine |
| Broker/GA quoting | BenefitFront, Benefix | Standardized group/ancillary quoting, census mapping | Small-group and standardized focus |
| Carrier-built rating tools | Spreadsheets, rating engines, actuarial code | The actual method | Fragmented inputs, versioning, explainability |
| Horizontal "ontology/operational AI" platforms | Various | Generic decision apps | Not native to the carrier's governed lakehouse |

## Positioning lines (customer-safe)
- "Bring your method; we make it governed, explainable and instant."
- "Third-party risk scores become governed inputs, not black boxes."
- "One ontology for underwriting, actuarial and finance."

## Honest notes
- For complex large groups, the market does not offer a universal instant quote; the demo shows *standard-case automation with exception referral*, which is realistic.
- Vendor names are for internal context only — **never** shown in customer-facing slides or the demo.

## Sources
- Gradient AI — Group health solutions: https://www.gradientai.com/health/
- EbixEnterprise Quote to Card launch: https://www.ebix.com/news-and-media/ebixenterprise-quote-to-card-ai-group-benefits-platform/
- BenefitFront: https://www.benefitfront.com/
- Benefix: https://benefix.us/benefix-health-insurance-platform-for-brokers
