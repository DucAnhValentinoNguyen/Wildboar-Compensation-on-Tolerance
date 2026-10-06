## 04_cfa.R -- Confirmatory Factor Analysis
## Focus: Tolerance is the only block the theory claims is REFLECTIVE and
## unidimensional. EFA (03_efa.R) found weak internal consistency (raw alpha
## = 0.34) and Tol3 essentially uncorrelated with the other 3 items. Here we
## formally compare nested CFA specifications for Tolerance using ordinal
## (WLSMV) estimation, since items are 5-point Likert.
suppressPackageStartupMessages({
  library(dplyr); library(lavaan); library(semTools)
})

root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
df <- readRDS(file.path(root, "output/models/clean_data.rds"))
tab_dir <- file.path(root, "output/tables")

sink(file.path(tab_dir, "20_cfa_log.txt"))

ordered_vars <- c("Tol1_5","Tol2_1","Tol3_1","Tol4_5")

## Model A: unidimensional 4-item Tolerance (matches original WTM assumption)
mA <- 'Tol =~ Tol1_5 + Tol2_1 + Tol3_1 + Tol4_5'
fitA <- cfa(mA, data = df, ordered = ordered_vars, estimator = "WLSMV")
cat("\n==================== MODEL A: 4-item unidimensional ====================\n")
print(summary(fitA, fit.measures = TRUE, standardized = TRUE))

## Model B: 3-item Tolerance, Tol3 dropped (EFA-informed)
mB <- 'Tol =~ Tol1_5 + Tol2_1 + Tol4_5'
fitB <- cfa(mB, data = df, ordered = c("Tol1_5","Tol2_1","Tol4_5"), estimator = "WLSMV")
cat("\n==================== MODEL B: 3-item (Tol3 dropped) ====================\n")
print(summary(fitB, fit.measures = TRUE, standardized = TRUE))
cat("Reliability (omega), Model B:\n")
print(reliability(fitB))

## Model C: two correlated facets -- Tol1+Tol2 (stated policy/management
## preference) vs Tol4 (personal cost acceptance); Tol3 excluded (personal
## safety threat perception - conceptually a risk-perception item, not a
## tolerance-preference item, consistent with its near-zero item-total r).
## Tol4 alone cannot be its own reflective factor (needs >=2 indicators), so
## this is reported as a correlation between Tol1+Tol2 composite and Tol4
## rather than as a formal 2-factor CFA.
cat("\n==================== Tol1+Tol2 vs Tol4: correlation check ====================\n")
tol12 <- rowMeans(df[c("Tol1_5","Tol2_1")])
print(cor.test(tol12, df$Tol4_5, method = "spearman"))

## Model D: Tolerance CFA embedded with Intangible Benefit (IB, single-item)
## and a 1-factor Intangible Cost (IC1+IC2_1, dropping the high-missingness
## IC2_3 and near-zero-loading IC2_2 per EFA) to check discriminant validity
## (HTMT / factor correlations) between Tolerance and the cost/benefit side.
mD <- '
  Tol =~ Tol1_5 + Tol2_1 + Tol4_5
  ICr =~ IC1 + IC2_1
'
fitD <- cfa(mD, data = df, ordered = c("Tol1_5","Tol2_1","Tol4_5","IC1","IC2_1"),
            estimator = "WLSMV")
cat("\n==================== MODEL D: Tolerance + reflective IC subset, discriminant check ====================\n")
print(summary(fitD, fit.measures = TRUE, standardized = TRUE))
cat("HTMT (Tol vs reflective-IC subset):\n")
print(htmt(mD, data = df, ordered = c("Tol1_5","Tol2_1","Tol4_5","IC1","IC2_1")))

## Model comparison table
fit_compare <- function(fit, label) {
  wanted <- c("chisq.scaled","df.scaled","pvalue.scaled",
              "cfi.scaled","tli.scaled","rmsea.scaled","srmr")
  m <- fitMeasures(fit)
  vals <- setNames(rep(NA_real_, length(wanted)), wanted)
  present <- intersect(wanted, names(m))
  vals[present] <- m[present]
  data.frame(model = label, t(round(vals, 3)))
}
comp_tbl <- bind_rows(
  fit_compare(fitA, "A: Tolerance 4-item"),
  fit_compare(fitB, "B: Tolerance 3-item (drop Tol3, saturated df=0)")
)
write.csv(comp_tbl, file.path(tab_dir, "21_cfa_model_comparison.csv"), row.names = FALSE)

sink()
cat("CFA complete. See output/tables/20_cfa_log.txt\n")
print(comp_tbl)
