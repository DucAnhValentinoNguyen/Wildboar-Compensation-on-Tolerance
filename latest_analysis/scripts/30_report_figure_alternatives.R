## 30_report_figure_alternatives.R -- the compensation estimate under the alternatives we did not choose
## (report figure "fig_alternatives.png"), drawn from the two tables written by 29_decision_alternatives.R.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
tab <- file.path(root, "output/tables"); fig <- file.path(root, "output/figures")
## Optional second copy of every figure in the report folder; skipped when that folder does not exist.
rep_dir <- file.path(root, "..", "docs", "Schreiben_Wild_boar_compensation_and_tolerance", "figures")
rep_fig <- if (dir.exists(rep_dir)) normalizePath(rep_dir) else NULL
col_neg <- "#B5392B"; col_blue <- "#2F6DB5"
th <- theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot",
                                            plot.title = element_text(face = "bold", size = 11))
save <- function(p, name, w, h) { for (d in c(fig, rep_fig)) ggsave(file.path(d, name), p, width = w, height = h, dpi = 200, bg = "white") }

pls_alt <- read.csv(file.path(tab, "180_alternatives_pls.csv")); reg_alt <- read.csv(file.path(tab, "181_alternatives_regression.csv"))
pa <- pls_alt %>% transmute(panel = "PLS-SEM: standardised total effect", variant, est = total, lo = total_lo, hi = total_hi)
ra <- reg_alt %>% filter(scale == "SD of tolerance") %>% transmute(panel = "Regression: adjusted difference in tolerance (SD)", variant, est, lo, hi)
fd <- bind_rows(pa, ra); fd$key <- paste(fd$panel, fd$variant, sep = "||"); fd$key <- factor(fd$key, levels = rev(unique(fd$key)))
fd$primary <- fd$variant %in% c("Primary model", "Primary: heteroscedasticity-robust errors")
f10 <- ggplot(fd, aes(est, key, colour = primary)) + geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.7) + geom_point(size = 2.6) +
  scale_colour_manual(values = c(`TRUE` = col_neg, `FALSE` = col_blue), guide = "none") +
  scale_y_discrete(labels = function(x) sub("^.*\\|\\|", "", x)) + facet_wrap(~panel, scales = "free", ncol = 1) +
  labs(title = "The compensation estimate under the alternatives we did not choose",
       subtitle = "Primary estimate in red; each other row changes one analytic decision; 95% intervals", x = "Estimate", y = NULL) + th
save(f10, "fig_alternatives.png", 9, 8.5)
