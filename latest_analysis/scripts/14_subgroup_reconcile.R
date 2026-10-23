## 14_subgroup_reconcile.R -- diagnose why IC->Tolerance subgroup magnitudes
## diverge between the trimmed PLS-MGA model (09_multigroup.R, no demographic/
## wealth controls) and the user's own observed-score analysis (which adjusts
## for county, park residence, age, gender, education, household size, income,
## agricultural dependence, land, livestock, assets). Refit subgroup-specific
## PLS-SEM models WITH the fuller control set to make an apples-to-apples
## comparison before deciding which number to present.
suppressPackageStartupMessages({ library(seminr); library(dplyr) })

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables")

mm_full <- constructs(
  composite("CP_WB", c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), weights = mode_B),
  composite("CP_A",  c("CP_A1","CP_A2","CP_A3"), weights = mode_B),
  composite("TC", c("TC1_DamagedArea","log_econloss"), weights = mode_B),
  composite("IC", c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
  composite("IB", single_item("IB")),
  composite("PS", c("PS1","PS2"), weights = mode_B),
  composite("CA", c("CA1","CA2","log_ca3"), weights = mode_B),
  composite("PE", single_item("PE")),
  composite("Gender", single_item("gender")),
  composite("Age", single_item("age")),
  composite("Education", single_item("education")),
  composite("Income", single_item("log_income")),
  composite("HHAsset", single_item("log_hh_asset")),
  composite("InNP", single_item("in_np")),
  composite("Site", single_item("site_baoxing")),
  composite("Tol", c("Tol1_5","Tol2_1","Tol4_5"), weights = mode_A)
)

exo <- c("CP_WB","CP_A","Gender","Age","Education","Income","HHAsset","InNP","Site")
med <- c("PE","CA","PS","TC","IC","IB")

sm_full <- relationships(
  paths(from = exo, to = med),
  paths(from = c(exo, med), to = "Tol")
)

fit_subgroup <- function(data, label) {
  m <- estimate_pls(data = data, measurement_model = mm_full, structural_model = sm_full,
                     missing = mean_replacement, maxIt = 500)
  b <- bootstrap_model(m, nboot = 3000, cores = 4, seed = 20260920)
  ## bypass summary.boot_seminr_model(): in a subgroup, some construct pair's
  ## bootstrap HTMT distribution has ~zero SD, which throws inside
  ## parse_boot_array_htmt. Paths themselves don't depend on HTMT, so extract
  ## them directly via the same internal helper summary() would otherwise call.
  p <- as.data.frame(seminr:::parse_boot_array(b$path_coef, b$boot_paths, alpha = 0.05))
  p$path <- rownames(p); p$group <- label
  p
}

df_with <- df %>% filter(CE0 == 1)
df_without <- df %>% filter(CE0 == 0)

cat("n with-compensation:", nrow(df_with), " | n without:", nrow(df_without), "\n")

res_with <- fit_subgroup(df_with, "With compensation (full controls)")
res_without <- fit_subgroup(df_without, "Without compensation (full controls)")

ic_tol <- bind_rows(res_with, res_without) %>% filter(path == "IC  ->  Tol")
print(ic_tol[, c("group","path","Original Est.","Bootstrap SD","T Stat.","Bootstrap P Val")])

write.csv(bind_rows(res_with, res_without), file.path(tab_dir, "110_subgroup_full_controls_paths.csv"), row.names = FALSE)

cat("\nComparison across the three specifications:\n")
cat("  Trimmed PLS-MGA model (09_multigroup.R, no demographic controls):\n")
cat("    with-comp IC->Tol = -0.414 | without-comp IC->Tol = -0.255\n")
cat("  Duc's observed-score analysis (background+resource adjusted, n=277/345):\n")
cat("    participants IC->Tol = -0.281 [-0.374,-0.173] | non-participants IC->Tol = -0.424 [-0.511,-0.261]\n")
cat("  This script (full PLS-SEM controls, n=277/348):\n")
print(ic_tol[, c("group","Original Est.","T Stat.")])
