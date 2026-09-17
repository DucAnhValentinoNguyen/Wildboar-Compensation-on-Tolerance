# Repository and statistical assessment — 17 September 2026

**Assessment:** This is a substantial exploratory consulting project with reusable data and analyses. It is not yet a validated publication pipeline. The priority is to reconcile measurement, coding, and the interpretation of compensation before expanding the model collection. A negative association remains in the diagnostic regressions conducted for this audit, but the current evidence does not establish that compensation reduces tolerance.

## Scope and evidence

Reviewed the exposé, kickoff protocol, questionnaire/codebook, slide deck, R/R Markdown and Python sources, and extracted text from the existing PDF reports. Inspected both workbook sheets and matched all 625 analysis records to raw records by ID. The audit adds a separate script and aggregate evidence; it does not modify the workbook or previous analyses.

Run ` .venv/bin/python src/audit_repository.py` from the repository root. Outputs are in `results/repository_audit/`, including coding cross-tabs, missingness, descriptive profiles, correlations, diagnostic regressions, and a JSON record of checks and software versions. The script resolves data paths relative to its own location.

**Validation boundary:** Workbook checks and diagnostic regressions were executed. The legacy 80-specification OLS loop was separately reproduced after substituting the local workbook path. The complete PLS-SEM, bootstrap, neural-network, and permutation suites were not rerun. R is installed, but the checked R analysis packages (`seminr`, `plspm`, `lavaan`, `readxl`, `rmarkdown`) are absent in this environment. Existing report estimates below are explicitly identified as reported results.

## Research context

Mengxi's exposé asks about direct and mediated compensation associations, tangible versus intangible costs and benefits, and robustness across specifications and application groups. The project uses the outer component of the Wildlife Tolerance Model; broader values and social norms are not fully measured.

Her dissertation places this question within cultural perceptions, policy history, and governance of human–wild-boar conflict in China. LMU's supplied event page announces a defense on 2 November 2026. This broader context makes institutional experience and the meaning of tolerance particularly relevant; it does not itself validate a specific statistical mechanism. [LMU event announcement](https://www.sprachlit.lmu.de/carsoncenter/en/upcoming-events-and-news/event/mengxi-kou-on-wild-boars-in-your-yard-cultural-perception-policy-history-and-the-governance-of-human-wild-boar-conflict-7fc0580d.html).

The slides describe interviews by Sichuan forestry administration staff, with 195 initial Baoxing respondents in August 2024 and 479 Qingchuan respondents in March–April 2025. The supplied workbook contains the retained 160 + 465 = 625 respondents, not all 674 initial records. The 49 exclusions and their reasons cannot be reconstructed from these retained records alone. County and survey period are confounded in this design; the dataset is not a panel.

## What has already been done

| Workstream | Sources | Assessment |
|---|---|---|
| Original WTM and successive measurement refinements | `docs/WildboarCompensation.pptx`, `src/Model 0.R`, model diagram PDFs | Extensive full-sample and application-group exploration; informative baseline, with data-driven indicator deletion requiring reassessment. |
| PLS-SEM mediation, moderation, subgroup and geographical comparisons | `src/plssem.Rmd`, `src/consulting.Rmd`, `src/consultingNew.Rmd`, `src/Consulting_Vaishali.Rmd`; `InitialAnalysis.pdf`, `PLS_SEM_Report.pdf`, `report.pdf` | Much of the requested agenda has been attempted. Specifications and interpretations differ; there is no single canonical model. |
| Exploratory/confirmatory factor analysis | `src/otherModels.Rmd` and later R Markdown work | Measurement difficulties have been noticed. Fresh-session execution and theoretical justification need attention. |
| Prediction with OLS, ridge, random forest, XGBoost, MLP, transformer | `src/python_code/analysis.py`, `src/Analysis.R`, `src/otherModels.Rmd`; model-results CSV and alternative-model reports | Six model families already compared. Recorded five-fold R²: OLS .133, ridge .133, RF .152, XGBoost .102, MLP .075, transformer .116. These are legacy results using the double-reversed safety item. |
| Feature importance and model-based compensation contrasts | Python/R importance scripts and saved CSVs | Useful exploratory work, but in-sample importance and incomplete uncertainty calculations limit the claims. |
| LASSO-based augmented inverse-probability estimation, labeled DML | `src/plssem.Rmd`, `src/consulting.Rmd` | Implemented without out-of-fold nuisance predictions; not a completed cross-fitted DML analysis. |
| Specification curve, 1,024 adjustment subsets, bootstrap, jackknife, alternative scores, MGA | `src/stress_test/`; `results/stress_test/Stress_Test_Report.pdf` | Substantial sensitivity work exists, but important implementation and reporting problems prevent treating it as validation. |

The PLS report describes a final model with tolerance R² = .337 and compensation path approximately −.14. Other documents contain different specifications and estimates. These should remain separate until each table can be tied to its generating script, data hash, settings, and outcome definition. `Model_0.3_Final.pdf` and `Model_0_3_Final.pdf` are different diagrams, despite their nearly identical names.

## Dataset inventory

The authoritative workbook and `src/python_code/3_Data.xlsx` are byte-identical at audit time (SHA-256 recorded in `checks.json`).

| Feature | Verified finding |
|---|---|
| Analysis sheet | 625 respondents, 57 columns, 625 unique IDs |
| Raw sheet | 201 columns; one descriptive header row plus 625 respondents |
| Geography | Two counties, 25 county–township keys, 177 complete county–township–village keys; one missing village |
| Application status | 277 applicants, 348 non-applicants |
| County imbalance | Baoxing: 119/160 applicants (74.4%); Qingchuan: 158/465 (34.0%) |
| Park residence | 105 inside, 520 outside |
| Explicit missingness in analysis sheet | CE1 and CE2 missing for all 348 non-applicants, plus one missing village |
| Richer raw information | Individual prevention methods/costs, crop-specific damage and loss, seasonal timing, encounters/hunting/reactions, reporting and information channels, payment text entries, original descriptive words |

The raw sheet is already filtered and partially transformed: it contains original response strings alongside derived columns. It should not be assumed to be an untouched survey export. Its 201 columns include paired raw/coded fields, not 201 independent variables.

## Confirmed issues that affect interpretation

### 1. Both negative tolerance items have already been reversed

Raw Chinese responses establish the mapping directly:

- Tol2: strong agreement with stricter population control maps to `Tol2_1 = 1`; strong disagreement maps to 5.
- Tol3: strong agreement that boars threaten personal safety maps to `Tol3_1 = 1`; strong disagreement maps to 5.
- Tol1 and Tol4 follow increasing agreement with non-lethal management and accepting damage, respectively.

There are **zero coding mismatches** for all observed raw responses: 625 each for Tol2, Tol3, and Tol4; 624 for Tol1, with one raw missing response filled in the analysis sheet.

`analysis.py`, `Analysis.R`, `otherModels.Rmd`, and both stress-test scripts reverse Tol3 again. The Python comment claiming it was not previously reversed is contradicted by the raw responses. The stress-test “codebook” alternative reverses both already-reversed items. Neither is a defensible primary coding.

Correct coding does not establish a unidimensional scale. Raw-score alpha is .338 for the four correctly oriented items and .503 without the safety item. Tol3 correlations with the other items range from −.046 to .073. Report item-level outcomes and assess dimensionality; retaining safety as a separate risk-perception outcome may be more interpretable than forcing it into a tolerance factor. Deleting it purely to improve significance is not sufficient justification.

### 2. Compensation means application, and one script uses the wrong variable

Both the codebook and raw question define `CE0` as **ever applied for wildlife-damage compensation**, specifically mentioning commercial insurance in the Chinese question. It does not independently establish receipt, amount, timing, eligibility, or wild-boar-specific payment. Use “applicants/non-applicants” until those distinctions are documented.

`src/Vaishali_Initialcode.R` defines compensation from `CP_WB1 != 1`, which measures boar sightings. This labels 500 respondents positive and disagrees with CE0 for **319 of 625**. It also mislabels payment timeliness/satisfaction as wild-boar conflict experience and fills their structural missingness with zero. This script is unsuitable as an analysis starting point. This finding does not imply all later R scripts share that error; later scripts explicitly use CE0.

### 3. Missing words are encoded as apparent attitude values

`IC2_2 = 0` for 45 respondents and `IC2_3 = 0` for 155. These correspond exactly to missing raw second/third words. Zero lies outside the codebook's 1–5 attitude scale. Several SEM specifications include these columns unchanged, mixing nonresponse with sentiment.

The existing `IC2_DescriptiveAttitude` correctly equals the mean of available nonzero word scores for every record. Its use avoids that particular zero-coding issue, although variable numbers of words and the original sentiment-coding process still merit documentation.

### 4. PS1 has the opposite direction to the stated count

Raw reporting choices map approximately to **4 minus the number of reporting institutions**: no report → 4, one institution → 3, two → 2, three → 1. Two responses combine “do not report” with an institution and need explicit handling.

The codebook describes PS1 as the number of institutions. Averaging the stored PS1 with PS2, an increasing information-channel count, mixes opposing directions. Reconstruct reporting choices from raw responses and verify the transformation. Neither field directly measures trust, administrative fatigue, or satisfaction; those labels exceed the questions' content.

### 5. Additional cleaning decisions require provenance

- CA1 exceeds 1 in nine records and CA2 in four; raw entries include 500–800 percent. These are present in the original response cells, not merely Python conversion errors. Query their meaning before correction, exclusion, or capping.
- Seven respondents report damaged area greater than total land. Confirm reference period, repeated damage, and units before labeling them erroneous.
- Raw area questions explicitly use **mu**, whereas the English questionnaire says hectares. Verify the stored unit before translating totals or calculating rates.
- PE equals zero for 83 respondents. Distinguish non-use from poor effectiveness, and check the numerator/denominator used to form PE.
- Complete analysis columns conceal some raw nonresponse: among applicants, two raw timeliness answers and one satisfaction answer are missing but CE1/CE2 are filled. Obtain the cleaning rules.

### 6. Existing robustness claims are stronger than their implementation

- The 80-specification loop reproduces 80 negative coefficients, 72 significant at .05, but only **36 distinct coefficient/p-value/sample-size triples**. `drop_tol3` and `plssem3` are identical, and some transformation/outlier switches do nothing for certain control sets. This is not 80 independent confirmations. It also omits the correctly oriented four-item score.
- County strings are coerced to numeric in the Python stress script, leaving **zero nonmissing county values**. Its county MGA branch cannot run with this workbook. Thus the county results in the PDF cannot be reproduced from that script as supplied.
- The Python MGA attempts a compensation coefficient within groups defined by compensation itself. That variable is constant and its effect is not identifiable within such a group; any returned coefficient is unsuitable for interpretation.
- The report and scripts differ in listed resample counts. The stress-test machine-readable CSV/JSON outputs are absent from the supplied legacy results directory.
- Nonsignificant group differences are not evidence of equivalence or generalizability. Group-specific standardization further complicates coefficient comparisons. Before latent/composite group comparisons, assess measurement invariance. [MICOM documentation](https://www.smartpls.com/documentation/algorithms-and-techniques/heterogeneity-and-multigroup/micom/).
- PCA and item-total weights are alternative scores, not fitted PLS-SEM and item-response models. Their labels should reflect what was estimated.

### 7. Prediction and causal inference need separate standards

The prediction scripts calculate indicator scaling and predictor scaling before cross-validation, and permutation importance on the training data. Move learned preprocessing inside training folds and calculate importance on held-out data. Use geography-aware validation where the goal is prediction for new communities.

The Python importance script bootstraps MLP/transformer contrasts **without refitting**. Those intervals omit model-fitting uncertainty. It also labels contrasts as outcome SD units even though the mean-z-score target has SD **.604**, not 1. For example, its OLS contrast −.1806 is about −.299 target SD. This explains part of the discrepancy with the stress report.

The R “DML” routines tune LASSO using cross-validation but predict nuisance functions on observations used to fit them. Tuning CV is not cross-fitting. [DoubleML resampling documentation](https://docs.doubleml.org/dev/guide/resampling.html).

Even correctly implemented DML would require defensible temporal ordering, confounder measurement, overlap, and identification assumptions. Simultaneously measured costs, attitudes, and policy experiences cannot automatically be treated as pre-application confounders. The current cross-sectional design does not justify statements that the policy causes harm, that mediation establishes governance fatigue, or that a nonsignificant monetary-loss coefficient proves money is unimportant.

## What the audit's diagnostic regressions show

For comparability, I retained the legacy full covariate construction and changed the tolerance definition and county adjustment. These are **diagnostic associations**, not a recommended final adjustment set; PS1, CA anomalies, and other legacy covariate limitations remain. Outcomes are averaged standardized items and then scaled to unit variance; CE0 remains 0/1. Intervals below use township-clustered standard errors with finite-cluster correction and t inference across 25 township clusters.

| Tolerance definition | Controls | Applicant contrast in outcome SD | 95% CI |
|---|---|---:|---:|
| Legacy double-reversed safety item | Legacy full controls | −.299 | [−.422, −.176] |
| Four items correctly oriented as stored | Legacy full controls | −.185 | [−.320, −.049] |
| Four items correctly oriented as stored | Legacy full controls + county | −.202 | [−.355, −.049] |
| Three items, excluding safety | Legacy full controls + county | −.262 | [−.389, −.135] |

The negative association survives these limited checks. Its size depends on what “tolerance” includes. This supports rebuilding the analysis, not discarding the study or certifying all existing conclusions. Cluster choice must ultimately follow the sampling process; clustering on only two counties is not a satisfactory solution.

## How to obtain more value from the dataset

| Priority | Research question and analysis | Necessary qualification |
|---|---|---|
| 1 | Establish a reproducible respondent profile, exclusion flow, item dictionary, county/application comparisons, and missingness map. | Recover sampling and cleaning provenance; separate genuine zeros, nonresponse, and skip logic. |
| 1 | Analyze non-lethal management support, population-control preferences, acceptance of damage, and safety perceptions individually using ordinal models and predicted probabilities. Compare justified three/four-item scores as sensitivity analyses. | Check sparse categories and proportional-odds assumptions; preserve the safety question's meaning. |
| 1 | Model compensation application and its association with tolerance using theory-led, temporally defensible adjustment sets, county effects, and community clustering. | Describe selection into application; distinguish total association from mediator-adjusted association. |
| 2 | Among applicants, examine timeliness, satisfaction, and their association with tolerance. Explore recorded payout amounts if interpretable. | CE1/CE2 are structurally undefined for non-applicants. Payment text is incomplete; verify amount and loss periods before payout/loss ratios. |
| 2 | Quantify livelihood vulnerability: crop mix, agricultural dependence, crop-specific losses, damaged-area share, and loss relative to income. | Confirm mu/hectares, time windows, zero incomes, and damage greater than area; retain denominator flags. |
| 2 | Describe prevention adoption, method-specific perceived effectiveness, and household prevention expenditure. | Separate adoption from effectiveness conditional on use; costs are incompletely recorded and methods are self-selected. |
| 2 | Examine minimum acceptable compensation, desired compensation, and insurance willingness to pay separately. | Validate percentages first; zero willingness and positive amounts may require a two-part analysis. |
| 2 | Study reporting institutions and information channels as observed behaviors; examine associations with application and tolerance. | Rebuild PS1; avoid calling these direct measures of institutional trust. |
| 2 | Examine seasonal conflict patterns, species mix, personal encounters, and reactions to boars. | Seasonal data describe recalled timing, not longitudinal changes. |
| 3 | Revisit original words using a transparent Chinese-language thematic coding scheme: fear, crop damage, hostility, ecological appreciation. | Preserve meaning and document coding reliability; do not invent missing words. |
| 3 | Refit theory-supported SEM paths and a small number of planned interactions; compare transparent regression with selected predictive models. | Formative/reflective choice follows the construct definition, not whichever improves fit. Mediation remains exploratory without temporal evidence. |

More model families are unlikely to be the highest-value next step. A coherent primary compensation/tolerance analysis plus secondary analyses of implementation experience, livelihood burden, and mitigation would use much more of Mengxi's fieldwork than repeated model searches on the same composites.

## Robustness plan after measurement repair

1. Freeze primary outcomes, exposure definitions, and a small set of theory-based adjustment sets before examining further significance patterns.
2. Compare item-level and justified composite outcomes, ordinal and continuous-outcome models, and county-adjusted versus county-specific associations.
3. Use community-aware uncertainty; assess township/village clustering according to the sampling design and influential-cluster sensitivity.
4. Audit percentage anomalies, extreme monetary losses, transformations, missing-word handling, and non-use of prevention. Keep a documented decision table rather than silently deleting observations.
5. Evaluate overlap and balance before any weighting/AIPW analysis. If pursued, use cross-fitting and report weight/propensity diagnostics and sensitivity to unmeasured confounding; do not claim these remove all selection bias.
6. For SEM, justify the measurement specification, assess reflective validity separately from formative indicator relevance/collinearity, and assess measurement invariance before MGA. [Formative versus reflective evaluation](https://www.smartpls.com/documentation/functionalities/thresholds/).
7. For prediction, use fold-local preprocessing, held-out importance, and grouped validation; treat leave-one-county-out performance as a two-site transportability check, not a precise generalization estimate.
8. Report effect sizes, uncertainty, and multiplicity handling for secondary outcome families. Null differences should be reported with intervals rather than interpreted as proof of sameness.

## Reproducibility and next discussion with Mengxi

The repository contains useful exploratory history but no authoritative entrypoint or environment lock. Several paths assume obsolete sessions or a particular working directory. `Consulting_Vaishali.Rmd` references `mm_rq1` without defining it; `otherModels.Rmd` uses `efa_data` before its later definition. `SEM.R` is effectively a placeholder. R/Python CV metrics and outcome scaling also differ. Existing uncommitted work was present before this audit and has been preserved.

Next implementation should establish one data-preparation layer, explicit variable roles/units, a small primary analysis, versioned outputs, and a source-to-report manifest. Archive earlier analyses as exploratory history rather than silently replacing their results.

The most useful clarifications are:

- How were households selected, how many were approached, and why were 49 records excluded? Were sampling weights, interviewer IDs, or original GPS retained elsewhere?
- What precisely does applying entail, which households actually received payment, and when relative to damage and interview? Did compensation cover any wildlife or specifically boars?
- What cleaning/imputation rules produced complete analysis fields, the reversed PS1, and the percentage entries above 100%?
- Are areas stored in mu, and what reference periods apply to damage, income, compensation, and mitigation expenditure?
- How were the descriptive words assigned sentiment scores, and which tolerance dimensions are central to the dissertation's substantive argument?

These questions refine the next analysis phase. They do not prevent using the verified findings in this assessment.
