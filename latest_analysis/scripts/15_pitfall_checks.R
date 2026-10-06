## 15_pitfall_checks.R -- three sensitivity checks on the compensation paradox
##  (A) Within-county: is CE0 -> Tolerance negative in BOTH counties, or is the
##      pooled estimate carried by one site? (compensation is confounded with
##      county, see 02_eda.R)
##  (B) Indirect effects: 95% bootstrap CIs and the smallest indirect effect
##      this design could detect with 80% power (~2.8 x bootstrap SD)
##  (C) Measurement error: latent-variable (lavaan, WLSMV) refit with Tolerance
##      as an ordinal latent factor and Intangible Cost given an assumed
##      reliability < 1, to see whether an error-prone mediator hides mediation
suppressPackageStartupMessages({ library(dplyr); library(seminr); library(lavaan); library(sandwich); library(lmtest) })

root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); mod_dir <- file.path(root, "output/models")
model0 <- readRDS(file.path(mod_dir, "plssem_model0_full.rds"))

sc <- as.data.frame(model0$construct_scores)
names(sc) <- paste0("s_", names(sc))
d <- bind_cols(df, sc)

sink(file.path(tab_dir, "120_pitfall_checks_log.txt"), split = TRUE)

## ---------------------------------------------------------------- (A)
cat("==================== (A) WITHIN-COUNTY CE0 -> TOLERANCE ====================\n")
cat("\nUnadjusted mean tolerance score (PLS composite, standardised) by county x CE0:\n")
print(d %>% group_by(site_baoxing, CE0) %>% summarise(n = n(), tol = mean(s_Tol), sd = sd(s_Tol), .groups = "drop"))

ctrl <- "s_CP_WB + s_CP_A + gender + age + education + log_income + log_hh_asset + in_np"
med  <- "s_PE + s_CA + s_PS + s_TC + s_IC + s_IB"
hc <- function(fit, term) { ct <- coeftest(fit, vcov = vcovHC(fit, type = "HC3")); ci <- coefci(fit, vcov = vcovHC(fit, type = "HC3"))
  data.frame(est = ct[term, 1], se = ct[term, 2], lo = ci[term, 1], hi = ci[term, 2], p = ct[term, 4]) }

rowsA <- list()
for (s in c(0, 1)) {
  ds <- d %>% filter(site_baoxing == s)
  lab <- ifelse(s == 1, "Baoxing", "Qingchuan")
  f_tot <- lm(as.formula(paste("s_Tol ~ CE0 +", ctrl)), data = ds)
  f_dir <- lm(as.formula(paste("s_Tol ~ CE0 +", ctrl, "+", med)), data = ds)
  rowsA[[length(rowsA) + 1]] <- cbind(county = lab, n = nrow(ds), model = "total (controls only)", hc(f_tot, "CE0"))
  rowsA[[length(rowsA) + 1]] <- cbind(county = lab, n = nrow(ds), model = "direct (controls + mediators)", hc(f_dir, "CE0"))
}
f_tot <- lm(as.formula(paste("s_Tol ~ CE0 + site_baoxing +", ctrl)), data = d)
f_dir <- lm(as.formula(paste("s_Tol ~ CE0 + site_baoxing +", ctrl, "+", med)), data = d)
rowsA[[length(rowsA) + 1]] <- cbind(county = "Pooled", n = nrow(d), model = "total (controls only)", hc(f_tot, "CE0"))
rowsA[[length(rowsA) + 1]] <- cbind(county = "Pooled", n = nrow(d), model = "direct (controls + mediators)", hc(f_dir, "CE0"))
tabA <- bind_rows(rowsA)
cat("\nCE0 coefficient on standardised tolerance score (CE0 is 0/1, so this is the\nadjusted gap in SD units; HC3 robust SE):\n"); print(tabA, digits = 3)

f_int <- lm(as.formula(paste("s_Tol ~ CE0 * site_baoxing +", ctrl, "+", med)), data = d)
cat("\nCE0 x county interaction (direct model):\n"); print(hc(f_int, "CE0:site_baoxing"), digits = 3)
write.csv(tabA, file.path(tab_dir, "121_within_county_ce0.csv"), row.names = FALSE)

## ---------------------------------------------------------------- (B)
cat("\n==================== (B) INDIRECT EFFECTS: CI AND DETECTABLE SIZE ====================\n")
ind <- read.csv(file.path(tab_dir, "51_mediation_indirect_effects.csv"))
tabB <- ind %>% transmute(mediator, est = Original.Est., se = Bootstrap.SD, lo = X2.5..CI, hi = X97.5..CI,
                          detectable_80 = 2.8 * Bootstrap.SD)
print(tabB, digits = 3)
cat("\nDirect effect CE0 -> Tol = -0.109. An indirect effect would need to be about\n2.8 x SE in size to be detected with 80% power at alpha = .05.\n")
write.csv(tabB, file.path(tab_dir, "122_indirect_ci_power.csv"), row.names = FALSE)

## ---------------------------------------------------------------- (C)
cat("\n==================== (C) LATENT-VARIABLE / MEASUREMENT-ERROR SENSITIVITY ====================\n")
d$Tol1o <- ordered(d$Tol1_5); d$Tol2o <- ordered(d$Tol2_1); d$Tol4o <- ordered(d$Tol4_5)
zs <- function(x) as.numeric(scale(x))
for (v in c("gender","age","education","log_income","log_hh_asset","in_np")) d[[paste0("z_", v)]] <- zs(d[[v]])
zc <- "s_CP_WB + s_CP_A + z_gender + z_age + z_education + z_log_income + z_log_hh_asset + z_in_np + site_baoxing"
vIC <- var(d$s_IC)

fit_rel <- function(rel) {
  m <- paste0('
    Tol =~ Tol1o + Tol2o + Tol4o
    ICl =~ 1*s_IC
    s_IC ~~ ', (1 - rel) * vIC, '*s_IC
    ICl ~ a*CE0 + ', zc, '
    Tol ~ c*CE0 + b*ICl + s_IB + s_PE + s_CA + s_PS + s_TC + ', zc, '
    ind := a*b
    tot := c + a*b
  ')
  f <- sem(m, data = d, estimator = "WLSMV", ordered = c("Tol1o","Tol2o","Tol4o"))
  pe <- standardizedSolution(f)
  g <- function(lab) pe[pe$label == lab, c("est.std","se","ci.lower","ci.upper","pvalue")]
  out <- rbind(cbind(quantity = "direct CE0->Tol (c)", g("c")), cbind(quantity = "IC->Tol (b)", g("b")),
               cbind(quantity = "CE0->IC (a)", g("a")), cbind(quantity = "indirect via IC (a*b)", g("ind")))
  cbind(IC_reliability = rel, out)
}
tabC <- bind_rows(lapply(c(1, 0.9, 0.8, 0.7, 0.6), fit_rel))
rownames(tabC) <- NULL
cat("Standardised (std.all) estimates. Tolerance = ordinal latent factor; Intangible Cost =\nPLS composite score with assumed reliability. CE0 is binary, so its std.all value is\nnot directly comparable in size to the PLS beta; compare signs and the pattern across rows.\n\n")
print(tabC, digits = 3)
write.csv(tabC, file.path(tab_dir, "123_latent_sensitivity.csv"), row.names = FALSE)
sink()
