## 27_latent_mediators.R -- measurement-error sensitivity for the four candidate mediators of the
## primary causal-role model (23_causal_role_models.R): compensation anticipation (CA), policy dependency
## (PS), intangible cost (IC) and intangible benefit (IB). Damage (TC) and prevention effectiveness (PE)
## are confounders, so they enter as covariates, not as mediators.
## Each mediator score is treated as a noisy proxy of a latent mediator with assumed reliability rel
## (error variance fixed at (1 - rel) * var); tolerance is an ordinal latent factor (Tol1, Tol2, Tol4), WLSMV.
suppressPackageStartupMessages({ library(dplyr); library(lavaan) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
d <- readRDS(file.path(root, "output/models/causal_S1_scores_data.rds"))
d$Tol1o <- ordered(d$Tol1_5); d$Tol2o <- ordered(d$Tol2_1); d$Tol4o <- ordered(d$Tol4_5)
for (v in c("gender","age","education","log_income","log_hh_asset","in_np")) d[[paste0("z_", v)]] <- as.numeric(scale(d[[v]]))
zc <- "s_CP_WB + s_CP_A + z_gender + z_age + z_education + z_log_income + z_log_hh_asset + z_in_np + site_baoxing + s_TC + s_PE"
meds <- c(CA = "s_CA", PS = "s_PS", IC = "s_IC", IB = "s_IB")
fit_rel <- function(rel) {
  lat <- paste0(sprintf("L%s =~ 1*%s\n%s ~~ %f*%s\n", names(meds), meds, meds, (1 - rel) * sapply(meds, function(v) var(d[[v]])), meds), collapse = "")
  reg <- paste0(sprintf("L%s ~ a%s*CE0 + %s\n", names(meds), names(meds), zc), collapse = "")
  tol <- paste0("Tol =~ Tol1o + Tol2o + Tol4o\nTol ~ c*CE0 + ", paste0(sprintf("b%s*L%s", names(meds), names(meds)), collapse = " + "), " + ", zc, "\n")
  cov <- "LCA ~~ LPS + LIC + LIB\nLPS ~~ LIC + LIB\nLIC ~~ LIB\n"
  ind <- paste0(sprintf("ind%s := a%s*b%s\n", names(meds), names(meds), names(meds)), collapse = "")
  tot <- paste0("totind := ", paste0(sprintf("a%s*b%s", names(meds), names(meds)), collapse = " + "), "\n")
  f <- sem(paste(lat, reg, tol, cov, ind, tot), data = d, estimator = "WLSMV", ordered = c("Tol1o","Tol2o","Tol4o"))
  pe <- standardizedSolution(f)
  g <- function(l) pe[pe$label == l, c("est.std","ci.lower","ci.upper","pvalue")]
  rows <- c(list(c = g("c")), setNames(lapply(names(meds), function(m) g(paste0("a", m))), paste0("a_", names(meds))),
            setNames(lapply(names(meds), function(m) g(paste0("b", m))), paste0("b_", names(meds))),
            setNames(lapply(names(meds), function(m) g(paste0("ind", m))), paste0("ind_", names(meds))), list(totind = g("totind")))
  out <- do.call(rbind, lapply(names(rows), function(n) cbind(term = n, rows[[n]]))); cbind(reliability = rel, out)
}
res <- bind_rows(lapply(c(1, .9, .8, .7, .6), fit_rel)); rownames(res) <- NULL
write.csv(res, file.path(root, "output/tables/147_latent_mediators_S1.csv"), row.names = FALSE)
sink(file.path(root, "output/tables/148_latent_mediators_S1_log.txt"), split = TRUE)
cat("Indirect effects (standardised), direct effect c, by assumed reliability of the four mediator scores:\n")
print(res %>% filter(grepl("^ind_|totind|^c$", term)) %>% mutate(across(where(is.numeric), ~round(., 3))))
cat("\nFirst legs (CE0 -> mediator) and second legs (mediator -> Tol):\n")
print(res %>% filter(grepl("^a_|^b_", term)) %>% mutate(across(where(is.numeric), ~round(., 3))))
sink()
