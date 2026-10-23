# Compensation and tolerance towards wild boar: analysis code

Code for the consulting project report *Understanding the compensation policy impact on local
resident's tolerance towards wild boars in Giant Panda National Park, China* (LMU Munich,
Statistical Consulting).

## What is in this repository

| Path | Content |
|---|---|
| `latest_analysis/scripts/` | One numbered script per analysis stage (table below) |
| `latest_analysis/run_all.sh` | Runs all scripts in order |
| `latest_analysis/install_packages.R` | Installs the R packages |

The survey data are **not** included; they are subject to the usage restrictions agreed with the
project partner (Mengxi Kou, Rachel Carson Center, LMU Munich). To reproduce the analysis, place the
partner's data file at `data/3_Data.xlsx` (sheets `Input Data` and `Raw data`) in the repository root.

## Running it

Requirements: R 4.5, Python 3 with `pandas` and `openpyxl`, and the R packages in
`latest_analysis/install_packages.R`.

```bash
Rscript latest_analysis/install_packages.R
bash latest_analysis/run_all.sh      # about an hour on 4+ cores; one log per script in latest_analysis/logs/rerun/
```

Every script reads its inputs from and writes its results to `latest_analysis/output/` (tables,
figures, fitted models); the folder is created by `run_all.sh`. Random steps use fixed seeds, except
the permutations of the multi-group analysis in `09_multigroup.R`, whose p-values therefore vary
slightly between runs.

## Scripts

| Script | Purpose | Report |
|---|---|---|
| `00_extract_raw_supplement.py` | Extra questionnaire fields from the raw-data sheet | Data |
| `01_data_prep.R` | Cleaning, recoding, log transforms | Data |
| `02_eda.R` | Descriptives, county confound, group tests, outliers | Data |
| `03_efa.R`, `04_cfa.R` | Exploratory and confirmatory factor analysis of the tolerance items and constructs | Measurement |
| `05_pca.R` | Household wealth index | Measurement |
| `06_plssem_core.R` | Full PLS-SEM of the Wildlife Tolerance Model | Model, appendix |
| `08_moderation.R` | RQ2: compensation x cost/benefit interactions | Model |
| `09_multigroup.R`, `10_robustness_specs.R`, `14_subgroup_reconcile.R` | RQ3: multi-group analysis and robustness specifications | Robustness |
| `11_regression_crosscheck.R` | Regression cross-check with robust standard errors | Model, appendix |
| `12_extended_analyses.R`, `13_path_diagram.R` | Extra questionnaire fields, path diagram | Appendix |
| `16_report_figures.R` | Descriptive report figures, covariate screen, vibration of effects | Model, appendix |
| `17_tolerance_formative_check.R` | Tolerance as reflective vs formative | Measurement |
| `18_log_transform_check.R` | Effect of the log transformation | Data, appendix |
| `19_ce0_direction_check.R` | Who applies for compensation (Wilcoxon, logistic regression) | Data |
| `21_verify_report_claims.R` | Independent recomputation of descriptive and reliability numbers | all |
| `22_moderation_with_controls.R` | RQ2 moderation with the full control set | Model |
| `23_causal_role_models.R` | RQ1: compensation-tolerance association under four adjustment sets, mediation, DAG check | Model |
| `24_applicant_experience.R` | RQ1: timeliness and satisfaction among applicants | Model |
| `25_mengxi_hypotheses.R` | The partner's 36 hypotheses | Appendix |
| `26_bias_analysis.R` | Bias analysis for unmeasured confounding (robustness value, E-value) | Discussion |
| `27_latent_mediators.R` | Measurement-error sensitivity for the candidate mediators | Discussion |
| `28_report_figures_causal.R` | Figures of the causal-role analysis | Model, discussion |

Scripts 23 onwards depend on the model objects saved by earlier scripts, so run them in order.
