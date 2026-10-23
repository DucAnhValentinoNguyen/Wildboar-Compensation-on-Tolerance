## 01_data_prep.R
## Independent, from-scratch data preparation for the Wildboar Compensation & Tolerance analysis.
## Source: data/3_Data.xlsx, sheet "Input Data" (n = 625), cross-checked against
## docs/2_Questionnaire&Codebook.docx

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(tibble)
})

root <- normalizePath(file.path(Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd()), ".."))  # repository root
out_models <- file.path(root, "latest_analysis/output/models")
dir.create(out_models, recursive = TRUE, showWarnings = FALSE)

raw <- read_excel(file.path(root, "data/3_Data.xlsx"), sheet = "Input Data")

## readxl mis-types two numeric columns as character (mixed cell-format
## artifact in the source workbook: Q10_VegArea, CP_A2 -- confirmed all
## values are clean digits, not genuine text). Coerce defensively and check
## no information is lost.
text_cols <- c("Q1_County", "Q1_Township", "Q1_Village")
for (col in setdiff(names(raw), text_cols)) {
  if (is.character(raw[[col]])) {
    coerced <- suppressWarnings(as.numeric(raw[[col]]))
    n_lost <- sum(is.na(coerced) & !is.na(raw[[col]]))
    if (n_lost > 0) stop("Coercion of ", col, " to numeric would lose ", n_lost, " non-numeric values")
    raw[[col]] <- coerced
  }
}

df <- raw %>%
  rename(
    county = Q1_County, township = Q1_Township, village = Q1_Village,
    in_np = Q3_InNP, gender = Q4_Gender, age = Q5_Age, education = Q6_Education,
    hh_pop = Q7_HouseholdPop, income = Q8_AnnualIncome, agri_prop = Q9_AgriProportion,
    total_cropland = Q11_TotalArea, total_livestock = Q13_TotalLivestock,
    crop_asset = Q14_CropAsset, livestock_asset = Q14_LivestockAsset,
    hh_asset = Q14_HouseholdAsset
  )

## --- Data-quality corrections (documented, not silent) -------------------

## (1) IC2_2 / IC2_3: codebook defines the descriptive-word valence scale as
## 1-5 only. Observed 0s (45 in IC2_2, 155 in IC2_3) exactly reproduce
## IC2_DescriptiveAttitude when excluded from the row mean -> confirmed that
## 0 encodes "respondent did not supply a 2nd/3rd word", i.e. structural
## missingness from a free-text prompt, not a valid scale point. Recode to NA.
df <- df %>%
  mutate(
    IC2_1_raw = IC2_1, IC2_2_raw = IC2_2, IC2_3_raw = IC2_3,
    IC2_2 = na_if(IC2_2, 0),
    IC2_3 = na_if(IC2_3, 0),
    n_words_given = 1 + !is.na(IC2_2) + !is.na(IC2_3),
    ## For PLS-SEM formative composites (which need a complete indicator
    ## matrix), impute a missing 2nd/3rd word rating with the respondent's
    ## own mean valence across the word(s) they did give (IC2_DescriptiveAttitude
    ## is exactly that quantity, already provided in the source data) --
    ## preserves the person's own signal rather than borrowing the sample mean.
    IC2_2_imp = ifelse(is.na(IC2_2), IC2_DescriptiveAttitude, IC2_2),
    IC2_3_imp = ifelse(is.na(IC2_3), IC2_DescriptiveAttitude, IC2_3)
  )

## (2) CA1 / CA2 are respondent-stated compensation percentages rescaled to
## proportions; codebook records them as raw "Integer" percentages, and most
## responses cluster at clean proportions (0.5, 0.8, 1.0). A small number of
## rows (9 for CA1, 4 for CA2) exceed 1.0 (up to 8.0). These are kept as-is
## for the primary analysis (a respondent CAN coherently demand >100% of
## assessed loss) but flagged, and a winsorised version is carried alongside
## for sensitivity analysis (see 08_robustness.R).
df <- df %>%
  mutate(
    ca1_extreme = CA1 > 1,
    ca2_extreme = CA2 > 1,
    CA1_w = pmin(CA1, 1),
    CA2_w = pmin(CA2, 1)
  )

## (3) PE, PS2, CA1, CA2, CA3 all define 0 as a legitimate substantive value
## per the codebook ("no strategy used" / "no channel" / "expects nothing") -
## left untouched, noted here to make clear these are NOT treated the same as
## the IC2 case above.

## (4) Skewed monetary / area variables: add log1p versions for modelling.
df <- df %>%
  mutate(
    log_income = log1p(income),
    log_hh_asset = log1p(hh_asset),
    log_crop_asset = log1p(crop_asset),
    log_livestock_asset = log1p(livestock_asset),
    log_econloss = log1p(TC2_EconomicLoss),
    log_damaged_area = log1p(TC1_DamagedArea),
    log_ca3 = log1p(CA3)
  )

## (5) Site / survey wave: Baoxing (2024-08) vs Qingchuan (2025-03/04) -
## different season, different administration -> included as a covariate /
## grouping factor throughout, since compensation participation is heavily
## confounded with county (Baoxing 74% vs Qingchuan 34% with compensation).
df <- df %>% mutate(county = factor(county), site_baoxing = as.integer(county == "Baoxing"))

## (6) Factor / labelled versions of key categoricals for descriptive use.
df <- df %>%
  mutate(
    gender_f = factor(gender, levels = c(0, 1), labels = c("Female", "Male")),
    education_f = factor(education, levels = 1:5,
                          labels = c("None", "Primary", "Middle", "High", "University+")),
    comp_f = factor(CE0, levels = c(0, 1), labels = c("No compensation", "With compensation")),
    in_np_f = factor(in_np, levels = c(0, 1), labels = c("Outside NP", "Inside NP"))
  )

## --- Composite (sum-score) indices for EDA / cross-checks -----------------
## These are *not* the final measurement model (that is decided by EFA/CFA);
## they exist only for descriptive purposes and as an OLS robustness check.
df <- df %>%
  rowwise() %>%
  mutate(
    tol_mean = mean(c(Tol1_5, Tol2_1, Tol3_1, Tol4_5), na.rm = TRUE),
    tol_mean_no3 = mean(c(Tol1_5, Tol2_1, Tol4_5), na.rm = TRUE),
    ic_mean = mean(c(IC1, IC2_1, IC2_2, IC2_3), na.rm = TRUE),
    cp_wb_mean = mean(c(CP_WB1, CP_WB2, CP_WB3, CP_WB4), na.rm = TRUE),
    cp_a_mean = mean(c(CP_A1, CP_A2, CP_A3), na.rm = TRUE),
    ca_mean = mean(c(CA1, CA2), na.rm = TRUE) # CA3 excluded: different unit (RMB, not %)
  ) %>%
  ungroup()

## --- Merge supplementary raw-questionnaire variables -----------------------
## Extracted from the "Raw data" sheet (Qualtrics export), which carries
## several fields never brought into "Input Data": species co-occurrence,
## conflict seasonality, personal threat exposure, hunting prevalence,
## behavioural reaction on encounter, and per-strategy mitigation detail.
## See latest_analysis/output/models/raw_supplement.csv (built by a one-off
## Python extraction from column positions documented in the analysis notes).
supp <- read.csv(file.path(root, "latest_analysis/output/models/raw_supplement.csv"),
                  encoding = "UTF-8", stringsAsFactors = FALSE)
df <- left_join(df, supp, by = "ID")

df <- df %>%
  mutate(
    hunted_label = factor(hunted_label, levels = c("Never","Rarely","Possible","Occasionally","Often")),
    reaction = factor(reaction, levels = c("Evacuate","Avoid/coexist","Drive away")),
    conflict_timing = factor(conflict_timing, levels = c("Daytime","Dawn/Dusk","Night"))
  )

saveRDS(df, file.path(out_models, "clean_data.rds"))

cat("Cleaned data saved:", nrow(df), "rows x", ncol(df), "cols\n")
cat("With compensation (CE0=1):", sum(df$CE0 == 1), "\n")
cat("Without compensation (CE0=0):", sum(df$CE0 == 0), "\n")
cat("By county:\n"); print(table(df$county, df$CE0))
