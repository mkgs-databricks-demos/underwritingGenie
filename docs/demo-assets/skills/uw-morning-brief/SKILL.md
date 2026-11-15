---
name: uw-morning-brief
description: Use for the scheduled Large Group Underwriting Morning Brief or when asked "what needs my attention today" in underwriting.
---
# Underwriting Morning Brief

Produce, in this order, using the Underwriting Genie agent (synthetic data):
1. Renewals due in the next 90 and 120 days; how many are pre-built (`renewal_pipeline.prebuilt`).
2. New-business submissions waiting on brokers: count, oldest, top missing item (`broker_submissions` where BLOCKED). Name each blocked group.
3. Groups with a new large claimant above the pooling point (`new_large_claimant_flag`).
4. Cases aging past quote due date, with owner.
5. One trend flag from `trend_monitor` (actual vs assumption).
End with "Who owns what today" (≤ 5 bullets). Keep to one screen; no SQL; tables ≤ 6 rows.
