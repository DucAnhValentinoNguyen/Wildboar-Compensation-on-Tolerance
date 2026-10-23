## 06_plssem_core.R -- Core PLS-SEM (Wildlife Tolerance Model, full sample)
## Re-specification of the client's WTM PLS-SEM using modern practice:
##  - Tolerance measured with 3 items (Tol1,Tol2,Tol4; Tol3 dropped per
##    EFA/CFA: near-zero item-total correlation & non-significant CFA loading)
##  - Intangible Cost formative block uses person-mean-imputed IC2_2/IC2_3
##    (avoids discarding ~25% of cases on a block whose 0s are structural
##    missingness, not real scale points; see 01_data_prep.R)
##  - Two previously-unused controls added: in_np (residence inside the
##    national park boundary) and site_baoxing (survey site/wave), the
##    latter because compensation participation is strongly confounded with
##    county (74% vs 34% -- see 02_eda.R)
##  - Skewed monetary indicators (economic loss, insurance payment) entered
##    log-transformed within their formative blocks
suppressPackageStartupMessages({
  library(dplyr); library(seminr)
})

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); mod_dir <- file.path(root, "output/models")

set.seed(20260920)

mm <- constructs(
  composite("CP_WB", c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), weights = mode_B),
  composite("CP_A",  c("CP_A1","CP_A2","CP_A3"), weights = mode_B),
  composite("PE",    single_item("PE")),
  composite("CE0",   single_item("CE0")),
  composite("CA",    c("CA1","CA2","log_ca3"), weights = mode_B),
  composite("PS",    c("PS1","PS2"), weights = mode_B),
  composite("TC",    c("TC1_DamagedArea","log_econloss"), weights = mode_B),
  composite("IC",    c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
  composite("IB",    single_item("IB")),
  composite("Gender", single_item("gender")),
  composite("Age", single_item("age")),
  composite("Education", single_item("education")),
  composite("Income", single_item("log_income")),
  composite("HHAsset", single_item("log_hh_asset")),
  composite("InNP", single_item("in_np")),
  composite("Site", single_item("site_baoxing")),
  composite("Tol", c("Tol1_5","Tol2_1","Tol4_5"), weights = mode_A)
)

tier0 <- c("CP_WB","CP_A","Gender","Age","Education","Income","HHAsset","InNP","Site")
tier1 <- c("PE","CE0")
tier2 <- c("CA","PS","TC","IC","IB")

sm <- relationships(
  paths(from = tier0, to = tier1),
  paths(from = c(tier0, tier1), to = tier2),
  paths(from = c(tier0, tier1, tier2), to = "Tol")
)

model0 <- estimate_pls(data = df, measurement_model = mm, structural_model = sm,
                        missing = mean_replacement, maxIt = 500)

s0 <- summary(model0)
cat("==================== MEASUREMENT MODEL: full dense model ====================\n")
print(s0$loadings)
print(s0$weights)
print(s0$validity$vif_items)
cat("\nR-squared (endogenous constructs):\n"); print(s0$paths)

cat("Bootstrapping (5000 resamples)...\n")
boot0 <- bootstrap_model(model0, nboot = 5000, cores = 4, seed = 20260920)
sb0 <- summary(boot0, alpha = 0.05)

sink(file.path(tab_dir, "40_plssem_full_model_log.txt"))
cat("==================== FULL DENSE MODEL: bootstrap path coefficients ====================\n")
print(sb0$bootstrapped_paths)
cat("\n==================== FULL DENSE MODEL: bootstrap outer weights ====================\n")
print(sb0$bootstrapped_weights)
cat("\n==================== FULL DENSE MODEL: bootstrap outer loadings ====================\n")
print(sb0$bootstrapped_loadings)
cat("\n==================== HTMT (discriminant validity) ====================\n")
print(s0$validity$htmt)
cat("\n==================== R-squared / R-squared adjusted ====================\n")
print(s0$paths)
sink()

saveRDS(model0, file.path(mod_dir, "plssem_model0_full.rds"))
saveRDS(boot0, file.path(mod_dir, "plssem_boot0_full.rds"))

## Export path table for the report
path_tbl <- as.data.frame(sb0$bootstrapped_paths)
path_tbl$path <- rownames(path_tbl)
write.csv(path_tbl, file.path(tab_dir, "41_plssem_full_paths.csv"), row.names = FALSE)

weight_tbl <- as.data.frame(sb0$bootstrapped_weights)
weight_tbl$indicator <- rownames(weight_tbl)
write.csv(weight_tbl, file.path(tab_dir, "42_plssem_full_weights.csv"), row.names = FALSE)

cat("\nCore PLS-SEM (full dense model) complete.\n")
cat("R^2(Tol) =", s0$paths["R^2","Tol"], "\n")
