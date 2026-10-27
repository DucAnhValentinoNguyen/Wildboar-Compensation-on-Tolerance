## 31_robustness_mga.R -- Sections 6 and 7 of the report (RQ3): robustness specifications and
## multi-group analysis. Every model here starts from the PRIMARY model of 23_causal_role_models.R
## (adjustment set S1): background constructs including survey site and park residence -> damage
## and prevention -> compensation participation (CE0) -> the four candidate mediators -> tolerance;
## four-item intangible cost, three-item tolerance, 2,000 bootstrap resamples (as 29_decision_alternatives.R).
##
## (A) Six specifications, each changing ONE choice relative to the primary model. Reported per
##     specification: total effect of CE0 on tolerance (the estimand of RQ1), its direct path,
##     and R2 of the tolerance equation. No SRMR: seminr has no SRMR for models with composites,
##     and a hand-made construct-level version is not the SRMR of the literature.
## (B) Measurement quality of the primary model (tolerance loadings, AVE, rho_C; largest VIF of
##     the formative indicators; HTMT of policy dependency, which motivates M_noPS).
## (C) Multi-group analysis by CE0 (applicants vs non-applicants), EXPLORATORY. The confirmatory
##     test of whether compensation changes the cost/benefit paths is the interaction test of
##     Section 4.6 (22_moderation_with_controls.R, 23_causal_role_models.R part D).
##     MGA 1: the tolerance equation of the primary model without CE0 (CE0 is the grouping variable).
##     MGA 2: the same, with ONLY the sociodemographic controls removed.
##     For each path into tolerance: group-specific estimate and bootstrap CI, permutation test of
##     the group difference, Holm correction across the paths of each MGA. MICOM step 2
##     (compositional invariance) and HTMT within each group are reported as preconditions.
## Output: output/tables/190-197_*.csv, 198_latex_rows.tex (rows to paste into Tables 12-14),
##         199_robustness_mga_log.txt. Runtime: about 30-60 minutes (permutations re-estimate the model).
suppressPackageStartupMessages({ library(dplyr); library(seminr) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
df <- df[!is.na(df$CE0), ]
tab_dir <- file.path(root, "output/tables")
SEED <- 20260920
NBOOT <- as.integer(Sys.getenv("WB_NBOOT", "2000")); NPERM <- as.integer(Sys.getenv("WB_NPERM", "1000"))  # override only for a quick test run

## ------------------------------------------------------------------ measurement and structural model
demo <- c("Gender", "Age", "Education", "Income", "HHAsset")
items <- list(CP_WB = c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), CP_A = c("CP_A1","CP_A2","CP_A3"),
              CA = c("CA1","CA2","log_ca3"), PS = c("PS1","PS2"), TC = c("TC1_DamagedArea","log_econloss"),
              IC = c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), Tol = c("Tol1_5","Tol2_1","Tol4_5"))
mk_mm <- function(tol = items$Tol, ic = items$IC, drop = character(0)) {
  parts <- list(
    CP_WB = composite("CP_WB", items$CP_WB, weights = mode_B), CP_A = composite("CP_A", items$CP_A, weights = mode_B),
    PE = composite("PE", single_item("PE")), CE0 = composite("CE0", single_item("CE0")),
    CA = composite("CA", items$CA, weights = mode_B), PS = composite("PS", items$PS, weights = mode_B),
    TC = composite("TC", items$TC, weights = mode_B),
    IC = if (length(ic) == 1) composite("IC", single_item(ic)) else composite("IC", ic, weights = mode_B),
    IB = composite("IB", single_item("IB")),
    Gender = composite("Gender", single_item("gender")), Age = composite("Age", single_item("age")),
    Education = composite("Education", single_item("education")), Income = composite("Income", single_item("log_income")),
    HHAsset = composite("HHAsset", single_item("log_hh_asset")), InNP = composite("InNP", single_item("in_np")),
    Site = composite("Site", single_item("site_baoxing")),
    Tol = composite("Tol", tol, weights = mode_A))
  do.call(constructs, unname(parts[setdiff(names(parts), drop)]))
}
## Same dense layered structure as 23_causal_role_models.R: every earlier layer points to every later one.
sm_for <- function(bg, pre, post, ce0 = TRUE) {
  mid <- if (ce0) "CE0" else character(0)
  p <- list(paths(from = bg, to = c(pre, mid, post, "Tol")))
  if (length(pre))  p <- c(p, list(paths(from = pre, to = c(mid, post, "Tol"))))
  if (ce0)          p <- c(p, list(paths(from = "CE0", to = c(post, "Tol"))))
  if (length(post)) p <- c(p, list(paths(from = post, to = "Tol")))
  do.call(relationships, p)
}
bg_all <- c("CP_WB", "CP_A", demo, "InNP", "Site")
pre1 <- c("TC", "PE"); post1 <- c("CA", "PS", "IC", "IB")
quiet <- function(expr) { out <- NULL; invisible(capture.output(out <- suppressWarnings(suppressMessages(expr)))); out }
fit <- function(data, mm, sm) quiet(estimate_pls(data, mm, sm, missing = mean_replacement, maxIt = 500))
boot <- function(m) quiet(summary(bootstrap_model(m, nboot = NBOOT, seed = SEED)))
pick <- function(tbl, row) {
  if (!row %in% rownames(tbl)) return(c(est = NA, lo = NA, hi = NA, p = NA))
  r <- tbl[row, ]; c(est = r[["Original Est."]], lo = r[["2.5% CI"]], hi = r[["97.5% CI"]], p = r[["Bootstrap P Val"]]) }

## ------------------------------------------------------------------ (A) six specifications
specs <- list(
  list("M0 (primary)", "None: primary model (Section 4.3)", mk_mm(),                    bg_all,             pre1, post1),
  list("M_noSocio",    "Sociodemographic controls removed",   mk_mm(drop = demo),        setdiff(bg_all, demo), pre1, post1),
  list("M_noTangible", "Tangible cost removed",               mk_mm(drop = "TC"),        bg_all,             "PE", post1),
  list("M_noPS",       "Policy dependency removed",           mk_mm(drop = "PS"),        bg_all,             pre1, setdiff(post1, "PS")),
  list("M_IC1only",    "Intangible cost = general attitude (IC1) only", mk_mm(ic = "IC1"), bg_all,          pre1, post1),
  list("M_TolFull",    "Tol3 restored (four-item tolerance)", mk_mm(tol = c("Tol1_5","Tol2_1","Tol3_1","Tol4_5")), bg_all, pre1, post1))
models <- list()
specA <- bind_rows(lapply(specs, function(s) {
  m <- fit(df, s[[3]], sm_for(s[[4]], s[[5]], s[[6]])); models[[s[[1]]]] <<- m
  sb <- boot(m)
  tot <- pick(sb$bootstrapped_total_paths, "CE0  ->  Tol"); dir <- pick(sb$bootstrapped_paths, "CE0  ->  Tol")
  cat("done:", s[[1]], "\n")
  data.frame(spec = s[[1]], change = s[[2]], total = tot[["est"]], total_lo = tot[["lo"]], total_hi = tot[["hi"]], total_p = tot[["p"]],
             direct = dir[["est"]], direct_p = dir[["p"]], r2_tol = summary(m)$paths["R^2", "Tol"])
}))
write.csv(specA, file.path(tab_dir, "190_robustness_specifications.csv"), row.names = FALSE)

## ------------------------------------------------------------------ (B) measurement quality, primary model
s0 <- summary(models[["M0 (primary)"]])
tol_load <- s0$loadings[items$Tol, "Tol"]
tol_rel <- s0$reliability["Tol", ]
vif_formative <- unlist(s0$validity$vif_items[c("CP_WB","CP_A","CA","PS","TC","IC")])
htmt_ps <- s0$validity$htmt
write.csv(data.frame(quantity = c(paste("loading", items$Tol), names(tol_rel), "max VIF formative indicators"),
                     value = c(tol_load, unlist(tol_rel), max(vif_formative))),
          file.path(tab_dir, "191_measurement_primary.csv"), row.names = FALSE)

## ------------------------------------------------------------------ (C) multi-group analysis
## Composite signs are arbitrary in each subsample; align every group model to the full-sample
## weights so that a path difference is never a sign flip of a composite.
align <- function(m, ref) {
  for (k in intersect(names(items), colnames(m$outer_weights))) {
    it <- rownames(m$outer_weights)[m$outer_weights[, k] != 0]
    if (sum(m$outer_weights[it, k] * ref$outer_weights[it, k]) < 0) {
      m$outer_weights[, k] <- -m$outer_weights[, k]; m$path_coef[k, ] <- -m$path_coef[k, ]; m$path_coef[, k] <- -m$path_coef[, k]
    }
  }
  m
}
## Pooled indicator matrix for MICOM step 2: mean-imputed and standardised on the pooled sample.
pooled_X <- function(mm_items) { X <- as.matrix(df[, mm_items]); for (j in seq_len(ncol(X))) X[is.na(X[, j]), j] <- mean(X[, j], na.rm = TRUE); scale(X) }
labels <- c(CP_WB = "Conflict experience, wild boar", CP_A = "Conflict experience, all species", PE = "Prevention effectiveness",
            TC = "Tangible cost", CA = "Compensation anticipation", PS = "Policy dependency", IC = "Intangible cost",
            IB = "Intangible benefit", Gender = "Gender", Age = "Age", Education = "Education", Income = "Income (log)",
            HHAsset = "Household assets (log)", InNP = "Park residence", Site = "Survey site (Baoxing)")

run_mga <- function(label, drop_demo) {
  bg <- if (drop_demo) setdiff(bg_all, demo) else bg_all
  mm <- mk_mm(drop = c("CE0", if (drop_demo) demo)); sm <- sm_for(bg, pre1, post1, ce0 = FALSE)
  ref <- fit(df, mm, sm)
  est <- function(d) align(fit(d, mm, sm), ref)
  g1 <- df[df$CE0 == 1, ]; g0 <- df[df$CE0 == 0, ]
  m1 <- est(g1); m0 <- est(g0)
  preds <- rownames(ref$path_coef)[ref$path_coef[, "Tol"] != 0]
  multi <- intersect(names(items), colnames(ref$outer_weights))
  X <- pooled_X(unlist(items[multi]))
  comp_c <- function(a, b) sapply(multi, function(k) { it <- items[[k]]; cor(X[, it] %*% a$outer_weights[it, k], X[, it] %*% b$outer_weights[it, k]) })
  d_obs <- m1$path_coef[preds, "Tol"] - m0$path_coef[preds, "Tol"]; c_obs <- comp_c(m1, m0)
  set.seed(SEED)
  perm <- replicate(NPERM, {
    pl <- sample(df$CE0)
    a <- tryCatch(est(df[pl == 1, ]), error = function(e) NULL); b <- tryCatch(est(df[pl == 0, ]), error = function(e) NULL)
    if (is.null(a) || is.null(b)) rep(NA, length(preds) + length(multi))
    else c(a$path_coef[preds, "Tol"] - b$path_coef[preds, "Tol"], comp_c(a, b))
  })
  pd <- perm[seq_along(preds), , drop = FALSE]; pc <- perm[length(preds) + seq_along(multi), , drop = FALSE]
  p_perm <- sapply(seq_along(preds), function(i) { x <- na.omit(pd[i, ]); (1 + sum(abs(x) >= abs(d_obs[i]))) / (1 + length(x)) })
  ## group-specific bootstrap intervals
  ## percentile intervals read directly from the bootstrap array (summary() of a subgroup bootstrap can fail
  ## on its HTMT intervals when a single-item construct has no variance in a resample)
  saveRDS(list(d_obs = d_obs, pd = pd, pc = pc, c_obs = c_obs), file.path(root, "output/models", paste0("perm_", gsub(" ", "", label), ".rds")))
  ci <- function(m) { b <- quiet(bootstrap_model(m, nboot = NBOOT, seed = SEED))
    t(sapply(preds, function(p) { x <- b$boot_paths[p, "Tol", ]
      c(est = m$path_coef[p, "Tol"], lo = unname(quantile(x, .025, na.rm = TRUE)), hi = unname(quantile(x, .975, na.rm = TRUE)), p = NA) })) }
  ci1 <- ci(fit(g1, mm, sm)); ci0 <- ci(fit(g0, mm, sm))
  paths_tab <- data.frame(mga = label, path = preds, name = labels[preds],
                          b_appl = m1$path_coef[preds, "Tol"], appl_lo = ci1[, "lo"], appl_hi = ci1[, "hi"],
                          b_nonappl = m0$path_coef[preds, "Tol"], nonappl_lo = ci0[, "lo"], nonappl_hi = ci0[, "hi"],
                          diff = d_obs, p_perm = p_perm, p_holm = p.adjust(p_perm, "holm"), row.names = NULL)
  ## MICOM step 2: is the observed correlation of the two groups' composite weights below the 5% quantile under permutation?
  micom <- data.frame(mga = label, construct = multi, c_obs = c_obs,
                      q05 = apply(pc, 1, quantile, probs = 0.05, na.rm = TRUE),
                      p = sapply(seq_along(multi), function(i) mean(pc[i, ] <= c_obs[i], na.rm = TRUE)), row.names = NULL)
  micom$invariant <- micom$c_obs >= micom$q05
  htmt_pairs <- function(m, grp) { h <- summary(m)$validity$htmt; h[upper.tri(h, diag = TRUE)] <- NA  # seminr fills the LOWER triangle
    w <- which(h > 0.85, arr.ind = TRUE); if (!nrow(w)) return(NULL)
    data.frame(mga = label, group = grp, a = rownames(h)[w[, 1]], b = colnames(h)[w[, 2]], htmt = h[w]) }
  r2 <- data.frame(mga = label, group = c("applicants", "non-applicants"), n = c(nrow(g1), nrow(g0)),
                   r2 = c(summary(m1)$paths["R^2", "Tol"], summary(m0)$paths["R^2", "Tol"]),
                   adj_r2 = c(summary(m1)$paths["AdjR^2", "Tol"], summary(m0)$paths["AdjR^2", "Tol"]))
  cat("done:", label, "\n")
  list(paths = paths_tab, micom = micom, htmt = bind_rows(htmt_pairs(m1, "applicants"), htmt_pairs(m0, "non-applicants")), r2 = r2,
       n_failed = sum(is.na(pd[1, ])))
}
mga1 <- run_mga("MGA 1", drop_demo = FALSE)
mga2 <- run_mga("MGA 2", drop_demo = TRUE)
write.csv(bind_rows(mga1$paths, mga2$paths), file.path(tab_dir, "192_mga_paths.csv"), row.names = FALSE)
write.csv(bind_rows(mga1$micom, mga2$micom), file.path(tab_dir, "193_mga_micom.csv"), row.names = FALSE)
write.csv(bind_rows(mga1$htmt, mga2$htmt), file.path(tab_dir, "194_mga_htmt_above_085.csv"), row.names = FALSE)
write.csv(bind_rows(mga1$r2, mga2$r2), file.path(tab_dir, "195_mga_r2.csv"), row.names = FALSE)

## ------------------------------------------------------------------ LaTeX rows for Tables 12-14
n3 <- function(x) ifelse(is.na(x), "--", sprintf("$%s%.3f$", ifelse(x < 0, "-", ""), abs(x)))
pv <- function(p) ifelse(p < .001, "$<.001$", sub("^0", "", sprintf("%.3f", p)))
rows12 <- with(specA, sprintf("%s & %s & %s & [%s, %s] & %s & %s & %.3f \\\\",
  gsub("_", "\\\\_", spec), change, n3(total), n3(total_lo), n3(total_hi), pv(total_p), n3(direct), r2_tol))
mga_rows <- function(t) { t <- t[order(t$p_perm), ]
  sprintf("%s & %s & %s & %s & %s & %s \\\\", t$name, n3(t$b_appl), n3(t$b_nonappl), n3(t$diff), pv(t$p_perm), pv(t$p_holm)) }
writeLines(c("% Table 12 (tab:robustness-specs): spec & change & total & CI & p & direct & R2", rows12, "",
             "% Table 13 (tab:mga1): predictor & applicants & non-applicants & diff & p & p_Holm", mga_rows(mga1$paths), "",
             "% Table 14 (tab:mga2)", mga_rows(mga2$paths)), file.path(tab_dir, "198_latex_rows.tex"))

## ------------------------------------------------------------------ log
sink(file.path(tab_dir, "199_robustness_mga_log.txt"), split = TRUE)
cat("==================== (A) Six specifications: CE0 -> tolerance ====================\n")
cat("total = total effect of CE0 (the RQ1 estimand; -0.131 in the primary model), direct = direct path.\n\n")
print(specA, digits = 3, row.names = FALSE)
cat(sprintf("\nRange of the total effect: %.3f to %.3f; all p < .05: %s\n", min(specA$total), max(specA$total), all(specA$total_p < .05)))
cat("\n==================== (B) Measurement quality of the primary model ====================\n")
cat("Tolerance outer loadings:\n"); print(round(tol_load, 3))
cat("Tolerance reliability (alpha, rhoC, AVE, rhoA):\n"); print(round(unlist(tol_rel), 3))
cat(sprintf("Largest VIF among formative indicators: %.2f\n", max(vif_formative)))
cat("HTMT of policy dependency with the other constructs (all values):\n")
h <- suppressWarnings(pmax(htmt_ps["PS", ], htmt_ps[, "PS"], na.rm = TRUE)); h <- h[names(h) != "PS" & is.finite(h)]
print(round(sort(h, decreasing = TRUE), 2))
for (r in list(mga1, mga2)) {
  cat("\n====================", r$paths$mga[1], "(exploratory) ====================\n")
  print(r$r2, digits = 3, row.names = FALSE)
  cat("\nPaths into tolerance, by group; permutation p and Holm-corrected p:\n")
  print(r$paths[order(r$paths$p_perm), -1], digits = 3, row.names = FALSE)
  cat(sprintf("\nPaths with p_perm < .05: %d of %d; after Holm: %d. Failed permutations: %d of %d\n",
              sum(r$paths$p_perm < .05), nrow(r$paths), sum(r$paths$p_holm < .05), r$n_failed, NPERM))
  cat("\nMICOM step 2 (compositional invariance; invariant if c_obs >= 5% permutation quantile):\n")
  print(r$micom[, -1], digits = 3, row.names = FALSE)
  cat("\nHTMT > 0.85 within each group:\n"); if (is.null(r$htmt) || !nrow(r$htmt)) cat("none\n") else print(r$htmt[, -1], digits = 3, row.names = FALSE)
}
sink()
