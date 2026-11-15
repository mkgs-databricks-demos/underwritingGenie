"""uw_seed: deterministic synthetic book for the Underwriting Genie demo (seed 2027).

Pure pandas / numpy (no Spark), so the generation logic can be unit-checked anywhere.
Used by the notebooks generate_synthetic_book (all tables) and reset_demo
(broker_submissions seed only).

Pinned values come from docs/design/L300-01 and must match exactly; Northwind
census, claims and claimants are read from docs/demo-assets/broker_packages.
Everything is fictional (Lakeside Health Plan); emails use .example domains.
Dates are ISO strings; the notebooks cast them to the table types.
"""

import os

import numpy as np
import pandas as pd

SEED = 2027
ASSUMPTION_VERSION = "AV-2027.1"
EXPERIENCE_MONTHS = [d.strftime("%Y-%m-%d") for d in pd.date_range("2024-07-01", "2026-06-01", freq="MS")]
PAID_THROUGH = "2026-08-01"
# One row per group x incurred month holds total (medical + Rx) paid to date; see the
# session 05 summary (L300-01 pins 24 Northwind rows at 436,666.67 each).
SERVICE_CATEGORY_ALL = "ALL"

NORTHWIND_ID = "GRP-NW-001"
LAKEVIEW_ID = "GRP-LV-002"

# ---------------------------------------------------------------- pinned rows (L300-01)
NORTHWIND = {
    "group_id": NORTHWIND_ID, "group_name": "Northwind Manufacturing", "status": "PROSPECT",
    "industry": "Manufacturing", "sic_code": "3599", "state": "OH", "zip3": "443",
    "enrolled_employees": 420, "members": 980, "member_months": 23520,
    "demographic_change": 1.010, "incumbent_premium_pmpm": 612.00, "incumbent_renewal_offer_pct": 0.142,
    "effective_date": "2027-01-01", "broker_name": "Harbor Benefits Partners",
    "broker_contact": "Jordan Ellis", "broker_email": "jordan.ellis@harborbenefits.example",
}

# Lakeview Logistics: in force, 3,200 lives, renewal 2027-01-01, two large claimants (one resolved).
# Not pinned beyond that in L300-01; fixed here so the renewal beat is stable.
LAKEVIEW = {
    "group_id": LAKEVIEW_ID, "group_name": "Lakeview Logistics", "status": "IN_FORCE",
    "industry": "Transportation and Warehousing", "sic_code": "4225", "state": "IN", "zip3": "462",
    "enrolled_employees": 1390, "members": 3200, "member_months": 76800,
    "demographic_change": 1.004, "incumbent_premium_pmpm": 548.00, "incumbent_renewal_offer_pct": None,
    "effective_date": "2026-01-01", "broker_name": "Summit Ridge Benefits Group",
    "broker_contact": "Morgan Reyes", "broker_email": "morgan.reyes@summitridgebenefits.example",
}
# Completed claims PMPM incl. Rx, before pooling. Chosen so rate_renewal at $250K / base
# lands near LAKEVIEW_RENEWAL.recommended_rate_action (checked in the session 05 summary).
LAKEVIEW_CLAIMS_PMPM = 426.00
LAKEVIEW_CLAIMANTS = [
    ("LC-01", "Cardiac surgery", "RESOLVED", 545000.0),
    ("LC-02", "Oncology", "ACTIVE", 390000.0),
]
LAKEVIEW_RENEWAL = {"renewal_date": "2027-01-01", "recommended_rate_action": 0.094,
                    "new_large_claimant_flag": True, "prebuilt": False, "owner": "Underwriter A"}

COMPLETION_FACTORS = {2: 1.120, 3: 1.060, 4: 1.035, 5: 1.020, 6: 1.012, 7: 1.006}  # others 1.000
TREND = [("low", 0.075), ("base", 0.090), ("high", 0.105)]
TREND_YEARS = 2.0
POOLING = [(150000, 38.00, 30000), (250000, 24.00, 42000), (500000, 11.00, 60000)]
NORTHWIND_MANUAL = (520.00, 1.04, 1.06, 1.03)
LAKEVIEW_MANUAL = (505.00, 1.00, 0.99, 1.05)
RETENTION, TARGET_LOSS_RATIO = 0.12, 0.88
TIER_FACTORS = [("EE", 1.00), ("ES", 2.00), ("EC", 1.85), ("EF", 2.85)]
PERSISTENCY = [  # band label, min (inclusive), max (exclusive), persistency
    ("<0%", -1.00, 0.00, 0.97), ("0-5%", 0.00, 0.05, 0.94), ("5-10%", 0.05, 0.10, 0.90),
    ("10-15%", 0.10, 0.15, 0.82), ("15-20%", 0.15, 0.20, 0.70), (">20%", 0.20, 10.00, 0.55),
]

NORTHWIND_PLANS = [  # plan_option, plan_name, deductible, oop max, coinsurance, relativity
    ("requested", "Choice PPO 1000", 1000, 4000, 0.20, 1.00),
    ("alternate", "Choice PPO 2500", 2500, 6000, 0.20, 0.94),
]
# In-force groups get a 'current' plan so rate_renewal (plan_option='current', L300-02 s5) works.
CURRENT_PLANS = [("Choice PPO 500", 500, 3000, 0.20), ("Choice PPO 1000", 1000, 4000, 0.20),
                 ("Choice PPO 1500", 1500, 5000, 0.20), ("Choice PPO 2500", 2500, 6000, 0.20)]

INTAKE_CHECKLIST = [  # item_id, item_name, severity, rule_text, broker_ask_template
    ("IC-01", "24 months of claims experience", "BLOCKING",
     "Claims experience covers 24 consecutive incurred months ending no more than 3 months before the submission.",
     "Please send 24 months of medical and Rx claims experience by incurred month ({detail})."),
    ("IC-02", "Incurred basis or lag report", "BLOCKING",
     "Experience is reported on an incurred basis with a paid-through date, or a lag report is attached.",
     "Please provide the experience on an incurred basis with the paid-through date, or attach a lag report ({detail})."),
    ("IC-03", "Complete census", "BLOCKING",
     "Every employee row has birth date, gender, coverage tier and ZIP; dependents are listed.",
     "Please complete the census: {detail} employee rows are missing birth date or coverage tier."),
    ("IC-04", "Large claimant report with status", "BLOCKING",
     "Every claimant over the reporting threshold has a status of ACTIVE, ONGOING or RESOLVED.",
     "Please add the current status (active, ongoing or resolved) for {detail} large claimants."),
    ("IC-05", "Benefit summary for requested plan(s)", "BLOCKING",
     "A benefit summary is attached for every plan the group asks us to quote.",
     "Please send the benefit summary for the requested plan ({detail})."),
    ("IC-06", "Requested effective date", "BLOCKING",
     "The submission states the requested effective date.",
     "Please confirm the requested effective date."),
    ("IC-07", "Current rates", "BLOCKING",
     "Current premium rates (composite or tiered) with the incumbent are provided.",
     "Please share the group's current rates with the incumbent."),
    ("IC-08", "Renewal offer from incumbent", "WARNING",
     "The incumbent's renewal offer is reported or attached.",
     "If available, please attach the incumbent's renewal exhibit."),
    ("IC-09", "Contribution strategy", "WARNING",
     "Employer contribution levels for employee and dependent coverage are stated.",
     "Please confirm the employer contribution strategy."),
    ("IC-10", "Prior plan changes", "WARNING",
     "Benefit changes during the experience period are listed (or none stated).",
     "Please list any plan design changes during the experience period."),
    ("IC-11", "COBRA and retiree counts", "WARNING",
     "COBRA participant and retiree counts are provided.",
     "Please confirm COBRA participant and retiree counts."),
    ("IC-12", "RFP questionnaire", "WARNING",
     "The RFP questionnaire is attached and complete.",
     "Please attach the completed RFP questionnaire."),
    ("IC-13", "Network preference", "WARNING",
     "The group's network preference is stated.",
     "Please confirm the network preference."),
    ("IC-14", "Rx carve-out status", "WARNING",
     "The submission states whether pharmacy benefits are carved out.",
     "Please confirm whether pharmacy is carved out."),
]

TREND_MONITOR = [  # metric, period, actual, assumed
    ("Medical PMPM trend", "Rolling 12 months ending 2026-09", 0.081, 0.083),
    ("Rx PMPM trend", "Rolling 12 months ending 2026-09", 0.134, 0.110),  # the one signal row
    ("Total PMPM trend", "Rolling 12 months ending 2026-09", 0.092, 0.090),
]

# ---------------------------------------------------------------- random book vocab
INDUSTRIES = [  # industry, SIC, industry_factor, name suffixes
    ("Manufacturing", "3444", 1.03, ["Fabrication", "Machining", "Components"]),
    ("Transportation and Warehousing", "4213", 1.04, ["Freight", "Logistics", "Distribution"]),
    ("Retail Trade", "5411", 0.98, ["Markets", "Outfitters", "Home Goods"]),
    ("Health Care Services", "8011", 1.01, ["Clinics", "Care Partners", "Therapy Group"]),
    ("Professional Services", "8711", 0.95, ["Engineering", "Consulting", "Design Studio"]),
    ("Construction", "1731", 1.06, ["Builders", "Electric", "Contractors"]),
    ("Educational Services", "8211", 0.97, ["Academy", "Learning Center"]),
    ("Accommodation and Food Services", "7011", 1.00, ["Hospitality", "Hotels", "Kitchens"]),
    ("Information Technology", "7372", 0.93, ["Software", "Data Systems"]),
    ("Finance and Insurance", "6061", 0.94, ["Credit Union", "Financial"]),
    ("Wholesale Trade", "5084", 1.00, ["Supply", "Wholesale"]),
]
NAME_PREFIXES = [
    "Alder", "Bluewater", "Cedar Ridge", "Driftwood", "Elm Hollow", "Foxglove", "Granite Peak",
    "Harborview", "Ironwood", "Juniper", "Kestrel", "Larkspur", "Maplecrest", "North Fork",
    "Oakmont", "Pinecrest", "Quarry Hill", "Riverbend", "Silverline", "Timberline", "Upland",
    "Valleybrook", "Westfield", "Yarrow", "Zephyr", "Amberfield", "Birchwood", "Coldwater",
    "Dunmore", "Eastgate",
]
LOCATIONS = [("OH", "430"), ("OH", "441"), ("IN", "462"), ("MI", "481"), ("IL", "606"),
             ("WI", "532"), ("KY", "402"), ("PA", "152")]
BROKERS = [  # firm, contact, email
    ("Harbor Benefits Partners", "Jordan Ellis", "jordan.ellis@harborbenefits.example"),
    ("Summit Ridge Benefits Group", "Morgan Reyes", "morgan.reyes@summitridgebenefits.example"),
    ("Lakeshore Risk Advisors", "Taylor Brooks", "taylor.brooks@lakeshorerisk.example"),
    ("Prairie Point Insurance Services", "Avery Quinn", "avery.quinn@prairiepoint.example"),
    ("Bridgeway Employee Benefits", "Casey Moreau", "casey.moreau@bridgewaybenefits.example"),
    ("Copperline Benefit Consultants", "Riley Okafor", "riley.okafor@copperline.example"),
]
UNDERWRITERS = ["Underwriter A", "Underwriter B", "Underwriter C", "Underwriter D"]
INTAKE_OWNERS = ["Intake Desk 1", "Intake Desk 2", "Intake Desk 3"]
CONDITIONS = ["Oncology", "Cardiac surgery", "Neonatal intensive care", "Transplant",
              "Hemophilia (specialty Rx)", "Orthopedic surgery", "Dialysis", "Trauma", "Multiple sclerosis (specialty Rx)"]

N_RANDOM_GROUPS = 58
N_RANDOM_NEW_LARGE_CLAIMANT = 5  # + Lakeview = 6 groups with new_large_claimant_flag


# ---------------------------------------------------------------- helpers
def resolve_assets_dir(notebook_dir, override=""):
    """Return the docs/demo-assets folder: the override, else the first candidate that exists.

    Candidates, relative to the notebook folder:
    * ../../../docs/demo-assets: the repo layout (<repo>/uw-genie-infra/src/notebooks), which is also
      the synced layout when databricks.yml adds ../docs/demo-assets to sync.paths (the sync root
      then becomes the repo root);
    * ../../docs/demo-assets: a copy synced inside the bundle root.
    """
    candidates = [override.strip()] if override.strip() else [
        os.path.normpath(os.path.join(notebook_dir, *rel, "docs", "demo-assets"))
        for rel in (("..", "..", ".."), ("..", ".."))
    ]
    for path in candidates:
        if os.path.isdir(os.path.join(path, "broker_packages")):
            return path
    raise FileNotFoundError(
        f"demo assets not found in {candidates}. The uw-genie-infra bundle must sync ../docs/demo-assets "
        "(databricks.yml sync.paths), or pass the assets_dir widget.")


def _lag(incurred):
    y, m = int(incurred[:4]), int(incurred[5:7])
    return (int(PAID_THROUGH[:4]) - y) * 12 + int(PAID_THROUGH[5:7]) - m


def completion_factor(lag):
    return COMPLETION_FACTORS.get(lag, 1.0)


def _census(rng, group_id, zip3, n_emp, n_members=None):
    """Employee + dependent rows (census_version v2). Hits n_members exactly when given."""
    tiers = rng.choice(["EE", "ES", "EC", "EF"], size=n_emp, p=[0.40, 0.18, 0.14, 0.28])
    spouses = np.isin(tiers, ["ES", "EF"]).astype(int)
    kids = np.where(np.isin(tiers, ["EC", "EF"]), 1, 0)
    with_kids = np.flatnonzero(kids)
    if n_members is None:
        extra = rng.poisson(0.6, size=len(with_kids))
        kids[with_kids] += extra
    else:
        extra = n_members - n_emp - spouses.sum() - kids.sum()
        if extra < 0 or len(with_kids) == 0:
            raise ValueError(f"cannot hit {n_members} members for {group_id}")
        kids[with_kids] += rng.multinomial(extra, np.full(len(with_kids), 1 / len(with_kids)))
    rows = []
    prefix = group_id.replace("GRP-", "").replace("-", "")
    emp_age = rng.integers(22, 64, size=n_emp)
    for i in range(n_emp):
        eid = f"{prefix}-{i + 1:05d}"
        g = rng.choice(["F", "M"])
        by = 2026 - int(emp_age[i])
        rows.append((group_id, eid, "EMPLOYEE", tiers[i], g, f"{by}-{rng.integers(1, 13):02d}-{rng.integers(1, 29):02d}", zip3, "v2"))
        if spouses[i]:
            sy = min(2004, max(1958, by + int(rng.integers(-4, 5))))
            rows.append((group_id, f"{eid}-S", "SPOUSE", None, "M" if g == "F" else "F",
                         f"{sy}-{rng.integers(1, 13):02d}-{rng.integers(1, 29):02d}", zip3, "v2"))
        for k in range(int(kids[i])):
            cy = int(rng.integers(max(by + 20, 2001), 2027))
            rows.append((group_id, f"{eid}-C{k + 1}", "CHILD", None, rng.choice(["F", "M"]),
                         f"{cy}-{rng.integers(1, 13):02d}-{rng.integers(1, 29):02d}", zip3, "v2"))
    return rows


def _claims(rng, group_id, members, pmpm):
    """24 incurred months; paid_to_date = completed / completion factor (so completion restores it)."""
    rows = []
    for k, inc in enumerate(EXPERIENCE_MONTHS):
        season = 1 + 0.04 * np.sin(2 * np.pi * (int(inc[5:7]) - 3) / 12)
        completed = members * pmpm * season * rng.normal(1.0, 0.05)
        rows.append((group_id, inc, PAID_THROUGH, SERVICE_CATEGORY_ALL,
                     round(completed / completion_factor(_lag(inc)), 2), "INCURRED"))
    return rows


def _size_band(ees):
    for lo, hi, label in [(0, 100, "50-99"), (100, 250, "100-249"), (250, 500, "250-499"), (500, 1000, "500-999")]:
        if lo <= ees < hi:
            return label
    return "1000+"


def _quarter(date):
    return f"{date[:4]}-Q{(int(date[5:7]) - 1) // 3 + 1}"


def _minus_days(date, days):
    return (pd.Timestamp(date) - pd.Timedelta(days=days)).strftime("%Y-%m-%d")


# ---------------------------------------------------------------- Northwind from broker files
def northwind_from_packages(assets_dir):
    """Census v1+v2, claims (v2 incurred file only) and large claimants v1+v2 for Northwind."""
    pk = os.path.join(assets_dir, "broker_packages")
    census = []
    for v in ("v1", "v2"):
        c = pd.read_csv(os.path.join(pk, f"northwind_{v}", "census.csv"), dtype=str, keep_default_na=False)
        for r in c.itertuples(index=False):
            census.append((NORTHWIND_ID, r.member_id, r.relationship, r.tier or None, r.gender or None,
                           r.birth_date or None, r.zip3 or None, v))
    inc = pd.read_csv(os.path.join(pk, "northwind_v2", "claims_experience_incurred.csv"), dtype={"incurred_month": str, "paid_through": str})
    claims = [(NORTHWIND_ID, r.incurred_month, r.paid_through, SERVICE_CATEGORY_ALL, float(r.total_paid_to_date), r.basis)
              for r in inc.itertuples(index=False)]
    lcs = []
    for v in ("v1", "v2"):
        lc = pd.read_csv(os.path.join(pk, f"northwind_{v}", "large_claimant_report.csv"), dtype=str, keep_default_na=False)
        for r in lc.itertuples(index=False):
            lcs.append((NORTHWIND_ID, r.claimant_id, r.condition_category, r.status or "UNKNOWN", float(r.total_paid_24mo), v))
    return census, claims, lcs


# ---------------------------------------------------------------- broker_submissions seed
def broker_submissions_seed():
    """25 submissions, deterministic and independent of the book (reset_demo restores exactly these).
    Prospect group ids GRP-NB-1xx other than Northwind are pipeline-only (not in groups)."""
    rng = np.random.default_rng(SEED + 1)
    rows = [
        ("SUB-NW-001-V1", NORTHWIND_ID, "Harbor Benefits Partners", "2026-11-09 09:14:00", "v1", "BLOCKED",
         "24 months of claims experience", "Intake Desk 1"),
        ("SUB-NW-001-V2", NORTHWIND_ID, "Harbor Benefits Partners", "2026-11-13 15:40:00", "v2", "READY_WITH_WARNINGS",
         "Renewal offer from incumbent", "Intake Desk 1"),
    ]
    blocking = [i[1] for i in INTAKE_CHECKLIST if i[2] == "BLOCKING"]
    warning = [i[1] for i in INTAKE_CHECKLIST if i[2] == "WARNING"]
    statuses = ["READY"] * 9 + ["READY_WITH_WARNINGS"] * 7 + ["BLOCKED"] * 7
    rng.shuffle(statuses)
    start = pd.Timestamp("2026-10-01 08:00:00")
    for i, st in enumerate(statuses):
        ts = start + pd.Timedelta(minutes=int(rng.integers(0, 43 * 24 * 60)))
        top = None if st == "READY" else str(rng.choice(blocking if st == "BLOCKED" else warning))
        resub = st != "BLOCKED" and rng.random() < 0.3
        rows.append((f"SUB-2026-{i + 101:04d}", f"GRP-NB-{i + 101:03d}", BROKERS[int(rng.integers(0, len(BROKERS)))][0],
                     ts.strftime("%Y-%m-%d %H:%M:%S"), "v2" if resub else "v1", st, top, INTAKE_OWNERS[i % 3]))
    return pd.DataFrame(rows, columns=["submission_id", "group_id", "broker_name", "received_ts", "package_version",
                                       "completeness_status", "top_missing_item", "owner"])


# ---------------------------------------------------------------- whole book
def build_book(assets_dir):
    """Return {table_name: pandas.DataFrame} for every base table that the book loads
    (submission_findings stays empty: written during the demo, truncated by reset_demo)."""
    rng = np.random.default_rng(SEED)
    groups, census, claims, lcs, plans, manual, pipeline = [], [], [], [], [], [], []

    # Northwind (prospect, pinned)
    groups.append(dict(NORTHWIND))
    nw_census, nw_claims, nw_lcs = northwind_from_packages(assets_dir)
    census += nw_census
    claims += nw_claims
    lcs += nw_lcs
    plans += [(NORTHWIND_ID,) + p for p in NORTHWIND_PLANS]
    manual.append((ASSUMPTION_VERSION, NORTHWIND_ID) + NORTHWIND_MANUAL)

    # Lakeview (in force, fixed)
    groups.append(dict(LAKEVIEW))
    census += _census(rng, LAKEVIEW_ID, LAKEVIEW["zip3"], LAKEVIEW["enrolled_employees"], LAKEVIEW["members"])
    claims += _claims(rng, LAKEVIEW_ID, LAKEVIEW["members"], LAKEVIEW_CLAIMS_PMPM)
    lcs += [(LAKEVIEW_ID, cid, cond, st, amt, "v2") for cid, cond, st, amt in LAKEVIEW_CLAIMANTS]
    plans.append((LAKEVIEW_ID, "current", "Choice PPO 1500", 1500, 5000, 0.20, 1.00))
    manual.append((ASSUMPTION_VERSION, LAKEVIEW_ID) + LAKEVIEW_MANUAL)
    lv_prem = LAKEVIEW["incumbent_premium_pmpm"] * LAKEVIEW["members"] * 12
    lv_rate = LAKEVIEW_RENEWAL["recommended_rate_action"]
    pipeline.append((LAKEVIEW_ID, LAKEVIEW["industry"], LAKEVIEW_RENEWAL["renewal_date"], _quarter(LAKEVIEW_RENEWAL["renewal_date"]),
                     _size_band(LAKEVIEW["enrolled_employees"]), round(lv_prem, 2),
                     round(lv_prem * (1 + lv_rate) * TARGET_LOSS_RATIO, 2), lv_rate,
                     LAKEVIEW_RENEWAL["new_large_claimant_flag"], LAKEVIEW_RENEWAL["prebuilt"],
                     _minus_days(LAKEVIEW_RENEWAL["renewal_date"], 60), LAKEVIEW_RENEWAL["owner"]))

    # 58 random in-force groups
    name_pool = [(p, ind) for p in NAME_PREFIXES for ind in range(len(INDUSTRIES))]
    picks = rng.choice(len(name_pool), size=N_RANDOM_GROUPS, replace=False)
    new_lc = set(rng.choice(N_RANDOM_GROUPS, size=N_RANDOM_NEW_LARGE_CLAIMANT, replace=False).tolist())
    renewal_months = ["2027-01-01", "2027-02-01", "2027-03-01", "2027-04-01", "2027-05-01", "2027-06-01"]
    for i, pick in enumerate(picks):
        prefix, ind_idx = name_pool[int(pick)]
        industry, sic, ind_factor, suffixes = INDUSTRIES[ind_idx]
        gid = f"GRP-BK-{i + 3:03d}"
        state, zip3 = LOCATIONS[int(rng.integers(0, len(LOCATIONS)))]
        ees = int(np.clip(round(np.exp(rng.normal(np.log(200), 0.9))), 60, 2500))
        rows = _census(rng, gid, zip3, ees)
        members = len(rows)
        census += rows
        renewal = renewal_months[int(rng.integers(0, len(renewal_months)))]
        firm, contact, email = BROKERS[1 + int(rng.integers(0, len(BROKERS) - 1))]
        prem_pmpm = round(float(rng.normal(560, 45)), 2)
        groups.append({
            "group_id": gid, "group_name": f"{prefix} {suffixes[int(rng.integers(0, len(suffixes)))]}",
            "status": "IN_FORCE", "industry": industry, "sic_code": sic, "state": state, "zip3": zip3,
            "enrolled_employees": ees, "members": members, "member_months": members * 24,
            "demographic_change": round(float(rng.normal(1.0, 0.012)), 3), "incumbent_premium_pmpm": prem_pmpm,
            "incumbent_renewal_offer_pct": None, "effective_date": f"{int(renewal[:4]) - 1}{renewal[4:]}",
            "broker_name": firm, "broker_contact": contact, "broker_email": email,
        })
        claims += _claims(rng, gid, members, float(rng.normal(470, 55)))
        for k in range(int(min(rng.poisson(max(members / 600, 0.5)), 8))):
            lcs.append((gid, f"LC-{k + 1:02d}", str(rng.choice(CONDITIONS)), str(rng.choice(["ACTIVE", "ONGOING", "RESOLVED"], p=[0.3, 0.25, 0.45])),
                        round(100000 + float(rng.lognormal(np.log(120000), 0.8)), 2), "v2"))
        plan = CURRENT_PLANS[int(rng.integers(0, len(CURRENT_PLANS)))]
        plans.append((gid, "current") + plan + (1.00,))
        manual.append((ASSUMPTION_VERSION, gid, 520.00, round(float(rng.normal(1.0, 0.04)), 3),
                       round(float(rng.normal(1.0, 0.03)), 3), ind_factor))
        rate = round(float(np.clip(rng.normal(0.085, 0.05), -0.05, 0.30)), 4)
        cur_prem = round(prem_pmpm * members * 12, 2)
        pipeline.append((gid, industry, renewal, _quarter(renewal), _size_band(ees), cur_prem,
                         round(cur_prem * (1 + rate) * TARGET_LOSS_RATIO * float(rng.normal(1.0, 0.015)), 2), rate,
                         i in new_lc, bool(rng.random() < 0.6), _minus_days(renewal, 60),
                         UNDERWRITERS[int(rng.integers(0, len(UNDERWRITERS)))]))

    av = ASSUMPTION_VERSION
    df = pd.DataFrame
    return {
        "groups": df(groups),
        "census_members": df(census, columns=["group_id", "member_id", "relationship", "tier", "gender", "birth_date", "zip3", "census_version"]),
        "claims_monthly": df(claims, columns=["group_id", "incurred_month", "paid_through", "service_category", "paid_to_date", "basis"]),
        "large_claimants": df(lcs, columns=["group_id", "claimant_id", "condition_category", "status", "total_claims", "package_version"]),
        "plan_designs": df(plans, columns=["group_id", "plan_option", "plan_name", "deductible_ind", "oop_max_ind", "coinsurance", "relativity"]),
        "completion_factors": df([(av, lag, completion_factor(lag)) for lag in range(0, 37)], columns=["assumption_version", "lag_months", "factor"]),
        "trend_assumptions": df([(av, s, r, TREND_YEARS) for s, r in TREND], columns=["assumption_version", "trend_scenario", "annual_rate", "trend_years"]),
        "pooling_points": df([(av,) + p for p in POOLING], columns=["assumption_version", "pooling_point", "pooling_charge_pmpm", "full_credibility_mm"]),
        "manual_rate_factors": df(manual, columns=["assumption_version", "group_id", "base_manual_pmpm", "area_factor", "demographic_factor", "industry_factor"]),
        "retention_targets": df([(av, RETENTION, TARGET_LOSS_RATIO)], columns=["assumption_version", "retention", "target_loss_ratio"]),
        "tier_factors": df([(av,) + t for t in TIER_FACTORS], columns=["assumption_version", "tier", "tier_factor"]),
        "persistency_curve": df(PERSISTENCY, columns=["rate_action_band", "band_min", "band_max", "persistency"]),
        "renewal_pipeline": df(pipeline, columns=["group_id", "industry", "renewal_date", "renewal_quarter", "size_band", "current_annual_premium",
                                                  "projected_annual_claims", "recommended_rate_action", "new_large_claimant_flag", "prebuilt",
                                                  "quote_due_date", "owner"]),
        "broker_submissions": broker_submissions_seed(),
        "trend_monitor": df([(m, p, a, s, av) for m, p, a, s in TREND_MONITOR], columns=["metric", "period", "actual_annual_trend", "assumed_annual_trend", "assumption_version"]),
        "intake_checklist": df(INTAKE_CHECKLIST, columns=["item_id", "item_name", "severity", "rule_text", "broker_ask_template"]),
    }


# ---------------------------------------------------------------- broker package checks (L300-05)
def package_gaps(pkg_dir):
    """Return the seeded blocking gaps found in a broker package folder (list of short strings)."""
    files = set(os.listdir(pkg_dir))
    gaps = []
    if "claims_experience_incurred.csv" in files:
        claims = pd.read_csv(os.path.join(pkg_dir, "claims_experience_incurred.csv"))
        month_col, basis = "incurred_month", set(claims["basis"])
    else:
        claims = pd.read_csv(os.path.join(pkg_dir, "claims_experience_paid.csv"))
        month_col, basis = "paid_month", set(claims["basis"])
    if claims[month_col].nunique() < 24:
        gaps.append(f"experience: {claims[month_col].nunique()} of 24 months")
    if basis != {"INCURRED"} and "lag_report.csv" not in files:
        gaps.append("experience: paid basis and no lag report")
    census = pd.read_csv(os.path.join(pkg_dir, "census.csv"), dtype=str, keep_default_na=False)
    emp = census[census["relationship"] == "EMPLOYEE"]
    bad = int(((emp["birth_date"] == "") | (emp["tier"] == "") | (emp["gender"] == "") | (emp["zip3"] == "")).sum())
    if bad:
        gaps.append(f"census: {bad} employee rows missing birth_date or tier")
    lc = pd.read_csv(os.path.join(pkg_dir, "large_claimant_report.csv"), dtype=str, keep_default_na=False)
    no_status = int((~lc["status"].isin(["ACTIVE", "ONGOING", "RESOLVED"])).sum())
    if no_status:
        gaps.append(f"large claimants: {no_status} missing status")
    if "benefit_summary_requested.md" not in files:
        gaps.append("benefit summary: requested plan missing")
    return gaps
