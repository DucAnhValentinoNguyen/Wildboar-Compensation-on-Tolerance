## 16_report_figures.R -- descriptive report figures with plain-language labels (no code names or
## underscores): RQ2 slopes by group, vibration of effects, covariate screen, tolerance items.
## Figures of the causal-role analysis (scripts 22-26) are drawn in 28_report_figures_causal.R.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2); library(sandwich); library(lmtest); library(tidyr) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
tab <- file.path(root, "output/tables"); fig <- file.path(root, "output/figures")
## Optional second copy of every figure in the report folder; skipped when that folder does not exist.
rep_dir <- file.path(root, "..", "docs", "Schreiben_Wild_boar_compensation_and_tolerance", "figures")
rep_fig <- if (dir.exists(rep_dir)) normalizePath(rep_dir) else NULL
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))

col_neg <- "#B5392B"; col_pos <- "#2B8A3E"; col_ns <- "#8A8A8A"
th <- theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot", plot.title = element_text(face = "bold"))
save <- function(p, name, w, h) { for (d in c(fig, rep_fig)) ggsave(file.path(d, name), p, width = w, height = h, dpi = 200, bg = "white") }
## ---- F5: RQ2 slopes by group ---------------------------------------------
sl <- df %>% transmute(`Intangible cost` = ic_idx, `Intangible benefit` = IB, `Tangible cost` = tc_idx, tol = tol_mean_no3,
                       group = ifelse(CE0 == 1, "Applied for compensation", "Did not apply")) %>%
  pivot_longer(c(`Intangible cost`, `Intangible benefit`, `Tangible cost`), names_to = "x", values_to = "v")
sl$x <- factor(sl$x, levels = c("Intangible cost", "Intangible benefit", "Tangible cost"))
set.seed(20260920)  # jitter positions
f5 <- ggplot(sl, aes(v, tol, colour = group, fill = group)) + geom_jitter(alpha = 0.12, size = 0.8, width = 0.05, height = 0.05) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.18, linewidth = 1) + facet_wrap(~x, scales = "free_x") +
  scale_colour_manual(values = c(`Applied for compensation` = col_neg, `Did not apply` = "#2F6DB5"), name = NULL) +
  scale_fill_manual(values = c(`Applied for compensation` = col_neg, `Did not apply` = "#2F6DB5"), name = NULL) +
  labs(title = "Costs, benefits and tolerance, by compensation group",
       subtitle = "Unadjusted linear fits; the adjusted interaction tests are in a separate figure", x = "Score on the predictor (standardised index or rating)",
       y = "Tolerance (mean of 3 items, 1-5)") + th + theme(legend.position = "bottom")
save(f5, "fig_slopes_by_group.png", 9.5, 4.2)

## ---- F7: vibration of effects (2^13 adjustment sets) ---------------------
adj <- c("cpwb_idx","tc_idx","ic_idx","IB","PS1","PS2","gender","age","education","log_income","log_hh_asset","in_np","site_baoxing")
sets <- expand.grid(rep(list(c(FALSE, TRUE)), length(adj))); names(sets) <- adj
x <- model.matrix(~ ., data = df[, c("CE0", adj)]); y <- df$tol_mean_no3
vib <- do.call(rbind, lapply(seq_len(nrow(sets)), function(i) {
  keep <- c("(Intercept)", "CE0", adj[unlist(sets[i, ])]); X <- x[, keep, drop = FALSE]
  fit <- lm.fit(X, y); n <- length(y); k <- ncol(X); s2 <- sum(fit$residuals^2) / (n - k)
  xtxi <- chol2inv(chol(crossprod(X))); dimnames(xtxi) <- list(colnames(X), colnames(X)); b <- fit$coefficients["CE0"]; se <- sqrt(s2 * xtxi["CE0", "CE0"])
  data.frame(est = b, p = 2 * pt(-abs(b / se), n - k), n_adj = sum(unlist(sets[i, ])))
}))
write.csv(vib, file.path(tab, "124_vibration_of_effects.csv"), row.names = FALSE)
cat(sprintf("Vibration: %d sets, %.1f%% negative, %.1f%% p<.05, estimate range [%.3f, %.3f], median %.3f\n",
            nrow(vib), 100 * mean(vib$est < 0), 100 * mean(vib$p < .05), min(vib$est), max(vib$est), median(vib$est)))
f7 <- ggplot(vib, aes(est, fill = p < .05)) + geom_histogram(bins = 40, colour = "white") + geom_vline(xintercept = 0, linetype = 2) +
  scale_fill_manual(values = c(`TRUE` = col_neg, `FALSE` = col_ns), labels = c(`TRUE` = "p < .05", `FALSE` = "p ≥ .05"), name = NULL) +
  labs(title = "Vibration of effects: 8,192 ways to adjust the compensation estimate",
       subtitle = "Every subset of 13 candidate covariates; compensation coefficient on mean tolerance",
       x = "Compensation coefficient (tolerance points, 1-5 scale)", y = "Number of models") + th +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 11))
save(f7, "fig_vibration.png", 8.5, 4.2)

## ---- F8/T: covariate screen of the original survey variables --------------
base <- df %>% mutate(site = site_baoxing, tol = tol_mean_no3)
cand <- c(in_np = "Lives inside national park", gender = "Gender", age = "Age", education = "Education", hh_pop = "Household size",
  income = "Annual income", agri_prop = "Share of income from agriculture", Q10_MaizeArea = "Maize area", Q10_PotatoArea = "Potato area",
  Q10_TeeArea = "Tea area", Q10_FruitArea = "Fruit area", Q10_HerbArea = "Herb area", Q10_VegArea = "Vegetable area", Q10_RapeArea = "Rapeseed area",
  Q10_SweetPotatoArea = "Sweet potato area", total_cropland = "Total cropland", Q12_Cattle = "Cattle", Q12_Sheep = "Sheep", Q12_Pig = "Pigs",
  Q12_Chicken = "Chickens", Q12_Bee = "Bee colonies", total_livestock = "Total livestock", crop_asset = "Crop asset value",
  livestock_asset = "Livestock asset value", hh_asset = "Household asset value",
  CP_WB1 = "Wild boar conflict: frequency of encounters", CP_WB2 = "Wild boar conflict: duration", CP_WB3 = "Wild boar conflict: frequency of conflict",
  CP_WB4 = "Wild boar population trend", CP_A1 = "All species: number of conflict species", CP_A2 = "All species: perceived severity",
  CP_A3 = "All species: duration", TC1_DamagedArea = "Damaged crop area", TC2_EconomicLoss = "Economic loss from damage",
  IC1 = "General attitude to wild boar", IC2_1 = "Word description 1 (rating)", IC2_2 = "Word description 2 (rating)", IC2_3 = "Word description 3 (rating)",
  IC2_DescriptiveAttitude = "Mean word rating", IB = "Intangible benefit (ecological value)", PE = "Prevention effectiveness",
  CE0 = "Compensation participation", CA1 = "Lowest accepted compensation (%)", CA2 = "Expected compensation (%)", CA3 = "Insurance willingness to pay",
  PS1 = "Policy support: institutions", PS2 = "Policy support: knowledge", site = "Survey site (Baoxing)")
rk <- function(v) rank(v, na.last = "keep")
screen <- bind_rows(lapply(names(cand), function(v) {
  d <- data.frame(y = base$tol, x = base[[v]], site = base$site); d <- d[complete.cases(d), ]
  ct <- suppressWarnings(cor.test(d$x, d$y, method = "spearman", exact = FALSE))
  fit <- lm(rk(y) ~ rk(x) + site, data = d); cf <- coeftest(fit, vcov = vcovHC(fit, "HC3"))
  data.frame(variable = cand[[v]], n = nrow(d), rho = unname(ct$estimate), p_raw = ct$p.value, rho_adj = cf["rk(x)", 1] * sd(rk(d$x)) / sd(rk(d$y)),
             p_adj = cf["rk(x)", 4])
}))
screen$p_adj[screen$variable == "Survey site (Baoxing)"] <- NA
screen$q_raw <- p.adjust(screen$p_raw, "BH"); screen$q_adj <- p.adjust(screen$p_adj, "BH")
write.csv(screen, file.path(tab, "125_covariate_screen.csv"), row.names = FALSE)
cat(sprintf("Screened %d variables. Unadjusted: %d with p<.05, %d with BH q<.05. Site-adjusted: %d with p<.05, %d with BH q<.05\n",
            nrow(screen), sum(screen$p_raw < .05), sum(screen$q_raw < .05), sum(screen$p_adj < .05, na.rm = TRUE), sum(screen$q_adj < .05, na.rm = TRUE)))
sc <- screen %>% mutate(grp = ifelse(q_raw < .05, "Significant (FDR 5%)", ifelse(p_raw < .05, "Nominal only (p < .05)", "Not significant"))) %>%
  arrange(rho) %>% mutate(variable = factor(variable, levels = variable))
f8 <- ggplot(sc, aes(rho, variable, colour = grp)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_segment(aes(x = 0, xend = rho, yend = variable), linewidth = 0.6) + geom_point(size = 2.2) +
  scale_colour_manual(values = c(`Significant (FDR 5%)` = "#2F6DB5", `Nominal only (p < .05)` = "#E8A33D", `Not significant` = col_ns), name = NULL) +
  labs(title = "Association of every survey variable with tolerance", subtitle = "Spearman correlation with mean tolerance (Tol1, Tol2, Tol4), one variable at a time",
       x = "Spearman correlation", y = NULL) + th + theme(legend.position = "bottom", axis.text.y = element_text(size = 8))
save(f8, "fig_covariate_screen.png", 8.5, 9.5)
print(screen %>% filter(p_raw < .05) %>% arrange(p_raw) %>% mutate(across(where(is.numeric), ~round(., 4))))

## ---- tolerance items: item-rest correlation and CFA loading (corrected statistic) ----
suppressPackageStartupMessages({ library(psych); library(lavaan) })
t4 <- df[, c("Tol1_5","Tol2_1","Tol3_1","Tol4_5")]
ist <- psych::alpha(t4, check.keys = FALSE)$item.stats
cf <- subset(standardizedSolution(cfa('Tol =~ Tol1_5 + Tol2_1 + Tol3_1 + Tol4_5', data = df, ordered = names(t4), estimator = "WLSMV")), op == "=~")
ti <- data.frame(item = c("Tol1: supports\nnon-lethal management", "Tol2: opposes\nstricter control", "Tol3: feels\npersonally safe", "Tol4: accepts\nsome damage"),
                 `Item-rest correlation` = ist$r.drop, `Factor loading (CFA)` = cf$est.std, check.names = FALSE) %>%
  pivot_longer(-item, names_to = "stat", values_to = "v")
write.csv(ti, file.path(tab, "134_tolerance_item_stats.csv"), row.names = FALSE)
f10 <- ggplot(ti, aes(item, v, fill = stat)) + geom_col(position = position_dodge(0.8), width = 0.75) +
  geom_text(aes(label = sprintf("%.2f", v), y = pmax(v, 0)), position = position_dodge(0.8), vjust = -0.4, size = 3.4) +
  geom_hline(yintercept = 0, colour = "grey40") + scale_fill_manual(values = c("Item-rest correlation" = "#2B8A3E", "Factor loading (CFA)" = "#2F6DB5"), name = NULL) +
  labs(title = "The personal-safety item does not belong with the other three", subtitle = "Item-rest correlation and standardised factor loading for the four tolerance items", x = NULL, y = NULL) +
  th + theme(legend.position = "bottom")
save(f10, "fig_tol_items.png", 8, 4.6)

## ---- tolerance scale reliability: 4-item raw, 3-item raw, 3-item ordinal alpha ----
t3 <- df[, c("Tol1_5","Tol2_1","Tol4_5")]
pc <- psych::polychoric(t3)$rho; rbar <- mean(pc[lower.tri(pc)])
rel <- data.frame(label = factor(c("4 items\n(raw alpha)", "3 items, Tol3 dropped\n(raw alpha)", "3 items, Tol3 dropped\n(ordinal alpha)"),
                                 levels = c("4 items\n(raw alpha)", "3 items, Tol3 dropped\n(raw alpha)", "3 items, Tol3 dropped\n(ordinal alpha)")),
                  alpha = c(psych::alpha(t4, check.keys = FALSE)$total$raw_alpha, psych::alpha(t3, check.keys = FALSE)$total$raw_alpha, 3 * rbar / (1 + 2 * rbar)),
                  four = c(TRUE, FALSE, FALSE))
write.csv(rel, file.path(tab, "135_tolerance_reliability.csv"), row.names = FALSE)
f11 <- ggplot(rel, aes(label, alpha, fill = four)) + geom_col(width = 0.6) +
  geom_hline(yintercept = 0.70, linetype = 2, colour = "grey40") +
  annotate("text", x = 0.55, y = 0.73, label = "conventional threshold (0.70)", hjust = 0, size = 3.4, colour = "grey30") +
  geom_text(aes(label = sprintf("%.2f", alpha)), vjust = -0.5, size = 3.8, fontface = "bold") +
  scale_fill_manual(values = c(`TRUE` = col_ns, `FALSE` = col_pos), guide = "none") +
  scale_y_continuous(limits = c(0, 0.8), breaks = seq(0, 0.8, 0.1)) +
  labs(title = "Dropping Tol3 improves the reliability of the tolerance scale, but not to 0.70",
       subtitle = "Cronbach's alpha of the tolerance items", x = NULL, y = "Cronbach's alpha") + th
save(f11, "fig_reliability.png", 7.5, 4.6)
