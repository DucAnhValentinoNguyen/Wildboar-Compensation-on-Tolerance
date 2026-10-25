## 19: balance check in the predictive direction -- who applies for compensation?
## Wilcoxon (bivariate, pooled) vs within-county Wilcoxon vs joint logistic regression of CE0.
suppressPackageStartupMessages({ library(dplyr); library(sandwich); library(lmtest) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
vars <- c(age = "Age", education = "Education", hh_pop = "Household size", income = "Annual income", agri_prop = "Share of income from agriculture",
          total_cropland = "Total cropland", total_livestock = "Total livestock", hh_asset = "Household assets")
w <- function(d, v) suppressWarnings(wilcox.test(d[[v]] ~ d$CE0, exact = FALSE)$p.value)
tab <- data.frame(variable = unname(vars), pooled = sapply(names(vars), w, d = df),
  Qingchuan = sapply(names(vars), w, d = filter(df, site_baoxing == 0)), Baoxing = sapply(names(vars), w, d = filter(df, site_baoxing == 1)))
tab$Pooled_BH <- p.adjust(tab$pooled, "BH")
cat("Wilcoxon rank-sum p-values: pooled vs within county\n"); print(tab, digits = 3)
d <- df %>% mutate(z_age = scale(age)[,1], z_edu = scale(education)[,1], z_hh = scale(hh_pop)[,1], z_inc = scale(log1p(income))[,1], z_agri = scale(agri_prop)[,1],
                   z_crop = scale(log1p(total_cropland))[,1], z_live = scale(log1p(total_livestock))[,1], z_ass = scale(log1p(hh_asset))[,1], male = gender)
fit_one <- function(form, lab) { m <- glm(form, data = d, family = binomial); ct <- coeftest(m, vcov = vcovHC(m, "HC3"))
  o <- data.frame(model = lab, term = rownames(ct), OR = exp(ct[,1]), lo = exp(ct[,1] - 1.96*ct[,2]), hi = exp(ct[,1] + 1.96*ct[,2]), p = ct[,4])[-1,]
  print(o, digits = 3, row.names = FALSE); o }
f <- CE0 ~ z_age + male + z_edu + z_hh + z_inc + z_agri + z_crop + z_live + z_ass
a <- fit_one(f, "no county"); b <- fit_one(update(f, . ~ . + site_baoxing), "with county")
cat("\nDirection check: odds ratios per 1 SD (log money variables); HC3 robust SEs\n")
write.csv(rbind(a, b), file.path(root, "output/tables/128_ce0_logistic.csv"), row.names = FALSE)
write.csv(tab, file.path(root, "output/tables/129_balance_within_county.csv"), row.names = FALSE)

## ---- Does the scale of the money and area variables matter for who applies? -----------------------
## The same logistic model (with county) with the four money/area variables as log(1+x) (primary),
## on the original scale, and as ranks; plus the skewness and zero counts that motivate the log.
sk <- function(x) mean((x - mean(x))^3) / sd(x)^3
mv <- c(Income = "income", Assets = "hh_asset", Cropland = "total_cropland", Livestock = "total_livestock",
        `Economic loss` = "TC2_EconomicLoss", `Insurance willingness to pay` = "CA3")
desc <- data.frame(variable = names(mv), min = sapply(mv, function(v) min(df[[v]])), median = sapply(mv, function(v) median(df[[v]])),
                   max = sapply(mv, function(v) max(df[[v]])), zeros = sapply(mv, function(v) sum(df[[v]] == 0)),
                   skew_raw = sapply(mv, function(v) sk(df[[v]])), skew_log = sapply(mv, function(v) sk(log1p(df[[v]]))), row.names = NULL)
write.csv(desc, file.path(root, "output/tables/128b_money_variable_scales.csv"), row.names = FALSE)
fit_scale <- function(tr, label) {
  dd <- df %>% mutate(age = as.numeric(scale(age)), male = gender, edu = as.numeric(scale(education)), hh = as.numeric(scale(hh_pop)),
                      inc = as.numeric(scale(tr(income))), agri = as.numeric(scale(agri_prop)), crop = as.numeric(scale(tr(total_cropland))),
                      live = as.numeric(scale(tr(total_livestock))), ass = as.numeric(scale(tr(hh_asset))))
  m <- glm(CE0 ~ age + male + edu + hh + inc + agri + crop + live + ass + site_baoxing, data = dd, family = binomial)
  ct <- coeftest(m, vcov = vcovHC(m, "HC3")); ci <- coefci(m, vcov = vcovHC(m, "HC3"))
  data.frame(scale = label, term = rownames(ct)[-1], OR = exp(ct[-1, 1]), lo = exp(ci[-1, 1]), hi = exp(ci[-1, 2]), p = ct[-1, 4], row.names = NULL)
}
sc <- bind_rows(fit_scale(log1p, "log(1+x)"), fit_scale(identity, "original scale"), fit_scale(rank, "ranks"))
write.csv(sc, file.path(root, "output/tables/128c_ce0_logistic_scales.csv"), row.names = FALSE)
cat("\nWho applies: money and area variables as log(1+x), original scale, and ranks\n"); print(sc[sc$term %in% c("inc","ass","crop","live","site_baoxing"), ], digits = 3, row.names = FALSE)
