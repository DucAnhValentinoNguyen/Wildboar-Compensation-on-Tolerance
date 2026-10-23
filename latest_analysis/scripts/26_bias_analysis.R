## 26_bias_analysis.R -- quantitative bias analysis for unmeasured confounding of the
## compensation -> tolerance association (the qualitative part is a table in the report).
## (a) Omitted-variable sensitivity (Cinelli & Hazlett 2020, sensemakr) for the OLS estimate under the
##     primary control set S1 and the larger set S2: robustness values, and how far the estimate would move
##     if a hidden confounder were 1, 2 or 3 times as strong as county, damage or (S2) attitude.
## (b) E-value (VanderWeele & Ding 2017) for the standardised difference and its confidence limit.
## (c) Contour figure of the adjusted estimate (plain-language labels) for the report.
## Uses the construct scores of the primary model saved by 23_causal_role_models.R.
suppressPackageStartupMessages({ library(dplyr); library(sensemakr); library(EValue); library(ggplot2) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
tab_dir <- file.path(root, "output/tables"); fig_dir <- file.path(root, "output/figures")
## Optional second copy of every figure in the report folder; skipped when that folder does not exist.
rep_dir <- file.path(root, "..", "docs", "Schreiben_Wild_boar_compensation_and_tolerance", "figures")
rep_fig <- if (dir.exists(rep_dir)) normalizePath(rep_dir) else NULL
d <- readRDS(file.path(root, "output/models/causal_S1_scores_data.rds"))
b <- d %>% transmute(Tolerance = s_Tol, Compensation = CE0, ConflictWildBoar = s_CP_WB, ConflictAll = s_CP_A,
                     Gender = gender, Age = age, Education = education, Income = log_income, Assets = log_hh_asset,
                     Park = in_np, County = site_baoxing, Damage = s_TC, Prevention = s_PE, Attitude = s_IC, Benefit = s_IB)
f1 <- Tolerance ~ Compensation + ConflictWildBoar + ConflictAll + Gender + Age + Education + Income + Assets + Park + County + Damage + Prevention
f2 <- update(f1, . ~ . + Attitude + Benefit)
m1 <- lm(f1, data = b); m2 <- lm(f2, data = b)
s1 <- sensemakr(model = m1, treatment = "Compensation", benchmark_covariates = c("County", "Damage"), kd = 1:3)
s2 <- sensemakr(model = m2, treatment = "Compensation", benchmark_covariates = c("County", "Damage", "Attitude"), kd = 1:3)

ev <- function(m) { est <- coef(m)["Compensation"]; se <- sqrt(vcov(m)["Compensation", "Compensation"])
  e <- evalues.MD(est = est, se = se, true = 0); list(est = est, se = se, tab = e) }
e1 <- ev(m1); e2 <- ev(m2)

sink(file.path(tab_dir, "170_bias_analysis_log.txt"), split = TRUE)
cat("==================== (a) Omitted-variable sensitivity, control set S1 ====================\n"); print(summary(s1))
cat("\n==================== (a) Omitted-variable sensitivity, control set S2 ====================\n"); print(summary(s2))
cat("\n==================== (b) E-values (standardised mean difference, RR approx exp(0.91 d)) ====================\n")
cat("S1: d =", round(e1$est, 3), "SE", round(e1$se, 3), "\n"); print(round(e1$tab, 3))
cat("S2: d =", round(e2$est, 3), "SE", round(e2$se, 3), "\n"); print(round(e2$tab, 3))
sink()
st <- bind_rows(cbind(set = "S1", s1$sensitivity_stats), cbind(set = "S2", s2$sensitivity_stats))
write.csv(st, file.path(tab_dir, "171_sensemakr_stats.csv"), row.names = FALSE)
write.csv(bind_rows(cbind(set = "S1", s1$bounds), cbind(set = "S2", s2$bounds)), file.path(tab_dir, "172_sensemakr_bounds.csv"), row.names = FALSE)
write.csv(rbind(data.frame(set = "S1", quantity = rownames(e1$tab), e1$tab, check.names = FALSE),
                data.frame(set = "S2", quantity = rownames(e2$tab), e2$tab, check.names = FALSE)), file.path(tab_dir, "173_evalues.csv"), row.names = FALSE)

## (d) confounding by county: the S1 estimate within each county (only two counties, so a covariate
##     cannot fully separate county from compensation)
suppressPackageStartupMessages({ library(sandwich); library(lmtest) })
fw <- update(f1, . ~ . - County)
wc <- bind_rows(lapply(list(Qingchuan = 0, Baoxing = 1), function(k) {
  m <- lm(fw, data = b[b$County == k, ]); v <- vcovHC(m, "HC3"); ct <- coeftest(m, vcov = v); ci <- coefci(m, vcov = v)
  data.frame(n = nrow(m$model), est = ct["Compensation", 1], lo = ci["Compensation", 1], hi = ci["Compensation", 2], p = ct["Compensation", 4]) }), .id = "county")
vp <- vcovHC(m1, "HC3"); ctp <- coeftest(m1, vcov = vp); cip <- coefci(m1, vcov = vp)
wc <- bind_rows(wc, data.frame(county = "Pooled", n = nrow(b), est = ctp["Compensation", 1], lo = cip["Compensation", 1], hi = cip["Compensation", 2], p = ctp["Compensation", 4]))
mi <- lm(update(f1, . ~ . + Compensation:County), data = b); cti <- coeftest(mi, vcov = vcovHC(mi, "HC3"))
write.csv(wc, file.path(tab_dir, "174_within_county_S1.csv"), row.names = FALSE)
sink(file.path(tab_dir, "170_bias_analysis_log.txt"), append = TRUE, split = TRUE)
cat("\n==================== (d) Within-county estimate, S1 controls (SD units, HC3) ====================\n"); print(wc, digits = 3)
cat("Compensation x county interaction:\n"); print(round(cti["Compensation:County", ], 4))
sink()

## (c) contour figure for S1
g <- expand.grid(r2dz = seq(0, 0.30, length.out = 121), r2yz = seq(0, 0.30, length.out = 121))
g$adj <- adjusted_estimate(m1, treatment = "Compensation", r2dz.x = g$r2dz, r2yz.dx = g$r2yz)
g$tadj <- adjusted_t(m1, treatment = "Compensation", r2dz.x = g$r2dz, r2yz.dx = g$r2yz)
bd <- s1$bounds %>% mutate(lab = sub("^([0-9])x ", "\\1\u00d7 ", bound_label), lab = sub("County", "county", lab), lab = sub("Damage", "damage", lab))
col_neg <- "#B5392B"
fC <- ggplot(g, aes(r2dz, r2yz)) +
  geom_contour(aes(z = adj), breaks = seq(-0.30, 0.10, by = 0.05), colour = "grey60", linewidth = 0.4) +
  geom_contour(aes(z = adj), breaks = 0, colour = col_neg, linewidth = 1, linetype = 2) +
  geom_contour(aes(z = tadj), breaks = qt(0.025, m1$df.residual), colour = "#2F6DB5", linewidth = 0.9, linetype = 3) +
  geom_point(data = bd, aes(r2dz.x, r2yz.dx), size = 2.6) +
  geom_text(data = bd %>% filter(grepl("county", lab)), aes(r2dz.x, r2yz.dx, label = lab), vjust = -0.9, size = 3.3) +
  annotate("text", x = 0.022, y = 0.016, label = "1\u00d7, 2\u00d7, 3\u00d7 damage", hjust = 0, size = 3.3) +
  annotate("segment", x = 0.021, xend = 0.016, y = 0.013, yend = 0.004, linewidth = 0.3) +
  annotate("point", x = 0, y = 0, size = 3, shape = 17) +
  annotate("text", x = 0.23, y = 0.285, label = "estimate reaches zero", colour = col_neg, size = 3.4) +
  annotate("text", x = 0.23, y = 0.265, label = "no longer significant", colour = "#2F6DB5", size = 3.4) +
  coord_cartesian(xlim = c(0, 0.30), ylim = c(-0.01, 0.30)) +
  labs(title = "How strong would a hidden confounder have to be?",
       subtitle = sprintf("Adjusted compensation estimate (tolerance, SD units; observed %.2f, triangle) for a hidden confounder of given strength.\nGrey lines in steps of 0.05; dots: confounders 1, 2 and 3 times as strong as county or damage", coef(m1)["Compensation"]),
       x = "Share of compensation participation explained by the confounder (partial R\u00b2)",
       y = "Share of tolerance explained by the confounder (partial R\u00b2)") +
  theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot",
                                        plot.title = element_text(face = "bold", size = 11), plot.subtitle = element_text(size = 9.5))
for (dd in c(fig_dir, rep_fig)) ggsave(file.path(dd, "fig_bias_contour.png"), fC, width = 8.5, height = 5.6, dpi = 200, bg = "white")
