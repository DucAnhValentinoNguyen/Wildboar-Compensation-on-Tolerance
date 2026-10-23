## 24_applicant_experience.R -- RQ1 mechanism: does the *quality* of the compensation experience
## go with tolerance? Among the 277 applicants, timeliness of payment (CE1) and satisfaction with the
## payment (CE2) are related to tolerance, adjusting for the primary (S1) control set
## (background + damage + prevention). A three-group comparison over the full sample then asks whether
## the lower tolerance of applicants is concentrated among dissatisfied applicants.
## Uses the construct scores of the primary model saved by 23_causal_role_models.R.
suppressPackageStartupMessages({ library(dplyr); library(sandwich); library(lmtest) })
root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
tab_dir <- file.path(root, "output/tables")
d <- readRDS(file.path(root, "output/models/causal_S1_scores_data.rds"))
ctrl <- "s_CP_WB + s_CP_A + gender + age + education + log_income + log_hh_asset + in_np + site_baoxing + s_TC + s_PE"
hc <- function(f, terms) { v <- vcovHC(f, "HC3"); ct <- coeftest(f, vcov = v); ci <- coefci(f, vcov = v)
  data.frame(term = terms, est = ct[terms, 1], se = ct[terms, 2], lo = ci[terms, 1], hi = ci[terms, 2], p = ct[terms, 4], row.names = NULL) }

sink(file.path(tab_dir, "150_applicant_experience_log.txt"), split = TRUE)
a <- d %>% filter(CE0 == 1)
cat("Applicants: n =", nrow(a), "\n\nTimeliness (CE1: 1 untimely, 2 moderate, 3 timely):\n"); print(table(a$CE1))
cat("\nSatisfaction (CE2: 1 dissatisfied, 2 moderate, 3 satisfied):\n"); print(table(a$CE2))
cat("\nCross-table CE1 x CE2:\n"); print(table(a$CE1, a$CE2))
cat("\nSpearman correlation CE1-CE2:", round(cor(a$CE1, a$CE2, method = "spearman"), 3), "\n")
cat("By county (share dissatisfied):\n"); print(round(tapply(a$CE2 == 1, a$county, mean), 3))

## (a) within applicants, tolerance in SD units of the full sample
fa <- lm(as.formula(paste("s_Tol ~ CE1 + CE2 +", ctrl)), data = a)
fb <- lm(as.formula(paste("s_Tol ~ I((CE1 + CE2) / 2) +", ctrl)), data = a)
ra <- rbind(cbind(model = "CE1 and CE2 together", hc(fa, c("CE1", "CE2"))),
            cbind(model = "mean of CE1 and CE2", hc(fb, "I((CE1 + CE2)/2)")))
cat("\n== (a) Applicants only: tolerance (SD units) on timeliness and satisfaction, S1 controls, HC3 ==\n"); print(ra, digits = 3)

## (b) three groups over the full sample
d <- d %>% mutate(group = factor(case_when(CE0 == 0 ~ "Did not apply", CE2 >= 2 ~ "Applied, moderately or fully satisfied", TRUE ~ "Applied, dissatisfied"),
                                levels = c("Did not apply", "Applied, moderately or fully satisfied", "Applied, dissatisfied")))
cat("\nGroup sizes:\n"); print(table(d$group))
fg <- lm(as.formula(paste("s_Tol ~ group +", ctrl)), data = d)
rg <- hc(fg, c("groupApplied, moderately or fully satisfied", "groupApplied, dissatisfied"))
rg$term <- c("Applied, moderately or fully satisfied", "Applied, dissatisfied")
cat("\n== (b) Difference from non-applicants (SD units), S1 controls, HC3 ==\n"); print(rg, digits = 3)
ct <- coeftest(fg, vcov = vcovHC(fg, "HC3"))
dd <- c(1, -1); v <- vcovHC(fg, "HC3")[c("groupApplied, moderately or fully satisfied","groupApplied, dissatisfied"), c("groupApplied, moderately or fully satisfied","groupApplied, dissatisfied")]
est <- sum(dd * coef(fg)[c("groupApplied, moderately or fully satisfied","groupApplied, dissatisfied")]); se <- sqrt(drop(t(dd) %*% v %*% dd))
cat(sprintf("Satisfied minus dissatisfied applicants: %.3f (SE %.3f), p = %.4f\n", est, se, 2 * pt(-abs(est / se), fg$df.residual)))
cat("\nUnadjusted mean tolerance (SD units) by group:\n"); print(round(tapply(d$s_Tol, d$group, mean), 3))
sink()
write.csv(rbind(cbind(analysis = "applicants", ra), cbind(analysis = "three_groups", model = "group vs non-applicants", rg)),
          file.path(tab_dir, "151_applicant_experience.csv"), row.names = FALSE)
write.csv(data.frame(group = levels(d$group), n = as.vector(table(d$group)), mean_unadj = as.vector(tapply(d$s_Tol, d$group, mean))),
          file.path(tab_dir, "152_applicant_groups.csv"), row.names = FALSE)
