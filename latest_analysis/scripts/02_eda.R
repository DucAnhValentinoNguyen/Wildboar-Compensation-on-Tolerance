## 02_eda.R -- Exploratory Data Analysis
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(purrr)
  library(tibble); library(scales); library(patchwork)
})

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data.rds"))
fig_dir <- file.path(root, "output/figures"); tab_dir <- file.path(root, "output/tables")
dir.create(fig_dir, showWarnings = FALSE); dir.create(tab_dir, showWarnings = FALSE)

theme_set(theme_minimal(base_size = 11))

## ---------- 1. Sample composition & data-quality summary ------------------

quality_tbl <- tibble(
  check = c(
    "N respondents", "With compensation (CE0=1)", "Without compensation (CE0=0)",
    "Baoxing county", "Qingchuan county", "Living inside NP",
    "IC2_2 recoded 0->NA (word 2 not given)", "IC2_3 recoded 0->NA (word 3 not given)",
    "CA1 > 1 (extreme, kept)", "CA2 > 1 (extreme, kept)",
    "Any missing value outside CE1/CE2 skip pattern"
  ),
  value = c(
    nrow(df), sum(df$CE0 == 1), sum(df$CE0 == 0),
    sum(df$county == "Baoxing"), sum(df$county == "Qingchuan"), sum(df$in_np == 1),
    sum(is.na(df$IC2_2) & df$IC2_2_raw == 0), sum(is.na(df$IC2_3) & df$IC2_3_raw == 0),
    sum(df$ca1_extreme), sum(df$ca2_extreme),
    sum(sapply(df %>% select(-CE1, -CE2), function(x) sum(is.na(x))))
  )
)
write.csv(quality_tbl, file.path(tab_dir, "00_data_quality_summary.csv"), row.names = FALSE)

## ---------- 2. Sociodemographics by county & by compensation status -------

soc_vars <- c("age", "education", "hh_pop", "income", "agri_prop", "total_cropland",
              "total_livestock", "hh_asset")

soc_by_group <- function(grpvar) {
  df %>%
    group_by(.data[[grpvar]]) %>%
    summarise(n = n(), across(all_of(soc_vars), list(mean = ~mean(.x, na.rm=TRUE),
                                                       median = ~median(.x, na.rm=TRUE),
                                                       sd = ~sd(.x, na.rm=TRUE)), .names = "{.col}_{.fn}"))
}
write.csv(soc_by_group("county"), file.path(tab_dir, "01_socio_by_county.csv"), row.names = FALSE)
write.csv(soc_by_group("comp_f"), file.path(tab_dir, "01_socio_by_compensation.csv"), row.names = FALSE)

## Chi-square / Wilcoxon comparisons: compensation groups
comp_tests <- map_dfr(soc_vars, function(v) {
  wt <- wilcox.test(df[[v]] ~ df$CE0)
  tibble(variable = v, test = "Wilcoxon", statistic = unname(wt$statistic), p_value = wt$p.value)
})
gender_chisq <- chisq.test(table(df$gender_f, df$comp_f))
county_chisq <- chisq.test(table(df$county, df$comp_f))
comp_tests <- bind_rows(
  comp_tests,
  tibble(variable = "gender", test = "Chi-sq", statistic = unname(gender_chisq$statistic), p_value = gender_chisq$p.value),
  tibble(variable = "county",  test = "Chi-sq", statistic = unname(county_chisq$statistic), p_value = county_chisq$p.value)
)
write.csv(comp_tests, file.path(tab_dir, "02_compensation_group_tests.csv"), row.names = FALSE)

## ---------- 3. Distributions of WTM indicators -----------------------------

likert_vars <- c("CP_WB1","CP_WB2","CP_WB3","CP_WB4","CP_A1","CP_A2","CP_A3",
                  "IC1","IC2_1","IC2_2","IC2_3","IB",
                  "Tol1_5","Tol2_1","Tol3_1","Tol4_5","PE","PS1","PS2")

long_likert <- df %>% select(all_of(likert_vars)) %>%
  pivot_longer(everything(), names_to = "item", values_to = "value")

p_likert <- ggplot(long_likert %>% filter(!is.na(value)), aes(x = value)) +
  geom_bar(fill = "#3b6e8f") +
  facet_wrap(~item, scales = "free", ncol = 4) +
  labs(title = "Distribution of Wildlife Tolerance Model indicators", x = NULL, y = "Count")
ggsave(file.path(fig_dir, "01_likert_distributions.png"), p_likert, width = 12, height = 10, dpi = 150)

## Skewed monetary variables (log scale)
money_vars <- c("income", "hh_asset", "TC2_EconomicLoss", "CA3")
long_money <- df %>% select(all_of(money_vars)) %>%
  pivot_longer(everything(), names_to = "item", values_to = "value") %>%
  filter(value >= 0)
p_money <- ggplot(long_money, aes(x = value + 1)) +
  geom_histogram(bins = 40, fill = "#00883F") +
  scale_x_log10(labels = comma) +
  facet_wrap(~item, scales = "free", ncol = 2) +
  labs(title = "Monetary / area variables (log10 scale, +1)", x = NULL, y = "Count")
ggsave(file.path(fig_dir, "02_monetary_distributions.png"), p_money, width = 9, height = 7, dpi = 150)

## ---------- 4. Tolerance items by compensation status & county ------------

tol_long <- df %>%
  select(comp_f, county, Tol1_5, Tol2_1, Tol3_1, Tol4_5, tol_mean) %>%
  pivot_longer(c(Tol1_5, Tol2_1, Tol3_1, Tol4_5, tol_mean), names_to = "item", values_to = "value")

p_tol_comp <- ggplot(tol_long, aes(x = comp_f, y = value, fill = comp_f)) +
  geom_boxplot(alpha = .7, outlier.size = .8) +
  facet_wrap(~item, scales = "free_y", ncol = 5) +
  labs(title = "Tolerance items by compensation status", x = NULL, y = "Score") +
  theme(legend.position = "none", axis.text.x = element_text(angle = 20, hjust = 1))
ggsave(file.path(fig_dir, "03_tolerance_by_compensation.png"), p_tol_comp, width = 11, height = 4, dpi = 150)

p_tol_county <- ggplot(tol_long, aes(x = county, y = value, fill = county)) +
  geom_boxplot(alpha = .7, outlier.size = .8) +
  facet_wrap(~item, scales = "free_y", ncol = 5) +
  labs(title = "Tolerance items by county (survey site/wave)", x = NULL, y = "Score") +
  theme(legend.position = "none")
ggsave(file.path(fig_dir, "04_tolerance_by_county.png"), p_tol_county, width = 11, height = 4, dpi = 150)

## ---------- 5. Correlation heatmap of numeric indicators -------------------

num_vars <- c("CP_WB1","CP_WB2","CP_WB3","CP_WB4","CP_A1","CP_A2","CP_A3",
              "TC1_DamagedArea","log_econloss","IC1","IC2_1","IC2_2","IC2_3","IB",
              "Tol1_5","Tol2_1","Tol3_1","Tol4_5","PE","CE0","CA1","CA2","log_ca3","PS1","PS2",
              "gender","age","education","log_income","log_hh_asset","in_np")

cor_mat <- cor(df[num_vars], use = "pairwise.complete.obs")
write.csv(round(cor_mat, 3), file.path(tab_dir, "03_correlation_matrix.csv"))

png(file.path(fig_dir, "05_correlation_heatmap.png"), width = 1400, height = 1300, res = 150)
corrplot::corrplot(cor_mat, method = "color", type = "upper", order = "original",
                    tl.cex = .65, tl.col = "black", diag = FALSE,
                    title = "Pairwise correlations (all numeric indicators)", mar = c(0,0,2,0))
dev.off()

## ---------- 6. Bivariate: compensation participation vs conflict / county --

tab_ce0_county <- table(df$county, df$comp_f)
tab_ce0_np <- table(df$in_np_f, df$comp_f)
write.csv(as.data.frame.matrix(tab_ce0_county), file.path(tab_dir, "04_ce0_by_county.csv"))
write.csv(as.data.frame.matrix(tab_ce0_np), file.path(tab_dir, "04_ce0_by_np.csv"))

## ---------- 7. Multivariate outlier screen (Mahalanobis) -------------------

maha_vars <- c("CP_WB1","CP_WB2","CP_WB3","CP_WB4","CP_A1","CP_A2","CP_A3",
               "TC1_DamagedArea","log_econloss","IC1","IB","Tol1_5","Tol2_1","Tol3_1","Tol4_5")
maha_data <- df[maha_vars]
maha_d2 <- mahalanobis(maha_data, colMeans(maha_data), cov(maha_data))
maha_p <- pchisq(maha_d2, df = length(maha_vars), lower.tail = FALSE)
df$maha_d2 <- maha_d2; df$maha_p <- maha_p
outlier_tbl <- df %>% filter(maha_p < .001) %>%
  select(ID, county, comp_f, maha_d2, maha_p)
write.csv(outlier_tbl, file.path(tab_dir, "05_multivariate_outliers.csv"), row.names = FALSE)

saveRDS(df, file.path(root, "output/models/clean_data_with_diagnostics.rds"))

cat("EDA complete.\n")
cat("Multivariate outliers (p<.001):", nrow(outlier_tbl), "of", nrow(df), "\n")
print(comp_tests)
