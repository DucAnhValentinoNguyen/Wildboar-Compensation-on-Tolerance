## 17: does the reflective (mode A) vs formative (mode B) choice for Tolerance change the main paths?
suppressPackageStartupMessages({ library(dplyr); library(seminr) })
root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
run <- function(tolmode, label) {
  mm <- constructs(
    composite("CP_WB", c("CP_WB1","CP_WB2","CP_WB3","CP_WB4"), weights = mode_B), composite("CP_A", c("CP_A1","CP_A2","CP_A3"), weights = mode_B),
    composite("PE", single_item("PE")), composite("CE0", single_item("CE0")),
    composite("CA", c("CA1","CA2","log_ca3"), weights = mode_B), composite("PS", c("PS1","PS2"), weights = mode_B),
    composite("TC", c("TC1_DamagedArea","log_econloss"), weights = mode_B), composite("IC", c("IC1","IC2_1","IC2_2_imp","IC2_3_imp"), weights = mode_B),
    composite("IB", single_item("IB")), composite("Gender", single_item("gender")), composite("Age", single_item("age")),
    composite("Education", single_item("education")), composite("Income", single_item("log_income")), composite("HHAsset", single_item("log_hh_asset")),
    composite("InNP", single_item("in_np")), composite("Site", single_item("site_baoxing")),
    composite("Tol", c("Tol1_5","Tol2_1","Tol4_5"), weights = tolmode))
  t0 <- c("CP_WB","CP_A","Gender","Age","Education","Income","HHAsset","InNP","Site")
  sm <- relationships(paths(from = t0, to = c("PE","CE0")), paths(from = c(t0,"PE","CE0"), to = c("CA","PS","TC","IC","IB")),
                      paths(from = c(t0,"PE","CE0","CA","PS","TC","IC","IB"), to = "Tol"))
  m <- estimate_pls(df, mm, sm, missing = mean_replacement, maxIt = 500)
  b <- bootstrap_model(m, nboot = 2000, cores = 4, seed = 20260920)
  p <- as.data.frame(summary(b)$bootstrapped_paths); p$path <- rownames(p)
  p <- p[p$path %in% c("IC  ->  Tol","IB  ->  Tol","PE  ->  Tol","CE0  ->  Tol"), c("path","Original Est.","T Stat.","2.5% CI","97.5% CI")]
  cat("\n==", label, " R2(Tol) =", round(summary(m)$paths["R^2","Tol"], 3), "\n"); print(p, digits = 3)
  cat("Tol weights/loadings:\n"); print(round(m$outer_weights[c("Tol1_5","Tol2_1","Tol4_5"), "Tol"], 3))
}
sink(file.path(root, "output/tables/126_tolerance_formative_check.txt"), split = TRUE)
run(mode_A, "Tolerance REFLECTIVE-style (mode A, primary)"); run(mode_B, "Tolerance FORMATIVE-style (mode B)")
sink()
