## 11_regression_crosscheck.R -- Triangulation with conventional regression
## PLS-SEM composite scores are opaque to non-specialist readers. This script
## cross-checks the PLS-SEM structural conclusions with (a) an OLS model of
## a simple Tolerance sum-score using heteroskedasticity-robust SEs, and
## (b) a cumulative-link mixed model (ordinal outcome, village random
## intercept) that accounts for the spatial clustering the single-level
## PLS-SEM ignores.
suppressPackageStartupMessages({
  library(dplyr); library(car); library(ordinal); library(broom)
})

root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables")

sink(file.path(tab_dir, "90_regression_crosscheck_log.txt"))

## Simple, interpretable composite indices (row means) matching the PLS-SEM
## formative blocks, for an OLS cross-check any reader can audit by hand.
df <- df %>%
  mutate(
    z_tc1 = as.numeric(scale(TC1_DamagedArea)), z_econloss = as.numeric(scale(log_econloss)),
    z_ic1 = as.numeric(scale(IC1)), z_ic2_1 = as.numeric(scale(IC2_1)),
    z_ic2_2 = as.numeric(scale(IC2_2_imp)), z_ic2_3 = as.numeric(scale(IC2_3_imp))
  ) %>%
  rowwise() %>%
  mutate(
    tc_idx = mean(c(z_tc1, z_econloss)),
    ic_idx = mean(c(z_ic1, z_ic2_1, z_ic2_2, z_ic2_3)),
    cpwb_idx = mean(c(CP_WB1, CP_WB2, CP_WB3, CP_WB4))
  ) %>% ungroup()

cat("==================== OLS: Tolerance (3-item mean) ~ predictors ====================\n")
ols1 <- lm(tol_mean_no3 ~ CE0 + cpwb_idx + tc_idx + ic_idx + IB + PS1 + PS2 +
             gender + age + education + log_income + log_hh_asset + in_np + site_baoxing,
           data = df)
print(summary(ols1))
cat("\nVIFs:\n"); print(vif(ols1))
cat("\nRobust (HC3) SEs:\n")
print(coeftest_res <- lmtest::coeftest(ols1, vcov = car::hccm(ols1, type = "hc3")))

cat("\n\n==================== Cumulative link mixed model (per-item ordinal, village random intercept) ====================\n")
## Use a separate ordered-factor column for clmm -- never overwrite the
## shared numeric Tol1_5 column in place, since this data.frame gets
## persisted below and other scripts expect Tol1_5 to stay numeric.
df$Tol1_5_ord <- factor(df$Tol1_5, ordered = TRUE)
df$village_f <- factor(paste(df$county, df$township, df$village))
clmm1 <- tryCatch(
  clmm(Tol1_5_ord ~ CE0 + cpwb_idx + tc_idx + ic_idx + IB + gender + age + education +
         log_income + log_hh_asset + in_np + site_baoxing + (1 | village_f),
       data = df),
  error = function(e) { cat("clmm failed:", conditionMessage(e), "\n"); NULL }
)
if (!is.null(clmm1)) print(summary(clmm1))

## Compare clustered vs naive SEs (design effect check)
cat("\n\n==================== Cluster-robust SE comparison (village clustering) ====================\n")
ols_naive <- lm(Tol1_5 ~ CE0 + cpwb_idx + tc_idx + ic_idx + IB +
                   gender + age + education + log_income + log_hh_asset + in_np + site_baoxing,
                 data = df)
cat("Naive OLS SEs:\n"); print(round(summary(ols_naive)$coefficients[,2], 4))
cl_vcov <- function(model, cluster) {
  M <- length(unique(cluster)); N <- length(cluster)
  K <- model$rank
  dfc <- (M/(M-1)) * ((N-1)/(N-K))
  uj <- apply(sandwich::estfun(model), 2, function(x) tapply(x, cluster, sum))
  dfc * sandwich::sandwich(model, meat = crossprod(as.matrix(uj))/N)
}
cl_res <- tryCatch({
  V <- cl_vcov(ols_naive, df$village_f)
  sqrt(diag(V))
}, error = function(e) { cat("cluster-robust SE failed:", conditionMessage(e), "\n"); NULL })
if (!is.null(cl_res)) { cat("\nVillage-clustered SEs:\n"); print(round(cl_res, 4)) }

sink()

write.csv(broom::tidy(ols1), file.path(tab_dir, "91_ols_tolerance.csv"), row.names = FALSE)
saveRDS(df, file.path(root, "output/models/clean_data_with_diagnostics.rds"))

cat("Regression cross-check complete.\n")
