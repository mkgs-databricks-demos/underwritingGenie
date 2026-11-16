# Genie One prompts: Morning Brief routine and Underwriting Genie demo artifact

**Purpose:** two Genie One prompts for the first live demo (2026-11-16):

* **Prompt A** sets up the Morning Brief as a scheduled Genie One routine and runs it once, so a completed brief is ready to open in beat 1.
* **Prompt B** builds a **customer-facing** Genie Artifact in Databricks design language: the vision for underwriting, the demo story, the Databricks products and how they are used (with diagrams), and a live-demo walkthrough with the exact copy-and-paste prompts for the beats tested on 2026-11-16.

**Written:** 2026-11-16, before build 1. Every number and prompt in the walkthrough was verified in Genie One today (see `docs/sessions/2026-11-16_genie-one-test-*.md`). Fallbacks and known quirks are in the presenter notes at the end of this file, not in the artifact.

**How to use:**

1. **Prompt A:** in a new Genie One chat with the `uw-morning-brief` skill on, first type `@` and select the agent **`[dev matthew_giglia] Underwriting Genie`** (the dev deployment's title includes this prefix), then paste everything between the `===== A` lines after it. Confirm the routine was created and that its first run finished. Leave that chat or run open as Tab A.
2. **Prompt B:** in another new Genie One chat, paste everything between the `===== B` lines. Present from the resulting artifact.

===== A

Set up a recurring routine for me called **"Large Group Underwriting Morning Brief"** that runs every weekday at 7:00 AM my local time, then run it once now so I have a completed brief to open.

Each run should do exactly this (all data is synthetic for Lakeside Health Plan):

Use the `uw-morning-brief` skill and the Genie agent titled **"[dev matthew_giglia] Underwriting Genie"** (space ID `01f1e1554179173991a4a487c2ae28ef`; the skill calls it "the Underwriting Genie agent") to produce today's Large Group Underwriting Morning Brief. If you cannot attach that agent, query the governed tables in `hls_fde_dev.uw_genie` directly (`renewal_pipeline`, `broker_submissions`, `groups`, `trend_monitor`). Produce it in this order:

1. Renewals due in the next 90 and 120 days, and how many are pre-built.
2. New business submissions waiting on brokers: count **every** submission with status BLOCKED in `broker_submissions`, including prospects that have no row in `groups` (show the group ID and broker when no group name exists); give the oldest one and the most common missing item; name Northwind Manufacturing if it is blocked.
3. Groups with a new large claimant above the pooling point, with renewal date, premium and owner.
4. Renewal quotes past their quote due date, with owners (summarize; no more than 6 rows).
5. One trend flag from `trend_monitor`: actual vs assumed, in points.

End with "Who owns what today" (no more than 5 bullets). Keep it to one screen, business language, no SQL, no dashboard links, no table longer than 6 rows. Do not explain why a renewal's rate action is what it is; list facts only. Take every number from that agent or those tables; do not calculate numbers in the text.

After creating the routine, tell me its name, schedule and when the first run finished, and show me that first brief.

===== A

===== B

Build me an interactive Genie Artifact titled **"Underwriting Genie: The Future of Large Group Underwriting"**. I will present it to customers (underwriting, actuarial and finance leaders), so it must be customer-facing, polished and concise. Use only the facts in this message; do not invent products, numbers or capabilities. All data is synthetic for a fictional carrier, "Lakeside Health Plan"; no real carrier, customer, broker or employee names. Show a "SYNTHETIC DEMO DATA" badge in the header. No internal notes, test results, bug lists or troubleshooting text anywhere in the artifact.

**Design: Databricks design language.**

* **Principles:** distilled (clean, minimal, every element earns its place, generous whitespace), bold (confident headings, strong focal points, Lava accents), fresh (modern layout and spacing).
* **Colors (use exactly):** hero / header band Navy 800 `#1B3139` with White text and a Lava 600 `#FF3621` accent line; page background Oat Light `#F9F7F4`; cards White `#FFFFFF` with 1px Gray Lines `#DCE0E2` borders and 12px radius; body text Navy 800, secondary text Gray Text `#5A6F77`; diagram nodes White or Oat Medium `#EEEDE9` with Navy 800 text and Navy 600 `#1B5162` arrows; highlight nodes and the active tab in Lava 600 (accent only, never large backgrounds). Status colors: success Green 600 `#00A972`, warning Yellow 600 `#FFAB00`, error Lava 700 `#BD2B26`, info / links Blue 600 `#2272B4`. Keep every text and background pair at WCAG AA contrast (4.5:1 for body text).
* **Typography:** DM Sans only (Bold 700 headings, Medium 500 labels and tabs, Regular 400 body), DM Mono only for prompts and object names. Sizes on an 8px scale: hero 48-56px, page headings 32-40px, card headings 24px, body 16px, captions 12-14px; line height 1.2 for headings, 1.5 for body; left-aligned text.
* **Components:** an eyebrow label (small, Medium, Gray Text) above each page heading; pill tabs for the 5 pages in the header band; KPI tiles (big Bold number, small caption); rounded pill badges; numbered step cards; buttons 8px radius (primary Lava 600 with White text).
* Draw every diagram as inline SVG or HTML (rounded boxes and arrows), not images. On page 4, show every prompt in a DM Mono block on Oat Medium with a "Copy" button.

Use a page selector with these 5 pages, in this order.

---

**Page 1: The vision**

Headline: "Underwriting is a document and data-assembly problem posing as a math problem."

The idea: for fully insured, experience-rated large group business, most underwriting time goes into chasing missing documents, checking census files and re-keying data, not into judgment. Underwriting Genie moves that work to the front door and lets an AI coworker do the assembly, while the math stays governed and the underwriter stays in charge.

Six principles (show as six cards):

1. **People, not plumbing.** No code on screen; business users work in plain language.
2. **Move underwriting to intake.** Find gaps the moment a broker package arrives, not days later.
3. **Governed math, explained by AI.** Rates come only from a governed Unity Catalog SQL function; the AI explains them and never calculates them.
4. **The underwriter decides.** Genie recommends and drafts; a person approves.
5. **Ontology makes answers correct, not just accurate.** Shared definitions (loss ratio, premium at risk, credibility) and certified metrics.
6. **Genie One is a coworker, not a dashboard.** Ask, act, and get a shareable artifact.

Add a "today vs. future" diagram: today = broker email -> manual checklist -> spreadsheet rating -> email back and forth (days); future = broker package -> Genie checks intake in minutes -> governed rating function -> interactive quote artifact -> underwriter decision -> broker proposal (same day).

**Three-tier governed-math rule** (a small callout): (1) rating outputs only from the governed functions, which can be called live; the stored scenario grid is a cache of the same outputs; (2) derived display values only through visible, labeled SQL; (3) never change assumptions, override rates or do math in the reply.

---

**Page 2: The demo story (what the audience sees and hears)**

Persona flow: Underwriting leader -> Account executive / underwriter -> Broker.

Show a horizontal timeline of beats with a one-line "what they see" and "what they hear" for each:

1. **Morning Brief.** See: Genie's morning summary of renewals due, blocked broker submissions, new large claimants, overdue quotes and a trend flag. Hear: "Before my first coffee, Genie tells me where to spend my day."
2. **Ready to quote?** See: a broker package for Northwind Manufacturing is dropped into the chat; Genie checks it against the 14-item intake checklist, says BLOCKED, lists each gap with the file it came from, quotes no rate, and drafts the broker reply. Hear: "This kind of gap usually shows up days later. Now it shows up in two minutes."
3. **Second package and an underwriting exception.** See: the broker's resubmission fixes every gap except one recency rule; Genie explains it and offers two governed paths; the underwriter approves an exception. Hear: "Genie follows the rule; the underwriter makes the call."
4. **Interactive New Business Quote.** See: Genie rates Northwind with the governed function and builds an interactive quote artifact: readiness, recommended rates, how we got here, levers (pooling point, trend, plan), large claimants, a broker proposal view and PDF. Hear: "Every number comes from one governed function, and Genie explains it in plain English."
5. **Guardrails.** See: a request to cut the Family rate is refused with governed alternatives; a new $1,500 deductible plan is not priced because it is not an approved plan. Hear: "It will not make up a price."

Key reference numbers (Northwind Manufacturing, synthetic, base scenario $250K pooling / base trend / requested plan Choice PPO 1000, assumption version AV-2027.1): 420 enrolled employees, 980 members, 23,520 member months, effective 1/1/2027; premium **$625.32 PMPM**, **$1,459.07** per employee per month, **+2.2%** vs the incumbent's current $612.00; credibility **0.7483**; tier rates EE $803.58, ES $1,607.16, EC $1,486.63, Family $2,290.21; $540,000 removed by pooling at $250K; incumbent renewal offer +14.2%.

---

**Page 3: Databricks products and how they are used**

Show an architecture diagram with three layers and arrows, then a table with one row per product ("Product", "What it does in this demo").

Layer A, **Data and governance (Unity Catalog)**, schema `hls_fde_dev.uw_genie`:

* **Unity Catalog tables and views:** the synthetic book (groups, census, monthly claims, large claimants, plan designs, renewal pipeline, broker submissions, intake checklist, trend and assumption tables).
* **Unity Catalog Volume:** the broker packages (Northwind v1 and v2 files).
* **Unity Catalog SQL table functions:** `rate_new_business()` and `rate_renewal()`, the governed rating method (claims + IBNR, pooling above the pooling point, trend, plan and demographic adjustment, credibility blend with the manual rate, retention, tier rates). The 18 Northwind scenarios are stored in `nb_quote_scenarios` and match a live call exactly.
* **Metric views:** `mv_renewal_book`, `mv_quote_outcomes`, `mv_intake_ops` (certified business metrics such as projected loss ratio and premium at risk).
* **Tags and lineage:** every object tagged; governance travels with the data.
* **Unity Catalog Skills:** four published skills (`lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief`) that teach Genie the underwriting procedures.

Layer B, **Intelligence:**

* **Databricks SQL warehouse (serverless):** runs every query and function call.
* **Genie Agent "Underwriting Genie":** the data agent over the governed tables, functions and metric views, with business instructions and example questions.

Layer C, **Experience:**

* **Genie One:** the chat coworker; uses the skills and the Underwriting Genie agent; reads uploaded broker packages; builds interactive **Genie Artifacts** and exports PDF.
* **Connectors:** Gmail connector for the broker reply draft (draft only; never sends).

Also show a small "How it was built and deployed" strip:

* **Declarative Automation Bundles:** two bundles (`uw-genie-infra` for data, functions, metric views, warehouse and jobs; `uw-genie-agent` for the Genie Agent).
* **Lakeflow Jobs:** "Setup Demo" (builds the book, functions and tests) and "Reset Demo".
* **Genie Code:** built the solution in planned waves of sessions, with automated tests (for example, the 18 rating scenarios must match a golden file to the cent).

Add a "request flow" diagram for the quote beat: broker package (Volume / chat upload) -> Genie One + `lg-intake-checklist` skill -> intake checklist table -> underwriter exception -> `rate_new_business()` via the Underwriting Genie agent -> `nb-quote-artifact` skill -> interactive artifact -> broker proposal PDF.

---

**Page 4: Live demo walkthrough (copy-and-paste prompts)**

Eyebrow "See it live". Intro line: "Every step below runs live in Genie One against the governed, synthetic Lakeside Health Plan book." Show each step as a numbered card with: a short title, the persona, the exact prompt in a copy-able DM Mono block (or the action), and "What you'll see". Use exactly these steps and prompts:

**Step 1: Morning Brief** (Underwriting leader)

Action: open the completed "Large Group Underwriting Morning Brief" routine run. To run it on demand instead, use the prompt: `Use uw-morning-brief to help me get started.`

What you'll see: 25 renewals in the next 90 days (12 pre-built) and 31 in 120 days (16 pre-built); broker submissions blocked and waiting on brokers, including Northwind Manufacturing; 6 groups with a new large claimant (Lakeview Logistics is the largest, $21.0M premium); 13 renewal quotes past due; Rx trend 13.4% vs 11.0% assumed (+2.4 points); "Who owns what today".

**Step 2: Renewals that need a big increase** (Underwriting leader)

Prompt: `Which renewals in the next 90 days have a rate action above 15%?`

What you'll see: 3 groups: Yarrow Software +16.3%, Cedar Ridge Contractors +16.2%, Birchwood Wholesale +15.4%.

**Step 3: Ready to quote?** (Account executive)

Action: drop in the Northwind Manufacturing broker package (`northwind_v1.zip`).

Prompt: `A broker just sent this new business request for Northwind Manufacturing. Is it ready to quote? If not, tell me exactly what's missing and draft a reply to the broker.`

What you'll see: BLOCKED, with evidence from each file: only 15 of 24 months of claims; paid basis with no lag report; 22 of 420 employees missing a birth date or tier; 3 large claimants without status; the requested plan's benefit summary missing. No rate quoted. A polite draft reply to the broker; nothing is sent.

**Step 4: The resubmission** (Underwriter)

Action: drop in the resubmitted package (`northwind_v2.zip`).

Prompt: `The broker sent the missing items. Re-check this package against the intake checklist before we rate it.`

What you'll see: every gap fixed except one rule: 24 months of experience that end about 5 months before the submission (the checklist allows 3). Two warnings remain. Genie offers two paths: ask the broker again, or an underwriting exception, because claims are paid through August and a lag report is attached.

**Step 5: Approve the exception and build the quote** (Underwriter)

Prompt: `Underwriting approves an exception for IC-01: claims are paid through Aug 2026 and a lag report is attached. Record the exception, then rate Northwind Manufacturing for a 1/1/2027 effective date and build me an interactive New Business Quote I can review and share with the account executive.`

What you'll see: Ready with warnings; an interactive quote with a readiness check that cites each file and marks the approved exception; $625.32 PMPM, $1,459.07 per employee per month, +2.2% vs current, credibility 0.7483; tier rates $803.58 / $1,607.16 / $1,486.63 / $2,290.21; a step-by-step "How we got here" (assumption version AV-2027.1).

**Step 6: Explore the levers** (Underwriter)

Action: in the quote, select pooling point $150K, then $500K, then the alternate plan, then reset to recommended.

What you'll see: $150K = $613.84 PMPM, credibility 0.8854; $500K = $639.06, credibility 0.6261; alternate plan (Choice PPO 2500) at $250K = $589.02, -3.8% vs current.

**Step 7: Why is the quote above current?** (Account executive)

Prompt: `Why is our quote 2.2% above the incumbent's current premium? Walk me through what drives it.`

What you'll see: a plain-English walk through the governed build-up: completed claims $10,590,476.75; $540,000 pooled above $250K plus a $24.00 PMPM pooling charge; experience $427.32 PMPM; trend 9.0% for 2 years; projected $536.77; manual rate $590.45; credibility 0.7483; blended $550.28; 12% retention; $625.32.

**Step 8: Broker proposal** (Account executive -> Broker)

Prompt: `Add a one-page broker proposal view to the artifact using the $250K pooling point and base trend, then I'll export it to PDF.`

What you'll see: requested and alternate plan rates side by side, "Rates subject to final underwriting", the synthetic badge, no internal detail; a one-page PDF.

**Step 9: Guardrail** (Account executive)

Prompt: `Lower the Family rate to $2,200 so we beat the incumbent's renewal by more.`

What you'll see: a polite refusal, an explanation of the Family tier factor, and governed options that land at or below $2,200 (for example $2,157.28 on the alternate plan).

**Step 10 (optional): Governed math, live** (Actuary)

Prompt: `Re-run the governed rating function live for Northwind at $250K / base / requested and confirm it matches the quote.`

What you'll see: a live call to the governed rating function; every field matches the quote.

**Step 11 (optional): A new plan design** (Account executive)

Prompt: `The client wants a $1,500 deductible version of the plan. What would that cost?`

What you'll see: no price for a plan that is not approved; Genie offers the two governed plans (Choice PPO 1000 $625.32, Choice PPO 2500 $589.02) and says an approved plan design is needed first.

Close with a full-width Navy 800 band: "Intake in minutes. Governed math, explained in plain English. The underwriter decides."

---

**Page 5: What's next**

Eyebrow "Roadmap". Show 4 cards (not shown live today): **Renewal workbench** (the same governed method and interactive artifact for renewals, starting with Lakeview Logistics); **Decisions to dollars** (projected loss ratio vs the 88% target and premium at risk under a 12% rate cap, from the certified renewal metric view); **Governed write-back** (record intake findings, underwriting exceptions and approved plan designs with approver and timestamp); **Automated document intake** (broker packages processed in a pipeline as they arrive instead of uploaded to chat). End with a short "Why Databricks" strip: one governed platform for data, rating logic, metrics and AI; every answer traceable to Unity Catalog.

---

Optional check: if the Genie agent "[dev matthew_giglia] Underwriting Genie" is available in this chat, confirm the Northwind base-scenario numbers on page 2 against `nb_quote_scenarios` (group `GRP-NW-001`, pooling point 250000, trend `base`, plan `requested`) and tell me in chat if any differ. Do not change the numbers in the artifact yourself.

===== B

## Presenter notes (not in the artifact)

**30 minutes before:**

* Skills on in Genie One: `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief`; unrelated skills off.
* Tabs: A = the Morning Brief routine run (Prompt A), B = a new empty chat "Underwriting Genie: live", C = the backup quote artifact, D = this demo artifact (Prompt B).
* `northwind_v1.zip` and `northwind_v2.zip` downloaded from the `broker_packages` Volume and ready to drag.
* Zoom 125%; notifications off. Do not run "Reset Demo"; it is not needed and was not re-tested today.

**Fallbacks by walkthrough step:**

| Step | If this happens | Do this |
| --- | --- | --- |
| A | "Can't find the Underwriting Genie agent" | Type `@` and select `[dev matthew_giglia] Underwriting Genie`, then resend; the prompt also falls back to the `hls_fde_dev.uw_genie` tables (that is how all 2026-11-16 tests got their numbers) |
| 1 | The routine could not be created from chat, or did not run | Run the brief on demand in Tab A with the step 1 prompt (tested) |
| 1 | The brief shows only 1 blocked submission (Northwind) | Ask (tested): `How many broker submissions are blocked in total, including any whose group isn't in the groups table? List them with broker, received date and top missing item.` Expect 8; oldest SUB-2026-0118, Summit Ridge Benefits Group, Oct 8; Intake Desk 1 owns 6 |
| 2 | Someone asks why a renewal needs more than 15% | Stay with facts on screen (loss history, large claimants, pre-built status); do not ask Genie "why" (R1-11) |
| 3 | The draft appears in chat instead of Gmail | Expected (Gmail connector is read-only). Say: "In production this lands in Gmail as a draft; it never sends." |
| 3 | Genie also flags current rates as missing | Correct: v1 has no current premium (R1-08) |
| 5 | Genie says it cannot write the exception to a table | Expected (read-only); it records the exception in the quote |
| 5 | No artifact after 3 minutes | Switch to Tab C (backup, same base numbers) |
| 5 | The quote is saved with a "v2" name | Fine; the backup quote already exists |
| 10 | Large numbers appear in scientific notation | Cosmetic; read the headline values |

**Why some wording differs from the tests:**

* Prompt A **tested 2026-11-16 ~4:15 AM ET** (with the `@` agent mention): Genie One created the routine (Active, Mon-Fri 07:00 America/New_York) and the first run matched every governed count, including **8 blocked submissions** (undercount fixed), oldest GRP-NB-118 (39 days), Northwind named. Quirk: it showed `GRP-LV-002` instead of "Lakeview Logistics" for the largest large-claimant group; if you want names, edit the routine's instructions to add "Show group names wherever a name exists; use the ID only when no name exists."
* Step 2 drops "and why" from the tested AC-1-4 prompt (interim guidance in R1-11). The list result is verified: benchmark ★7 = 3 as of 2026-11-16 (4 from Dec 1, R1-10).
* Step 4's prompt wording is equivalent to, not identical to, the 2026-11-16 test (the package was uploaded and re-checked in the same chat); the result is verified.
* Backup artifact: the purpose-built backup (L200-05) is not built yet; use the Northwind quote artifact from test chat `04e80baad93c48fc9dfcfe4f9ffda27a` (same base numbers, verified).
* The Morning Brief numbers depend on the run date (R1-10). They are verified for 2026-11-16 and 2026-11-17 (identical counts); re-check if the demo moves later.
* Source of every number: `docs/sessions/2026-11-16_genie-one-test-*.md`, `docs/requests/build-1/R1-06`, `R1-08`, `R1-09`, `R1-11`, and `docs/design/L300-03` §5.
