## 03_efa.R -- Exploratory Factor Analysis
## Purpose: empirically test the dimensionality the original WTM measurement
## model assumed a priori (Tolerance as one reflective factor; Intangible
## Cost as one formative block combining IC1 + three word-ratings; Conflict
## Experience as two formative blocks), before committing to a CFA/PLS-SEM
## specification.
suppressPackageStartupMessages({
  library(dplyr); library(psych); library(GPArotation)
})

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data.rds"))
tab_dir <- file.path(root, "output/tables"); fig_dir <- file.path(root, "output/figures")

sink(file.path(tab_dir, "10_efa_log.txt"))

## ---------- Block 1: Tolerance items ---------------------------------------
cat("\n\n==================== TOLERANCE ITEMS ====================\n")
tol_items <- df %>% select(Tol1_5, Tol2_1, Tol3_1, Tol4_5)
print(KMO(tol_items))
print(cortest.bartlett(cor(tol_items), n = nrow(tol_items)))
print(alpha(tol_items))
fa_tol <- fa(tol_items, nfactors = 1, fm = "ml")
print(fa_tol$loadings)
cat("Alt: drop Tol3 -> alpha & unidimensionality\n")
print(alpha(df %>% select(Tol1_5, Tol2_1, Tol4_5)))

## ---------- Block 2: Intangible Cost items ---------------------------------
cat("\n\n==================== INTANGIBLE COST ITEMS ====================\n")
ic_items <- df %>% select(IC1, IC2_1, IC2_2, IC2_3)
print(KMO(ic_items[complete.cases(ic_items), ]))
pa_ic <- fa.parallel(ic_items, fm = "ml", fa = "fa", plot = FALSE, n.iter = 200)
cat("Parallel analysis suggested # factors:", pa_ic$nfact, "\n")
fa_ic2 <- fa(ic_items, nfactors = 2, fm = "ml", rotate = "oblimin")
print(fa_ic2$loadings)
fa_ic1 <- fa(ic_items, nfactors = 1, fm = "ml")
print(fa_ic1$loadings)

## ---------- Block 3: Conflict Experience (WB + All combined pool) ---------
cat("\n\n==================== CONFLICT EXPERIENCE ITEMS ====================\n")
cp_items <- df %>% select(CP_WB1, CP_WB2, CP_WB3, CP_WB4, CP_A1, CP_A2, CP_A3)
print(KMO(cp_items))
pa_cp <- fa.parallel(cp_items, fm = "ml", fa = "fa", plot = FALSE, n.iter = 200)
cat("Parallel analysis suggested # factors:", pa_cp$nfact, "\n")
fa_cp2 <- fa(cp_items, nfactors = 2, fm = "ml", rotate = "oblimin")
print(fa_cp2$loadings)

## ---------- Block 4: Policy Support + Compensation Anticipation -----------
cat("\n\n==================== PS + CA ITEMS ====================\n")
psca_items <- df %>% select(PS1, PS2, CA1, CA2)
print(KMO(psca_items))
fa_psca <- fa(psca_items, nfactors = 2, fm = "ml", rotate = "oblimin")
print(fa_psca$loadings)

## ---------- Block 5: full reflective-candidate pool (overall structure) ---
cat("\n\n==================== FULL POOL (all Likert reflective candidates) ====================\n")
full_items <- df %>% select(CP_WB1, CP_WB2, CP_WB3, CP_WB4, CP_A1, CP_A2, CP_A3,
                             IC1, IC2_1, IC2_2, IC2_3, IB,
                             Tol1_5, Tol2_1, Tol3_1, Tol4_5, PS1, PS2)
pa_full <- fa.parallel(full_items, fm = "ml", fa = "fa", plot = FALSE, n.iter = 200)
cat("Parallel analysis suggested # factors:", pa_full$nfact, "\n")
fa_full <- fa(full_items, nfactors = pa_full$nfact, fm = "ml", rotate = "oblimin")
print(fa_full$loadings, cutoff = .30)

sink()

## Save scree plot for the full pool
png(file.path(fig_dir, "06_efa_scree_full_pool.png"), width = 900, height = 650, res = 130)
fa.parallel(full_items, fm = "ml", fa = "fa", n.iter = 200,
            main = "Parallel analysis: full WTM Likert item pool")
dev.off()

## Save loadings tables as CSV for the report
write.csv(round(unclass(fa_tol$loadings), 3), file.path(tab_dir, "11_efa_tolerance_1factor.csv"))
write.csv(round(unclass(fa_ic2$loadings), 3), file.path(tab_dir, "12_efa_intangiblecost_2factor.csv"))
write.csv(round(unclass(fa_cp2$loadings), 3), file.path(tab_dir, "13_efa_conflictexp_2factor.csv"))
write.csv(round(unclass(fa_full$loadings), 3), file.path(tab_dir, "14_efa_fullpool.csv"))

cat("EFA complete. See output/tables/10_efa_log.txt for full console output.\n")
