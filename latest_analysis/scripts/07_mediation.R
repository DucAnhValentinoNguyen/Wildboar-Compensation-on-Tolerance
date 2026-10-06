## 07_mediation.R -- RQ1: Does compensation participation act on tolerance
## directly, or through other social/psychological mediators?
## Uses bootstrapped specific-indirect-effect tests (Nitzl, Roldan & Cepeda
## 2016 approach) through each Tier-2 mediator that sits between
## Compensation Participation (CE0) and Tolerance.
suppressPackageStartupMessages({ library(seminr); library(dplyr) })

root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
tab_dir <- file.path(root, "output/tables")
boot0 <- readRDS(file.path(root, "output/models/plssem_boot0_full.rds"))

mediators <- c("CA","PS","TC","IC","IB")

sink(file.path(tab_dir, "50_mediation_log.txt"))
cat("==================== RQ1: CE0 -> Tolerance mediation decomposition ====================\n\n")

res_list <- lapply(mediators, function(m) {
  se <- specific_effect_significance(boot0, from = "CE0", to = "Tol", through = m)
  cat("--- Through", m, "---\n"); print(se); cat("\n")
  se_df <- as.data.frame(se)
  se_df$mediator <- m
  se_df
})
indirect_tbl <- bind_rows(res_list)
names(indirect_tbl) <- make.names(names(indirect_tbl))
write.csv(indirect_tbl, file.path(tab_dir, "51_mediation_indirect_effects.csv"), row.names = FALSE)

## Direct effect CE0 -> Tol
direct <- summary(boot0)$bootstrapped_paths["CE0  ->  Tol", , drop = FALSE]
cat("\n--- Direct effect: CE0 -> Tol ---\n"); print(direct)

total_indirect <- sum(indirect_tbl$Original.Est., na.rm = TRUE)
direct_est <- direct[1, "Original Est."]
total_effect <- direct_est + total_indirect
vaf <- total_indirect / total_effect

cat("\nTotal indirect effect (sum across 5 mediators):", round(total_indirect, 4), "\n")
cat("Direct effect:", round(direct_est, 4), "\n")
cat("Total effect (direct + total indirect):", round(total_effect, 4), "\n")
cat("VAF (Variance Accounted For by mediators) =", round(vaf, 3), "\n")
if (abs(direct_est) > 1.96 * direct[1, "Bootstrap SD"] & total_indirect != 0) {
  cat("-> Pattern: COMPLEMENTARY (partial) mediation -- both direct and indirect paths present.\n")
}

sink()

summary_tbl <- data.frame(
  quantity = c("Direct effect (CE0->Tol)", "Total indirect effect", "Total effect", "VAF"),
  value = round(c(direct_est, total_indirect, total_effect, vaf), 4)
)
write.csv(summary_tbl, file.path(tab_dir, "52_mediation_summary.csv"), row.names = FALSE)

cat("Mediation analysis complete.\n"); print(summary_tbl)
