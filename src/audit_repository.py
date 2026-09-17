"""Read-only workbook audit and diagnostic associations, not a final analysis.

Run from any directory: .venv/bin/python src/audit_repository.py
Writes aggregate evidence only to results/repository_audit/.
"""
from pathlib import Path
import hashlib
import json
import platform

import numpy as np
import pandas as pd
import statsmodels.api as sm

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "repository_audit"
OUT.mkdir(parents=True, exist_ok=True)
source = ROOT / "data" / "3_Data.xlsx"
d = pd.read_excel(source, sheet_name="Input Data")
raw = pd.read_excel(source, sheet_name="Raw data").iloc[1:].copy()
raw["ID"] = pd.to_numeric(raw["ID"])
m = d.merge(raw, on="ID", validate="one_to_one", suffixes=("", "_raw"))
assert len(m) == len(d) == len(raw)

mapping = {"非常不同意": 1, "不同意": 2, "一般": 3, "同意": 4, "非常同意": 5}
coding = []
for question, column, reverse in [
    ("Q30_5", "Tol1_5", False), ("Q30_4", "Tol2_1", True),
    ("Q30_3", "Tol3_1", True), ("Q30_2", "Tol4_5", False),
]:
    expected = m[question].map(mapping)
    if reverse:
        expected = 6 - expected
    observed = expected.notna()
    coding.append(dict(item=column, raw_question=question, reversed_in_workbook=reverse,
                       n_observed=int(observed.sum()), raw_missing=int((~observed).sum()),
                       mismatches=int((expected[observed] != m.loc[observed, column]).sum())))
    pd.crosstab(m[question], m[column]).to_csv(OUT / f"coding_{column}.csv")
pd.DataFrame(coding).to_csv(OUT / "tolerance_coding.csv", index=False)
pd.crosstab(m.Q17, m.PS1).to_csv(OUT / "reporting_channels_PS1.csv")
pd.crosstab(d.Q1_County, d.CE0).to_csv(OUT / "county_application.csv")
d.describe(include="all").T.to_csv(OUT / "variable_profile.csv")
d.isna().sum().rename("missing_n").to_csv(OUT / "missingness.csv")

def z(x):
    return (x - x.mean()) / x.std(ddof=0)

def alpha(x):
    k = x.shape[1]
    return k / (k - 1) * (1 - x.var(ddof=1).sum() / x.sum(axis=1).var(ddof=1))

items = d[["Tol1_5", "Tol2_1", "Tol3_1", "Tol4_5"]]
items.corr().to_csv(OUT / "tolerance_correlations.csv")
legacy = items.copy()
legacy["Tol3_1"] = 6 - legacy["Tol3_1"]
outcomes = {
    "four_items_as_stored": z(items).mean(axis=1),
    "three_items_without_safety": z(items.drop(columns="Tol3_1")).mean(axis=1),
    "legacy_double_reversed_safety": z(legacy).mean(axis=1),
}
# Hold all other legacy scoring choices fixed to isolate outcome/county changes.
# These controls include simultaneous attitudes; these are NOT causal estimates.
sc = pd.DataFrame(index=d.index)
maps = {
    "ConflictExp_WB": ["CP_WB1", "CP_WB2", "CP_WB3", "CP_WB4"],
    "ConflictExp_All": ["CP_A1", "CP_A2", "CP_A3"],
    "Intangible_Costs": ["IC1", "IC2_DescriptiveAttitude"],
    "Intangible_Benefits": ["IB"], "Prevention_Eff": ["PE"],
    "Policy_Support": ["PS1", "PS2"],
}
for name, cols in maps.items():
    sc[name] = z(d[cols]).mean(axis=1)
sc["Tangible_Costs"] = z(np.log1p(d[["TC1_DamagedArea", "TC2_EconomicLoss"]])).mean(axis=1)
ca = d[["CA1", "CA2", "CA3"]].copy()
ca["CA3"] = np.log1p(ca["CA3"])
sc["Compensation_Anticipation"] = z(ca).mean(axis=1)
wtm = list(sc.columns)
demo = ["Q4_Gender", "Q5_Age", "Q6_Education", "Q8_AnnualIncome",
        "Q9_AgriProportion", "Q11_TotalArea", "Q13_TotalLivestock",
        "Q14_HouseholdAsset", "Q3_InNP"]
sc[demo] = d[demo]
sc["CE0"] = d.CE0
sc["county_Qingchuan"] = (d.Q1_County == "Qingchuan").astype(int)
town = d[["Q1_County", "Q1_Township"]].astype(str).agg("/".join, axis=1)
rows = []
for outcome, values in outcomes.items():
    for label, controls in {
        "unadjusted": [], "county": ["county_Qingchuan"],
        "legacy_full": wtm + demo,
        "legacy_full_plus_county": wtm + demo + ["county_Qingchuan"],
    }.items():
        X = sc[["CE0"] + controls].copy()
        for c in X:
            if X[c].nunique() > 2:
                X[c] = z(X[c])
        model = sm.OLS(z(values), sm.add_constant(X))
        for cov in ["HC3", "township_cluster"]:
            fit = (model.fit(cov_type="HC3") if cov == "HC3" else
                   model.fit(cov_type="cluster", cov_kwds={"groups": town,
                             "use_correction": True}, use_t=True))
            ci = fit.conf_int().loc["CE0"]
            rows.append(dict(outcome=outcome, controls=label, covariance=cov,
                             n=int(fit.nobs), beta=fit.params.CE0,
                             ci_low=ci.iloc[0], ci_high=ci.iloc[1], p=fit.pvalues.CE0))
pd.DataFrame(rows).to_csv(OUT / "diagnostic_associations.csv", index=False)

checks = {
    "workbook_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
    "duplicate_workbook_identical": source.read_bytes() == (ROOT / "src/python_code/3_Data.xlsx").read_bytes(),
    "input_rows": len(d), "input_columns": len(d.columns), "matched_raw_rows": len(m),
    "unique_IDs": d.ID.nunique(), "township_keys": town.nunique(),
    "complete_village_keys": len(d.dropna(subset=["Q1_Village"])[["Q1_County", "Q1_Township", "Q1_Village"]].drop_duplicates()),
    "wrong_compensation_proxy_disagreements": int(((d.CP_WB1 != 1).astype(int) != d.CE0).sum()),
    "CA1_above_one": int((d.CA1 > 1).sum()), "CA2_above_one": int((d.CA2 > 1).sum()),
    "damaged_area_above_total_area": int((d.TC1_DamagedArea > d.Q11_TotalArea).sum()),
    "PE_zero": int((d.PE == 0).sum()),
    "IC2_2_zero": int((d.IC2_2 == 0).sum()), "IC2_3_zero": int((d.IC2_3 == 0).sum()),
    "IC2_2_zero_matches_raw_missing": bool(((m.IC2_2 == 0) == m.Q35_2.isna()).all()),
    "IC2_3_zero_matches_raw_missing": bool(((m.IC2_3 == 0) == m.Q35_3.isna()).all()),
    "descriptive_attitude_equals_nonzero_mean": bool(np.allclose(d.IC2_DescriptiveAttitude,
        d[["IC2_1", "IC2_2", "IC2_3"]].replace(0, np.nan).mean(axis=1))),
    "raw_timeliness_missing_among_applicants": int(m.loc[m.CE0 == 1, "Q14"].isna().sum()),
    "raw_satisfaction_missing_among_applicants": int(m.loc[m.CE0 == 1, "Q15"].isna().sum()),
    "alpha_raw_four_as_stored": float(alpha(items)),
    "alpha_raw_three_without_safety": float(alpha(items.drop(columns="Tol3_1"))),
    "alpha_raw_legacy_double_reversed_safety": float(alpha(legacy)),
    "legacy_target_sd": float(outcomes["legacy_double_reversed_safety"].std(ddof=0)),
    "versions": {"python": platform.python_version(), "pandas": pd.__version__,
                 "numpy": np.__version__, "statsmodels": sm.__version__},
}
(OUT / "checks.json").write_text(json.dumps(checks, indent=2) + "\n")
print(json.dumps(checks, indent=2))
print(pd.DataFrame(rows).round(4).to_string(index=False))
