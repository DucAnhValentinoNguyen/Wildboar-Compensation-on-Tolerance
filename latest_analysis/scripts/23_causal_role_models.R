## 23_causal_role_models.R -- RQ1 under explicit causal-role assumptions.
## Which constructs can be mediators of compensation participation (CE0)? Applying for
## compensation cannot change the damage a household suffered (TC) or how well its prevention
## measures work (PE), so these are confounders. Attitudes (IC, IB), compensation expectations (CA)
## and policy dependency (PS) are ambiguous: they could be consequences of applying or causes of it.
## The CE0 -> tolerance association is estimated under four nested adjustment sets:
##   S0  background only            (every other construct treated as a mediator)
##   S1  S0 + TC + PE               (primary: damage and prevention are confounders)
##   S2  S1 + IC + IB               (attitudes are confounders as well)
##   S3  S2 + CA + PS               (everything is a confounder = fully adjusted direct effect)
## (A) PLS-SEM, one structural model per role assumption; the estimand is the CE0 total effect.
## (B) OLS on the construct scores of the primary (S1) model, HC3 SEs (also used by 26_bias_analysis.R).
## (C) Mediation through the four candidate mediators in the primary model (exploratory).
## (D) RQ2 moderation re-estimated with the S1 control set.
## (E) dagitty check that each adjustment set follows from the stated DAG.
suppressPackageStartupMessages({ library(dplyr); library(seminr); library(sandwich); library(lmtest); library(car) })
## dagitty is called by namespace only: it exports its own paths(), which would mask seminr::paths().
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); mod_dir <- file.path(root, "output/models")

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
  composite("Gender", single_item("gender")), composite("Age", single_item("age")),
  composite("Education", single_item("education")), composite("Income", single_item("log_income")),
  composite("HHAsset", single_item("log_hh_asset")), composite("InNP", single_item("in_np")),
  composite("Site", single_item("site_baoxing")),
  composite("Tol",   c("Tol1_5","Tol2_1","Tol4_5"), weights = mode_A)
)
bg <- c("CP_WB","CP_A","Gender","Age","Education","Income","HHAsset","InNP","Site")
roles <- list(
  S0 = list(pre = character(0),              post = c("PE","TC","CA","PS","IC","IB")),
  S1 = list(pre = c("TC","PE"),              post = c("CA","PS","IC","IB")),
  S2 = list(pre = c("TC","PE","IC","IB"),    post = c("CA","PS")))
## Dense layered structure: background -> pre-treatment confounders -> CE0 -> candidate mediators -> Tol,
## every earlier layer pointing to every later one; no paths within a layer.
sm_for <- function(pre, post) {
  p <- list(paths(from = bg, to = c(pre, "CE0", post, "Tol")))
  if (length(pre)) p <- c(p, list(paths(from = pre, to = c("CE0", post, "Tol"))))
  p <- c(p, list(paths(from = "CE0", to = c(post, "Tol"))))
  if (length(post)) p <- c(p, list(paths(from = post, to = "Tol")))
  do.call(relationships, p)
}

## ---------------------------------------------------------------- (A) PLS-SEM per role assumption
fits <- list()
for (s in names(roles)) {
  m <- estimate_pls(df, mm, sm_for(roles[[s]]$pre, roles[[s]]$post), missing = mean_replacement, maxIt = 500)
  b <- bootstrap_model(m, nboot = 5000, cores = 4, seed = 20260920)
  fits[[s]] <- list(model = m, boot = b, sb = summary(b))
}
saveRDS(fits$S1$model, file.path(mod_dir, "plssem_causal_S1.rds"))
saveRDS(fits$S1$boot,  file.path(mod_dir, "plssem_causal_S1_boot.rds"))
p1 <- as.data.frame(fits$S1$sb$bootstrapped_paths); p1$path <- rownames(p1)
write.csv(p1, file.path(tab_dir, "141_causal_S1_paths.csv"), row.names = FALSE)

pick <- function(tbl, row) { r <- tbl[row, ]; data.frame(est = r[["Original Est."]], se = r[["Bootstrap SD"]], lo = r[["2.5% CI"]], hi = r[["97.5% CI"]], p = r[["Bootstrap P Val"]]) }
plsA <- bind_rows(
  cbind(set = "S0", effect = "total",  pick(fits$S0$sb$bootstrapped_total_paths, "CE0  ->  Tol")),
  cbind(set = "S1", effect = "total",  pick(fits$S1$sb$bootstrapped_total_paths, "CE0  ->  Tol")),
  cbind(set = "S2", effect = "total",  pick(fits$S2$sb$bootstrapped_total_paths, "CE0  ->  Tol")),
  cbind(set = "S3", effect = "direct", pick(fits$S1$sb$bootstrapped_paths,       "CE0  ->  Tol")))
r2 <- function(s) summary(fits[[s]]$model)$paths["R^2", "Tol"]
plsA$R2_Tol <- c(r2("S0"), r2("S1"), r2("S2"), r2("S1"))

sink(file.path(tab_dir, "142_causal_role_models_log.txt"), split = TRUE)
cat("==================== (A) PLS-SEM: CE0 -> tolerance under four role assumptions ====================\n")
cat("S0-S2: total effect of CE0 in the model where the named constructs come before CE0;\nS3: direct CE0 -> Tol path of the primary (S1) model (everything adjusted).\n\n")
print(plsA, digits = 3, row.names = FALSE)
cat("\nTolerance equation of the primary S1 model (identical regressors in every structure):\n")
print(p1[grepl("->  Tol$", p1$path), c("path","Original Est.","Bootstrap SD","2.5% CI","97.5% CI","Bootstrap P Val")], digits = 3, row.names = FALSE)
cat("\nCE0 equation of the primary S1 model (who applies, given background, damage, prevention):\n")
print(p1[grepl("->  CE0$", p1$path), c("path","Original Est.","2.5% CI","97.5% CI","Bootstrap P Val")], digits = 3, row.names = FALSE)
cat("\nR2 (S1):\n"); print(round(summary(fits$S1$model)$paths["R^2", ], 3))
cat("\nOuter weights of the formative constructs (S1):\n")
w <- fits$S1$model$outer_weights; print(round(w[rowSums(abs(w)) > 0 & !rownames(w) %in% c("PE","CE0","IB","gender","age","education","log_income","log_hh_asset","in_np","site_baoxing","Tol1_5","Tol2_1","Tol4_5"), c("CP_WB","CP_A","CA","PS","TC","IC")], 3))

## ---------------------------------------------------------------- (B) OLS on construct scores
sc <- as.data.frame(fits$S1$model$construct_scores); names(sc) <- paste0("s_", names(sc))
d <- bind_cols(df, sc)
saveRDS(d, file.path(mod_dir, "causal_S1_scores_data.rds"))
f_bg <- "s_CP_WB + s_CP_A + gender + age + education + log_income + log_hh_asset + in_np + site_baoxing"
sets <- list(S0 = f_bg, S1 = paste(f_bg, "+ s_TC + s_PE"), S2 = paste(f_bg, "+ s_TC + s_PE + s_IC + s_IB"),
             S3 = paste(f_bg, "+ s_TC + s_PE + s_IC + s_IB + s_CA + s_PS"))
sd_ce0 <- sd(d$CE0); sd_tol <- sd(d$s_Tol)
olsB <- bind_rows(lapply(names(sets), function(s) {
  f <- lm(as.formula(paste("s_Tol ~ CE0 +", sets[[s]])), data = d); v <- vcovHC(f, "HC3")
  ct <- coeftest(f, vcov = v); ci <- coefci(f, vcov = v)
  data.frame(set = s, b_sd = ct["CE0", 1] / sd_tol, se = ct["CE0", 2] / sd_tol, lo = ci["CE0", 1] / sd_tol, hi = ci["CE0", 2] / sd_tol,
             p = ct["CE0", 4], beta_std = ct["CE0", 1] * sd_ce0 / sd_tol, r2 = summary(f)$r.squared)
}))
cat("\n==================== (B) OLS on S1 construct scores, HC3 ====================\n")
cat("b_sd = adjusted difference in tolerance (SD units) between applicants and non-applicants;\nbeta_std = the same on the standardised scale of the PLS path coefficients.\n\n")
print(olsB, digits = 3, row.names = FALSE)
res <- bind_rows(
  data.frame(method = "PLS-SEM", plsA[, c("set","effect","est","se","lo","hi","p")]),
  data.frame(method = "OLS (SD units)", set = olsB$set, effect = ifelse(olsB$set == "S3", "direct", "total"),
             est = olsB$b_sd, se = olsB$se, lo = olsB$lo, hi = olsB$hi, p = olsB$p))
write.csv(res, file.path(tab_dir, "143_ce0_by_role_assumption.csv"), row.names = FALSE)

## ---------------------------------------------------------------- (C) mediation in the primary model
meds <- c(CA = "Compensation anticipation", PS = "Policy dependency", IC = "Intangible cost", IB = "Intangible benefit")
medC <- bind_rows(lapply(names(meds), function(mz) {
  se <- as.data.frame(specific_effect_significance(fits$S1$boot, from = "CE0", to = "Tol", through = mz))
  names(se) <- make.names(names(se))
  a <- pick(fits$S1$sb$bootstrapped_paths, paste0("CE0  ->  ", mz)); bb <- pick(fits$S1$sb$bootstrapped_paths, paste0(mz, "  ->  Tol"))
  data.frame(mediator = mz, name = meds[[mz]], ind = se$Original.Est., ind_se = se$Bootstrap.SD, ind_lo = se$X2.5..CI, ind_hi = se$X97.5..CI, ind_p = se$Bootstrap.P.Val,
             a = a$est, a_lo = a$lo, a_hi = a$hi, a_p = a$p, b = bb$est, b_lo = bb$lo, b_hi = bb$hi, b_p = bb$p, detectable_80 = 2.8 * se$Bootstrap.SD)
}))
tot <- pick(fits$S1$sb$bootstrapped_total_paths, "CE0  ->  Tol"); dir <- pick(fits$S1$sb$bootstrapped_paths, "CE0  ->  Tol")
toti <- pick(fits$S1$sb$bootstrapped_total_indirect_paths, "CE0  ->  Tol")
cat("\n==================== (C) Mediation through the four candidate mediators (primary model) ====================\n")
print(medC, digits = 3, row.names = FALSE)
cat(sprintf("\nTotal effect %.4f [%.4f, %.4f]; direct %.4f [%.4f, %.4f]; total indirect %.4f [%.4f, %.4f], p = %.4f; share indirect = %.3f\n",
            tot$est, tot$lo, tot$hi, dir$est, dir$lo, dir$hi, toti$est, toti$lo, toti$hi, toti$p, toti$est / tot$est))
write.csv(medC, file.path(tab_dir, "144_mediation_S1.csv"), row.names = FALSE)
write.csv(data.frame(quantity = c("total","direct","total_indirect"), est = c(tot$est, dir$est, toti$est), lo = c(tot$lo, dir$lo, toti$lo),
                     hi = c(tot$hi, dir$hi, toti$hi), p = c(tot$p, dir$p, toti$p)), file.path(tab_dir, "145_mediation_S1_summary.csv"), row.names = FALSE)
cat("\nDamage and prevention as confounders in S1 -- paths into CE0 and into tolerance:\n")
print(p1[p1$path %in% c("TC  ->  CE0","PE  ->  CE0","TC  ->  Tol","PE  ->  Tol","TC  ->  IC","TC  ->  IB"), c("path","Original Est.","2.5% CI","97.5% CI","Bootstrap P Val")], digits = 3, row.names = FALSE)

## ---------------------------------------------------------------- (D) RQ2 moderation with the S1 control set
fD <- lm(as.formula(paste("s_Tol ~ CE0 * (s_TC + s_IC + s_IB) +", f_bg, "+ s_PE")), data = d)
ctD <- coeftest(fD, vcov = vcovHC(fD, "HC3"))
cat("\n==================== (D) RQ2 moderation, S1 controls (OLS on construct scores, HC3) ====================\n")
print(round(ctD[grepl("CE0", rownames(ctD)), ], 4))
jt <- linearHypothesis(fD, c("CE0:s_TC = 0","CE0:s_IC = 0","CE0:s_IB = 0"), vcov. = vcovHC(fD, "HC3"))
cat(sprintf("Joint robust Wald test of the three interactions: F = %.3f, p = %.3f\n", jt$F[2], jt$`Pr(>F)`[2]))
write.csv(data.frame(term = rownames(ctD)[grepl("CE0", rownames(ctD))], ctD[grepl("CE0", rownames(ctD)), ], check.names = FALSE),
          file.path(tab_dir, "146_moderation_S1_controls.csv"), row.names = FALSE)

## ---------------------------------------------------------------- (E) DAG check of the adjustment sets
## B = background block (conflict experience, demographics, county, park residence).
common <- "B -> {TC PE CE0 CA PS IC IB Tol}\n PE -> TC\n {TC PE} -> {CA PS IC IB Tol}\n {CA PS IC IB} -> Tol\n CE0 -> Tol\n"
dags <- list(
  S0 = paste0("dag {\n", "B -> {TC PE CE0 CA PS IC IB Tol}\n PE -> TC\n CE0 -> {TC PE CA PS IC IB Tol}\n {TC PE CA PS IC IB} -> Tol\n }"),
  S1 = paste0("dag {\n", common, " {TC PE} -> CE0\n CE0 -> {CA PS IC IB}\n }"),
  S2 = paste0("dag {\n", common, " {TC PE IC IB} -> CE0\n CE0 -> {CA PS}\n }"),
  S3 = paste0("dag {\n", common, " {TC PE IC IB CA PS} -> CE0\n }"))
cat("\n==================== (E) Minimal adjustment sets implied by each DAG (total effect CE0 -> Tol) ====================\n")
for (s in names(dags)) {
  g <- dagitty::dagitty(dags[[s]]); a <- dagitty::adjustmentSets(g, exposure = "CE0", outcome = "Tol", type = "minimal", effect = "total")
  cat(s, ":", paste(sapply(a, function(x) paste0("{", paste(sort(x), collapse = ", "), "}")), collapse = " or "), "\n")
}
sink()
