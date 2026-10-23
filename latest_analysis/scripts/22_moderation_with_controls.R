## 22_moderation_with_controls.R -- RQ2 moderation re-estimated WITH the full control set.
## 08_moderation.R tests CE0 x {TC, IC, IB} in a model with no covariates. Because compensation
## participation is confounded with county, the interaction tests are repeated here (a) in the full
## PLS-SEM tolerance equation (all background constructs, site, PE, CA, PS as covariates) and
## (b) as an observed-score OLS with robust SEs and a joint test of the three interactions.
suppressPackageStartupMessages({ library(seminr); library(dplyr); library(sandwich); library(lmtest); library(car) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables")
mm <- constructs(
  composite("CP_WB", c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), weights = mode_B), composite("CP_A", c("CP_A1","CP_A2","CP_A3"), weights = mode_B),
  composite("PE", single_item("PE")), composite("CE0", single_item("CE0")),
  composite("CA", c("CA1","CA2","log_ca3"), weights = mode_B), composite("PS", c("PS1","PS2"), weights = mode_B),
  composite("TC", c("TC1_DamagedArea","log_econloss"), weights = mode_B), composite("IC", c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
  composite("IB", single_item("IB")), composite("Gender", single_item("gender")), composite("Age", single_item("age")),
  composite("Education", single_item("education")), composite("Income", single_item("log_income")), composite("HHAsset", single_item("log_hh_asset")),
  composite("InNP", single_item("in_np")), composite("Site", single_item("site_baoxing")),
  composite("Tol", c("Tol1_5","Tol2_1","Tol4_5"), weights = mode_A),
  interaction_term(iv = "TC", moderator = "CE0", method = two_stage),
  interaction_term(iv = "IC", moderator = "CE0", method = two_stage),
  interaction_term(iv = "IB", moderator = "CE0", method = two_stage))
ctrl <- c("CP_WB","CP_A","Gender","Age","Education","Income","HHAsset","InNP","Site","PE","CA","PS")
sm <- relationships(paths(from = c(ctrl, "TC","IC","IB","CE0","TC*CE0","IC*CE0","IB*CE0"), to = "Tol"))
m <- estimate_pls(df, mm, sm, missing = mean_replacement, maxIt = 500)
b <- bootstrap_model(m, nboot = 5000, cores = 4, seed = 20260920)
p <- as.data.frame(summary(b)$bootstrapped_paths); p$path <- rownames(p)
write.csv(p, file.path(tab_dir, "132_moderation_full_controls_paths.csv"), row.names = FALSE)
sink(file.path(tab_dir, "133_moderation_full_controls_log.txt"), split = TRUE)
cat("==== (a) PLS-SEM two-stage moderation WITH full controls; R2(Tol) =", round(summary(m)$paths["R^2","Tol"], 3), "====\n")
print(p[grepl("\\*|^TC |^IC |^IB |^CE0 |^Site ", p$path), c("path","Original Est.","Bootstrap SD","2.5% CI","97.5% CI","Bootstrap P Val")], digits = 3, row.names = FALSE)
cat("\n==== (b) OLS on observed scores, HC3 ====\n")
base <- tol_mean_no3 ~ CE0 * (tc_idx + ic_idx + IB) + cpwb_idx + PE + PS1 + PS2 + gender + age + education + log_income + log_hh_asset + in_np + site_baoxing
f1 <- lm(base, data = df); ct <- coeftest(f1, vcov = vcovHC(f1, "HC3")); print(round(ct[grepl("CE0", rownames(ct)), ], 4))
cat("\nJoint robust Wald test of the three interactions:\n")
print(linearHypothesis(f1, c("CE0:tc_idx = 0","CE0:ic_idx = 0","CE0:IB = 0"), vcov. = vcovHC(f1, "HC3")))
cat("\nSame, WITHOUT any controls (mirrors 08_moderation.R):\n")
f0 <- lm(tol_mean_no3 ~ CE0 * (tc_idx + ic_idx + IB), data = df); ct0 <- coeftest(f0, vcov = vcovHC(f0, "HC3")); print(round(ct0[grepl("CE0", rownames(ct0)), ], 4))
cat("\nSimple slopes by group (OLS with controls, fitted separately):\n")
for (g in 0:1) { fg <- lm(update(base, . ~ . - CE0 - CE0:tc_idx - CE0:ic_idx - CE0:IB), data = df[df$CE0 == g, ]); cg <- coeftest(fg, vcov = vcovHC(fg, "HC3"))
  cat("CE0 =", g, "n =", sum(df$CE0 == g), "\n"); print(round(cg[c("tc_idx","ic_idx","IB"), ], 4)) }
cat("\nDoes the county, rather than compensation, moderate? site x costs (with controls):\n")
f2 <- lm(update(base, . ~ . + site_baoxing:tc_idx + site_baoxing:ic_idx + site_baoxing:IB), data = df); c2 <- coeftest(f2, vcov = vcovHC(f2, "HC3")); print(round(c2[grepl(":", rownames(c2)), ], 4))
sink()
