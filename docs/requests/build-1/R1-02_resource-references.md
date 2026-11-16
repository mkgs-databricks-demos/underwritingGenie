# R1-02 `${resources...}` for every catalog/schema reference

**Status:** Open (`uw-genie-infra` already compliant; recheck after R1-01)
**Origin:** Owner request, 2026-11-16 (owner's standing convention: "Schema References in Bundle YAML")
**Related:** R1-01, R1-04

## Problem

Resource definitions must reference the schema through the bundle resource so deploy ordering is guaranteed and a rename (R1-01) flows everywhere. Raw `${var.catalog}` / `${var.schema}` belongs only in the schema resource itself.

## Current state (evidence, 2026-11-16)

* `uw-genie-infra/resources/schemas/uw_genie.schema.yml`: `catalog_name: ${var.catalog}`, `name: ${var.schema}` (correct: the one allowed place).
* `uw-genie-infra/resources/jobs/setup_demo.job.yml` and `reset_demo.job.yml`: job parameter defaults use `${resources.schemas.uw_genie.catalog_name}` / `${resources.schemas.uw_genie.name}` (compliant).
* `uw-genie-infra/resources/volumes/broker_packages.yml`: `catalog_name` / `schema_name` from `${resources.schemas.uw_genie.*}` (compliant).
* `uw-genie-agent`: no schema resource. `databricks.yml` defines `catalog` / `schema` variables (`hls_fde_dev` / `uw_genie` defaults and per-target values), and `underwriting_genie.genie_space.yml` holds literal `hls_fde_dev.uw_genie.*` identifiers.

## Requested change

1. Keep infra compliant through R1-01; any new resource (for example the R1-03 metric view job) uses `${resources.schemas.uw_genie.*}` and `${resources.sql_warehouses.uw_genie_warehouse.id}`.
2. Agent bundle: cross-bundle references cannot use `${resources...}`. Keep `catalog` / `schema` variables, set them per target to match infra (same rule as scAuditor: "agent `catalog`/`schema` vars MUST match infra values per target"), and remove the literal identifiers via R1-04.

## Files affected

* `uw-genie-infra/resources/**` (new resources only)
* `uw-genie-agent/databricks.yml`, `uw-genie-agent/resources/genie_spaces/underwriting_genie.genie_space.yml`

## Acceptance criteria

* In `uw-genie-infra/resources/`, `${var.catalog}` / `${var.schema}` appear only in `schemas/uw_genie.schema.yml`.
* In `uw-genie-agent/`, catalog and schema appear only as variables (no literal `hls_fde_dev` / `uw_genie` in resource files).
* `bundle validate --strict` passes for both bundles and both targets.
