% Compensation application and wild-boar tolerance
% Statistical consulting for Mengxi Kou
% 17 September 2026

## Compensation application and tolerance

- Wild-boar conflict in Giant Panda National Park, China
- Fresh analysis for Mengxi Kou
- Measurement, associations, mechanisms, and robustness

## The substantive question

- Can financial compensation support coexistence?
- Do applicants report different tolerance?
- Which lived experiences and institutional contacts accompany that difference?

## Study design and retained sample

- 625 households: Baoxing 160; Qingchuan 465
- Different interview periods: August 2024 vs March–April 2025
- 25 townships; 177 complete village keys; 49 earlier exclusions unexplained

## Application is not verified payment

- CE0 asks whether the respondent applied
- 277 applicants; 348 non-applicants
- Receipt, timing, and eligibility are not independently established

## Application differs by county

- County adjustment is essential context, not causal identification.

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/application_by_county.png){height=60%}

## Four questions, four dimensions

- Non-lethal management; population control; safety; accepting damage

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/tolerance_distributions.png){height=60%}

## A traceable data rebuild

- Preserve the workbook; record every derived change
- Restore raw nonresponse and missing-word zeros
- Rebuild institutional counts; flag unresolved percentages and units

## EDA establishes the comparison

- Profiles, missingness, skewness, ceiling effects, and imbalance
- Raw questionnaire fields retain additional substantive information

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/balance.png){height=60%}

## An analysis map, not a model contest

- Measurement: EFA → theory CFA; PCA as description
- Associations: ordinal, score, Bayesian, and nonlinear models
- Mechanisms: PLS paths, interaction, MGA
- Stress tests and prediction answer separate questions

## What is reflective, formative, or observed?

- Tolerance: reflective hypothesis under examination
- Institutions and tangible costs: formative components
- CE0 and ecological value: observed single items
- Item meanings constrain admissible models

## EFA: the expected structure is not assured

- Ordinal polychorics, minres extraction, oblimin rotation
- Parallel analysis and identification must be read together

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/parallel_analysis.png){height=60%}

## CFA: internal validation, not independent replication

- Three-item tolerance two-factor validation: CFI 0.967, RMSEA 0.048
- Village-disjoint development and validation partitions
- Weak word-item loadings and factor overlap remain

## PCA describes variance; it does not validate constructs

- Standardized complete-case item PCA
- Loadings and explained variance supplied
- PCA components are not latent causes, IRT, or PLS-SEM

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/pca_variance.png){height=60%}

## The HTMT question

- Historical 1.112 must be reassessed after coding corrections
- Corrected reflective cost/tolerance diagnostics still show overlap
- HTMT is not a pass/fail rule for formative institutional contact

## Primary estimands and uncertainty

- Four ordinal outcomes; Holm adjustment within each model family
- Unadjusted → background → resources → explanatory
- County effects; township-clustered uncertainty
- Report probabilities and intervals, not just p-values

## Item-level results differ

- The strongest background-adjusted signal concerns non-lethal management.

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/primary_ordinal.png){height=60%}

## Composite results depend on the definition

- Three- and four-item scores are secondary summaries.

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/score_associations.png){height=60%}

## Ordinal assumptions and Bayesian checks

- 4/4 Bayesian models passed the prespecified MCMC checks
- Township random intercepts; weakly informative priors
- Nonparallel slopes and sparse-category fits remain concerns

## PLS-SEM: compare specified models

- Baseline; mediation; conflict/prevention extension
- Three vs four tolerance items; IC1-only sensitivity
- Standard PLS-PM; full measurement refit in the bootstrap

## Direct and indirect associations

- Intervals come from 5,000 county-stratified township resamples.

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/pls_paths.png){height=60%}

## The proposed mechanisms remain uncertain

- Direct path: -0.142 [-0.193, -0.092]
- Indirect via costs: -0.025 [-0.065, 0.020]
- Indirect via institutions: 0.024 [-0.002, 0.049]
- These data do not demonstrate governance fatigue.

## Small interaction; uncertain group differences

- Interaction: 0.100 [-0.074, 0.264]
- Interaction f² = 0.003
- All four cluster-bootstrap MGA intervals include zero
- No strong difference is not proof of equivalence

## Secondary findings use more of the fieldwork

- Agricultural dependence and prevention deserve attention
- Applicant timeliness/satisfaction estimates are uncertain
- Insurance preferences, channels, crops, and seasons are profiled
- Secondary family uses BH multiplicity adjustment

## How much can we predict?

- Best observed grouped-CV RMSE: 0.537 (elastic_net)

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/prediction.png){height=60%}

## Cross-fitting checks adjusted associations

- Five AIPW contrasts: -0.216 to -0.193 raw score points
- Nuisance models predict unseen townships
- Overlap and balance are checked; causal assumptions remain

## A transparent specification curve

- 360 distinct model/uncertainty combinations; outcomes shown separately

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/specification_curve.png){height=60%}

## Stress-test the observations and assumptions

- Leave-one-township contrast range: -0.353 to -0.289
- Village clustering; county checks; extreme-loss sensitivity
- Unresolved-value handling and confounding-strength grid
- All failures and model choices remain visible

## What can we defend?

- Applicants report lower tolerance on several management dimensions
- Measurement and outcome choice materially affect the story
- The proposed mediation and moderation are not established
- Policy failure is not identified by this survey

## What remains for the final report?

- Clarify sampling, exclusions, payment timing, percentages, and units
- Resolve methodological questions from today's discussion
- Amend the decision register and rerun affected analyses
- Preserve the presentation release for comparison

## Discussion

- Which tolerance dimensions matter for the policy question?
- What evidence would distinguish selection from policy effects?
- Which measurement interpretation is defensible?

## Backup: Backup: direct answers to Mengxi

- Measurement: no clean, automatic latent structure
- HTMT: diagnose reflective blocks; do not merge formative behaviors blindly
- Moderation: small and uncertain; MGA: no strong difference
- Interpretation: association, not demonstrated causal mediation

## Backup: Backup: selection and causal direction

- Application is voluntary and measured cross-sectionally
- County, losses, attitudes, and institutions can shape selection
- Cross-fitting removes training reuse, not unmeasured confounding
- No valid instrument or longitudinal policy comparison is established

## Backup: Backup: why not interpret nonsignificance as equality?

- Group differences can be imprecise
- Equivalence needs a justified margin and adequate precision
- Group-standardized coefficients depend on variance
- MICOM non-rejection is not proof of full invariance

## Backup: Backup: posterior predictive check

- MCMC diagnostics and model fit answer different questions.

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/bayes_ppc_tol1.png){height=60%}

## Backup: Backup: propensity overlap

- Inspect support, balance, clipping, and effective sample size.

![](/home/duc/Wildboar-Compensation-on-Tolerance/results/fresh/figures/overlap.png){height=60%}

## Backup: Backup: p-hacking safeguards

- Dated plan; prior inspection disclosed
- Full results and failures; no significance-driven deletion
- Deduplicated specifications; multiplicity; internal validation
- No p-curve or certificate of 'no p-hacking'

## Backup: Backup: missingness and anomalies

- Structural payment missingness is never imputed
- Word zeros are absent answers, not positive sentiment
- Percentages above 100% are flagged, not guessed
- Median/mode sensitivity is limited, not full multiple imputation

## Backup: Backup: reproducibility

- R targets pipeline and renv lockfile
- Source/data hashes, seeds, grouped folds, model objects
- Reports and slides read the same saved tables
- One build command; separate render and validation commands

## Backup: Backup: methodological references

- lavaan: categorical WLSMV; psych: EFA and parallel analysis
- cSEM: PLS-PM and MICOM; brms: ordinal multilevel models
- Simonsohn et al. (2020): specification curve analysis
- DoubleML: cross-fitting and sensitivity assumptions

