# Presentation rehearsal: 39-slide audience questions and suggested answers

Prepared for Tuesday’s presentation. Use the answers as defensible starting points, not as a script to recite verbatim.

**Audience lens.** Questions are written as if asked by Dr. Sabine Hoffmann (StaBLab director, with expertise spanning statistical consulting, Bayesian methods and biostatistics), Marie Scherzer (StaBLab doctoral researcher focused on complex uncertainty), Mengxi Kou (fieldwork owner and substantive researcher), and statistics students. The audience should press on estimands, measurement, uncertainty, causal language, and the connection to the questionnaire.

**Priority slides.** Slides 3, 4, 6, 11, 12, 15, 19, 20, 21, 25, 26, 28, 32, 33, 35 and 36 receive five questions each because they are most likely to attract methodological challenge.

## Slide 1. Compensation application and tolerance

**Mengxi: What is the one-sentence contribution of this presentation?**

**Suggested answer:** This is a transparent analysis of Mengxi’s cleaned survey that separates what the data show from what they cannot identify. Application is associated with lower tolerance on some management dimensions, but the survey does not prove that compensation caused the difference.

## Slide 2. The substantive question

**Mengxi: Why study compensation if the design cannot estimate a causal policy effect?**

**Suggested answer:** Because the survey can still identify patterned differences, possible mechanisms, measurement problems, and design requirements for a future evaluation. I present those as evidence for learning and hypothesis generation, not as a causal programme evaluation.

## Slide 3. Study design and retained sample

**Sabine: Why are county and survey period treated as inseparable?**

**Suggested answer:** Baoxing and Qingchuan were surveyed in different periods, so county indicators also carry period differences. I adjust for county and cluster uncertainty by township, but I do not claim that a county coefficient removes period confounding.

**Sabine: How representative is 625 households?**

**Suggested answer:** Population representativeness is unknown because the sampling frame and the 49 excluded interviews are not documented. I describe the retained sample precisely and avoid generalizing beyond the surveyed county-period combinations.

**Marie: Why cluster by township rather than county?**

**Suggested answer:** There are only two counties, so county-clustered standard errors would be unreliable. Townships provide the more usable grouping level; county and village alternatives are sensitivity checks.

**Mengxi: Could survey period explain the association?**

**Suggested answer:** Yes. County and period are confounded. County adjustment changes the comparison but cannot separate a county effect from a period effect.

**Student: Why create a grouping key for the missing village?**

**Suggested answer:** To avoid silently dropping observations or inventing a location. The key permits conservative clustering while preserving the fact that the true village is unknown.

**Sabine: What would you ask Mengxi before publication?**

**Suggested answer:** The sampling mechanism, exclusion reason for 49 interviews, exact interview dates, and whether any villages or households were selected purposively.

## Slide 4. Application is not verified payment

**Mengxi: What exactly is the treatment variable?**

**Suggested answer:** CE0 records whether a respondent applied for compensation. It does not verify eligibility, approval, receipt, amount, or timing. Throughout the analysis I therefore call it application, not treatment receipt.

**Sabine: Why not code application as treatment?**

**Suggested answer:** Because treatment implies a defined exposure. CE0 only records an application, while approval, receipt, amount, timing, and eligibility are unknown.

**Marie: What selection processes could drive application?**

**Suggested answer:** Loss severity, expectations of compensation, access to officials, prior institutional contact, and household attitudes could all affect applying.

**Mengxi: Does adjustment make applicants comparable?**

**Suggested answer:** Only conditional on measured covariates and the assumptions of the model. It cannot balance unmeasured factors or establish timing.

**Student: Would payment receipt be a better variable?**

**Suggested answer:** Yes, if receipt, amount, timing, and eligibility were recorded reliably. Even then, a credible comparison design would still be needed.

**Sabine: What is the safest wording in the presentation?**

**Suggested answer:** “Respondents who reported applying differ from those who did not.” I avoid “compensation reduced tolerance.”

## Slide 5. Application differs by county

**Marie: Could the pooled applicant comparison be driven by county composition?**

**Suggested answer:** Yes. Application is about 74% in one county and 34% in the other. This is why county adjustment and township-level uncertainty are essential, and why the pooled contrast should not be read as a programme effect.

## Slide 6. Four questions, four dimensions

**Sabine: Why not average the four tolerance questions into one scale?**

**Suggested answer:** Their meanings differ: non-lethal management, population control, safety, and accepting damage. Tol2 and Tol3 were already reverse-coded. I show item-level results and treat composite scores as secondary because a common direction does not establish one latent construct.

**Sabine: Were Tol2 and Tol3 reverse-coded by you?**

**Suggested answer:** No. They were already reverse-coded in the cleaned data, and the raw Chinese responses support that mapping. Reversing them again would be an error.

**Marie: Why is the safety item treated differently?**

**Suggested answer:** Its distribution and associations differ from the management items, suggesting that safety concern may be a distinct substantive dimension.

**Mengxi: What would justify a common tolerance factor?**

**Suggested answer:** Consistent item meaning, adequate loadings, acceptable dependence structure, and a theory that the items are interchangeable manifestations. The current evidence is insufficient.

**Student: Could item-level analysis increase multiplicity problems?**

**Suggested answer:** Yes, which is why adjustment families and Holm correction are explicit. Item-level transparency is preferable to hiding heterogeneity in one score.

**Sabine: What is the practical implication of four dimensions?**

**Suggested answer:** Policy may affect tolerance toward management actions, perceived safety, and accepting damage differently; one overall tolerance number could conceal that distinction.

## Slide 7. A traceable data rebuild

**Marie: How did you prevent cleaning choices from becoming researcher degrees of freedom?**

**Suggested answer:** Every transformation is logged: stored reverse coding is preserved, nonexistent descriptive-word zeros become missing, structural skips remain missing, unresolved percentages are flagged, and the derived dictionary and transformation log are published with the outputs.

## Slide 8. EDA establishes the comparison

**Student: What did EDA change about the analysis plan?**

**Suggested answer:** It revealed county/application imbalance, sparse ordinal categories, skewed loss variables, ceiling effects, structural missingness, and distinct item distributions. Those findings led to item-level ordinal models, explicit clustering, and sensitivity analyses rather than one default regression.

## Slide 9. An analysis map, not a model contest

**Sabine: How do you stop a large methods menu from becoming a model contest?**

**Suggested answer:** Each method answers a different question: EFA/CFA examine measurement, ordinal models estimate item associations, PLS-SEM evaluates the specified mechanism structure, Bayesian models provide a complement, prediction assesses transportability, and robustness tests sensitivity. No method is selected because it produces the most favourable estimate.

## Slide 10. What is reflective, formative, or observed?

**Sabine: Why are institutional contacts treated as formative rather than reflective?**

**Suggested answer:** Reporting institutions and information channels are behaviours that can co-occur without being interchangeable manifestations of one underlying trait. I therefore inspect their weights, coverage, and collinearity instead of applying reflective reliability rules mechanically.

## Slide 11. EFA: the expected structure is not assured

**Sabine: What does the four-factor parallel-analysis result actually establish?**

**Suggested answer:** It suggests that four dimensions may be present among the eight items in the development split. It does not identify a defensible four-factor questionnaire: the item pool and indicator counts are limited, and the two-factor EFA has an ultra-Heywood warning.

**Sabine: Why use polychoric correlations?**

**Suggested answer:** The items are ordinal, so polychoric correlations approximate associations between underlying ordered response propensities better than treating categories as continuous Pearson variables.

**Marie: What is the Heywood warning?**

**Suggested answer:** An estimated communality or loading reaches an inadmissible boundary, signalling that the factor solution may be unstable or overinterpreted.

**Mengxi: Why not force the four-factor solution suggested by parallel analysis?**

**Suggested answer:** Eight items do not provide enough indicators for a stable four-factor reflective model, and parallel analysis is a dimensionality clue rather than a complete identification argument.

**Student: What is the role of the development split?**

**Suggested answer:** It reduces the temptation to use the same observations to select and validate a structure, while remaining an internal rather than independent validation exercise.

**Sabine: What would you do with a larger follow-up sample?**

**Suggested answer:** Pre-specify the factor model, collect at least three strong indicators per construct, test ordinal CFA on a genuinely new sample, and compare measurement invariance across counties or groups.

## Slide 12. CFA: internal validation, not independent replication

**Sabine: Why call the CFA validation internal rather than confirmatory evidence?**

**Suggested answer:** The holdout was created from the same survey and the data were already inspected. It is useful for checking prespecified theory models on village-disjoint observations, but it is not an independent sample or a preregistered replication.

**Sabine: Why not optimize CFA with modification indices?**

**Suggested answer:** That would make the validation data part of model search and inflate apparent fit. I evaluate fixed theory models and report weaknesses.

**Marie: Does CFI 0.967 prove the scale is valid?**

**Suggested answer:** No. It indicates good comparative fit for that model and sample, but validity also depends on indicator meaning, reliability, factor overlap, invariance, and external relations.

**Mengxi: Why is a three-item factor potentially just-identified?**

**Suggested answer:** A three-indicator single-factor model can have zero degrees of freedom under common specifications, so perfect fit is algebraic rather than strong empirical confirmation.

**Student: What does “internal validation” mean here?**

**Suggested answer:** A village-disjoint holdout from the same survey checks whether a prespecified model behaves similarly in held-out observations; it is not replication in a new population.

**Sabine: How should you answer if asked whether CFA supports PLS-SEM?**

**Suggested answer:** It supports inspecting the measurement assumptions, but it does not automatically validate the PLS composites or the structural causal story.

## Slide 13. PCA describes variance; it does not validate constructs

**Student: What would be an invalid use of the PCA?**

**Suggested answer:** Choosing the component that maximizes the application coefficient and presenting that coefficient as the policy effect would be selective. PCA is used only as a descriptive variance-reduction and scoring sensitivity check.

## Slide 14. The HTMT question

**Sabine: Does a high HTMT mean that the constructs must be merged?**

**Suggested answer:** No. It is a warning to inspect indicator meaning and construct overlap. Here the tolerance and cost indicators may share attitudinal content, while institutional contact is formative and should not be forced through a reflective HTMT rule.

## Slide 15. Primary estimands and uncertainty

**Marie: What is your primary estimand?**

**Suggested answer:** The primary estimand is the adjusted association between application status and each ordinal tolerance item, expressed through cumulative-logit coefficients or predicted probabilities, with township-clustered uncertainty. It is not a causal treatment effect.

**Sabine: Why are there four outcome estimands?**

**Suggested answer:** The four tolerance questions have distinct meanings and the measurement evidence does not justify treating them as one interchangeable outcome.

**Marie: What does the adjustment sequence show?**

**Suggested answer:** It shows how the application association changes as background, resources, and contemporaneous explanatory variables are added. The explanatory model is not a total policy effect.

**Mengxi: Why use Holm correction?**

**Suggested answer:** To control family-wise error across the prespecified item/model family while retaining more power than a simple Bonferroni correction.

**Student: Why report probabilities as well as odds ratios?**

**Suggested answer:** Predicted probabilities are easier to interpret for ordinal outcomes and make the substantive size visible; odds ratios alone can obscure practical differences.

**Sabine: What is the limitation of township-clustered inference with 25 townships?**

**Suggested answer:** Finite-cluster inference is more credible than treating respondents as independent, but 25 clusters still makes uncertainty estimation imperfect. Village and alternative checks are reported.

## Slide 16. Item-level results differ

**Mengxi: What result survives the item-level scrutiny?**

**Suggested answer:** The clearest negative application association is for the non-lethal-management item in the background-adjusted analysis. Other items are less precise after adjustment and multiplicity correction, while the safety item behaves differently. I do not collapse these into one psychological conclusion.

## Slide 17. Composite results depend on the definition

**Student: Why do composite estimates change when the score definition changes?**

**Suggested answer:** Equal raw-item means, standardized means, and three- versus four-item scores encode different measurement choices and scales. A coefficient change can therefore reflect outcome construction rather than a new substantive relationship.

## Slide 18. Ordinal assumptions and Bayesian checks

**Sabine: Do good R-hat and effective sample sizes validate the ordinal model?**

**Suggested answer:** They validate computational convergence only. They do not resolve nonparallel slopes, sparse categories, possible misspecification, or confounding. The Bayesian models are a complementary uncertainty analysis, not a cure for design limitations.

## Slide 19. PLS-SEM: compare specified models

**Sabine: Why use PLS-SEM when the measurement model is imperfect?**

**Suggested answer:** PLS-SEM is used as an exploratory, component-based structural summary with explicit formative and reflective distinctions. I compare specifications, report weights, loadings, VIF, R², f² and SRMR, and keep the conclusions conditional because construct validity is not guaranteed.

**Sabine: Why include formative blocks?**

**Suggested answer:** Institutional contacts and tangible cost components are behaviours or components that need not covary as reflective indicators. Formative specification matches that theory better.

**Marie: What does PLS-SEM add beyond separate regressions?**

**Suggested answer:** It provides a coherent exploratory system linking specified measurement blocks and structural paths, while allowing comparison of direct, indirect, and interaction paths.

**Mengxi: Why not call the PLS model causal?**

**Suggested answer:** PLS estimates associations in a cross-sectional observational dataset. Its path diagram is a theoretical organization, not identification of temporal or causal effects.

**Student: How do you assess the measurement blocks?**

**Suggested answer:** Reflective blocks use loadings and reliability where appropriate; formative blocks use weights, VIF, coverage and substantive interpretation. I do not apply one diagnostic to every block.

**Sabine: Why compare baseline, mediation, extended, three/four-item, and IC1-only models?**

**Suggested answer:** To show how conclusions depend on defensible measurement and structural choices rather than presenting one selected specification as uniquely correct.

## Slide 20. Direct and indirect associations

**Marie: How were the indirect intervals obtained?**

**Suggested answer:** I used 5,000 county-stratified township bootstrap resamples and recomputed the relevant paths and indirect products. One inadmissible bootstrap fit was recorded rather than silently replaced. Both proposed indirect intervals include zero.

**Sabine: What is the direct PLS path?**

**Suggested answer:** Approximately −0.142, with a bootstrap interval around −0.194 to −0.083 in the primary summary. It is an adjusted standardized association under that PLS specification.

**Marie: Do the indirect paths support mediation?**

**Suggested answer:** No. The cost and institution indirect intervals both cross zero, so the data do not provide strong evidence for either proposed indirect association.

**Mengxi: Why stratify bootstrap resamples by county?**

**Suggested answer:** To preserve the highly unequal county composition while resampling township groups, reducing a bootstrap that accidentally changes the design balance.

**Student: What does one inadmissible bootstrap fit imply?**

**Suggested answer:** It is a warning about model stability. I record it and report bootstrap success rather than replacing it silently or pretending every resample was valid.

**Sabine: Can a significant direct path coexist with uncertain mediation?**

**Suggested answer:** Yes. A total or direct association can exist without a precisely estimated indirect product, especially with cross-sectional measurement and sampling uncertainty.

## Slide 21. The proposed mechanisms remain uncertain

**Mengxi: Can you claim that compensation creates governance fatigue?**

**Suggested answer:** No. The institutional indirect estimate is compatible with both a small negative effect and zero, and the design does not establish temporal order. The appropriate statement is that the proposed mechanism is not supported strongly enough in these data.

**Sabine: What temporal order would causal mediation require?**

**Suggested answer:** Application would need to precede the mediator, which would precede tolerance, with confounding of treatment–mediator and mediator–outcome relationships adequately controlled.

**Marie: Could the mediator be a consequence rather than a cause?**

**Suggested answer:** Yes. Institutional contact or perceived intangible cost may change after applying, or both may reflect prior loss severity and attitudes.

**Mengxi: Why report an indirect estimate at all?**

**Suggested answer:** It quantifies the proposed model and shows its uncertainty transparently, while making clear that the estimate is not proof of a mechanism.

**Student: What would strengthen the mechanism claim?**

**Suggested answer:** Repeated measurements before and after application, verified timing, richer confounders, and a design with credible variation in eligibility or exposure.

**Sabine: What should Mengxi take away substantively?**

**Suggested answer:** The survey motivates mechanisms worth studying, but it does not establish governance fatigue or a compensation paradox as a causal process.

## Slide 22. Small interaction; uncertain group differences

**Sabine: What does the interaction f² of 0.003 tell us?**

**Suggested answer:** It indicates a very small incremental contribution of the application-by-cost interaction in the fitted PLS model. Its bootstrap interval includes zero, so I report it as exploratory evidence rather than a reliable moderation finding.

## Slide 23. Secondary findings use more of the fieldwork

**Mengxi: How did you avoid turning secondary variables into a fishing expedition?**

**Suggested answer:** I label this family exploratory, preserve coverage and missingness, apply BH adjustment within the family, distinguish adoption from effectiveness among users, and withhold unsupported payout/loss ratios and causal cost-effectiveness rankings.

## Slide 24. How much can we predict?

**Student: Why include prediction in a causal consulting project?**

**Suggested answer:** Prediction answers a different practical question: how well tolerance scores transport to unseen townships. Grouped nested cross-validation prevents village/community leakage. Predictive importance is not causal importance.

## Slide 25. Cross-fitting checks adjusted associations

**Marie: What assumptions remain behind the AIPW-style contrast?**

**Suggested answer:** Consistency, adequate overlap, no important unmeasured confounding conditional on covariates, and sufficiently good nuisance models. Cross-fitting reduces overfitting bias in nuisance estimation, but it cannot verify those substantive assumptions.

**Sabine: Why call it AIPW-style rather than AIPW causal estimation?**

**Suggested answer:** The implementation uses orthogonal-style cross-fitted nuisance predictions and an augmented contrast, but the causal assumptions are not established, so “style” prevents overclaiming.

**Marie: What does cross-fitting protect against?**

**Suggested answer:** It reduces overfitting and dependence between nuisance-model fitting and held-out residual calculations. It does not remove confounding.

**Mengxi: Why only background/resources in the nuisance models?**

**Suggested answer:** That is the prespecified adjustment set for this sensitivity analysis. Adding simultaneous mediators would change the estimand and could block part of a total association.

**Student: What does overlap look like?**

**Suggested answer:** The propensity distributions and effective sample size are reported. Sparse regions mean the contrast depends more heavily on extrapolation and should be interpreted cautiously.

**Sabine: Would a good AIPW estimate settle the policy question?**

**Suggested answer:** No. It would still require consistency, positivity, no unmeasured confounding, correct treatment definition, and meaningful timing.

## Slide 26. A transparent specification curve

**Sabine: Why is a specification curve useful if it cannot prove the absence of p-hacking?**

**Suggested answer:** It makes reasonable analytical choices visible, deduplicates identical inputs, and shows whether the sign and magnitude are stable across outcomes, adjustment families, transformations, missingness choices, and clustering. It documents researcher degrees of freedom; it does not turn observational data into causal evidence.

**Sabine: How many specifications are shown?**

**Suggested answer:** The curve contains 360 distinct model and uncertainty combinations after deduplicating exact duplicates, with outcomes shown separately.

**Marie: Is this a fishing expedition?**

**Suggested answer:** No. The choices were defined around plausible outcome, adjustment, transformation, missingness, clustering, and anomaly decisions, and all outputs are retained. It is a transparency tool, not a significance search.

**Mengxi: What does a high fraction of negative estimates mean?**

**Suggested answer:** It indicates directional stability across the displayed specifications; it is not a probability that the causal effect is negative.

**Student: Why keep the safety item separate?**

**Suggested answer:** Because combining it with management items could create an artificial impression of robustness while concealing substantive heterogeneity.

**Sabine: What would count as a concerning curve?**

**Suggested answer:** A sign that changes frequently, large dependence on one arbitrary coding choice, or effects driven by a single outcome/cluster. Those patterns would weaken the narrative.

## Slide 27. Stress-test the observations and assumptions

**Marie: What did the leave-one-township-out analysis show?**

**Suggested answer:** The contrast remained negative across the reported township exclusions, with the range approximately −0.353 to −0.289 for the tested contrast. That reduces concern that one township alone drives the estimate, but it does not solve unmeasured confounding.

## Slide 28. What can we defend?

**Mengxi: What is your strongest defensible conclusion?**

**Suggested answer:** Applicants report lower tolerance on several management-related dimensions, but the pattern varies by item and model. The data do not establish that compensation causes lower tolerance, nor do they establish the proposed mediation or moderation mechanisms.

**Sabine: What is the difference between association and policy failure?**

**Suggested answer:** An applicant/non-applicant difference may reflect selection, expectations, loss severity, or institutional access. It does not show that the policy failed or caused lower tolerance.

**Marie: What result is robust enough to state?**

**Suggested answer:** The negative association appears on several management-related dimensions and remains directionally negative in several stress tests, but precision and interpretation vary by item and specification.

**Mengxi: Why not lead with the PLS path?**

**Suggested answer:** Because the item-level and measurement evidence determine how much confidence the structural summary deserves. The PLS result is one component of the evidence, not the headline causal estimate.

**Student: What would change your conclusion?**

**Suggested answer:** Evidence of verified payment timing, a credible eligibility discontinuity or longitudinal comparison, better measurement indicators, or a major sensitivity showing that the current association disappears.

**Sabine: How should policy-makers use this result?**

**Suggested answer:** As a signal to investigate heterogeneous experiences and improve data collection, not as evidence to expand or withdraw compensation based on a causal claim.

## Slide 29. What remains for the final report?

**Mengxi: What information would most improve the final report?**

**Suggested answer:** Clarification of sampling and exclusions, payment timing and receipt, the meaning of percentage and area units, and the county-period fieldwork structure. Those answers would determine which analyses can be strengthened and which limitations must remain.

## Slide 30. Discussion

**Sabine: What criticism would you most like the audience to raise?**

**Suggested answer:** Whether the estimands and measurement decisions match the fieldwork process. That is more valuable than debating which algorithm is best, because the main uncertainty is identification and construct meaning.

## Slide 31. Backup: direct answers to Mengxi

**Mengxi: Which of Mengxi’s original questions can the current data answer directly?**

**Suggested answer:** The data can describe application patterns, tolerance-item distributions, associations with costs and institutions, and robustness across reasonable specifications. They cannot identify verified compensation receipt effects or prove a causal mechanism.

## Slide 32. Backup: selection and causal direction

**Sabine: Could lower tolerance lead people to apply, rather than application lowering tolerance?**

**Suggested answer:** Yes. Loss severity, expectations, pre-existing attitudes, access to reporting, and application behaviour may influence one another. A cross-sectional comparison cannot establish direction; longitudinal timing or an external eligibility rule would be needed.

**Sabine: What is the most plausible reverse-causality story?**

**Suggested answer:** Households with lower tolerance or stronger expectations may be more likely to apply, while application itself may also affect attitudes. Both directions can operate simultaneously.

**Marie: Can covariate adjustment solve reverse causality?**

**Suggested answer:** No. Adjustment can reduce measured confounding but cannot reconstruct time order from one measurement occasion.

**Mengxi: What design would address direction?**

**Suggested answer:** Panel data with pre-application tolerance, verified application and payment dates, or a credible quasi-experimental eligibility rule.

**Student: What baseline variables are missing?**

**Suggested answer:** The survey does not provide a clean pre-application tolerance measure or independently verified payment history, which limits causal ordering.

**Sabine: How should this appear in the final report?**

**Suggested answer:** As a central limitation in the estimand statement, interpretation, and recommendations for future data collection.

## Slide 33. Backup: why not interpret nonsignificance as equality?

**Marie: Why does a confidence interval crossing zero not prove no difference?**

**Suggested answer:** It means the data are compatible with zero and with a range of nonzero effects at the chosen uncertainty level. Equivalence requires a prespecified practically negligible margin and a design powered to test it.

**Sabine: What is the difference between “not significant” and “no effect”?**

**Suggested answer:** A non-rejecting interval can contain zero and meaningful positive or negative values. It is evidence of imprecision, not proof of equality.

**Marie: When could you claim practical equivalence?**

**Suggested answer:** With a prespecified smallest effect of interest, an equivalence or noninferiority procedure, and enough information to exclude effects outside that margin.

**Mengxi: How do you communicate a null result?**

**Suggested answer:** State the estimate, interval, and range of effects still compatible with the data; avoid binary “effect/no effect” language.

**Student: Does Bayesian uncertainty solve this issue?**

**Suggested answer:** No. Posterior probabilities quantify uncertainty under a model and prior; they do not make a weak design informative about exact equality.

**Sabine: Why is this important for MGA?**

**Suggested answer:** The cluster-bootstrap MGA intervals include zero, so the correct statement is no strong evidence of group differences, not that the groups are identical.

## Slide 34. Backup: posterior predictive check

**Sabine: What does a posterior predictive check add beyond R-hat?**

**Suggested answer:** R-hat and effective sample size assess sampling convergence. A posterior predictive check asks whether replicated data from the fitted model resemble important features of the observed data, such as ordinal category frequencies. It still does not validate causality.

## Slide 35. Backup: propensity overlap

**Marie: Why does overlap matter for an adjusted applicant contrast?**

**Suggested answer:** If some covariate profiles are almost always applicants or almost never applicants, the comparison relies on extrapolation. I report propensity ranges and effective sample size so the reader can see how much information supports the contrast.

**Sabine: What is positivity in this setting?**

**Suggested answer:** For comparable covariate profiles, both application statuses must occur with non-negligible probability. Otherwise the adjusted contrast extrapolates.

**Marie: Why report effective sample size?**

**Suggested answer:** It shows how much information remains after weighting or adjustment; a small effective sample warns that a few observations dominate.

**Mengxi: Can overlap be fixed by trimming?**

**Suggested answer:** Trimming changes the target population and should be prespecified. It cannot create information where one application status is absent.

**Student: What does the plot tell the audience?**

**Suggested answer:** Whether applicant and non-applicant propensity distributions overlap enough for a credible descriptive comparison under the measured covariates.

**Sabine: What remains unknown even with good overlap?**

**Suggested answer:** Unmeasured confounding, treatment misclassification, temporal order, and whether the target population is the surveyed population or a wider region.

## Slide 36. Backup: p-hacking safeguards

**Sabine: What concrete safeguards did you use against p-hacking?**

**Suggested answer:** A dated decision register, explicit primary outcomes, family-wise Holm or exploratory BH correction, complete specification tables, deduplication, visible failures, and reporting of null or uncertain results. These safeguards improve auditability but cannot prove researcher intent.

**Sabine: Can any analysis prove that p-hacking did not happen?**

**Suggested answer:** No. The safeguards make decisions and results auditable, but they cannot observe intentions or reconstruct every analysis considered.

**Marie: Why preregistration-like decisions after data collection?**

**Suggested answer:** The dataset was already collected, so this is a transparent decision register and analysis freeze rather than prospective preregistration. It still prevents quiet switching during reporting.

**Mengxi: How did multiplicity enter the workflow?**

**Suggested answer:** Holm correction is used for prespecified primary families; BH correction is labelled exploratory for secondary families; the specification curve displays the broader result set.

**Student: Why report failures?**

**Suggested answer:** Suppressing inadmissible fits or diagnostics would make the evidence look cleaner than it is. Visible failures show where conclusions are fragile.

**Sabine: What is the strongest anti-p-hacking practice here?**

**Suggested answer:** Define the estimand and outcome family first, publish the full decision register and complete output tables, and separate confirmatory claims from exploratory coverage.

## Slide 37. Backup: missingness and anomalies

**Mengxi: Why not simply impute every missing value and repair percentages above 100%?**

**Suggested answer:** Some missingness is structural: non-applicants have no payment satisfaction. Descriptive-word zeros may mean the word was not selected, while other blanks mean missing. Percentages above 100% have unresolved units or entry meanings, so inventing repairs would add unsupported information.

## Slide 38. Backup: reproducibility

**Student: What would another analyst need to reproduce the result?**

**Suggested answer:** The cleaned workbook, transformation log, hashed analysis data, fixed seeds, R and Python source, manifest, output tables and figures, and validation checks. The repository also records the analysis decisions and limitations.

## Slide 39. Backup: methodological references

**Student: Which methodological principles guide the workflow?**

**Suggested answer:** Ordinal measurement is handled with polychoric and ordinal CFA tools; clustered uncertainty follows the sampling structure; PLS outputs distinguish formative from reflective blocks; grouped cross-validation prevents community leakage; and causal language is restricted to what the design can support.
