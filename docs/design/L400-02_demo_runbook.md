# L400-02 — Demo Runbook

Matthew Giglia | Field Engineering · v0.1 · 2026-11-15 · Synthetic, carrier-neutral Databricks point of view


## 1. T-24h
- Deploy bundle to target `demo`; run `setup_demo`; confirm tests green.
- Run S8 dry run #3; record timings.
- Run the scheduled Morning Brief manually ("Run now") so tab (a) is fresh.

## 2. T-30 min
Follow L200-07 §1 setup (tabs, files, skills, session instruction, zoom). Run `reset_demo` first if the workspace was used since the dry run. Delete leftover Gmail drafts to the broker contact.

## 3. Run of show (15 min demo inside a 30-min meeting)
| Min | Beat | Fallback |
|---|---|---|
| 0–2 | 1 Morning brief | Screenshot |
| 2–6 | 2 Ready to quote? | Show expected findings from L300-05 |
| 6–11 | 2b Interactive NB Quote | Backup artifact tab |
| 11–13 | 3 Renewal (optional) | Skip |
| 13–15 | 4 Decisions to dollars | Metric view chart screenshot |

## 4. Recovery scripts
- "Let me show you one I generated this morning" → backup artifact.
- If Genie drifts into calculation: "Use only the governed scenarios" (one line, then continue).

## 5. After the demo
Run `reset_demo`; save the live artifact link if the audience should receive it; log the run in `sessions/`.

## 6. Review-gate artifact prompt (before SVG/HTML rendering)
Paste into Genie One:
```
Create a Genie Artifact titled "Underwriting Cockpit Demo — Design Review" from the files in
brainstorming/genie-one-documents/genie-one-large-group-underwriting/docs: render the 7 Mermaid diagrams in
docs/diagrams/mermaid, summarize the L100 (sections 1–8, including the base-case number table), list the 12
assumed decisions from research/06 as review questions with Approve / Change options, and show the build wave plan.
Save it to the shared genie_artifacts folder.
```
After approval: render diagrams to `diagrams/svg` + `diagrams/html` and produce the Databricks-themed HTML for the L100 and the customer talk track.
