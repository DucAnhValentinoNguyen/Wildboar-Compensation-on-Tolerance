library(targets)
source("src/fresh/common.R")
for(f in list.files("src/fresh",pattern="\\.R$",full.names=TRUE))if(basename(f)!="common.R")source(f)
tar_option_set(seed=20260917, error="continue", format="file")
list(
  tar_target(workbook,"data/3_Data.xlsx"),
  tar_target(decisions,"docs/ANALYSIS_DECISIONS.md"),
  tar_target(prepared,{workbook;decisions;prepare_data()}),
  tar_target(eda,run_eda(prepared)),
  tar_target(measurement,run_measurement(prepared)),
  tar_target(regression,run_regression(prepared)),
  tar_target(structural,run_structural(prepared)),
  tar_target(bayesian,run_bayesian(prepared)),
  tar_target(secondary,run_secondary(prepared)),
  tar_target(robustness,run_robustness(prepared)),
  tar_target(adjustment,run_adjustment(prepared)),
  tar_target(prediction,run_prediction(prepared)),
  tar_target(deliverables,{eda;measurement;regression;structural;bayesian;secondary;robustness;adjustment;prediction;render_deliverables()}),
  tar_target(validation,{deliverables;validate_project()})
)
