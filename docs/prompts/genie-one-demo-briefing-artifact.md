# Genie One prompt: Underwriting Genie demo briefing artifact

**Purpose:** paste the prompt below into a **new Genie One chat** to build a presenter-facing Genie Artifact that (1) explains the vision for underwriting, (2) previews what the audience will see and hear, (3) shows which Databricks products are used and how, with diagrams, and (4) gives the exact, copy-and-paste presenter script for the beats tested on 2026-11-16.

**Written:** 2026-11-16, before build 1. Every number and prompt in the script was verified in Genie One today (see `docs/sessions/2026-11-16_genie-one-test-*.md`). Beats not yet tested are listed as "not in today's script".

**How to use:**

1. Open a new Genie One chat (not the live demo chat). The briefing artifact does not need any skill; the Underwriting Genie agent is optional (only for the optional number check at the end of the prompt).
2. Copy everything between the two `=====` lines into the chat and send it.
3. Keep the artifact open in its own tab during the demo; page 4 is the presenter script.

=====

Build me an interactive Genie Artifact titled **"Underwriting Genie: Demo Briefing"** for a presenter. It is for me only (not for the audience). Use only the facts in this message; do not invent products, numbers or capabilities. All data is synthetic for a fictional carrier, "Lakeside Health Plan"; no real carrier, customer, broker or employee names. Show a small "SYNTHETIC DEMO DATA" badge in the header.

**Design:** a clean, modern page with a navy header (#1B3139) and a red-orange accent (#FF3621), DM Sans font, plenty of white space. Use a tab or page selector with these 5 pages, in this order. Draw diagrams as inline SVG or HTML (boxes and arrows), not images. Make every prompt on page 4 a copy-able block with a "Copy" button.

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

**Page 4: Presenter script (copy-and-paste prompts)**

At the top, a "Before you start (30 minutes before)" checklist:

* Keep the Northwind quote artifact from the earlier test chat as the **backup** and open it in its own tab (Tab C). Because it exists, the live quote may be saved with a "v2" name; that is fine.
* In Genie One, turn on the four skills: `lg-intake-checklist`, `experience-rating-explainer`, `nb-quote-artifact`, `uw-morning-brief`. Turn off unrelated skills.
* Have `northwind_v1.zip` and `northwind_v2.zip` ready to drag in (downloaded from the `broker_packages` Volume).
* Open the tabs: Tab A a new chat for the Morning Brief, Tab B a new empty chat titled "Underwriting Genie: live", Tab C the backup quote artifact.
* Zoom 125%; notifications off.

Then show each step as a card with: step number, tab, the exact prompt (copy-able), "What you should see" and "If it goes wrong". Use exactly these steps and prompts:

**Step 1 (Tab A): Morning Brief**

Prompt: `Use uw-morning-brief to help me get started.`

What you should see: 25 renewals in the next 90 days (12 pre-built) and 31 in 120 days (16 pre-built); 6 groups with a new large claimant (Lakeview Logistics is the largest, $21.0M premium); 13 quotes past due (all due Nov 2 for 1/1/2027 renewals); Rx trend 13.4% vs 11.0% assumed (+2.4 points); "Who owns what today".

If it goes wrong: the brief may show only 1 blocked submission (Northwind). The governed answer is 8. Use Step 2.

**Step 2 (Tab A): Blocked submissions**

Prompt: `How many broker submissions are blocked in total, including any whose group isn't in the groups table? List them with broker, received date and top missing item.`

What you should see: 8 blocked; the oldest is SUB-2026-0118 from Summit Ridge Benefits Group (Oct 8); the most common missing item is "24 months of claims experience" (3); Intake Desk 1 owns 6. Talk track: "Genie checks its own work when you ask."

**Step 3 (Tab A, optional): Renewals above 15%**

Prompt: `Which renewals in the next 90 days have a rate action above 15%?`

What you should see: 3 groups: Yarrow Software +16.3%, Cedar Ridge Contractors +16.2%, Birchwood Wholesale +15.4%.

If it goes wrong: do not ask "why" for these renewals today (the renewal explanation is being reworked). If asked, stick to facts on screen: loss history, large claimants, pre-built status.

**Step 4 (Tab B): Ready to quote?**

Action: drag in `northwind_v1.zip`.

Prompt: `A broker just sent this new business request for Northwind Manufacturing. Is it ready to quote? If not, tell me exactly what's missing and draft a reply to the broker.`

What you should see: BLOCKED with evidence from each file: only 15 of 24 months of claims; paid basis with no lag report; 22 of 420 employees missing a birth date or tier; 3 large claimants without status; the requested plan's benefit summary missing (only the PPO 2500 summary). It may also flag current rates as missing. No rate quoted. A polite reply to Jordan Ellis at Harbor Benefits Partners.

If it goes wrong: the Gmail connector may be read-only, so the draft appears in chat. Say: "In production this lands in Gmail as a draft; it never sends."

**Step 5 (Tab B): The resubmission**

Action: drag in `northwind_v2.zip`.

Prompt: `The broker sent the missing items. Re-check this package against the intake checklist before we rate it.`

What you should see: every gap fixed except IC-01: 24 incurred months that end June 2026, about 5 months before the submission (the rule allows 3). Two warnings remain: no incumbent renewal exhibit (IC-08) and no statement of prior plan changes (IC-10). Genie offers two paths: ask the broker again, or an underwriting exception.

Talk track: "Genie follows the rule exactly. Claims are paid through August and a lag report is attached, so this is a judgment call for the underwriter."

**Step 6 (Tab B): Approve the exception and build the quote**

Prompt: `Underwriting approves an exception for IC-01: claims are paid through Aug 2026 and a lag report is attached. Record the exception, then rate Northwind Manufacturing for a 1/1/2027 effective date and build me an interactive New Business Quote I can review and share with the account executive.`

What you should see: status READY_WITH_WARNINGS; an artifact with 8 sections and the SYNTHETIC badge; readiness rows citing real file names, with IC-01 amber "Exception approved"; $625.32 PMPM, $1,459.07, +2.2%, credibility 0.7483, tier rates $803.58 / $1,607.16 / $1,486.63 / $2,290.21; a 10-step "How we got here" (AV-2027.1).

If it goes wrong: Genie One cannot write the exception to a table (read-only); it records it in the artifact instead. That is expected. If the artifact takes more than 3 minutes, switch to the backup artifact (Tab C); it has the same base numbers.

**Step 7 (artifact): Levers**

Action: click pooling point $150K, then $500K, then plan "Alternate", then reset to recommended.

What you should see: $150K = $613.84 PMPM, credibility 0.8854, $875,000 pooled; $500K = $639.06, credibility 0.6261, $112,000 pooled; Alternate (Choice PPO 2500) at $250K = $589.02, -3.8% vs current.

Talk track: "A lower pooling point moves more risk to the pool and gives Northwind's own experience more weight."

**Step 8 (Tab B): Why is the quote above current?**

Prompt: `Why is our quote 2.2% above the incumbent's current premium? Walk me through what drives it.`

What you should see: completed claims $10,590,476.75; $540,000 pooled above $250K plus a $24.00 PMPM pooling charge; experience $427.32 PMPM; trend 9.0% for 2 years (factor 1.1881); projected $536.77; manual rate $590.45; credibility 0.7483; blended $550.28; 12% retention; $625.32.

**Step 9 (Tab B): Broker proposal and PDF**

Prompt: `Add a one-page broker proposal view to the artifact using the $250K pooling point and base trend, then I'll export it to PDF.`

What you should see: requested and alternate rates side by side, "Rates subject to final underwriting", the SYNTHETIC badge, no internal detail. Export the PDF from the artifact.

**Step 10 (Tab B): Guardrail**

Prompt: `Lower the Family rate to $2,200 so we beat the incumbent's renewal by more.`

What you should see: a polite refusal; it explains the Family tier factor; it offers governed options that land at or below $2,200 (for example $2,157.28 on the alternate plan).

**Step 11 (Tab B, optional): Live governed call**

Prompt: `Re-run the governed rating function live for Northwind at $250K / base / requested and confirm it matches the quote.`

What you should see: a live `rate_new_business()` call; all fields match the quote (difference 0.00).

**Step 12 (Tab B, optional): New plan design**

Prompt: `The client wants a $1,500 deductible version of the plan. What would that cost?`

What you should see: no price for the new design ("not a governed plan"); it offers Choice PPO 1000 ($625.32) and Choice PPO 2500 ($589.02) and says an approved plan relativity is needed.

Close: "Intake in minutes, governed math explained in plain English, and the underwriter decides."

---

**Page 5: Not in today's script, and backup**

List these as "not yet tested, do not show today": the scheduled 7:00 AM Morning Brief task; the Lakeview Logistics renewal beat; the "decisions to dollars" CFO beat on the renewal metric view; asking "why" for renewal rate actions.

List known quirks and the line to say: Morning Brief may undercount blocked submissions (use Step 2); the Gmail draft may appear in chat; the IC-01 exception is recorded in the artifact, not a table; the live quote may be saved with a "v2" name because the backup exists; Genie may show large numbers in scientific notation in comparison tables.

Backup plan: if a step fails or the artifact takes more than 3 minutes, switch to the backup artifact (Tab C) and continue narrating from page 2.

---

Optional check: if the Underwriting Genie agent is available in this chat, confirm the Northwind base-scenario numbers on page 2 against `nb_quote_scenarios` (group `GRP-NW-001`, pooling point 250000, trend `base`, plan `requested`) and tell me if any differ. Do not change the script numbers yourself.

=====

## Notes for the presenter

* Backup artifact: the purpose-built backup (L200-05) is not built yet; use the Northwind quote artifact created in test chat `04e80baad93c48fc9dfcfe4f9ffda27a` (same base numbers, verified). Do not run "Reset Demo" right before the demo; it is not needed and has not been re-tested today.
* Step 5's prompt wording is equivalent to, not identical to, the wording used in the 2026-11-16 test (the package was uploaded and re-checked in the same chat); the result is verified.
* Step 3's prompt drops "and why" from the tested AC-1-4 prompt, following the interim guidance in R1-11. The list result is verified (benchmark ★7 = 3 as of 2026-11-16; it becomes 4 on Dec 1, see R1-10).
* The "Morning Brief" numbers depend on the run date (R1-10). They are verified for 2026-11-16 and 2026-11-17 (identical counts on both dates); re-check if the demo moves to a later date.
* Source of every number: `docs/sessions/2026-11-16_genie-one-test-*.md`, `docs/requests/build-1/R1-06`, `R1-08`, `R1-09`, `R1-11`, and `docs/design/L300-03` §5.
