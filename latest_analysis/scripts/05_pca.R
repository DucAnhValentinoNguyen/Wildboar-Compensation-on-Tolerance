## 05_pca.R -- Principal Component Analysis
## (1) Construct an asset-based household wealth/livelihood index from crop,
##     livestock and asset variables -- these were collected but never used
##     as a control/moderator in the original WTM model (only Q14_CropAsset
##     was used as a single manifest "HouseholdAsset" indicator).
## (2) PCA on the WTM Likert item pools as an atheoretical cross-check
##     against the EFA/CFA factor structure.
suppressPackageStartupMessages({
  library(dplyr); library(psych); library(factoextra)
})

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); fig_dir <- file.path(root, "output/figures")

sink(file.path(tab_dir, "30_pca_log.txt"))

## ---------- Wealth / livelihood PCA -----------------------------------------
cat("==================== HOUSEHOLD WEALTH / LIVELIHOOD PCA ====================\n")
wealth_vars <- c("Q10_MaizeArea","Q10_PotatoArea","Q10_TeeArea","Q10_FruitArea",
                  "Q10_HerbArea","Q10_VegArea","total_cropland",
                  "Q12_Cattle","Q12_Sheep","Q12_Pig","Q12_Chicken","Q12_Bee",
                  "total_livestock", "log_income", "log_hh_asset")
wealth_data <- df[wealth_vars]
pca_wealth <- prcomp(wealth_data, scale. = TRUE)
print(summary(pca_wealth))
cat("\nLoadings (rotation) on PC1-PC3:\n")
print(round(pca_wealth$rotation[, 1:3], 3))

## First PC as a wealth/livelihood-scale index (sign-check: higher = wealthier)
df$wealth_pc1 <- pca_wealth$x[, 1]
if (cor(df$wealth_pc1, df$log_hh_asset) < 0) df$wealth_pc1 <- -df$wealth_pc1
cat("\nCorrelation of PC1 with log household asset:", cor(df$wealth_pc1, df$log_hh_asset), "\n")
cat("Correlation of PC1 with log income:", cor(df$wealth_pc1, df$log_income), "\n")

png(file.path(fig_dir, "07_pca_wealth_scree.png"), width = 800, height = 600, res = 130)
print(fviz_eig(pca_wealth, addlabels = TRUE, main = "Wealth/livelihood PCA: scree plot"))
dev.off()

png(file.path(fig_dir, "08_pca_wealth_biplot.png"), width = 900, height = 800, res = 130)
print(fviz_pca_var(pca_wealth, col.var = "contrib", repel = TRUE,
                    title = "Wealth/livelihood PCA: variable contributions"))
dev.off()

## ---------- Cross-check PCA on Tolerance & Conflict-experience pools -------
cat("\n\n==================== CROSS-CHECK PCA: Tolerance items ====================\n")
pca_tol <- prcomp(df[c("Tol1_5","Tol2_1","Tol3_1","Tol4_5")], scale. = TRUE)
print(summary(pca_tol))
print(round(pca_tol$rotation, 3))

cat("\n\n==================== CROSS-CHECK PCA: Conflict experience items ====================\n")
pca_cp <- prcomp(df[c("CP_WB1","CP_WB2","CP_WB3","CP_WB4","CP_A1","CP_A2","CP_A3")], scale. = TRUE)
print(summary(pca_cp))
print(round(pca_cp$rotation[,1:3], 3))

sink()

saveRDS(df, file.path(root, "output/models/clean_data_with_diagnostics.rds"))
write.csv(round(pca_wealth$rotation[,1:3], 3), file.path(tab_dir, "31_pca_wealth_loadings.csv"))

cat("PCA complete. Wealth PC1 explains",
    round(summary(pca_wealth)$importance[2,1]*100,1), "% of variance.\n")
