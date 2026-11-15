# Databricks notebook source
# DBTITLE 1,Install latest Databricks SDK
# MAGIC %pip install --upgrade databricks-sdk

# COMMAND ----------

# DBTITLE 1,Restart Python
dbutils.library.restartPython()

# COMMAND ----------

# MAGIC %md
# MAGIC # upload_packages
# MAGIC
# MAGIC Copies the two Northwind broker packages from `docs/demo-assets/broker_packages/` to the UC volume
# MAGIC `${catalog}.${schema}.broker_packages` (L300-05), then checks them in the volume:
# MAGIC
# MAGIC * `northwind_v1` (incomplete) has exactly the 5 seeded blocking gaps: 15 of 24 months, paid basis with
# MAGIC   no lag report, 22 employee census rows missing DOB or tier, 3 claimants missing status, no benefit
# MAGIC   summary for the requested plan.
# MAGIC * `northwind_v2` (complete) has none.
# MAGIC * Every email address in the packages uses a `.example` domain.
# MAGIC
# MAGIC Re-runnable: files are overwritten. All content is fictional.

# COMMAND ----------

# DBTITLE 1,Parameters
import os
import re
import shutil
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

notebook_path = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
notebook_dir = os.path.dirname(notebook_path if notebook_path.startswith("/Workspace") else "/Workspace" + notebook_path)
if notebook_dir not in sys.path:
    sys.path.insert(0, notebook_dir)
import uw_seed  # noqa: E402

source_root = os.path.join(uw_seed.resolve_assets_dir(notebook_dir, assets_override), "broker_packages")
volume_root = f"/Volumes/{catalog}/{schema}/broker_packages"
if not os.path.isdir(volume_root):
    raise FileNotFoundError(f"volume {volume_root} not found (deployed by the uw-genie-infra bundle)")
PACKAGES = ["northwind_v1", "northwind_v2"]
print(f"{source_root} -> {volume_root}")

# COMMAND ----------

# DBTITLE 1,Copy both packages to the volume
uploaded = {}
for pkg in PACKAGES:
    src, dst = os.path.join(source_root, pkg), os.path.join(volume_root, pkg)
    os.makedirs(dst, exist_ok=True)
    files = sorted(f for f in os.listdir(src) if os.path.isfile(os.path.join(src, f)))
    for f in files:
        shutil.copyfile(os.path.join(src, f), os.path.join(dst, f))
    # Drop files that are no longer in the source package (keeps v1 gaps intact after edits).
    for f in set(os.listdir(dst)) - set(files):
        if os.path.isfile(os.path.join(dst, f)):
            os.remove(os.path.join(dst, f))
    uploaded[pkg] = files
    print(f"{pkg}: {len(files)} files -> {dst}")

# COMMAND ----------

# DBTITLE 1,Verify the packages in the volume
failures = []
v1_gaps = uw_seed.package_gaps(os.path.join(volume_root, "northwind_v1"))
v2_gaps = uw_seed.package_gaps(os.path.join(volume_root, "northwind_v2"))
print("northwind_v1 gaps:", *v1_gaps, sep="\n  ")
print("northwind_v2 gaps:", v2_gaps or "none")

expected_v1 = [
    "experience: 15 of 24 months",
    "experience: paid basis and no lag report",
    "census: 22 employee rows missing birth_date or tier",
    "large claimants: 3 missing status",
    "benefit summary: requested plan missing",
]
if v1_gaps != expected_v1:
    failures.append(f"northwind_v1 gaps {v1_gaps} != expected 5 seeded gaps {expected_v1}")
if v2_gaps:
    failures.append(f"northwind_v2 should have no blocking gaps, found {v2_gaps}")

for pkg in PACKAGES:
    for f in os.listdir(os.path.join(volume_root, pkg)):
        if os.path.getsize(os.path.join(volume_root, pkg, f)) != os.path.getsize(os.path.join(source_root, pkg, f)):
            failures.append(f"{pkg}/{f}: size differs from source")
        if f.endswith((".txt", ".md", ".csv")):
            with open(os.path.join(volume_root, pkg, f), encoding="utf-8") as fh:
                emails = re.findall(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+", fh.read())
            bad = [e for e in emails if not e.lower().endswith(".example")]
            if bad:
                failures.append(f"{pkg}/{f}: non-.example emails {bad}")

if failures:
    raise AssertionError("; ".join(failures))
print("both packages uploaded and verified")

# COMMAND ----------

# DBTITLE 1,Exit with uploaded files
import json

dbutils.notebook.exit(json.dumps({"volume": volume_root, "files": uploaded, "v1_gaps": v1_gaps}))
