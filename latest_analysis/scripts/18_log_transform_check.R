## 18: do the log(1+x) transforms matter? Same OLS as 11_regression_crosscheck, with raw vs log vs z-scored-raw money variables.
suppressPackageStartupMessages({ library(dplyr); library(sandwich); library(lmtest) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
df$econloss <- df$TC2_EconomicLoss
f <- function(inc, ass, loss, lab) {
  d <- df; d$m_inc <- inc(d$income); d$m_ass <- ass(d$hh_asset); d$m_loss <- loss(d$econloss)
  fit <- lm(tol_mean_no3 ~ CE0 + cpwb_idx + m_loss + ic_idx + IB + PS1 + PS2 + gender + age + education + m_inc + m_ass + in_np + site_baoxing, data = d)
  ct <- coeftest(fit, vcov = vcovHC(fit, "HC3"))
  data.frame(spec = lab, R2 = summary(fit)$r.squared, CE0 = ct["CE0", 1], p_CE0 = ct["CE0", 4], IC = ct["ic_idx", 1], IB = ct["IB", 1],
             sig_money = paste(c("income","assets","loss")[ct[c("m_inc","m_ass","m_loss"), 4] < .05], collapse = "+"),
             p_inc = ct["m_inc", 4], p_ass = ct["m_ass", 4], p_loss = ct["m_loss", 4])
}
id <- identity; lg <- log1p; zs <- function(x) as.numeric(scale(x))
out <- bind_rows(f(lg, lg, lg, "log(1+x) (primary)"), f(id, id, id, "raw RMB"), f(zs, zs, zs, "raw, z-scored"), f(rank, rank, rank, "rank-transformed"))
print(out, digits = 3); write.csv(out, file.path(root, "output/tables/127_log_transform_check.csv"), row.names = FALSE)
cat("\nSkewness of raw vs log:\n")
sk <- function(x) { x <- x[is.finite(x)]; mean((x - mean(x))^3) / sd(x)^3 }
print(round(sapply(list(income = df$income, assets = df$hh_asset, loss = df$econloss, ca3 = df$CA3), function(x) c(raw = sk(x), log = sk(log1p(x)))), 2))
