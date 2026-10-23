## 28_report_figures_causal.R -- report figures for the causal-role analysis (RQ1, RQ2), drawn from the
## outputs of scripts 08, 22-26. Plain-language labels throughout.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2); library(tidyr) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
tab <- file.path(root, "output/tables"); fig <- file.path(root, "output/figures")
## Optional second copy of every figure in the report folder; skipped when that folder does not exist.
rep_dir <- file.path(root, "..", "docs", "Schreiben_Wild_boar_compensation_and_tolerance", "figures")
rep_fig <- if (dir.exists(rep_dir)) normalizePath(rep_dir) else NULL
col_neg <- "#B5392B"; col_pos <- "#2B8A3E"; col_ns <- "#8A8A8A"; col_blue <- "#2F6DB5"
th <- theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot",
                                            plot.title = element_text(face = "bold", size = 11))
save <- function(p, name, w, h) { for (d in c(fig, rep_fig)) ggsave(file.path(d, name), p, width = w, height = h, dpi = 200, bg = "white") }
arr <- arrow(length = unit(0.18, "cm"), type = "closed")
lab <- c(CP_WB = "Conflict experience (wild boar)", CP_A = "Conflict experience (all species)", Gender = "Gender", Age = "Age",
         Education = "Education", Income = "Household income", HHAsset = "Household assets", InNP = "Lives inside national park",
         Site = "Survey site (Baoxing)", PE = "Prevention effectiveness", CE0 = "Compensation participation",
         CA = "Compensation anticipation", PS = "Policy dependency", TC = "Tangible cost", IC = "Intangible cost", IB = "Intangible benefit")
sigcol <- function(lo, hi) ifelse(lo > 0, "Positive", ifelse(hi < 0, "Negative", "Not significant"))
cols <- c(Positive = col_pos, Negative = col_neg, `Not significant` = col_ns)
p1 <- read.csv(file.path(tab, "141_causal_S1_paths.csv"), check.names = FALSE)
r2 <- read.csv(file.path(tab, "143_ce0_by_role_assumption.csv"))

## ---- F1: the causal-role diagram ---------------------------------------------------------------
## Boxes: background (left), damage and prevention (below), compensation (centre), the four ambiguous
## constructs (above), tolerance (right). Background arrows to the later boxes are omitted for clarity.
gold <- "#B07D00"
nodes <- data.frame(
  x = c(1.1, 3.4, 5.4, 7.6, 9.6),
  y = c(3.0, 1.0, 3.0, 5.0, 3.0),
  label = c("Background\nconflict experience,\ndemographics, county,\npark residence",
            "Damage and prevention\n(confounders)\ntangible cost,\nprevention effectiveness",
            "Compensation\nparticipation",
            "Attitudes, expectations,\npolicy dependency\nintangible cost and benefit,\ncompensation anticipation",
            "Tolerance"),
  fill = c("white", "white", "#F3D9D5", "#FFF3D6", "#D6EBDB"))
f1 <- ggplot() +
  annotate("segment", x = 2.25, xend = 4.55, y = 3.0, yend = 3.0, arrow = arr, linewidth = 0.7) +
  annotate("segment", x = 1.6, xend = 2.55, y = 2.35, yend = 1.5, arrow = arr, linewidth = 0.7) +
  annotate("segment", x = 4.1, xend = 4.95, y = 1.5, yend = 2.55, arrow = arr, linewidth = 0.7) +
  annotate("curve", x = 4.55, xend = 9.95, y = 0.85, yend = 2.6, curvature = 0.2, arrow = arr, linewidth = 0.7) +
  annotate("segment", x = 6.25, xend = 9.05, y = 3.0, yend = 3.0, arrow = arr, linewidth = 1.1, colour = col_neg) +
  annotate("segment", x = 5.55, xend = 6.55, y = 3.5, yend = 4.45, arrow = arr, linewidth = 0.8, linetype = 2, colour = gold) +
  annotate("segment", x = 6.95, xend = 5.95, y = 4.45, yend = 3.5, arrow = arr, linewidth = 0.8, linetype = 3, colour = gold) +
  annotate("segment", x = 8.45, xend = 9.35, y = 4.45, yend = 3.45, arrow = arr, linewidth = 0.7) +
  annotate("curve", x = 9.25, xend = 5.85, y = 2.62, yend = 2.6, curvature = -0.25, arrow = arr, linewidth = 0.7, linetype = 3, colour = "grey30") +
  geom_label(data = nodes, aes(x, y, label = label, fill = fill), size = 3.2, lineheight = 0.95, label.padding = unit(0.5, "lines")) +
  scale_fill_identity() +
  annotate("text", x = 7.65, y = 3.22, label = "association of interest", colour = col_neg, size = 3.2, fontface = "bold") +
  annotate("text", x = 5.6, y = 4.2, label = "mediator?", colour = gold, size = 3.1, hjust = 1) +
  annotate("text", x = 6.95, y = 3.75, label = "confounder?", colour = gold, size = 3.1, hjust = 0) +
  annotate("text", x = 7.55, y = 2.5, label = "reverse causation?", colour = "grey30", size = 3.0) +
  coord_cartesian(xlim = c(-0.1, 10.4), ylim = c(0.3, 5.7)) +
  labs(title = "Which variables can be mediators of compensation participation?",
       subtitle = "Damage and prevention come before applying and are confounders; attitudes, expectations and policy dependency\ncould be causes or consequences of applying, so both roles are estimated. Background arrows to later boxes are not drawn.") +
  theme_void(base_size = 12) + theme(plot.title = element_text(face = "bold", size = 11), plot.subtitle = element_text(size = 9.5), plot.margin = margin(8, 8, 8, 8))
save(f1, "fig_causal_roles.png", 9.5, 5.4)

## ---- F2: the compensation estimate under each role assumption --------------------------------------
setlab <- c(S0 = "S0: background only", S1 = "S1: + damage and prevention (primary)", S2 = "S2: + attitudes",
            S3 = "S3: + expectations and policy dependency\n(direct effect, everything adjusted)")
r2$label <- factor(setlab[r2$set], levels = rev(setlab))
r2$method <- factor(ifelse(r2$method == "PLS-SEM", "PLS-SEM (standardised path coefficient)", "Regression on construct scores\n(difference in tolerance, SD units)"),
                    levels = c("PLS-SEM (standardised path coefficient)", "Regression on construct scores\n(difference in tolerance, SD units)"))
f2 <- ggplot(r2, aes(est, label)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.8, colour = col_neg) +
  geom_point(size = 3, colour = col_neg) + facet_wrap(~method, scales = "free_x") +
  labs(title = "Compensation participation and tolerance under four assumptions about what to adjust for",
       subtitle = "Each row adds the constructs named to the set treated as confounders; 95% intervals", x = "Estimate", y = NULL) + th
save(f2, "fig_ce0_by_role.png", 9.5, 4.2)

## ---- F3: mediation in the primary model (candidate mediators only) -------------------------------------
md <- read.csv(file.path(tab, "144_mediation_S1.csv")); ms <- read.csv(file.path(tab, "145_mediation_S1_summary.csv"))
med <- bind_rows(
  md %>% transmute(label = paste("via", tolower(name)), est = ind, lo = ind_lo, hi = ind_hi, type = "Indirect effect"),
  ms %>% filter(quantity == "total_indirect") %>% transmute(label = "Total indirect effect", est, lo, hi, type = "Indirect effect"),
  ms %>% filter(quantity == "direct") %>% transmute(label = "Direct effect", est, lo, hi, type = "Direct or total effect"),
  ms %>% filter(quantity == "total") %>% transmute(label = "Total effect (primary estimate)", est, lo, hi, type = "Direct or total effect"))
med$label <- factor(med$label, levels = rev(med$label))
f3 <- ggplot(med, aes(est, label, colour = type)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.8) + geom_point(size = 3) +
  scale_colour_manual(values = c(`Indirect effect` = col_ns, `Direct or total effect` = col_neg), name = NULL) +
  labs(title = "Total, direct and indirect effects of compensation participation on tolerance",
       subtitle = "Primary model (damage and prevention as confounders); 95% bootstrap intervals",
       x = "Effect on tolerance (standardised)", y = NULL) + th + theme(legend.position = "bottom")
save(f3, "fig_mediation.png", 8.5, 4.6)

## ---- F4: the two legs of each candidate indirect path ---------------------------------------------------
md$y <- rev(seq_len(nrow(md))) + 0.5; md$asig <- md$a_lo > 0 | md$a_hi < 0; md$bsig <- md$b_lo > 0 | md$b_hi < 0
yc <- mean(md$y); dlab <- p1 %>% filter(path == "CE0  ->  Tol")
f4 <- ggplot(md) +
  geom_segment(aes(x = 1.15, xend = 3.35, y = yc, yend = y, colour = asig), linewidth = 0.8, arrow = arr) +
  geom_segment(aes(x = 4.65, xend = 6.85, y = y, yend = yc, colour = bsig), linewidth = 0.8, arrow = arr) +
  annotate("curve", x = 0.6, xend = 7.4, y = yc - 0.5, yend = yc - 0.5, curvature = 0.5, colour = col_neg, linewidth = 1, arrow = arr) +
  annotate("label", x = 4, y = yc - 2.3, label = sprintf("Direct path: %.3f (significant)", dlab$`Original Est.`), colour = col_neg, fontface = "bold", size = 3.6) +
  geom_label(aes(x = 4, y = y, label = name), size = 3.7, label.padding = unit(0.45, "lines")) +
  geom_label(aes(x = 2.35, y = yc + (y - yc) * 0.55, label = sprintf("%+.2f", a), colour = asig), size = 3.3, fill = "white", linewidth = 0, show.legend = FALSE) +
  geom_label(aes(x = 5.65, y = yc + (y - yc) * 0.45, label = sprintf("%+.2f", b), colour = bsig), size = 3.3, fill = "white", linewidth = 0, show.legend = FALSE) +
  annotate("label", x = 0.6, y = yc, label = "Compensation\nparticipation", fontface = "bold", size = 3.9, label.padding = unit(0.5, "lines")) +
  annotate("label", x = 7.4, y = yc, label = "Tolerance", fontface = "bold", size = 3.9, fill = col_pos, colour = "white", label.padding = unit(0.5, "lines")) +
  annotate("text", x = 2.2, y = max(md$y) + 0.75, label = "Leg 1: does compensation\npredict the mediator?", size = 3.3, colour = "grey30") +
  annotate("text", x = 5.8, y = max(md$y) + 0.75, label = "Leg 2: does the mediator\npredict tolerance?", size = 3.3, colour = "grey30") +
  scale_colour_manual(values = c(`TRUE` = "black", `FALSE` = "grey65"), labels = c(`TRUE` = "95% interval excludes zero", `FALSE` = "Includes zero"), name = NULL) +
  coord_cartesian(xlim = c(-0.2, 8.1), ylim = c(yc - 3.35, max(md$y) + 1.2)) +
  labs(title = "The two legs of each candidate indirect path",
       subtitle = "Primary model; damage and prevention are adjusted for as confounders and are not candidate mediators") +
  theme_void(base_size = 12) + theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 11), plot.margin = margin(8, 8, 8, 8))
save(f4, "fig_mediation_legs.png", 9, 5.4)

## ---- F5: RQ2 interaction coefficients, without and with the full control set ------------------------------
mod <- read.csv(file.path(tab, "61_moderation_paths.csv"), check.names = FALSE); names(mod)[1] <- "path"
modc <- read.csv(file.path(tab, "132_moderation_full_controls_paths.csv"), check.names = FALSE)
ilab <- c("TC*CE0  ->  Tol" = "Tangible cost × compensation", "IC*CE0  ->  Tol" = "Intangible cost × compensation",
          "IB*CE0  ->  Tol" = "Intangible benefit × compensation")
getint <- function(d, l) d %>% filter(path %in% names(ilab)) %>% transmute(label = ilab[path], est = `Original Est.`, lo = `2.5% CI`, hi = `97.5% CI`, p = `Bootstrap P Val`, model = l)
im <- bind_rows(getint(mod, "Costs and benefits only"), getint(modc, "With all controls (county, conflict, demographics)"))
im$label <- factor(im$label, levels = rev(unname(ilab)))
f5 <- ggplot(im, aes(est, label, colour = model)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.8, position = position_dodge(0.6)) +
  geom_point(size = 3, position = position_dodge(0.6)) +
  geom_text(aes(label = sprintf("p = %.2f", p), x = hi), hjust = -0.15, size = 3.2, position = position_dodge(0.6), show.legend = FALSE) +
  scale_colour_manual(values = c("Costs and benefits only" = col_ns, "With all controls (county, conflict, demographics)" = col_blue), name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.2))) +
  labs(title = "Does compensation change how costs and benefits relate to tolerance?",
       subtitle = "Interaction coefficients with 95% bootstrap intervals; all include zero in both models", x = "Interaction coefficient", y = NULL) +
  th + theme(legend.position = "bottom")
save(f5, "fig_interaction_forest.png", 8.5, 4.2)

## ---- F6: within-county estimate (primary control set) ---------------------------------------------------
wc <- read.csv(file.path(tab, "174_within_county_S1.csv"))
wc$label <- factor(sprintf("%s (n = %d)", ifelse(wc$county == "Pooled", "Both counties, county as covariate", wc$county), wc$n),
                   levels = rev(sprintf("%s (n = %d)", ifelse(wc$county == "Pooled", "Both counties, county as covariate", wc$county), wc$n)))
f6 <- ggplot(wc, aes(est, label)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.8, colour = col_neg) + geom_point(size = 3, colour = col_neg) +
  labs(title = "The compensation gap in tolerance, within each county",
       subtitle = "Adjusted difference (applicants minus non-applicants) in standardised tolerance, primary control set, 95% robust CI",
       x = "Difference in tolerance (standard deviations)", y = NULL) + th
save(f6, "fig_within_county.png", 8.5, 3.6)

## ---- F7: tolerance by quality of the compensation experience ---------------------------------------------
ae <- read.csv(file.path(tab, "151_applicant_experience.csv")) %>% filter(analysis == "three_groups")
ag <- read.csv(file.path(tab, "152_applicant_groups.csv"))
ae <- bind_rows(data.frame(term = "Did not apply", est = 0, lo = NA, hi = NA), ae[, c("term","est","lo","hi")])
ae$n <- ag$n[match(ae$term, ag$group)]
ae$label <- factor(sprintf("%s (n = %d)", ae$term, ae$n), levels = rev(sprintf("%s (n = %d)", ae$term, ae$n)))
f7 <- ggplot(ae, aes(est, label)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.8, colour = col_neg, na.rm = TRUE) +
  geom_point(size = 3, colour = col_neg) +
  labs(title = "Is lower tolerance concentrated among dissatisfied applicants?",
       subtitle = "Difference from households that did not apply (reference), primary control set, 95% robust CI",
       x = "Difference in tolerance (standard deviations)", y = NULL) + th
save(f7, "fig_applicant_groups.png", 8.5, 3.4)

## ---- F8/F9: predictors of tolerance in the primary model ---------------------------------------------------
pt <- p1 %>% filter(grepl("->  Tol$", path)) %>%
  mutate(from = sub("  ->  Tol", "", path), label = lab[from], lo = `2.5% CI`, hi = `97.5% CI`, est = `Original Est.`, eff = sigcol(lo, hi)) %>%
  arrange(est) %>% mutate(label = factor(label, levels = label))
f8 <- ggplot(pt, aes(est, label, colour = eff)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.8) + geom_point(size = 3) +
  scale_colour_manual(values = cols, name = NULL) +
  labs(title = "All direct predictors of tolerance", subtitle = "Standardised path coefficients with 95% bootstrap intervals (n = 625)",
       x = "Path coefficient", y = NULL) + th + theme(legend.position = "bottom")
save(f8, "fig_all_direct_paths.png", 8, 5.5)
h <- pt %>% filter(eff != "Not significant") %>% arrange(est); h$label <- factor(h$label, levels = h$label)
f9 <- ggplot(h, aes(est, label, colour = eff)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2, linewidth = 0.9) + geom_point(size = 3.5) +
  geom_text(aes(label = sprintf("%+.2f", est)), vjust = -1.1, size = 3.8, show.legend = FALSE) +
  scale_colour_manual(values = cols, name = NULL) +
  labs(title = "The significant direct predictors of tolerance", subtitle = "Standardised path coefficients, 95% bootstrap intervals, n = 625",
       x = "Path coefficient", y = NULL) + th + theme(legend.position = "bottom")
save(f9, "fig_rq1_paths.png", 8, 3.8)
