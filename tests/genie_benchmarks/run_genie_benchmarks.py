# Databricks notebook source
# MAGIC %md
# MAGIC # Underwriting Genie: agent benchmark runner
# MAGIC
# MAGIC Asks the deployed Genie Agent the 15 benchmark questions from `docs/design/L300-03_metric_views_and_genie_agent_config.md` §5,
# MAGIC one new conversation per question (the same isolation as Genie benchmarks), and checks each answer against the expected values.
# MAGIC
# MAGIC * **Parameters (required, no defaults):** `space_id` (the deployed Genie space ID). Optional: `only` (comma-separated benchmark IDs, e.g. `1,8`).
# MAGIC * **Checks:** `values` must all appear in the answer text or result rows (commas ignored); `names` are a presentation check (group names instead of IDs) reported separately.
# MAGIC * **Expected values** are for the synthetic book as of 2026-11-16 (setup_demo run that day). Benchmark 7 is date-dependent until build 1 request R1-10 pins an as-of date; benchmarks 7-8 change after R1-11.
# MAGIC * Exits with an error if any `values` check fails.

# COMMAND ----------

# DBTITLE 1,Install latest Databricks SDK
# MAGIC %pip install --upgrade databricks-sdk

# COMMAND ----------

dbutils.library.restartPython()

# COMMAND ----------

import json
import time

from databricks.sdk import WorkspaceClient

# id, question, values (must match), names (presentation check)
BENCHMARKS = [
    ("1", "What is the Family tier rate for Northwind Manufacturing at the $250K pooling point, base trend, requested plan?", ["2,290.21"], []),
    ("2", "What is Northwind Manufacturing's credibility at the $150K, $250K and $500K pooling points (base trend, requested plan)?", ["0.885", "0.748", "0.626"], []),
    ("3", "What is Northwind Manufacturing's premium change vs its current premium in the base case?", ["2.2"], []),
    ("4", "What is Northwind Manufacturing's premium PMPM on the alternate plan in the base case?", ["589.02"], []),
    ("5", "How much was removed by pooling at the $250K pooling point for Northwind Manufacturing?", ["540"], []),
    ("6", "Is Northwind Manufacturing's v1 submission ready to quote?", ["blocked"], []),
    ("7", "Which renewals in the next 90 days have a rate action above 15%?", ["16.2", "16.3", "15.4"], ["Yarrow Software", "Cedar Ridge Contractors", "Birchwood Wholesale"]),
    ("8", "For Q1 2027 renewals, how much premium is at risk with rate actions capped at 12% versus uncapped?", ["25.30", "23.03"], []),
    ("9", "What is the IBNR for Northwind Manufacturing?", ["110,47"], []),
    ("10", "How many member months does Northwind Manufacturing have?", ["23,520"], []),
    ("11", "What is Northwind Manufacturing's manual rate in the base case?", ["590.45"], []),
    ("12", "What is Northwind Manufacturing's composite PEPM in the base case?", ["1,459.07"], []),
    ("13", "Which brokers have the most blocked submissions?", ["Harbor Benefits Partners"], []),
    ("14", "What is the target loss ratio?", ["88"], []),
    ("15", "Which scenario gives the highest premium for Northwind Manufacturing?", ["656.55"], []),
]


def _norm(s: str) -> str:
    return s.replace(",", "").lower()


def ask(w: WorkspaceClient, space_id: str, question: str) -> dict:
    """Ask one question in a new Genie conversation; return text, SQL, rows and timing."""
    t0 = time.time()
    m = w.genie.start_conversation_and_wait(space_id, question)
    out = {"status": str(m.status).split(".")[-1], "secs": round(time.time() - t0, 1),
           "text": [], "sql": None, "rows": None}
    for a in m.attachments or []:
        if a.text:
            out["text"].append(a.text.content)
        if a.query:
            out["sql"] = a.query.query
            r = w.genie.get_message_attachment_query_result(space_id, m.conversation_id, m.message_id, a.attachment_id)
            res = r.statement_response.result
            out["rows"] = (res.data_array or [])[:10] if res else None
    return out


def _round_values(blob: str) -> str:
    """Add 2-decimal millions for large numbers in result rows, so $25.30M style answers also match."""
    extra = []
    for tok in blob.replace('"', " ").replace("[", " ").replace("]", " ").split():
        try:
            v = float(tok.strip(","))
        except ValueError:
            continue
        if abs(v) >= 1e6:
            extra.append(f"{v / 1e6:.2f}")
        if 0 < abs(v) < 1:
            extra.append(f"{v * 100:.1f}")
    return blob + " " + " ".join(extra)


def run_benchmarks(w: WorkspaceClient, space_id: str, only=None) -> list:
    if not space_id:
        raise ValueError("space_id is required (the deployed Genie space ID)")
    rows = []
    for bid, q, values, names in BENCHMARKS:
        if only and bid not in only:
            continue
        try:
            r = ask(w, space_id, q)
        except Exception as e:  # keep going; record the error
            r = {"status": f"ERROR {e}"[:200], "secs": None, "text": [], "sql": None, "rows": None}
        blob = _norm(_round_values(" ".join(r["text"]) + " " + json.dumps(r["rows"], default=str)))
        v_hit = [v for v in values if _norm(v) in blob]
        n_hit = [n for n in names if _norm(n) in blob]
        rows.append({
            "benchmark": bid,
            "question": q,
            "status": r["status"],
            "secs": r["secs"],
            "values_ok": len(v_hit) == len(values),
            "values": f"{len(v_hit)}/{len(values)}",
            "names": f"{len(n_hit)}/{len(names)}" if names else "",
            "names_ok": len(n_hit) == len(names),
            "sql": (r["sql"] or "").strip(),
            "answer": " | ".join(r["text"])[:1000],
        })
    return rows

# COMMAND ----------

dbutils.widgets.text("space_id", "", "Genie space ID (required)")
dbutils.widgets.text("only", "", "Benchmark IDs, comma-separated (optional)")

space_id = dbutils.widgets.get("space_id").strip()
only = {s.strip() for s in dbutils.widgets.get("only").split(",") if s.strip()} or None
if not space_id:
    raise ValueError("Set the space_id widget to the deployed Genie space ID")

# WorkspaceClient() default auth fails on serverless; use this notebook's own host and token.
_ctx = dbutils.notebook.entry_point.getDbutils().notebook().getContext()
w = WorkspaceClient(host="https://" + spark.conf.get("spark.databricks.workspaceUrl"), token=_ctx.apiToken().get())

results = run_benchmarks(w, space_id, only)
display(spark.createDataFrame(results))

failed = [r["benchmark"] for r in results if not r["values_ok"]]
names_missing = [r["benchmark"] for r in results if not r["names_ok"]]
print(f"values: {len(results) - len(failed)}/{len(results)} pass; names missing on: {names_missing or 'none'}")
if failed:
    raise AssertionError(f"Benchmarks failed on values: {failed}")
