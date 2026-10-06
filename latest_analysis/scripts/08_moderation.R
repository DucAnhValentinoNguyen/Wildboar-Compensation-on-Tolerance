## 08_moderation.R -- RQ2: do Tangible Cost, Intangible Cost and Intangible
## Benefit paths to Tolerance depend on (interact with) compensation
## participation? Two-stage moderation in PLS-SEM (Henseler & Chin 2010;
## Hair et al. Primer on PLS-SEM ch.7). CE0 (compensation participation) is
## used as the moderator (available for the full n=625 sample); the more
## detailed Compensation Experience (timeliness/satisfaction) construct only
## exists for the with-compensation subgroup and is tested separately in a
## subgroup model (09_multigroup_robustness.R).
suppressPackageStartupMessages({ library(seminr); library(dplyr) })

root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); mod_dir <- file.path(root, "output/models")

mm <- constructs(
  composite("TC", c("TC1_DamagedArea","log_econloss"), weights = mode_B),
  composite("IC", c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
  composite("IB", single_item("IB")),
  composite("CE0", single_item("CE0")),
  composite("Tol", c("Tol1_5","Tol2_1","Tol4_5"), weights = mode_A),
  interaction_term(iv = "TC", moderator = "CE0", method = two_stage),
  interaction_term(iv = "IC", moderator = "CE0", method = two_stage),
  interaction_term(iv = "IB", moderator = "CE0", method = two_stage)
)

sm <- relationships(
  paths(from = c("TC","IC","IB","CE0","TC*CE0","IC*CE0","IB*CE0"), to = "Tol")
)

mod_model <- estimate_pls(data = df, measurement_model = mm, structural_model = sm,
                           missing = mean_replacement, maxIt = 500)
boot_mod <- bootstrap_model(mod_model, nboot = 5000, cores = 4, seed = 20260920)
sb <- summary(boot_mod)

sink(file.path(tab_dir, "60_moderation_log.txt"))
cat("==================== RQ2: Moderation of CE0 on TC/IC/IB -> Tolerance ====================\n")
print(sb$bootstrapped_paths)
cat("\nR^2:\n"); print(summary(mod_model)$paths)
sink()

write.csv(as.data.frame(sb$bootstrapped_paths), file.path(tab_dir, "61_moderation_paths.csv"))
saveRDS(boot_mod, file.path(mod_dir, "plssem_boot_moderation.rds"))

cat("Moderation analysis complete.\n")
print(sb$bootstrapped_paths)
