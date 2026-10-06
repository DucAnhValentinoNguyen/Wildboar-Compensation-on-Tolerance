## 16_report_figures.R -- report figures with plain-language labels (no code
## names / underscores), the covariate screen, and a vibration-of-effects run.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2); library(sandwich); library(lmtest); library(tidyr) })
root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
tab <- file.path(root, "output/tables"); fig <- file.path(root, "output/figures")
rep_fig <- "/home/duc/Wildboar-Compensation-on-Tolerance/Schreiben_Wild_boar_compensation_and_tolerance/figures"
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
paths <- read.csv(file.path(tab, "41_plssem_full_paths.csv"), check.names = FALSE)
ind <- read.csv(file.path(tab, "51_mediation_indirect_effects.csv"))
mod <- read.csv(file.path(tab, "61_moderation_paths.csv"), check.names = FALSE)
names(mod)[1] <- "path"

col_neg <- "#B5392B"; col_pos <- "#2B8A3E"; col_ns <- "#8A8A8A"
th <- theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot", plot.title = element_text(face = "bold"))
save <- function(p, name, w, h) { for (d in c(fig, rep_fig)) ggsave(file.path(d, name), p, width = w, height = h, dpi = 200, bg = "white") }
lab <- c(CP_WB = "Conflict experience (wild boar)", CP_A = "Conflict experience (all species)",
         Gender = "Gender", Age = "Age", Education = "Education", Income = "Household income",
         HHAsset = "Household assets", InNP = "Lives inside national park", Site = "Survey site (Baoxing)",
         PE = "Prevention effectiveness", CE0 = "Compensation participation", CA = "Compensation anticipation",
         PS = "Policy support", TC = "Tangible cost", IC = "Intangible cost", IB = "Intangible benefit")
sigcol <- function(lo, hi, est) ifelse(lo > 0, "Positive", ifelse(hi < 0, "Negative", "Not significant"))
cols <- c(Positive = col_pos, Negative = col_neg, `Not significant` = col_ns)

## ---- F1: all direct paths to tolerance (RQ1/RQ2 context) -----------------
p1 <- paths %>% filter(grepl("->  Tol$", `path`)) %>%
  mutate(from = sub("  ->  Tol", "", path), label = lab[from], lo = `2.5% CI`, hi = `97.5% CI`, est = `Original Est.`,
         eff = sigcol(lo, hi, est)) %>% arrange(est) %>% mutate(label = factor(label, levels = label))
f1 <- ggplot(p1, aes(est, label, colour = eff)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.8) + geom_point(size = 3) +
  scale_colour_manual(values = cols, name = NULL) +
  labs(title = "All direct predictors of tolerance", subtitle = "Standardised path coefficients with 95% bootstrap intervals (n = 625)",
       x = "Path coefficient", y = NULL) + th + theme(legend.position = "bottom")
save(f1, "fig_all_direct_paths.png", 8, 5.5)

## ---- F2: mediation -------------------------------------------------------
mlab <- c(CA = "Compensation anticipation", PS = "Policy support", TC = "Tangible cost", IC = "Intangible cost", IB = "Intangible benefit")
direct <- paths %>% filter(path == "CE0  ->  Tol")
med <- ind %>% transmute(label = mlab[mediator], est = Original.Est., lo = X2.5..CI, hi = X97.5..CI, type = "Indirect effect (through this mediator)")
med <- bind_rows(med, data.frame(label = "Direct effect (not through any measured mediator)", est = direct$`Original Est.`,
                                 lo = direct$`2.5% CI`, hi = direct$`97.5% CI`, type = "Direct effect"))
med$label <- factor(med$label, levels = rev(med$label))
f2 <- ggplot(med, aes(est, label, colour = type)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.8) + geom_point(size = 3) +
  scale_colour_manual(values = c(`Indirect effect (through this mediator)` = col_ns, `Direct effect` = col_neg), name = NULL) +
  labs(title = "No measured mediator carries the compensation effect",
       subtitle = "Specific indirect effects and direct effect, 95% bootstrap intervals", x = "Effect on tolerance (standardised)", y = NULL) +
  th + theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 11))
save(f2, "fig_mediation.png", 8.5, 4.5)

## ---- F3: within-county ---------------------------------------------------
wc <- read.csv(file.path(tab, "121_within_county_ce0.csv")) %>% filter(grepl("direct", model)) %>%
  mutate(label = factor(sprintf("%s (n = %d)", ifelse(county == "Pooled", "Both counties, county as covariate", county), n),
                        levels = rev(sprintf("%s (n = %d)", c("Qingchuan","Baoxing","Both counties, county as covariate"), c(465,160,625)))))
f3 <- ggplot(wc, aes(est, label)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.8, colour = col_neg) + geom_point(size = 3, colour = col_neg) +
  labs(title = "The compensation gap in tolerance, within each county",
       subtitle = "Adjusted difference (applicants minus non-applicants) in standardised tolerance, 95% robust CI",
       x = "Difference in tolerance (standard deviations)", y = NULL) + th + theme(plot.title = element_text(face = "bold", size = 11))
save(f3, "fig_within_county.png", 8.5, 3.6)

## ---- F4: RQ2 interaction coefficients, without and with the full control set ----
ilab <- c("TC*CE0  ->  Tol" = "Tangible cost \u00d7 compensation", "IC*CE0  ->  Tol" = "Intangible cost \u00d7 compensation",
          "IB*CE0  ->  Tol" = "Intangible benefit \u00d7 compensation")
getint <- function(d, lab) d %>% filter(path %in% names(ilab)) %>% transmute(label = ilab[path], est = `Original Est.`, lo = `2.5% CI`, hi = `97.5% CI`, p = `Bootstrap P Val`, model = lab)
im <- getint(mod, "Costs and benefits only")
fc <- file.path(tab, "132_moderation_full_controls_paths.csv")
if (file.exists(fc)) im <- bind_rows(im, getint(read.csv(fc, check.names = FALSE), "With all controls (county, conflict, demographics)"))
im$label <- factor(im$label, levels = rev(unname(ilab)))
f4 <- ggplot(im, aes(est, label, colour = model)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.8, position = position_dodge(0.6)) +
  geom_point(size = 3, position = position_dodge(0.6)) +
  geom_text(aes(label = sprintf("p = %.2f", p), x = hi), hjust = -0.15, size = 3.2, position = position_dodge(0.6), show.legend = FALSE) +
  scale_colour_manual(values = c("Costs and benefits only" = col_ns, "With all controls (county, conflict, demographics)" = "#2F6DB5"), name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.2))) +
  labs(title = "Does compensation change how costs and benefits relate to tolerance?",
       subtitle = "Interaction coefficients with 95% bootstrap intervals; all include zero in both models", x = "Interaction coefficient", y = NULL) +
  th + theme(plot.title = element_text(face = "bold", size = 11), legend.position = "bottom")
save(f4, "fig_interaction_forest.png", 8.5, 4.2)

## ---- F5: RQ2 slopes by group ---------------------------------------------
sl <- df %>% transmute(`Intangible cost` = ic_idx, `Intangible benefit` = IB, `Tangible cost` = tc_idx, tol = tol_mean_no3,
                       group = ifelse(CE0 == 1, "Applied for compensation", "Did not apply")) %>%
  pivot_longer(c(`Intangible cost`, `Intangible benefit`, `Tangible cost`), names_to = "x", values_to = "v")
sl$x <- factor(sl$x, levels = c("Intangible cost", "Intangible benefit", "Tangible cost"))
f5 <- ggplot(sl, aes(v, tol, colour = group, fill = group)) + geom_jitter(alpha = 0.12, size = 0.8, width = 0.05, height = 0.05) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.18, linewidth = 1) + facet_wrap(~x, scales = "free_x") +
  scale_colour_manual(values = c(`Applied for compensation` = col_neg, `Did not apply` = "#2F6DB5"), name = NULL) +
  scale_fill_manual(values = c(`Applied for compensation` = col_neg, `Did not apply` = "#2F6DB5"), name = NULL) +
  labs(title = "Costs, benefits and tolerance, by compensation group",
       subtitle = "Unadjusted linear fits; the adjusted interaction tests are in the previous figure", x = "Score on the predictor (standardised index or rating)",
       y = "Tolerance (mean of 3 items, 1-5)") + th + theme(legend.position = "bottom")
save(f5, "fig_slopes_by_group.png", 9.5, 4.2)

## ---- F6: MGA by compensation group ---------------------------------------
mga <- data.frame(path = c("Intangible cost", "Intangible benefit", "Tangible cost", "Policy support", "Compensation anticipation", "Prevention effectiveness"),
                  `Did not apply` = c(-0.2553, 0.1681, -0.0082, -0.0560, -0.0764, 0.1481),
                  `Applied` = c(-0.4143, 0.1965, 0.0658, -0.0757, 0.1063, 0.0943), p = c(.0404, .6327, .7789, .4229, .7654, .2657),
                  check.names = FALSE) %>%
  pivot_longer(c(`Did not apply`, Applied), names_to = "group", values_to = "est") %>%
  mutate(path = factor(path, levels = rev(unique(path))), group = ifelse(group == "Applied", "Applied for compensation", "Did not apply"))
f6 <- ggplot(mga, aes(est, path, colour = group)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_point(size = 3, position = position_dodge(0.5)) +
  scale_colour_manual(values = c(`Applied for compensation` = col_neg, `Did not apply` = "#2F6DB5"), name = NULL) +
  labs(title = "Paths to tolerance in the two compensation groups",
       subtitle = "Only intangible cost differs (permutation p = .04, uncorrected for the 12 comparisons)", x = "Path coefficient", y = NULL) +
  th + theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 11))
save(f6, "fig_mga_groups.png", 8.5, 4.2)

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

## ---- headline figure re-drawn without code names ---------------------------
h <- p1 %>% filter(eff != "Not significant") %>% arrange(est)
h$label <- factor(h$label, levels = h$label)
f0 <- ggplot(h, aes(est, label, colour = eff)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.9) + geom_point(size = 3.5) +
  geom_text(aes(label = sprintf("%+.2f", est)), vjust = -1.1, size = 3.8, show.legend = FALSE) +
  scale_colour_manual(values = cols, name = NULL) +
  labs(title = "The four significant predictors of tolerance", subtitle = "Standardised path coefficients, 95% bootstrap intervals; R² = 0.234, n = 625",
       x = "Path coefficient", y = NULL) + th + theme(legend.position = "bottom")
save(f0, "fig_rq1_paths.png", 8, 3.8)

## ---- mediation path diagram: both legs of every indirect path ---------------
g <- function(p) paths[paths$path == p, ]
star <- function(lo, hi) ifelse(lo > 0 | hi < 0, "*", "")
md <- data.frame(m = c("CA","PS","TC","IC","IB"), y = c(5,4,3,2,1))
md$name <- mlab[md$m]
md$a <- sapply(md$m, function(m) g(paste0("CE0  ->  ", m))$`Original Est.`); md$alo <- sapply(md$m, function(m) g(paste0("CE0  ->  ", m))$`2.5% CI`); md$ahi <- sapply(md$m, function(m) g(paste0("CE0  ->  ", m))$`97.5% CI`)
md$b <- sapply(md$m, function(m) g(paste0(m, "  ->  Tol"))$`Original Est.`); md$blo <- sapply(md$m, function(m) g(paste0(m, "  ->  Tol"))$`2.5% CI`); md$bhi <- sapply(md$m, function(m) g(paste0(m, "  ->  Tol"))$`97.5% CI`)
md$asig <- star(md$alo, md$ahi) == "*"; md$bsig <- star(md$blo, md$bhi) == "*"
write.csv(md, file.path(tab, "130_mediation_legs.csv"), row.names = FALSE)
arr <- arrow(length = unit(0.18, "cm"), type = "closed")
f9 <- ggplot(md) +
  geom_segment(aes(x = 1.15, xend = 3.35, y = 3, yend = y, colour = asig), linewidth = 0.8, arrow = arr) +
  geom_segment(aes(x = 4.65, xend = 6.85, y = y, yend = 3, colour = bsig), linewidth = 0.8, arrow = arr) +
  annotate("curve", x = 0.6, xend = 7.4, y = 2.5, yend = 2.5, curvature = 0.55, colour = col_neg, linewidth = 1, arrow = arr) +
  annotate("label", x = 4, y = -1.0, label = "Direct path: −0.109 (significant)", colour = col_neg, fontface = "bold", size = 3.8) +
  geom_label(aes(x = 4, y = y, label = name), size = 3.8, label.padding = unit(0.45, "lines")) +
  geom_label(aes(x = 2.35, y = 3 + (y - 3) * 0.55, label = sprintf("%+.2f", a), colour = asig), size = 3.3, fill = "white", linewidth = 0, show.legend = FALSE) +
  geom_label(aes(x = 5.65, y = 3 + (y - 3) * 0.45, label = sprintf("%+.2f", b), colour = bsig), size = 3.3, fill = "white", linewidth = 0, show.legend = FALSE) +
  annotate("label", x = 0.6, y = 3, label = "Compensation\nparticipation", fontface = "bold", size = 4, label.padding = unit(0.5, "lines")) +
  annotate("label", x = 7.4, y = 3, label = "Tolerance", fontface = "bold", size = 4, fill = "#2B8A3E", colour = "white", label.padding = unit(0.5, "lines")) +
  annotate("text", x = 2.2, y = 5.7, label = "Leg 1: does compensation\npredict the mediator?", size = 3.4, colour = "grey30") +
  annotate("text", x = 5.8, y = 5.7, label = "Leg 2: does the mediator\npredict tolerance?", size = 3.4, colour = "grey30") +
  scale_colour_manual(values = c(`TRUE` = "black", `FALSE` = "grey65"), labels = c(`TRUE` = "Significant path", `FALSE` = "Not significant"), name = NULL) +
  coord_cartesian(xlim = c(-0.2, 8.1), ylim = c(-1.2, 6.1)) +
  labs(title = "Why no construct mediates: each indirect path needs two significant legs",
       subtitle = "Standardised path coefficients from the full model; no mediator has both legs significant") +
  theme_void(base_size = 12) + theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 11), plot.margin = margin(8, 8, 8, 8))
save(f9, "fig_mediation_legs.png", 9, 5.6)
print(md[, c("name","a","alo","ahi","b","blo","bhi")], digits = 2)

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
