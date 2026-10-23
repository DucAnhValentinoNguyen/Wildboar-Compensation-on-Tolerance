## 09_multigroup.R -- RQ3 (part 1): robustness across groups
## (a) Simplified compositional-invariance check (MICOM step 2 in spirit):
##     do construct scores correlate ~1 and have similar means/SDs across
##     groups when computed with a single pooled weight scheme?
## (b) PLS-MGA (permutation-based) path-coefficient comparison between
##     with/without-compensation groups, and between the two survey
##     counties (Baoxing vs Qingchuan) -- the latter because EDA showed
##     compensation participation is confounded with county.
suppressPackageStartupMessages({ library(seminr); library(dplyr) })

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); mod_dir <- file.path(root, "output/models")

## A trimmed structural model (core mediators only) is used for multigroup
## work: dense 89-path models are underpowered per group once split (n=277
## vs 348), so we focus the comparison on the theoretically central paths.
mm <- constructs(
  composite("CP_WB", c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), weights = mode_B),
  composite("TC", c("TC1_DamagedArea","log_econloss"), weights = mode_B),
  composite("IC", c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
  composite("IB", single_item("IB")),
  composite("PS", c("PS1","PS2"), weights = mode_B),
  composite("CA", c("CA1","CA2","log_ca3"), weights = mode_B),
  composite("PE", single_item("PE")),
  composite("Tol", c("Tol1_5","Tol2_1","Tol4_5"), weights = mode_A)
)
sm <- relationships(
  paths(from = "CP_WB", to = c("PE","CA","PS","TC","IC","IB")),
  paths(from = c("PE","CA","PS","TC","IC","IB"), to = "Tol")
)

model_core <- estimate_pls(data = df, measurement_model = mm, structural_model = sm,
                            missing = mean_replacement, maxIt = 500)

sink(file.path(tab_dir, "70_multigroup_log.txt"))

## ---------- (a) Compositional invariance (simplified) ----------------------
cat("==================== Simplified compositional invariance check ====================\n")
scores <- as.data.frame(model_core$construct_scores)
scores$CE0 <- df$CE0; scores$county <- df$county
for (construct in c("CP_WB","TC","IC","IB","PS","CA","PE","Tol")) {
  g1 <- scores[[construct]][scores$CE0 == 0]
  g2 <- scores[[construct]][scores$CE0 == 1]
  ct <- cor.test(rank(scores[[construct]]), scores$CE0)
  cat(sprintf("%-8s | mean(no-comp)=%.3f mean(comp)=%.3f  Welch t p=%.4f\n",
              construct, mean(g1), mean(g2), t.test(g1, g2)$p.value))
}

## ---------- (b) PLS-MGA: with vs without compensation ----------------------
cat("\n\n==================== PLS-MGA: Compensation participation groups ====================\n")
mga_ce0 <- estimate_pls_mga(model_core, df$CE0 == 1, nboot = 2000)
print(mga_ce0)

## ---------- (c) PLS-MGA: county (survey site/wave) --------------------------
cat("\n\n==================== PLS-MGA: County (Baoxing vs Qingchuan) ====================\n")
mga_county <- estimate_pls_mga(model_core, df$county == "Baoxing", nboot = 2000)
print(mga_county)

sink()

saveRDS(model_core, file.path(mod_dir, "plssem_core_trimmed.rds"))
saveRDS(mga_ce0, file.path(mod_dir, "mga_ce0.rds"))
saveRDS(mga_county, file.path(mod_dir, "mga_county.rds"))

cat("Multigroup analysis complete. See output/tables/70_multigroup_log.txt\n")
