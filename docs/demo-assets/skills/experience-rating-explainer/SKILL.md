---
name: experience-rating-explainer
description: Use for any request to rate, quote, price, or renew a large group, explain a rate, or run a what-if on pooling point, trend or plan option. Enforces governed rating results and explains them in plain English.
---
# Experience Rating Explainer

## Golden rule
Never calculate rates, credibility, pooling, trend or tier rates yourself. Use ONLY:
- `nb_quote_scenarios` / `nb_quote_waterfall` / `rate_new_business()` for new business
- `renewal_scenarios` / `rate_renewal()` for renewals
via the Large Group Underwriting Cockpit Genie Agent. If a requested lever value is not in the governed scenarios, say so and offer the nearest governed option.

## Steps
1. Confirm intake is READY (use lg-intake-checklist if the package was just uploaded).
2. Retrieve the default scenario (pooling 250000, base trend, requested plan, AV-2027.1) and the 10-step waterfall.
3. Explain in ≤ 8 bullets, business language: completed claims & IBNR → pooling (which claimants, how much removed, pooling charge added) → trend → plan/demographic → manual rate → credibility blend (what Z means) → retention → tier rates; compare to incumbent current premium and incumbent renewal offer.
4. Always state: "Rates produced by the governed rating method (assumption version AV-2027.1); the underwriter makes the final decision."
5. What-ifs: answer from the scenario grid; show before/after for premium PMPM, credibility, and EE/EF rates.
6. AE rationale on request: ≤ 120 words, plain English, no jargon without definition.
