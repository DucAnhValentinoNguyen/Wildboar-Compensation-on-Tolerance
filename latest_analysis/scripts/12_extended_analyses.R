## 12_extended_analyses.R -- exploiting parts of the dataset the original
## WTM model never used: personal threat exposure, hunting-prevalence
## perception, behavioural reaction on encounter, species co-occurrence,
## the asset-based wealth index (05_pca.R), mitigation-strategy portfolios,
## and the free-text "three words" descriptions.
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(nnet); library(broom)
  library(cluster); library(factoextra)
})

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
df <- readRDS(file.path(root, "output/models/clean_data_with_diagnostics.rds"))
tab_dir <- file.path(root, "output/tables"); fig_dir <- file.path(root, "output/figures")

sink(file.path(tab_dir, "100_extended_log.txt"))

## ---------- (1) Wealth PCA index vs. asset/income controls ------------------
cat("==================== Wealth index vs Tolerance & Tangible Cost ====================\n")
m_wealth <- lm(tol_mean_no3 ~ wealth_pc1 + log_income + CE0 + gender + age + education +
                 site_baoxing, data = df)
print(summary(m_wealth))
cat("\nWealth index predicting perceived tangible cost (log economic loss):\n")
print(summary(lm(log_econloss ~ wealth_pc1 + CE0 + site_baoxing, data = df)))

## ---------- (2) Personal threat exposure as an alternative cost proxy ------
cat("\n\n==================== Direct threat exposure (scared/attacked) ====================\n")
cat("Prevalence: "); print(table(df$direct_threat_exposure, useNA = "always"))
m_threat <- lm(tol_mean_no3 ~ direct_threat_exposure + ic_idx + IB + CE0 + site_baoxing,
               data = df)
print(summary(m_threat))
cat("\nDoes direct threat exposure predict Intangible Cost (IC1)?\n")
print(summary(lm(IC1 ~ direct_threat_exposure + site_baoxing, data = df)))

## ---------- (3) Hunting prevalence perception -------------------------------
cat("\n\n==================== Perceived hunting prevalence ====================\n")
print(table(df$hunted_label, df$comp_f))
print(summary(lm(tol_mean_no3 ~ hunted_ordinal + site_baoxing, data = df)))

## ---------- (4) Behavioural reaction on encounter (multinomial) -----------
cat("\n\n==================== Encounter reaction ~ tolerance & attitudes ====================\n")
print(table(df$reaction))
df$reaction <- relevel(df$reaction, ref = "Avoid/coexist")
m_react <- multinom(reaction ~ tol_mean_no3 + ic_idx + IB + direct_threat_exposure + site_baoxing,
                     data = df, trace = FALSE)
print(summary(m_react))
z <- summary(m_react)$coefficients / summary(m_react)$standard.errors
p <- (1 - pnorm(abs(z))) * 2
cat("\np-values:\n"); print(round(p, 4))

## ---------- (5) Species co-occurrence ---------------------------------------
cat("\n\n==================== Multi-species conflict exposure ====================\n")
print(table(df$multispecies_conflict))
print(summary(lm(tol_mean_no3 ~ multispecies_conflict + n_species_conflict + site_baoxing,
                  data = df)))

## ---------- (6) Mitigation-strategy portfolio clustering -------------------
cat("\n\n==================== Mitigation strategy adoption clusters ====================\n")
pe_cols <- c("PE_A_count","PE_B_count","PE_C_count","PE_D_count","PE_E_count","PE_F_count","PE_G_count")
pe_data <- df[pe_cols]
names(pe_data) <- c("Barriers","Disruption","HumanGuard","CropChange","AnimalGuard","Relocation/Hunt","Resettlement")
gower_d <- daisy(pe_data, metric = "gower")
pam_k <- lapply(2:5, function(k) pam(gower_d, k = k, diss = TRUE))
sil_widths <- sapply(pam_k, function(x) x$silinfo$avg.width)
cat("Average silhouette width for k=2..5:", round(sil_widths, 3), "\n")
best_k <- which.max(sil_widths) + 1
pam_best <- pam_k[[which.max(sil_widths)]]
df$mitig_cluster <- factor(pam_best$clustering)
cat("Chosen k =", best_k, "\n")
print(aggregate(pe_data, by = list(cluster = df$mitig_cluster), mean))
cat("\nAdoption rate (n strategies used) by cluster:\n")
print(df %>% group_by(mitig_cluster) %>% summarise(n=n(), mean_PE_count = mean(PE_count, na.rm=TRUE),
                                                     mean_tol = mean(tol_mean_no3, na.rm=TRUE)))
print(summary(aov(tol_mean_no3 ~ mitig_cluster, data = df)))

sink()

## ---------- (7) Three-word free-text frequency, by compensation status ----
words_long <- df %>%
  select(ID, comp_f, word1, word2, word3) %>%
  pivot_longer(c(word1, word2, word3), names_to = "slot", values_to = "word") %>%
  filter(!is.na(word), word != "")

top_words_overall <- words_long %>% count(word, sort = TRUE) %>% head(15)
top_words_by_comp <- words_long %>% count(comp_f, word) %>%
  group_by(comp_f) %>% slice_max(n, n = 10) %>% ungroup()

write.csv(top_words_overall, file.path(tab_dir, "101_top_words_overall.csv"), row.names = FALSE)
write.csv(top_words_by_comp, file.path(tab_dir, "102_top_words_by_compensation.csv"), row.names = FALSE)

## Save extended-analysis figures
p1 <- ggplot(pe_data %>% mutate(cluster = df$mitig_cluster) %>%
               pivot_longer(-cluster, names_to = "strategy", values_to = "used"),
             aes(x = strategy, y = used, fill = cluster)) +
  stat_summary(fun = mean, geom = "bar", position = "dodge") +
  labs(title = "Mitigation-strategy adoption rate by cluster", y = "Proportion using", x = NULL) +
  theme_minimal() + theme(axis.text.x = element_text(angle = 30, hjust = 1))
ggsave(file.path(fig_dir, "09_mitigation_clusters.png"), p1, width = 9, height = 5, dpi = 150)

saveRDS(df, file.path(root, "output/models/clean_data_with_diagnostics.rds"))

cat("Extended analyses complete.\n")
