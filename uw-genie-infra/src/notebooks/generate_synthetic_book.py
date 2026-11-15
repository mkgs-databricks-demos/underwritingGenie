# Databricks notebook source
# DBTITLE 1,Install latest Databricks SDK
# MAGIC %pip install --upgrade databricks-sdk

# COMMAND ----------

# DBTITLE 1,Restart Python
dbutils.library.restartPython()

# COMMAND ----------

# MAGIC %md
# MAGIC # generate_synthetic_book
# MAGIC
# MAGIC Loads the synthetic Lakeside Health Plan book (seed 2027) into `${catalog}.${schema}`.
# MAGIC Runs as the `setup_demo` task after `create_tables` (00_ddl.sql), so every table already exists
# MAGIC with its comments and tags; this notebook only overwrites the rows.
# MAGIC
# MAGIC * Pinned values from L300-01 (Northwind, Lakeview, assumption set AV-2027.1, intake checklist,
# MAGIC   persistency curve, plan options) and Northwind census / claims / claimants from
# MAGIC   `docs/demo-assets/broker_packages` (v2 is the rating basis; v1 rows are kept with `census_version` /
# MAGIC   `package_version` = v1).
# MAGIC * 58 random in-force groups + Northwind + Lakeview = 60 groups.
# MAGIC * Assertions from L200-01 Testing at the end; any failure fails the task.
# MAGIC
# MAGIC Generation logic lives in `uw_seed.py` next to this notebook (pure pandas, shared with `reset_demo`).
# MAGIC All data is fictional.

# COMMAND ----------

# DBTITLE 1,Parameters
import os
import re
import sys

dbutils.widgets.text("catalog", "hls_fde_dev", "Catalog")
dbutils.widgets.text("schema", "uw_genie", "Schema")
dbutils.widgets.text("assets_dir", "", "docs/demo-assets path (blank = resolve from repo layout)")

catalog = dbutils.widgets.get("catalog").strip()
schema = dbutils.widgets.get("schema").strip()
assets_override = dbutils.widgets.get("assets_dir").strip()
for name, value in (("catalog", catalog), ("schema", schema)):
    if not re.fullmatch(r"[A-Za-z0-9_]+", value):
        raise ValueError(f"invalid {name}: {value!r}")
fq = f"`{catalog}`.`{schema}`"

notebook_path = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
notebook_dir = os.path.dirname(notebook_path if notebook_path.startswith("/Workspace") else "/Workspace" + notebook_path)
if notebook_dir not in sys.path:
    sys.path.insert(0, notebook_dir)
import uw_seed  # noqa: E402

assets_dir = uw_seed.resolve_assets_dir(notebook_dir, assets_override)
print(f"target {fq}; assets {assets_dir}")

# COMMAND ----------

# DBTITLE 1,Build the book (pandas)
book = uw_seed.build_book(assets_dir)
for table, pdf in book.items():
    print(f"{table:22s} {len(pdf):>7,d} rows")

# COMMAND ----------

# DBTITLE 1,Write every table (overwrite rows, keep DDL comments and tags)
import pandas as pd
from pyspark.sql import functions as F
from pyspark.sql.types import StringType, StructField, StructType


def _as_text(value):
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return None
    return str(value)


def write_table(table, pdf):
    """Overwrite the rows of an existing table. Values travel as strings and are cast to the
    table's own column types, so the 00_ddl.sql schema, comments and tags stay authoritative."""
    target = spark.table(f"{fq}.`{table}`").schema
    cols = [f.name for f in target.fields]
    if set(cols) != set(pdf.columns):
        raise ValueError(f"{table}: columns {sorted(pdf.columns)} do not match the table {sorted(cols)}")
    rows = [tuple(_as_text(v) for v in rec) for rec in pdf[cols].itertuples(index=False, name=None)]
    sdf = spark.createDataFrame(rows, StructType([StructField(c, StringType(), True) for c in cols]))
    sdf = sdf.select([F.col(f.name).cast(f.dataType).alias(f.name) for f in target.fields])
    sdf.write.insertInto(f"{fq}.`{table}`", overwrite=True)


for table, pdf in book.items():
    write_table(table, pdf)

# Written during the demo (intake skill); starts empty.
spark.sql(f"TRUNCATE TABLE {fq}.submission_findings")
print("all tables written")

# COMMAND ----------

# DBTITLE 1,Assertions (L200-01 Testing, L400-01 S2 acceptance)
def scalar(query):
    return spark.sql(query).collect()[0][0]


nw = uw_seed.NORTHWIND_ID
failures = []


def check(name, actual, expected):
    ok = actual == expected
    print(f"{'PASS' if ok else 'FAIL'}  {name}: {actual!r} (expected {expected!r})")
    if not ok:
        failures.append(name)


check("groups total", scalar(f"SELECT COUNT(*) FROM {fq}.groups"), 60)
check("groups distinct ids", scalar(f"SELECT COUNT(DISTINCT group_id) FROM {fq}.groups"), 60)
check("in-force groups", scalar(f"SELECT COUNT(*) FROM {fq}.groups WHERE status = 'IN_FORCE'"), 59)
check("Northwind member_months", scalar(f"SELECT member_months FROM {fq}.groups WHERE group_id = '{nw}'"), 23520)
check("Northwind EEs / members",
      tuple(spark.sql(f"SELECT enrolled_employees, members FROM {fq}.groups WHERE group_id = '{nw}'").collect()[0]), (420, 980))
check("Northwind incumbent PMPM", scalar(f"SELECT incumbent_premium_pmpm FROM {fq}.groups WHERE group_id = '{nw}'"), 612.0)

# The broker file has 24 x 436,666.67 = 10,480,000.08 (L300-01 pins both the monthly value and the
# $10.48M total); compare at whole dollars.
check("Northwind claims paid_to_date (whole $)",
      scalar(f"SELECT ROUND(SUM(paid_to_date), 0) FROM {fq}.claims_monthly WHERE group_id = '{nw}'"), 10480000.0)
check("Northwind claims rows", scalar(f"SELECT COUNT(*) FROM {fq}.claims_monthly WHERE group_id = '{nw}'"), 24)
check("Northwind claims basis",
      scalar(f"SELECT concat_ws(',', sort_array(collect_set(basis))) FROM {fq}.claims_monthly WHERE group_id = '{nw}'"), "INCURRED")

tiers = {r.tier: r.enrolled for r in spark.sql(f"SELECT tier, enrolled FROM {fq}.group_tier_counts WHERE group_id = '{nw}'").collect()}
check("Northwind v2 tier counts", tiers, {"EE": 168, "ES": 76, "EC": 59, "EF": 117})
check("Northwind v2 census members",
      scalar(f"SELECT COUNT(*) FROM {fq}.census_members WHERE group_id = '{nw}' AND census_version = 'v2'"), 980)
check("Northwind v1 employee rows missing DOB or tier",
      scalar(f"""SELECT COUNT(*) FROM {fq}.census_members WHERE group_id = '{nw}' AND census_version = 'v1'
                 AND relationship = 'EMPLOYEE' AND (birth_date IS NULL OR tier IS NULL)"""), 22)

lc_v2 = {r.claimant_id: (r.status, r.total_claims) for r in spark.sql(
    f"SELECT claimant_id, status, total_claims FROM {fq}.large_claimants WHERE group_id = '{nw}' AND package_version = 'v2'").collect()}
check("Northwind v2 large claimants", lc_v2, {"LC-01": ("RESOLVED", 612000.0), "LC-02": ("ACTIVE", 410000.0),
                                               "LC-03": ("ONGOING", 268000.0), "LC-04": ("RESOLVED", 185000.0)})
check("Northwind v1 claimants without status",
      scalar(f"SELECT COUNT(*) FROM {fq}.large_claimants WHERE group_id = '{nw}' AND package_version = 'v1' AND status = 'UNKNOWN'"), 3)

plans = {r.plan_option: (r.plan_name, r.relativity) for r in spark.sql(
    f"SELECT plan_option, plan_name, relativity FROM {fq}.plan_designs WHERE group_id = '{nw}'").collect()}
check("Northwind plan options", plans, {"requested": ("Choice PPO 1000", 1.0), "alternate": ("Choice PPO 2500", 0.94)})
check("Northwind manual factors", tuple(spark.sql(
    f"""SELECT base_manual_pmpm, area_factor, demographic_factor, industry_factor FROM {fq}.manual_rate_factors
        WHERE group_id = '{nw}' AND assumption_version = 'AV-2027.1'""").collect()[0]), (520.0, 1.04, 1.06, 1.03))
check("completion factors lag 2..7", [r.factor for r in spark.sql(
    f"SELECT factor FROM {fq}.completion_factors WHERE assumption_version = 'AV-2027.1' AND lag_months BETWEEN 2 AND 7 ORDER BY lag_months").collect()],
      [1.12, 1.06, 1.035, 1.02, 1.012, 1.006])
check("trend scenarios", {r.trend_scenario: (r.annual_rate, r.trend_years) for r in spark.sql(
    f"SELECT trend_scenario, annual_rate, trend_years FROM {fq}.trend_assumptions").collect()},
      {"low": (0.075, 2.0), "base": (0.09, 2.0), "high": (0.105, 2.0)})
check("pooling points", {r.pooling_point: (r.pooling_charge_pmpm, r.full_credibility_mm) for r in spark.sql(
    f"SELECT pooling_point, pooling_charge_pmpm, full_credibility_mm FROM {fq}.pooling_points").collect()},
      {150000: (38.0, 30000), 250000: (24.0, 42000), 500000: (11.0, 60000)})
check("retention / target LR", tuple(spark.sql(f"SELECT retention, target_loss_ratio FROM {fq}.retention_targets").collect()[0]), (0.12, 0.88))
check("tier factors", {r.tier: r.tier_factor for r in spark.sql(f"SELECT tier, tier_factor FROM {fq}.tier_factors").collect()},
      {"EE": 1.0, "ES": 2.0, "EC": 1.85, "EF": 2.85})
check("persistency bands", scalar(f"SELECT COUNT(*) FROM {fq}.persistency_curve"), 6)
check("intake checklist items (BLOCKING, WARNING)", tuple(spark.sql(
    f"""SELECT COUNT(*), SUM(CASE WHEN severity = 'BLOCKING' THEN 1 ELSE 0 END),
               SUM(CASE WHEN severity = 'WARNING' THEN 1 ELSE 0 END) FROM {fq}.intake_checklist""").collect()[0]), (14, 7, 7))

subs = {r.package_version: r.completeness_status for r in spark.sql(
    f"SELECT package_version, completeness_status FROM {fq}.broker_submissions WHERE group_id = '{nw}'").collect()}
check("Northwind submissions", subs, {"v1": "BLOCKED", "v2": "READY_WITH_WARNINGS"})
check("broker submissions", scalar(f"SELECT COUNT(*) FROM {fq}.broker_submissions"), 25)
check("Lakeview in renewal pipeline", scalar(
    f"SELECT COUNT(*) FROM {fq}.renewal_pipeline WHERE group_id = '{uw_seed.LAKEVIEW_ID}' AND renewal_date = DATE'2027-01-01'"), 1)
check("groups with new large claimant flag", scalar(f"SELECT COUNT(*) FROM {fq}.renewal_pipeline WHERE new_large_claimant_flag"), 6)
check("trend_monitor signal rows (|actual - assumed| >= 1pt)",
      scalar(f"SELECT COUNT(*) FROM {fq}.trend_monitor WHERE ABS(actual_annual_trend - assumed_annual_trend) >= 0.01"), 1)
check("broker emails outside .example", scalar(
    f"SELECT COUNT(*) FROM {fq}.groups WHERE broker_email IS NOT NULL AND broker_email NOT LIKE '%.example'"), 0)

# Every base object carries both governed tags (set by 00_ddl.sql).
expected_objects = sorted(list(book) + ["submission_findings", "group_tier_counts"])
tagged = {r.table_name for r in spark.sql(f"""
    SELECT table_name FROM `{catalog}`.information_schema.table_tags
    WHERE schema_name = '{schema}'
      AND ((tag_name = 'domain' AND tag_value = 'underwriting') OR (tag_name = 'data_class' AND tag_value = 'synthetic'))
    GROUP BY table_name HAVING COUNT(DISTINCT tag_name) = 2""").collect()}
check("objects missing domain/data_class tags", sorted(set(expected_objects) - tagged), [])

if failures:
    raise AssertionError(f"{len(failures)} assertion(s) failed: {failures}")
print(f"all {len(expected_objects)} objects loaded and checked")

# COMMAND ----------

# DBTITLE 1,Exit with row counts
import json

dbutils.notebook.exit(json.dumps({t: len(p) for t, p in book.items()}))
