# Pitch 01 — Customer Vision Talk Track + Demo Narrative (customer-facing)

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


Audience: health plan business and data leaders (underwriting, actuarial, finance, sales, data). 100% customer-facing: no customer names, no internal names, synthetic data only.

## Slide 1 — Underwriting is a document problem posing as a math problem
- The rating method is well understood. The time goes into collecting, checking, re-keying and explaining the inputs: census, 24–36 months of experience, large claimant reports, benefit summaries, RFPs, broker emails.
- Gaps are discovered late — after the case has waited in a queue.
- With group medical trend projected near 9% for 2027, stale or incomplete inputs are expensive.

## Slide 2 — Move the decision to the front door
- Broker or account executive submits; an agent checks completeness against *your* intake standards instantly and asks for exactly what's missing.
- Complete cases are rated by *your* governed method, explained step by step, and packaged as a shareable quote.
- Underwriters focus judgment on exceptions: unusual claimants, redesigns, competitive situations.

## Slide 3 — One governed foundation for underwriting, pricing and finance
- The facts behind a quote — completed claims, pooling, trend, credibility, manual rate — are the same facts finance uses for projected loss ratio and premium at risk.
- Defined once (ontology), governed once (Unity Catalog), explained everywhere (Genie).
- Governed math, explained by AI: the model never improvises a rate; every number traces to an assumption version — aligned with emerging AI governance expectations for insurers.

## Demo narrative (12–15 min)
1. **Morning brief** — "No one opened a dashboard."
2. **Ready to quote?** — broker package dropped in; gaps found in seconds; broker reply drafted.
3. **Interactive New Business Quote** — complete package rated; Genie builds a living quote artifact; pooling point and plan options explored; broker proposal exported.
4. *(optional)* **Renewal explained** — waterfall + what-ifs.
5. **Decisions to dollars** — projected loss ratio vs target; premium at risk under a rate cap.

**Close:** "Everything you saw runs on one governed foundation. Together we'd build it on your rating manual, your intake standards and your data."

## Discovery questions
1. Who sits in the "Underwriting Genie" first — underwriters, account executives/brokers, or leadership?
2. Large group quote time today, request → quote out? Where does it stall?
3. How do submissions arrive, and how often are they incomplete on first pass?
4. Where does the rating method live (spreadsheets, rating engine, actuarial code)? Who owns changes?
5. How are pooling, credibility and trend assumptions governed and versioned?
6. How consistent are decisions across underwriters, and how is it measured?
7. What would finance need to trust AI-assisted quotes in the forecast?
8. What would success look like in 90 days?
