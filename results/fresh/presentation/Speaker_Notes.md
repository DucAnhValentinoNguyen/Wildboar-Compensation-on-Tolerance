# Speaker notes: 45-minute talk + 15-minute discussion

## 1. Compensation application and tolerance

Target time: 0.9 minutes
Opening: our task is to learn what this fieldwork supports, including results that challenge the original narrative. We distinguish compensation application from payment receipt throughout. Outline the 45-minute talk and reserve 15 minutes for methodological discussion.

- Wild-boar conflict in Giant Panda National Park, China
- Fresh analysis for Mengxi Kou
- Measurement, associations, mechanisms, and robustness

## 2. The substantive question

Target time: 1.4 minutes
The policy motivation is important, but this household survey measures simultaneous reports. We can describe and adjust associations; the causal effect of a compensation programme requires additional identification. Introduce the Wildlife Tolerance Model as a conceptual starting point, not a predetermined statistical solution.

- Can financial compensation support coexistence?
- Do applicants report different tolerance?
- Which lived experiences and institutional contacts accompany that difference?

## 3. Study design and retained sample

Target time: 1.4 minutes
County and survey timing are inseparable here. There are no repeated measurements on the same households. Unknown sampling and exclusion mechanisms limit population generalization. A missing village receives its own grouping key, not an invented location.

- 625 households: Baoxing 160; Qingchuan 465
- Different interview periods: August 2024 vs March–April 2025
- 25 townships; 177 complete village keys; 49 earlier exclusions unexplained

## 4. Application is not verified payment

Target time: 1.4 minutes
The original wording matters: never label CE0 as random policy exposure or guaranteed compensation receipt. Selection into applying can reflect losses, reporting access, and attitudes. Applicants are not automatically comparable to non-applicants.

- CE0 asks whether the respondent applied
- 277 applicants; 348 non-applicants
- Receipt, timing, and eligibility are not independently established

## 5. Application differs by county

Target time: 1.4 minutes
Explain the 74% versus 34% application rates. Geographic composition can change pooled comparisons. This motivates county fixed effects and township clustering, not standard errors clustered on only two counties.

- County adjustment is essential context, not causal identification.

## 6. Four questions, four dimensions

Target time: 1.9 minutes
Read the substantive meaning of each item. Tol2 and Tol3 are already reversed, confirmed by Mengxi and raw responses. Higher Tol3 means less safety concern. A common positive orientation does not establish one underlying factor.

- Non-lethal management; population control; safety; accepting damage

## 7. A traceable data rebuild

Target time: 1.9 minutes
Clarify that data cleaning is evidence-based rather than selected for favorable results. Percentages over 100% remain unresolved and receive sensitivity analysis. Non-applicants have structurally undefined payment satisfaction. Prevention non-use is not poor effectiveness.

- Preserve the workbook; record every derived change
- Restore raw nonresponse and missing-word zeros
- Rebuild institutional counts; flag unresolved percentages and units

## 8. EDA establishes the comparison

Target time: 0.9 minutes
The full EDA tables are available, including every derived variable and the raw-field inventory. Do not read every imbalance as a hypothesis test. Emphasize sparse ordinal categories, skewed losses, and different household compositions.

- Profiles, missingness, skewness, ceiling effects, and imbalance
- Raw questionnaire fields retain additional substantive information

## 9. An analysis map, not a model contest

Target time: 1.9 minutes
Explain why methods are complementary. The best predictive model does not identify a policy effect. CFA fit does not prove a mechanism. A PLS composite does not automatically represent an error-free latent variable.

- Measurement: EFA → theory CFA; PCA as description
- Associations: ordinal, score, Bayesian, and nonlinear models
- Mechanisms: PLS paths, interaction, MGA
- Stress tests and prediction answer separate questions

## 10. What is reflective, formative, or observed?

Target time: 1.9 minutes
Avoid using low alpha as a reason to relabel a construct formative. Institutional contact counts and information channels are behaviors, not interchangeable symptoms of fatigue. Reflective diagnostics such as HTMT must be interpreted within this distinction.

- Tolerance: reflective hypothesis under examination
- Institutions and tangible costs: formative components
- CE0 and ecological value: observed single items
- Item meanings constrain admissible models

## 11. EFA: the expected structure is not assured

Target time: 1.9 minutes
The development split has 316 respondents and only 238 complete eight-item records. Pairwise polychorics use available pairs. The parallel suggestion of four factors among eight items is not an identified four-factor questionnaire model. The two-factor EFA has a Heywood problem; report it openly.

- Ordinal polychorics, minres extraction, oblimin rotation
- Parallel analysis and identification must be read together

## 12. CFA: internal validation, not independent replication

Target time: 1.9 minutes
Use the holdout to assess fixed theory models rather than optimize modification indices. The dataset was previously seen, so do not call this independent confirmation. Explain that a standalone three-item factor is just-identified and its perfect fit would not validate it. Factor orientation is arbitrary; compare absolute latent correlations.

- Three-item tolerance two-factor validation: CFI 0.967, RMSEA 0.048
- Village-disjoint development and validation partitions
- Weak word-item loadings and factor overlap remain

## 13. PCA describes variance; it does not validate constructs

Target time: 0.9 minutes
PCA answers a variance-reduction question. It is useful for checking whether scoring changes the picture, but choosing a component to maximize the application coefficient would be selective analysis. Keep it separate from the substantive construct argument.

- Standardized complete-case item PCA
- Loadings and explained variance supplied
- PCA components are not latent causes, IRT, or PLS-SEM

## 14. The HTMT question

Target time: 1.9 minutes
This directly answers Mengxi's question. Revisit the indicators before merging constructs. The rebuilt reflective cost/tolerance HTMT is high, consistent with overlapping attitudinal content and weak word-item coherence. Institutional contact should not be renamed governance fatigue based on a correlation.

- Historical 1.112 must be reassessed after coding corrections
- Corrected reflective cost/tolerance diagnostics still show overlap
- HTMT is not a pass/fail rule for formative institutional contact

## 15. Primary estimands and uncertainty

Target time: 1.9 minutes
The adjustment sequence changes the interpretation. The explanatory model conditions on simultaneous attitudes and potential mediators. It does not estimate the total policy effect. Explain finite-cluster t inference with 25 townships and why village clustering is a sensitivity.

- Four ordinal outcomes; Holm adjustment within each model family
- Unadjusted → background → resources → explanatory
- County effects; township-clustered uncertainty
- Report probabilities and intervals, not just p-values

## 16. Item-level results differ

Target time: 1.9 minutes
Point out the negative application association for Tol1, uncertainty for other items after Holm adjustment, and little adjusted association for safety. The stronger resource-adjusted Tol2/Tol4 estimates appear in backup tables. Do not summarize all outcomes as the same psychological response.

- The strongest background-adjusted signal concerns non-lethal management.

## 17. Composite results depend on the definition

Target time: 1.9 minutes
Read the outcome-SD scale carefully. Equal raw-item means differ from the earlier mean-z-score construction. A change in coefficient size can reflect the outcome definition and adjustment, not an algorithm discovering a new causal effect.

- Three- and four-item scores are secondary summaries.

## 18. Ordinal assumptions and Bayesian checks

Target time: 1.4 minutes
Four chains, R-hat at most 1.01, ESS at least 400, and no divergences are computational checks. Posterior predictive plots are provided. Some proportional-odds diagnostics indicate deviations; a Tol2 partial model has a singular Hessian. Do not claim that Bayesian estimation solves these substantive assumptions.

- 4/4 Bayesian models passed the prespecified MCMC checks
- Township random intercepts; weakly informative priors
- Nonparallel slopes and sparse-category fits remain concerns

## 19. PLS-SEM: compare specified models

Target time: 1.9 minutes
The main model uses formative cost and institution blocks, observed application/benefit, and a reflective tolerance specification. We report weights, loadings, VIF, reliability where applicable, R², f² and SRMR. Fit and explained variance do not establish causality or construct validity.

- Baseline; mediation; conflict/prevention extension
- Three vs four tolerance items; IC1-only sensitivity
- Standard PLS-PM; full measurement refit in the bootstrap

## 20. Direct and indirect associations

Target time: 1.9 minutes
The direct negative path persists, but both proposed indirect intervals cross zero. The institutional and cost indirect paths have opposite signs and almost cancel. Distinguish standardized PLS paths from the two-stage raw 0/1 application interaction. One bootstrap fit was inadmissible and was recorded, not replaced.

- Intervals come from 5,000 county-stratified township resamples.

## 21. The proposed mechanisms remain uncertain

Target time: 1.4 minutes
This is an important departure from earlier reports. Even a nonzero indirect product would need temporal and confounding assumptions to support causal mediation. Here uncertainty already prevents a strong statistical mediation claim.

- Direct path: -0.142 [-0.193, -0.092]
- Indirect via costs: -0.025 [-0.065, 0.020]
- Indirect via institutions: 0.024 [-0.002, 0.049]
- These data do not demonstrate governance fatigue.

## 22. Small interaction; uncertain group differences

Target time: 1.4 minutes
Keep the prespecified interaction in the exploratory results. Do not delete it to make the model appear stronger. MICOM is a conventional supporting diagnostic; means/variances are not fully invariant. Group-standardized paths are not identical to common-scale observed interactions.

- Interaction: 0.100 [-0.074, 0.264]
- Interaction f² = 0.003
- All four cluster-bootstrap MGA intervals include zero
- No strong difference is not proof of equivalence

## 23. Secondary findings use more of the fieldwork

Target time: 1.4 minutes
The aim is useful substantive coverage, not accumulating significant results. Adoption and conditional effectiveness answer different questions. Payment text and prevention expenditure are incomplete; payout/loss ratios and causal cost-effectiveness rankings are withheld. Original word counts await human thematic review.

- Agricultural dependence and prevention deserve attention
- Applicant timeliness/satisfaction estimates are uncertain
- Insurance preferences, channels, crops, and seasons are profiled
- Secondary family uses BH multiplicity adjustment

## 24. How much can we predict?

Target time: 1.4 minutes
Five outer and three inner township folds prevent community leakage. Scaling and imputation are trained within folds. Differences among the leading models are small and do not prove linearity. Held-out importance is predictive reliance, not causal importance.

- Best observed grouped-CV RMSE: 0.537 (elastic_net)

## 25. Cross-fitting checks adjusted associations

Target time: 1.4 minutes
Explain the orthogonal-style score without presenting DML as an automatic confounding cure. Only background/resources enter nuisance models. Repeated splits check algorithmic sensitivity, not five independent replications. Report propensity ranges and effective sample size.

- Five AIPW contrasts: -0.216 to -0.193 raw score points
- Nuisance models predict unseen townships
- Overlap and balance are checked; causal assumptions remain

## 26. A transparent specification curve

Target time: 1.9 minutes
We vary reasonable decisions and deduplicate identical inputs. This is not a search for significance. A percentage of negative estimates is not a probability of robustness. Invalid reverse coding is not a reasonable alternative. The safety item should not be hidden among composite results.

- 360 distinct model/uncertainty combinations; outcomes shown separately

## 27. Stress-test the observations and assumptions

Target time: 0.9 minutes
Influence tests assess whether a small number of observations or communities dominate the result. They do not address all unmeasured confounding. The bias grid is a linear point-estimate sensitivity, not a cluster-adjusted causal confidence interval.

- Leave-one-township contrast range: -0.353 to -0.289
- Village clustering; county checks; extreme-loss sensitivity
- Unresolved-value handling and confounding-strength grid
- All failures and model choices remain visible

## 28. What can we defend?

Target time: 1.4 minutes
Offer the most defensible interpretation in plain language. Compensation application may mark respondents with different experiences, expectations, and institutional contact. Multiple explanations remain compatible with the data. A causal policy evaluation needs timing and a credible design.

- Applicants report lower tolerance on several management dimensions
- Measurement and outcome choice materially affect the story
- The proposed mediation and moderation are not established
- Policy failure is not identified by this survey

## 29. What remains for the final report?

Target time: 0.9 minutes
All available-data analyses are reproducible today. Future work is substantive clarification and response to feedback, not inventing causal identification. Clearly separate information unavailable in the workbook from computational tasks already completed.

- Clarify sampling, exclusions, payment timing, percentages, and units
- Resolve methodological questions from today's discussion
- Amend the decision register and rerun affected analyses
- Preserve the presentation release for comparison

## 30. Discussion

Target time: 0.5 minutes
Invite methodological criticism. Have the following backup slides and the full report ready. Allocate 15 minutes to discussion and record questions for the three-week final-report revision.

- Which tolerance dimensions matter for the policy question?
- What evidence would distinguish selection from policy effects?
- Which measurement interpretation is defensible?

## 31. Backup: direct answers to Mengxi

Backup slide
Use this as the checklist that every item of the Exploratory Contribution was addressed. The full report contains the explicit question-to-answer mapping.

- Measurement: no clean, automatic latent structure
- HTMT: diagnose reflective blocks; do not merge formative behaviors blindly
- Moderation: small and uncertain; MGA: no strong difference
- Interpretation: association, not demonstrated causal mediation

## 32. Backup: selection and causal direction

Backup slide
If asked for an ATE, explain the identification assumptions and why our adjusted contrasts do not establish them. Conditioning on current attitudes can block or distort paths; a statistical arrow is not temporal evidence.

- Application is voluntary and measured cross-sectionally
- County, losses, attitudes, and institutions can shape selection
- Cross-fitting removes training reuse, not unmeasured confounding
- No valid instrument or longitudinal policy comparison is established

## 33. Backup: why not interpret nonsignificance as equality?

Backup slide
A nonsignificant MGA is supplementary evidence of no clear difference, exactly as Mengxi suggested. The study did not specify a substantive equivalence margin, so it cannot claim equivalent mechanisms.

- Group differences can be imprecise
- Equivalence needs a justified margin and adequate precision
- Group-standardized coefficients depend on variance
- MICOM non-rejection is not proof of full invariance

## 34. Backup: posterior predictive check

Backup slide
Compare observed response frequencies with replicated frequencies. The remaining three item plots and all diagnostics are available in the report outputs.

- MCMC diagnostics and model fit answer different questions.

## 35. Backup: propensity overlap

Backup slide
Overlap in the fitted propensity distribution does not prove overlap on unobserved confounders. The exported balance table shows how observed differences change after weighting.

- Inspect support, balance, clipping, and effective sample size.

## 36. Backup: p-hacking safeguards

Backup slide
Explain that the appropriate safeguard is transparent analytical practice. P-curve on correlated tests from this single sample would not establish the absence of selective reporting.

- Dated plan; prior inspection disclosed
- Full results and failures; no significance-driven deletion
- Deduplicated specifications; multiplicity; internal validation
- No p-curve or certificate of 'no p-hacking'

## 37. Backup: missingness and anomalies

Backup slide
The transformation log identifies exactly which values changed and why. One missing raw Tol1 changes the score sample from 625 to 624. Main PLS complete cases number 622 because reporting responses are also missing.

- Structural payment missingness is never imputed
- Word zeros are absent answers, not positive sentiment
- Percentages above 100% are flagged, not guessed
- Median/mode sensitivity is limited, not full multiple imputation

## 38. Backup: reproducibility

Backup slide
Commands: Rscript run_project.R --restore; Rscript run_project.R; Rscript run_project.R --render; Rscript run_project.R --verify. A rebuild should not rely on an RStudio workspace or .RData.

- R targets pipeline and renv lockfile
- Source/data hashes, seeds, grouped folds, model objects
- Reports and slides read the same saved tables
- One build command; separate render and validation commands

## 39. Backup: methodological references

Backup slide
Clickable references and full URLs are in the report and PLAN.md. These guide method choices; they do not validate the present dataset automatically.

- lavaan: categorical WLSMV; psych: EFA and parallel analysis
- cSEM: PLS-PM and MICOM; brms: ordinal multilevel models
- Simonsohn et al. (2020): specification curve analysis
- DoubleML: cross-fitting and sensitivity assumptions

