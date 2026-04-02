# =============================================================================
# Wild Boar Tolerance Study – PLS-SEM Analysis in R
# Giant Panda National Park, China
# Protocol Steps: Measurement model → Mediation/Moderation → MGA → Robustness
# =============================================================================

# 0. INSTALL & LOAD PACKAGES ───────────────────────────────────────────────
install.packages(c("seminr", "readxl", "dplyr", "tidyr", "ggplot2",
                   "psych", "corrplot", "flextable", "officer"))

library(seminr)   
library(readxl)      
library(dplyr)       
library(tidyr)       
library(ggplot2)
library(psych)
library(corrplot)   



# 1. DATA LOADING & PREPARATION

df_raw <- read_excel("3_Data.xlsx", sheet = "Input Data")

# 1.1  Binary compensation variable (CP_WB1: 1=no compensation, 2-5 = some)
#    277 with compensation, 348 without
#   Treat CP_WB1 == 1 as "No compensation", 2-5 as "Yes compensation"
df <- df_raw %>%
  mutate(
    Compensation = if_else(CP_WB1 == 1, 0L, 1L),          # 0 = No, 1 = Yes
    
    # Conflict Experience (WB-specific; CE1/CE2 only for compensation group)
    CE1_imp = replace_na(CE1, 0),
    CE2_imp = replace_na(CE2, 0),
    
    # Log-transform heavily skewed tangible cost variables
    TC1_log = log1p(TC1_DamagedArea),
    TC2_log = log1p(TC2_EconomicLoss),
    CA1_log = log1p(CA1),
    CA2_log = log1p(CA2),
    CA3_log = log1p(CA3))

cat("Total N:", nrow(df), "\n")
cat("With compensation:", sum(df$Compensation == 1), "\n")
cat("Without compensation:", sum(df$Compensation == 0), "\n")
cat("Counties:", table(df$Q1_County), "\n")


# 2. DESCRIPTIVE STATISTICS & MISSING DATA

# 2.1  Key variable overview
key_vars <- c(
  "Tol1_5", "Tol2_1", "Tol3_1", "Tol4_5",       # Tolerance
  "TC1_DamagedArea", "TC2_EconomicLoss",           # Tangible costs
  "IC1", "IC2_1", "IC2_2", "IC2_3",               # Intangible costs
  "IB",                                            # Intangible benefits
  "PE",                                            # Prevention effectiveness
  "CE0", "CE1_imp", "CE2_imp",                     # Conflict experience
  "CA1", "CA2", "CA3",                             # Compensation anticipation
  "PS1", "PS2",                                    # Policy support/dependency
  "Q5_Age", "Q4_Gender", "Q6_Education",
  "Q8_AnnualIncome", "Q14_HouseholdAsset"
)

desc_stats <- describe(df[, key_vars])[, c("n", "mean", "sd", "median",
                                           "min", "max", "skew", "kurtosis")]
print(round(desc_stats, 3))

# 2.2  Missing values
cat("\nMissing values per key variable:\n")
print(colSums(is.na(df[, key_vars])))

# 2.3  Correlation matrix (reflective indicators)
cor_vars <- c("Tol1_5", "Tol2_1", "Tol3_1", "Tol4_5",
              "IC1", "IC2_1", "IC2_2", "IC2_3", "IB")
cor_mat <- cor(df[, cor_vars], use = "pairwise.complete.obs")

## Plot einfach so
corrplot(cor_mat, method = "color", type = "upper",
         addCoef.col = "black", number.cex = 0.7,
         tl.col = "black", tl.srt = 45,
         title = "Correlation Matrix – Tolerance & Intangible Cost/Benefit Indicators",
         mar = c(0, 0, 2, 0))

# 2.4  Group comparison (compensation vs. no compensation)
group_compare <- df %>%
  group_by(Compensation) %>%
  summarise(across(all_of(c("Tol1_5", "Tol2_1", "Tol4_5",
                            "IC1", "IC2_1", "IB", "PE")),
                   list(mean = ~mean(.x, na.rm = TRUE),
                        sd   = ~sd(.x,   na.rm = TRUE)),
                   .names = "{.col}_{.fn}"))
print(group_compare)

# t-tests for tolerance items by compensation group
for (v in c("Tol1_5", "Tol2_1", "Tol4_5")) {
  tt <- t.test(df[[v]] ~ df$Compensation)
  cat(sprintf("t-test %s: t=%.3f, p=%.4f\n", v, tt$statistic, tt$p.value))
}


# 3. PLS-SEM MEASUREMENT MODEL (Model 0 – Full Sample)

# Uses the {seminr} package. All reflective constructs follow WTM outer model.

# ─3.1  Define measurement model
mm <- constructs(
  # Tolerance (reflective)
  composite("Tolerance",
            multi_items("Tol", c("1_5", "2_1", "4_5")),   # Tol3_1 excluded (see protocol)
            weights = correlation_weights),
  
  # Intangible Costs (reflective)
  composite("IntangibleCosts",
            multi_items("IC", c("1", "2_1", "2_2")),       # IC2_3 excluded (non-sig)
            weights = correlation_weights),
  
  # Intangible Benefits (single item)
  composite("IntangibleBenefits",
            single_item("IB")),
  
  # Tangible Costs (reflective)
  composite("TangibleCosts",
            multi_items("TC", c("1_log", "2_log")),
            weights = correlation_weights),
  
  # Conflict Experience – WB specific (reflective; CE1/CE2 imputed to 0 for non-comp.)
  composite("ConflictExp_WB",
            multi_items("CE", c("1_imp", "2_imp")),
            weights = correlation_weights),
  
  # Conflict Experience – General
  single_item("CE0"),   # treated as single-item proxy
  
  # Prevention Effectiveness (single item)
  single_item("PE"),
  
  # Policy Support / Dependency
  composite("PolicyDep",
            multi_items("PS", c("1", "2")),
            weights = correlation_weights),
  
  # Compensation Anticipation
  composite("CompAnticipation",
            multi_items("CA", c("1_log", "3_log")),  # CA2 excluded (non-sig)
            weights = correlation_weights),
  
  # Compensation (binary, used as antecedent)
  single_item("Compensation"))

# 3.2  Define structural model (Model 0 – direct effects)
sm <- relationships(
  paths(from = "Compensation",      to = "Tolerance"),
  paths(from = "IntangibleCosts",   to = "Tolerance"),
  paths(from = "IntangibleBenefits",to = "Tolerance"),
  paths(from = "TangibleCosts",     to = "Tolerance"),
  paths(from = "ConflictExp_WB",    to = "Tolerance"),
  paths(from = "CE0",               to = "Tolerance"),
  paths(from = "PE",                to = "Tolerance"),
  paths(from = "PolicyDep",         to = "Tolerance"),
  paths(from = "CompAnticipation",  to = "Tolerance"),
  # Sociodemographics as controls
  paths(from = c("Q5_Age", "Q4_Gender", "Q6_Education",
                 "Q8_AnnualIncome", "Q14_HouseholdAsset"),
        to = "Tolerance"))

#  3.3  Estimate Model 0
set.seed(42)
model0 <- estimate_pls(
  data             = as.data.frame(df),
  measurement_model= mm,
  structural_model = sm,
  inner_weights    = path_weighting,
  missing          = mean_replacement,
  missing_value    = NA)

# ── 3.4  Summarise measurement model
sum0 <- summary(model0)

cat("\n=== LOADINGS (Model 0) ===\n")
print(sum0$loadings)

cat("\n=== RELIABILITY (Cronbach α, rho_A, CR, AVE) ===\n")
print(sum0$reliability)

cat("\n=== DISCRIMINANT VALIDITY (HTMT) ===\n")
# Bootstrap required for HTMT confidence intervals
boot0 <- bootstrap_model(model0, nboot = 1000, seed = 42)
sum_boot0 <- summary(boot0)
print(sum_boot0$bootstrapped_HTMT)   # All values should be < 0.85 (strict) or < 0.90

cat("\n=== STRUCTURAL PATHS (Model 0 – bootstrapped) ===\n")
print(sum_boot0$bootstrapped_paths)

# 3.5  Additional fit indices
cat("\n=== MODEL FIT (SRMR, etc.) ===\n")
print(sum0$it_criteria)   # includes SRMR; target SRMR < 0.08




