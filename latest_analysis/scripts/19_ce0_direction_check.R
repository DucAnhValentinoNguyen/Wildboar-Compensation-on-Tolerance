## 19: balance check in the predictive direction -- who applies for compensation?
## Wilcoxon (bivariate, pooled) vs within-county Wilcoxon vs joint logistic regression of CE0.
suppressPackageStartupMessages({ library(dplyr); library(sandwich); library(lmtest) })
root <- "/home/duc/Wildboar-Compensation-on-Tolerance/latest_analysis"
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
