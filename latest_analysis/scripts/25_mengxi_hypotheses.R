## 25_mengxi_hypotheses.R -- the project partner's hypothesised model (docs/Hypothesis List.pptx),
## fitted as drawn, and a verdict for each of the 36 hypotheses H1.1.1-H3.4.1.
## Structure of the hypothesis diagram:
##   conflict experience (wild boar, all species)
##     -> {perceived control (PE), compensation participation (CE0), compensation anticipation (CA), policy dependency (PS)}
##     -> {tangible cost (TC), intangible cost (IC), intangible benefit (IB)} -> tolerance; gender -> tolerance.
##   No paths within a layer. Demographics, survey site and park residence enter as controls of every
##   endogenous construct (site because compensation is confounded with county). A second fit without site
##   and park residence mirrors the partner's original specification and shows which verdicts depend on it.
## Verdicts: directional hypotheses use the 95% bootstrap interval (supported / opposite / not supported) and
## a Benjamini-Hochberg q over the 34 directional tests; the two "no association" hypotheses use an equivalence
## check: the 90% interval must lie inside (-0.1, 0.1), a standardised path below Cohen's (1988) small effect.
suppressPackageStartupMessages({ library(dplyr); library(seminr) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables")

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
conf <- c("CP_WB","CP_A"); l1 <- c("PE","CE0","CA","PS"); l2 <- c("TC","IC","IB")
fit_h <- function(controls) {
  sm <- relationships(
    paths(from = conf, to = c(l1, l2, "Tol")),
    paths(from = l1, to = c(l2, "Tol")),
    paths(from = l2, to = "Tol"),
    paths(from = controls, to = c(l1, l2, "Tol")))
  m <- estimate_pls(df, mm, sm, missing = mean_replacement, maxIt = 500)
  b <- bootstrap_model(m, nboot = 5000, cores = 4, seed = 20260920)
  p95 <- as.data.frame(summary(b, alpha = 0.05)$bootstrapped_paths); p90 <- as.data.frame(summary(b, alpha = 0.10)$bootstrapped_paths)
  list(model = m, p95 = p95, p90 = p90, boot = b)
}
main <- fit_h(c("Gender","Age","Education","Income","HHAsset","InNP","Site"))
orig <- fit_h(c("Gender","Age","Education","Income","HHAsset"))

## id, from, to, predicted sign (+1, -1, 0 = no association), short wording
H <- read.csv(text = "
id,from,to,sign,text
H1.1.1,CP_WB,Tol,-1,Wild boar conflict -> lower tolerance
H1.1.2,CP_WB,IB,-1,Wild boar conflict -> lower intangible benefit
H1.1.3,CP_WB,IC,1,Wild boar conflict -> higher intangible cost
H1.1.4,CP_WB,TC,1,Wild boar conflict -> higher tangible cost
H1.1.5,CP_WB,PE,-1,Wild boar conflict -> lower prevention effectiveness
H1.1.6,CP_WB,CE0,1,Wild boar conflict -> more likely to apply
H1.1.7,CP_WB,CA,1,Wild boar conflict -> stronger compensation anticipation
H1.1.8,CP_WB,PS,1,Wild boar conflict -> greater policy dependency
H1.2.1,CP_A,Tol,-1,All-wildlife conflict -> lower tolerance
H1.2.2,CP_A,IB,-1,All-wildlife conflict -> lower intangible benefit
H1.2.3,CP_A,IC,1,All-wildlife conflict -> higher intangible cost
H1.2.4,CP_A,TC,1,All-wildlife conflict -> higher tangible cost
H1.2.5,CP_A,PE,-1,All-wildlife conflict -> lower prevention effectiveness
H1.2.6,CP_A,CE0,1,All-wildlife conflict -> more likely to apply
H1.2.7,CP_A,CA,1,All-wildlife conflict -> stronger compensation anticipation
H1.2.8,CP_A,PS,1,All-wildlife conflict -> greater policy dependency
H2.1.1,PE,Tol,1,Prevention effectiveness -> higher tolerance
H2.1.2,PE,IB,1,Prevention effectiveness -> higher intangible benefit
H2.1.3,PE,IC,-1,Prevention effectiveness -> lower intangible cost
H2.1.4,PE,TC,-1,Prevention effectiveness -> lower tangible cost
H2.2.1,CE0,Tol,1,Applied for compensation -> higher tolerance
H2.2.2,CE0,IB,1,Applied for compensation -> higher intangible benefit
H2.2.3,CE0,IC,-1,Applied for compensation -> lower intangible cost
H2.2.4,CE0,TC,-1,Applied for compensation -> lower tangible cost
H2.3.1,CA,Tol,-1,Compensation anticipation -> lower tolerance
H2.3.2,CA,IB,-1,Compensation anticipation -> lower intangible benefit
H2.3.3,CA,IC,1,Compensation anticipation -> higher intangible cost
H2.3.4,CA,TC,1,Compensation anticipation -> higher tangible cost
H2.4.1,PS,Tol,-1,Policy dependency -> lower tolerance
H2.4.2,PS,IB,-1,Policy dependency -> lower intangible benefit
H2.4.3,PS,IC,1,Policy dependency -> higher intangible cost
H2.4.4,PS,TC,1,Policy dependency -> higher tangible cost
H3.1.1,TC,Tol,0,Tangible cost: no independent association with tolerance
H3.2.1,IC,Tol,-1,Intangible cost -> lower tolerance
H3.3.1,IB,Tol,1,Intangible benefit -> higher tolerance
H3.4.1,Gender,Tol,0,Gender: no independent association with tolerance
", strip.white = TRUE)
stopifnot(nrow(H) == 36)

verdicts <- function(fit, label) {
  out <- H
  key <- paste0(H$from, "  ->  ", H$to)
  stopifnot(all(key %in% rownames(fit$p95)))
  out$est <- fit$p95[key, "Original Est."]; out$lo <- fit$p95[key, "2.5% CI"]; out$hi <- fit$p95[key, "97.5% CI"]
  out$p <- fit$p95[key, "Bootstrap P Val"]; out$lo90 <- fit$p90[key, "5% CI"]; out$hi90 <- fit$p90[key, "95% CI"]
  dir <- out$sign != 0
  ## seminr's bootstrap p-value is twice the share of resamples on the other side of zero; record that share so that
  ## rows whose interval is far from zero but whose p-value is not small (a long tail in the resamples) can be explained
  out$share_opposite <- mapply(function(f, t, e) mean(sign(fit$boot$boot_paths[f, t, ]) != sign(e)), out$from, out$to, out$est)
  out$q <- NA; out$q[dir] <- p.adjust(out$p[dir], "BH")
  out$verdict <- ifelse(!dir,
    ifelse(out$lo90 > -0.1 & out$hi90 < 0.1, "Supported (equivalence)", ifelse(out$lo > 0 | out$hi < 0, "Not supported", "Inconclusive")),
    ifelse(out$lo > 0 & out$sign > 0 | out$hi < 0 & out$sign < 0, "Supported",
      ifelse(out$lo > 0 & out$sign < 0 | out$hi < 0 & out$sign > 0, "Opposite", "Not supported")))
  out$survives_fdr <- ifelse(dir, out$q < .05, NA)
  out$model <- label
  out
}
vm <- verdicts(main, "with site and park residence as controls (main)")
vo <- verdicts(orig, "partner's original controls (demographics only)")
vm$verdict_without_site <- vo$verdict; vm$est_without_site <- vo$est
write.csv(vm, file.path(tab_dir, "160_mengxi_hypotheses.csv"), row.names = FALSE)

sink(file.path(tab_dir, "161_mengxi_hypotheses_log.txt"), split = TRUE)
cat("R2 (main fit):\n"); print(round(summary(main$model)$paths["R^2", ], 3))
cat("\nHypothesis verdicts (main fit; last column: verdict without site/park controls)\n\n")
print(vm[, c("id","text","sign","est","lo","hi","p","q","verdict","survives_fdr","verdict_without_site")], digits = 3, row.names = FALSE)
cat("\nCounts (main):\n"); print(table(vm$verdict))
cat("\nVerdicts that change without the site/park controls:\n"); print(vm[vm$verdict != vm$verdict_without_site, c("id","text","est","est_without_site","verdict","verdict_without_site")], digits = 3, row.names = FALSE)
cat("\nOuter weights of the formative constructs (main fit):\n")
w <- main$model$outer_weights
print(round(w[c("CP_WB1","CP_WB2","CP_WB3","CP_WB4","CP_A1","CP_A2","CP_A3","CA1","CA2","log_ca3","PS1","PS2","TC1_DamagedArea","log_econloss","IC1","IC2_1","IC2_2_imp","IC2_3_imp"), c("CP_WB","CP_A","CA","PS","TC","IC")], 3))
sink()
