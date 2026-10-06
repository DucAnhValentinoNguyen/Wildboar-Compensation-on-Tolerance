## 20: measurement-error sensitivity for ALL five mediators at once (extends 15_pitfall_checks.R part C).
## Each mediator score is treated as a noisy proxy of a latent mediator with assumed reliability rel
## (error variance fixed at (1-rel)*var). Tolerance = ordinal latent factor (Tol1, Tol2, Tol4).
suppressPackageStartupMessages({ library(dplyr); library(lavaan) })
root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
model0 <- readRDS(file.path(root, "output/models/plssem_model0_full.rds"))
sc <- as.data.frame(model0$construct_scores); names(sc) <- paste0("s_", names(sc))
d <- bind_cols(df, sc)
d$Tol1o <- ordered(d$Tol1_5); d$Tol2o <- ordered(d$Tol2_1); d$Tol4o <- ordered(d$Tol4_5)
for (v in c("gender","age","education","log_income","log_hh_asset","in_np")) d[[paste0("z_", v)]] <- as.numeric(scale(d[[v]]))
zc <- "s_CP_WB + s_CP_A + z_gender + z_age + z_education + z_log_income + z_log_hh_asset + z_in_np + site_baoxing + s_PE"
meds <- c(CA = "s_CA", PS = "s_PS", TC = "s_TC", IC = "s_IC", IB = "s_IB")
fit_rel <- function(rel) {
  lat <- paste0(sprintf("L%s =~ 1*%s\n%s ~~ %f*%s\n", names(meds), meds, meds, (1 - rel) * sapply(meds, function(v) var(d[[v]])), meds), collapse = "")
  reg <- paste0(sprintf("L%s ~ a%s*CE0 + %s\n", names(meds), names(meds), zc), collapse = "")
  tol <- paste0("Tol =~ Tol1o + Tol2o + Tol4o\nTol ~ c*CE0 + ", paste0(sprintf("b%s*L%s", names(meds), names(meds)), collapse = " + "), " + ", zc, "\n")
  cov <- paste0("LCA ~~ LPS + LTC + LIC + LIB\nLPS ~~ LTC + LIC + LIB\nLTC ~~ LIC + LIB\nLIC ~~ LIB\n")
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
write.csv(res, file.path(root, "output/tables/131_latent_all_mediators.csv"), row.names = FALSE)
print(res %>% filter(grepl("^ind_|totind|^c$", term)) %>% mutate(across(where(is.numeric), ~round(., 3))))
print(res %>% filter(reliability == .7, grepl("^a_", term)) %>% mutate(across(where(is.numeric), ~round(., 3))))
