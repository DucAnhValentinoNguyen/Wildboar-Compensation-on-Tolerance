## 29_decision_alternatives.R -- the compensation -> tolerance association under the alternatives we
## did NOT choose. For each analytic decision of the report, the primary estimate (adjustment set S1 of
## 23_causal_role_models.R: background + damage + prevention) is re-estimated with the alternative
## choice, so that the report can state whether the decision matters.
## (A) PLS-SEM variants of the measurement model, the data, and the controls (total and direct effect of
##     CE0 on tolerance, plus the intangible cost -> tolerance path used in RQ2).
## (B) Regression variants of the estimation framework on the construct scores of the primary model:
##     robust vs village- and township-clustered standard errors, a village random intercept, other
##     outcome definitions, ordinal models of the single tolerance items, and farm-structure controls.
suppressPackageStartupMessages({ library(dplyr); library(seminr); library(sandwich); library(lmtest) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
tab_dir <- file.path(root, "output/tables")
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
df <- df %>% mutate(log_cropland = log1p(total_cropland), log_potato = log1p(Q10_PotatoArea), log_livestock = log1p(total_livestock))

## ------------------------------------------------------------------------------------------ (A) PLS-SEM
mk_mm <- function(tol = c("Tol1_5","Tol2_1","Tol4_5"), tol_w = mode_A, ic = "full", site = TRUE, money = "log", ca = c("CA1","CA2"), farm = FALSE) {
  ic_c <- switch(ic, full = composite("IC", c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
                     two  = composite("IC", c("IC1","IC2_1"), weights = mode_B),
                     one  = composite("IC", single_item("IC1")))
  tc_c <- if (money == "log") composite("TC", c("TC1_DamagedArea","log_econloss"), weights = mode_B) else composite("TC", c("TC1_DamagedArea","TC2_EconomicLoss"), weights = mode_B)
  ca_c <- if (money == "log") composite("CA", c(ca, "log_ca3"), weights = mode_B) else composite("CA", c(ca, "CA3"), weights = mode_B)
  inc  <- if (money == "log") single_item("log_income") else single_item("income")
  ass  <- if (money == "log") single_item("log_hh_asset") else single_item("hh_asset")
  parts <- list(
    composite("CP_WB", c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), weights = mode_B), composite("CP_A", c("CP_A1","CP_A2","CP_A3"), weights = mode_B),
    composite("PE", single_item("PE")), composite("CE0", single_item("CE0")), ca_c, composite("PS", c("PS1","PS2"), weights = mode_B), tc_c, ic_c,
    composite("IB", single_item("IB")), composite("Gender", single_item("gender")), composite("Age", single_item("age")),
    composite("Education", single_item("education")), composite("Income", inc), composite("HHAsset", ass), composite("InNP", single_item("in_np")),
    composite("Tol", tol, weights = tol_w))
  if (site) parts <- c(parts, list(composite("Site", single_item("site_baoxing"))))
  if (farm) parts <- c(parts, list(composite("Cropland", single_item("log_cropland")), composite("Potato", single_item("log_potato")),
                                   composite("Livestock", single_item("log_livestock")), composite("HHSize", single_item("hh_pop")), composite("AgriShare", single_item("agri_prop"))))
  do.call(constructs, parts)
}
bg_for <- function(site = TRUE, farm = FALSE) c("CP_WB","CP_A","Gender","Age","Education","Income","HHAsset","InNP", if (site) "Site", if (farm) c("Cropland","Potato","Livestock","HHSize","AgriShare"))
fit_s1 <- function(data, mm, bg, label, nboot = 2000) {
  pre <- c("TC","PE"); post <- c("CA","PS","IC","IB")
  sm <- relationships(paths(from = bg, to = c(pre, "CE0", post, "Tol")), paths(from = pre, to = c("CE0", post, "Tol")),
                      paths(from = "CE0", to = c(post, "Tol")), paths(from = post, to = "Tol"))
  m <- estimate_pls(data, mm, sm, missing = mean_replacement, maxIt = 500)
  b <- bootstrap_model(m, nboot = nboot, cores = 16, seed = 20260920); sb <- summary(b)
  g <- function(tbl, row) { r <- tbl[row, ]; c(r[["Original Est."]], r[["2.5% CI"]], r[["97.5% CI"]], r[["Bootstrap P Val"]]) }
  tot <- g(sb$bootstrapped_total_paths, "CE0  ->  Tol"); dir <- g(sb$bootstrapped_paths, "CE0  ->  Tol"); ic <- g(sb$bootstrapped_paths, "IC  ->  Tol")
  cat("done:", label, "\n")
  data.frame(variant = label, n = nrow(data), total = tot[1], total_lo = tot[2], total_hi = tot[3], total_p = tot[4],
             direct = dir[1], direct_lo = dir[2], direct_hi = dir[3], ic_tol = ic[1], ic_lo = ic[2], ic_hi = ic[3], r2 = summary(m)$paths["R^2", "Tol"])
}
df_w <- df %>% mutate(CA1 = CA1_w, CA2 = CA2_w)
pls <- bind_rows(
  fit_s1(df, mk_mm(), bg_for(), "Primary model"),
  fit_s1(df, mk_mm(tol = c("Tol1_5","Tol2_1","Tol3_1","Tol4_5")), bg_for(), "Tolerance with all four items"),
  fit_s1(df, mk_mm(tol_w = mode_B), bg_for(), "Tolerance as formative construct"),
  fit_s1(df, mk_mm(ic = "two"), bg_for(), "Intangible cost from two complete items"),
  fit_s1(df, mk_mm(ic = "one"), bg_for(), "Intangible cost from the general attitude only"),
  fit_s1(df_w, mk_mm(), bg_for(), "Expected compensation capped at 100%"),
  fit_s1(df %>% filter(maha_p >= .001), mk_mm(), bg_for(), "Multivariate outliers excluded"),
  fit_s1(df, mk_mm(money = "raw"), bg_for(), "Money variables on the original scale"),
  fit_s1(df, mk_mm(site = FALSE), bg_for(site = FALSE), "County not adjusted for"),
  fit_s1(df, mk_mm(farm = TRUE), bg_for(farm = TRUE), "Farm structure added as controls"))
write.csv(pls, file.path(tab_dir, "180_alternatives_pls.csv"), row.names = FALSE)

## ------------------------------------------------------------------------------------- (B) regression
d <- readRDS(file.path(root, "output/models/causal_S1_scores_data.rds"))
d <- d %>% mutate(log_cropland = log1p(total_cropland), log_potato = log1p(Q10_PotatoArea), log_livestock = log1p(total_livestock),
                  township_f = factor(paste(county, township)))
rhs <- "CE0 + s_CP_WB + s_CP_A + gender + age + education + log_income + log_hh_asset + in_np + site_baoxing + s_TC + s_PE"
f_main <- as.formula(paste("s_Tol ~", rhs))
sdt <- sd(d$s_Tol)
row_lm <- function(variant, fit, vc, scale = "SD of tolerance", term = "CE0", div = 1) {
  ct <- coeftest(fit, vcov = vc); ci <- coefci(fit, vcov = vc)
  data.frame(variant = variant, scale = scale, est = ct[term, 1] / div, lo = ci[term, 1] / div, hi = ci[term, 2] / div, p = ct[term, 4])
}
m1 <- lm(f_main, data = d)
reg <- bind_rows(
  row_lm("Primary: heteroscedasticity-robust errors", m1, vcovHC(m1, "HC3")),
  row_lm("Errors clustered by village", m1, vcovCL(m1, cluster = d$village_f, type = "HC1")),
  row_lm("Errors clustered by township", m1, vcovCL(m1, cluster = d$township_f, type = "HC1")))
## random intercept for village
m_re <- lme4::lmer(update(f_main, . ~ . + (1 | village_f)), data = d, REML = TRUE)
fe <- lme4::fixef(m_re)["CE0"]; se <- sqrt(diag(as.matrix(vcov(m_re))))["CE0"]
reg <- bind_rows(reg, data.frame(variant = "Village random intercept (multilevel)", scale = "SD of tolerance", est = fe, lo = fe - 1.96 * se, hi = fe + 1.96 * se, p = 2 * pnorm(-abs(fe / se))))
m0 <- lme4::lmer(s_Tol ~ 1 + (1 | village_f), data = d); vc <- as.data.frame(lme4::VarCorr(m0))
icc_v <- vc$vcov[1] / sum(vc$vcov)
m0t <- lme4::lmer(s_Tol ~ 1 + (1 | township_f), data = d); vct <- as.data.frame(lme4::VarCorr(m0t)); icc_t <- vct$vcov[1] / sum(vct$vcov)
m0r <- lme4::lmer(update(f_main, . ~ . + (1 | village_f)), data = d); vr <- as.data.frame(lme4::VarCorr(m0r)); icc_v_adj <- vr$vcov[1] / sum(vr$vcov)
## other outcome definitions
d$tol4 <- as.numeric(scale(d$tol_mean)); d$tol1 <- as.numeric(scale(d$Tol1_5)); d$tol2 <- as.numeric(scale(d$Tol2_1)); d$tol4only <- as.numeric(scale(d$Tol4_5))
for (o in list(c("tol4", "Four-item mean (Tol3 kept)"), c("tol1", "Single item: non-lethal management (Tol1)"), c("tol2", "Single item: stricter control (Tol2)"), c("tol4only", "Single item: acceptance of damage (Tol4)"))) {
  fm <- as.formula(paste(o[1], "~", rhs)); fit <- lm(fm, data = d)
  reg <- bind_rows(reg, row_lm(o[2], fit, vcovHC(fit, "HC3")))
}
## ordinal logistic model of each of the three tolerance items
for (it in c("Tol1_5","Tol2_1","Tol4_5")) {
  d$y_ord <- factor(d[[it]], ordered = TRUE)
  fit <- ordinal::clm(as.formula(paste("y_ord ~", rhs)), data = d)
  s <- summary(fit)$coefficients["CE0", ]
  reg <- bind_rows(reg, data.frame(variant = paste("Ordinal logistic model,", c(Tol1_5 = "Tol1", Tol2_1 = "Tol2", Tol4_5 = "Tol4")[it]), scale = "log odds",
                                   est = s[1], lo = s[1] - 1.96 * s[2], hi = s[1] + 1.96 * s[2], p = s[4]))
}
## farm structure
fit_f <- lm(update(f_main, . ~ . + log_cropland + log_potato + log_livestock + hh_pop + agri_prop), data = d)
reg <- bind_rows(reg, row_lm("Farm structure added as controls", fit_f, vcovHC(fit_f, "HC3")))
rownames(reg) <- NULL
write.csv(reg, file.path(tab_dir, "181_alternatives_regression.csv"), row.names = FALSE)
write.csv(data.frame(quantity = c("ICC village (null model)", "ICC township (null model)", "ICC village (after covariates)", "villages", "townships"),
                     value = c(icc_v, icc_t, icc_v_adj, nlevels(d$village_f), nlevels(d$township_f))), file.path(tab_dir, "182_clustering.csv"), row.names = FALSE)

sink(file.path(tab_dir, "183_alternatives_log.txt"), split = TRUE)
cat("==== (A) PLS-SEM variants: CE0 -> tolerance (S1 structure) ====\n"); print(pls, digits = 3, row.names = FALSE)
cat("\n==== (B) Regression variants ====\n"); print(reg, digits = 3, row.names = FALSE)
cat(sprintf("\nICC village %.3f (townships %.3f; village after covariates %.3f); %d villages, %d townships\n", icc_v, icc_t, icc_v_adj, nlevels(d$village_f), nlevels(d$township_f)))
cat("\nFarm-structure controls in the regression:\n"); print(round(coeftest(fit_f, vcov = vcovHC(fit_f, "HC3"))[c("CE0","log_cropland","log_potato","log_livestock","hh_pop","agri_prop"), ], 4))
sink()
## The figure of these alternatives is drawn in 28_report_figures_causal.R from the two CSV files written above.
