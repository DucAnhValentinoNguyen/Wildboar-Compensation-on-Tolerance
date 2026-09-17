# Fresh analysis, presentation, and final-report plan

Agreed 17 September 2026. Implementation requested end to end today. The original staged schedule below is compressed into a single implementation run; subsequent examiner feedback remains future work. Mengxi confirmed that Tol2 and Tol3 are already reverse-coded.

## 1. Objectives and deliverables

Build an R-first, reproducible study from the motivation, questionnaire, hypotheses, and workbook. Previous findings are audit history, not targets for model selection or conclusions.

Complete the broad analysis before preparing a 45-minute presentation for statistics examiners followed by 15 minutes of discussion. Deliver comprehensive EDA, documented derived data, EFA/CFA/PCA/PLS-SEM, primary association analyses, exploratory mechanisms, subgroup comparisons, prediction, secondary analyses, and robustness/stress tests. Produce an editable PowerPoint, speaker notes, references, backup slides, an analytical report, and a reproducibility appendix. The final report can incorporate feedback during the three weeks after presentation.

Use “compensation application” for CE0. Direct and indirect paths are associations under specified models, not established causal effects.

## 2. Data foundation and EDA

Use targets, a project-local renv environment, and R Markdown. Preserve the workbook and legacy files. Provide a build command and a render command. Version variable definitions, model specifications, seeds, resampling settings, and decisions. Every result identifies its data version, outcome, adjustment set, sample size, estimator, and uncertainty method.

- Keep Tol2/Tol3 as stored.
- Convert missing-word zeros to missingness; never invent words.
- Reconstruct institution counts from raw reporting choices; flag contradictory choices.
- Keep CE1/CE2 structurally missing for non-applicants; identify filled raw nonresponse.
- Preserve original percentages; exclude unresolved values above 100% from primary percentage analyses and retain them in sensitivity analyses.
- Label recorded area units provisionally as mu; no conversion without confirmation.
- Separate prevention non-use from effectiveness conditional on use.
- Keep a respondent-level transformation/exclusion log without editing the source.

Describe every substantive field in both sheets, explaining unusable fields. Cover sampling/filtering, missingness, skip patterns, duplicates, unusual values, distributions, floor/ceiling effects, county/application/park comparisons, geographic clustering, group imbalance, ordinal and continuous correlations, crops, livelihoods, damage, payment experience, institutions, prevention, seasonality, and words. Prepare a short clarification document; unresolved questions limit affected interpretations rather than halt unrelated work.

## 3. Measurement and analysis

### Measurement

Create a reflective/formative/observed item map. Core factor investigation includes four tolerance and four intangible-cost indicators. Broader association maps include ecological value and institutional variables without forcing behavioral counts into reflective factors.

- EFA: polychoric correlations, minimum-residual extraction, parallel analysis, oblique rotation, cross-loadings, and stability.
- CFA: theory-specified reflective structures and explicitly exploratory EFA-informed alternatives; ordinal WLSMV; report loadings, residuals, factor correlations, reliability, fit, and inadmissibility.
- PCA: variance description and alternative scoring, distinguished from latent factors.
- PLS-SEM: justified reflective constructs/composites/observed variables; separate measurement and structural assessment.

Create a fixed approximately equal village-grouped split, balanced as closely as possible by county/application. Develop EFA-informed specifications in one partition and evaluate unchanged in the other. Report sparse-category or identification failures. Full-sample estimates follow; this is internal validation, not independent confirmation of previously examined data. Do not validate a just-identified three-item CFA by perfect fit. Do not merge constructs merely to lower HTMT. Examine the reported HTMT 1.112 using corrected coding, within-construct coherence, measurement type, and appropriate diagnostics.

### Primary associations

Prespecify the four tolerance items as an outcome family; Holm-adjust their focal application tests. Composite scores are complementary.

- Ordinal logistic models with county effects and township-aware uncertainty; partial proportional-odds alternatives when necessary.
- Three/four-item score regressions with robust/clustered intervals.
- Bayesian ordinal township-random-intercept models with weakly informative priors and posterior predictive checks.
- GAM sensitivity for nonlinear age/economic relationships.

Adjustment stages: unadjusted; background (county, park residence, age, gender, education, household size); extended (agricultural dependence and economic/exposure measures). Treat contemporaneous conflict/cost/perception adjustment separately from plausible pre-application confounding. Avoid redundant total/component assets. Report probabilities and contrasts as well as coefficients.

### Structural models

Estimate the attachment's baseline: compensation, intangible costs/benefits, institutions, tangible costs → tolerance. Estimate compensation → intangible costs/institutions → tolerance, retaining direct paths. Extend with conflict experience and prevention adoption/effectiveness. Use cSEM for PLS, assessment, and composite invariance. Compare theory, admissibility, prediction, and stability rather than significance-driven deletion. Bootstrap the full measurement/structural estimation.

Retain Compensation × Intangible Cost as prespecified exploratory work regardless of p-value; report interval, f², predicted contrasts, and substantive size. Formal MGA focuses on applicants/non-applicants. Check measurement invariance first; CE0 is not a predictor within CE0-defined groups. If invariance fails, report that and compare common observed items.

### Broad substantive programme

Analyze application selection; applicant-only timeliness/satisfaction and interpretable payouts; livelihood/crop-specific burden; prevention adoption/effectiveness/expenditure; minimum/desired compensation and two-part insurance willingness to pay; reporting/information behaviors; species/seasonality/encounters/reactions; original-word frequency and transparent thematic summaries. Validated thematic coding requires human review.

Prediction compares intercept-only, regularized regression, GAM, random forest, and boosting under nested grouped CV with fold-local preprocessing and held-out importance. Add cross-fitted AIPW/DML-style adjustment, overlap/balance, and unmeasured-confounding sensitivity, explicitly assumption-dependent. Exclude neural networks, IV, and longitudinal policy designs without a defensible data-supported role.

## 4. Robustness and acceptance

Freeze a dated decision register before rebuilding, not a preregistration of unseen data. Deduplicated specification curves vary outcomes, valid measurements, adjustment, transformations, unresolved values/missingness, estimation/clustering. Separate distinct estimands. Log failures and exclusions. Neither duplicate specifications nor percentage-significant summaries constitute independent confirmations or probabilities of robustness.

Stress tests: township/village clustering; leave-one-township-out; county estimates/transport checks; complete-case versus appropriate incidental-missingness sensitivity (never structural-payment imputation); extreme-loss/percentage sensitivity; scoring and validation stability; full-estimation bootstrap; overlap/effective sample size; unmeasured confounding; multiplicity by outcome family. Use 2,000 cluster bootstraps for focal structural results and 5,000-replicate principal-path stability checks. Report failures rather than silently replacing them.

Acceptance: verified coding and skip logic; no CV leakage; no constant-exposure subgroup coefficients; traceable failures/specifications; Bayesian convergence and posterior checks; report numbers generated from outputs; clean-session reproduction; cautious claims; explicit answers to every Exploratory Contribution question, including insufficient evidence.

## 5. Presentation and original schedule

Original schedule: days 1–2 environment, preparation, EDA, measurement; days 3–4 models and secondary modules; day 5 prediction/adjustment/stress tests; days 6–7 slides, verification, rehearsal. User subsequently requested execution today.

45 minutes: background 8, methods 17, results 15, conclusions/limitations 5. Approximately 30 main slides plus backup. Cover HTMT/construct overlap, structural hierarchy, tiny interaction, nonsignificant MGA, specification sensitivity, and whether “compensation paradox” remains an appropriate label. Prepare discussion answers on measurement, EFA/CFA reuse, ordinal responses, selection, confounding, clustering, missingness, power, multiplicity, and generalizability. Incorporate later feedback and clarifications transparently during the three report weeks.

## Method references

- Ordinal CFA: https://lavaan.ugent.be/tutorial/cat.html
- HTMT: https://www.smartpls.com/documentation/algorithms-and-techniques/validity-and-model-fit/discriminant-validity-assessment/
- Specification curves: https://doi.org/10.1038/s41562-020-0912-z
- Cross-fitting: https://docs.doubleml.org/stable/guide/resampling.html
- Sensitivity: https://docs.doubleml.org/stable/guide/sensitivity.html
