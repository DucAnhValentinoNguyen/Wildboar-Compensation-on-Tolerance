## 10_robustness_specs.R -- RQ3 (part 2): sensitivity to modelling choices
##  (a) Tolerance measured with all 4 items vs the EFA/CFA-informed 3 items
##  (b) multivariate outliers (n=14, p<.001 Mahalanobis) excluded vs retained
##  (c) CA1/CA2 extreme values (>1) winsorised at 1.0 vs retained as-is
##  (d) common-method-bias diagnostics: Harman's single factor test +
##      full collinearity VIF (Kock 2015)
##  (e) PLSpredict out-of-sample assessment (Shmueli et al. 2019) vs a naive
##      linear-model benchmark, for each Tolerance indicator
suppressPackageStartupMessages({ library(seminr); library(dplyr); library(psych) })

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); mod_dir <- file.path(root, "output/models")

sink(file.path(tab_dir, "80_robustness_log.txt"))

mm_core <- function(tol_items, ca1var = "CA1", ca2var = "CA2") {
  constructs(
    composite("CP_WB", c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), weights = mode_B),
    composite("TC", c("TC1_DamagedArea","log_econloss"), weights = mode_B),
    composite("IC", c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
    composite("IB", single_item("IB")),
    composite("PS", c("PS1","PS2"), weights = mode_B),
    composite("CA", c(ca1var, ca2var, "log_ca3"), weights = mode_B),
    composite("PE", single_item("PE")),
    composite("Tol", tol_items, weights = mode_A)
  )
}
sm_core <- relationships(
  paths(from = "CP_WB", to = c("PE","CA","PS","TC","IC","IB")),
  paths(from = c("PE","CA","PS","TC","IC","IB"), to = "Tol")
)

fit_and_extract <- function(data, mm, label) {
  m <- estimate_pls(data = data, measurement_model = mm, structural_model = sm_core,
                     missing = mean_replacement, maxIt = 500)
  b <- bootstrap_model(m, nboot = 2000, cores = 4, seed = 20260920)
  p <- as.data.frame(summary(b)$bootstrapped_paths)
  p$path <- rownames(p); p$spec <- label
  list(model = m, boot = b, paths = p)
}

cat("==================== (a) Tolerance: 4-item vs 3-item specification ====================\n")
r_4item <- fit_and_extract(df, mm_core(c("Tol1_5","Tol2_1","Tol3_1","Tol4_5")), "4-item Tolerance")
r_3item <- fit_and_extract(df, mm_core(c("Tol1_5","Tol2_1","Tol4_5")), "3-item Tolerance (primary)")
cmp_tol <- bind_rows(r_4item$paths, r_3item$paths) %>% filter(grepl("-> Tol$|->Tol$|Tol", path))
print(cmp_tol[, c("spec","path","Original Est.","Bootstrap SD","T Stat.")])

cat("\n\n==================== (b) Multivariate outliers: excluded vs retained ====================\n")
df_no_out <- df %>% filter(maha_p >= .001)
r_full   <- fit_and_extract(df, mm_core(c("Tol1_5","Tol2_1","Tol4_5")), "All n=625")
r_noout  <- fit_and_extract(df_no_out, mm_core(c("Tol1_5","Tol2_1","Tol4_5")), "Outliers excluded n=611")
cmp_out <- bind_rows(r_full$paths, r_noout$paths)
print(cmp_out[, c("spec","path","Original Est.","T Stat.")])

cat("\n\n==================== (c) CA1/CA2 winsorised vs raw ====================\n")
r_raw <- r_3item # same as primary, CA1/CA2 raw
r_wins <- fit_and_extract(df, mm_core(c("Tol1_5","Tol2_1","Tol4_5"), ca1var = "CA1_w", ca2var = "CA2_w"),
                           "CA1/CA2 winsorised at 1.0")
cmp_ca <- bind_rows(r_raw$paths, r_wins$paths) %>% filter(grepl("CA", path))
print(cmp_ca[, c("spec","path","Original Est.","T Stat.")])

cat("\n\n==================== (d) Common Method Bias diagnostics ====================\n")
cmb_items <- df %>% select(CP_WB1,CP_WB2,CP_WB3,CP_WB4,TC1_DamagedArea,log_econloss,
                            IC1,IC2_1,IB,PS1,PS2,CA1,CA2,PE,Tol1_5,Tol2_1,Tol4_5)
harman <- fa(cmb_items, nfactors = 1, fm = "pa")
cat("Harman's single-factor test: 1st factor explains",
    round(harman$Vaccounted[2,1]*100, 1), "% of variance (rule of thumb concern if >50%)\n")

## Full collinearity VIF (Kock 2015): regress each construct's score on a
## common random marker variable + all other construct scores; here
## approximated by regressing each indicator on all *other* indicators.
full_vif <- sapply(names(cmb_items), function(v) {
  frm <- as.formula(paste(v, "~ ."))
  fit <- lm(frm, data = cmb_items)
  1 / (1 - summary(fit)$r.squared)
})
cat("\nFull collinearity VIF per indicator (Kock 2015; concern if > 3.3):\n")
print(round(full_vif, 2))

sink()

write.csv(cmp_tol, file.path(tab_dir, "81_robustness_tolitems.csv"), row.names = FALSE)
write.csv(cmp_out, file.path(tab_dir, "82_robustness_outliers.csv"), row.names = FALSE)
write.csv(cmp_ca, file.path(tab_dir, "83_robustness_ca_winsor.csv"), row.names = FALSE)
write.csv(data.frame(indicator = names(full_vif), full_vif = round(full_vif,2)),
          file.path(tab_dir, "84_robustness_full_vif.csv"), row.names = FALSE)

## ---------- (e) PLSpredict ---------------------------------------------------
## Note: seminr's predict_DA technique errors on this model (an internal
## subsetting bug triggered by the mix of single-item and multi-item
## composites); predict_EA (the alternative embedded-model technique) is
## used instead and works correctly.
cat("Running PLSpredict...\n")
## seminr's predict_pls() fails ("Can't subset columns ... not a matrix") when the model was estimated on
## the full wide tibble, so refit the same model on a plain data frame with only its own indicator columns.
## The estimates are identical; only the data container differs. Fold assignment is random, so fix the seed.
pred_items <- c("CP_WB1","CP_WB2","CP_WB3","CP_WB4","TC1_DamagedArea","log_econloss","IC1","IC2_1","IC2_2_imp","IC2_3_imp",
                "IB","PS1","PS2","CA1","CA2","log_ca3","PE","Tol1_5","Tol2_1","Tol4_5")
m_pred <- estimate_pls(data = as.data.frame(df)[, pred_items], measurement_model = mm_core(c("Tol1_5","Tol2_1","Tol4_5")),
                       structural_model = sm_core, missing = mean_replacement, maxIt = 500)
set.seed(20260920)
predict_res <- predict_pls(m_pred, technique = predict_EA, noFolds = 10, reps = 10)
pred_summary <- summary(predict_res)
saveRDS(predict_res, file.path(mod_dir, "plspredict_result.rds"))
sink(file.path(tab_dir, "85_plspredict_log.txt"))
print(pred_summary)
sink()

cat("Robustness checks complete.\n")
