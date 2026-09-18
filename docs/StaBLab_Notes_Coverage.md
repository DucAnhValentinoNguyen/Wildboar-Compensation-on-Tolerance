# StaBLab Notes coverage audit

This matrix checks the requests and questions in `docs/StaBLab Notes.docx` against the fresh analysis release. “Addressed” means that an analysis, output, and defensible interpretation exist. It does not mean that the data support a causal answer where the survey design cannot identify one.

## Exploratory Contribution

| StaBLab request | Evidence in the fresh release | Status and answer |
|---|---|---|
| Do indicators cluster into expected constructs? | `results/fresh/tables/efa_comparison.csv`, EFA loadings, parallel analysis, ordinal CFA | **Addressed.** Parallel analysis suggests four dimensions among eight items, but the item pool does not support a defensible four-factor CFA. The two-factor EFA has an ultra-Heywood warning. |
| Are constructs empirically overlapping? | `cfa_fit.csv`, `cfa_parameters.csv`, `htmt_scope.csv` | **Addressed.** Tolerance and the proposed reflective intangible-cost block overlap: corrected HTMT is 1.074 for the four-item tolerance comparison and 0.927 for the three-item comparison. The historical 1.112 is treated as an earlier diagnostic, not silently reused. |
| Should indicators be removed, reassigned, or merged? | Measurement conclusion in `docs/Analysis_Report.Rmd`; three- and four-item PLS specifications | **Addressed cautiously.** The four observed tolerance items remain the primary outcome family. The three-item score is a transparent sensitivity. No significance-driven deletion or automatic institution–sentiment merger is justified. |
| Is policy support distinct from intangible costs and tolerance? | Formative PLS blocks, HTMT scope, CFA alternatives | **Addressed with a construct qualification.** Institutional contact/information indicators are behaviours specified formatively; they are not interchangeable reflective symptoms of “governance fatigue.” Intangible-cost/tolerance reflective separation remains uncertain. |
| Different predictor combinations | `specification_curve.csv` and `specification_summary.csv` | **Addressed.** Background, resources, conflict, and explanatory adjustment families are compared without an arbitrary all-subsets search. |
| Alternative measurement specifications | EFA, CFA, PCA, five PLS specifications | **Addressed.** Three/four tolerance items, IC1-only, baseline, mediation, and extended conflict/prevention structures are compared. |
| Controls included/excluded | Specification curve and ordinal adjustment families | **Addressed.** Unadjusted, background, resources, conflict, and explanatory families are retained separately. |
| Alternative tolerance indicators | Item-level ordinal models, three-item and four-item scores | **Addressed.** Results are shown separately; the safety item behaves differently and is not hidden in a composite. |
| Different subgroup definitions | `mga_cluster_differences.csv`, county-specific associations, leave-one-township-out | **Addressed.** Application groups are compared; county-specific and township influence checks are supplementary. MGA intervals include zero. |

## Baseline structure and mechanisms

| StaBLab question | Evidence | Defensible answer |
|---|---|---|
| Are compensation and policy support at the same conceptual level as costs/benefits? | `docs/Analysis_Report.Rmd` sections 2 and 5; PLS syntax in `src/fresh/structural.R` | **No.** Compensation/application is an observed policy-experience indicator. Institutional contact is a formative behavioural block. Costs and benefits represent lived experiences or perceptions. The model keeps these roles distinct rather than letting significance define the concepts. |
| Should prevention effectiveness and conflict experience be added? | Extended PLS model, `pls_quality.csv`, `pls_paths.csv` | **Tested.** The extended model adds conflict, prevention use, and conditional effectiveness. It is useful as an exploratory extension; contemporaneous data do not identify the direction of those paths. |
| Is the baseline structural model defensible? | Baseline, mediation, extended, four-item, and IC1-only PLS outputs | **Conditionally.** It is defensible as a transparent exploratory association system with explicitly mixed observed, formative, and reflective blocks. It is not a causal path model. |
| Does the direct application association persist? | Ordinal models, `pls_bootstrap_summary.csv`, specification curve | **Yes directionally for several management-related outcomes.** The primary PLS direct path is −0.142 with a 5,000-replicate interval approximately [−0.194, −0.083]. This is an adjusted association, not a verified compensation effect. |
| Is the intangible-cost pathway mediated? | `pls_bootstrap_summary.csv` | **Not established.** Indirect cost estimate −0.025, interval approximately [−0.065, 0.020], crossing zero. The institutional indirect interval also crosses zero. Temporal order and mediator confounding are not identified. |
| Is the “compensation paradox” established? | Report conclusion and specification curve | **No causal paradox is established.** Applicants report lower tolerance on several dimensions, but selection, measurement, county-period confounding, and reverse direction remain compatible explanations. |

## HTMT / discriminant validity

The current diagnostic is narrower and more defensible than applying HTMT to every block. HTMT is reported only for proposed reflective tolerance/cost comparisons. Institutional contact is formative, so a reflective HTMT pass/fail rule is not appropriate. The practical conclusion is to retain the distinction provisionally for substantive analysis, flag overlap, and avoid renaming institutional contact as governance fatigue or merging constructs solely because of a high ratio.

## Compensation × intangible cost moderation

| StaBLab question | Result |
|---|---|
| Is the interaction significant? | The PLS interaction coefficient is approximately 0.100 with a 5,000-bootstrap interval [−0.074, 0.264] and centered bootstrap p approximately 0.254. The observed-score interaction is 0.053, interval [−0.044, 0.149], p = 0.272. |
| Is f² meaningful? | PLS interaction f² is approximately 0.003. Its interval is small and the effect is substantively weak. The nonnegative f² percentile interval is not itself a valid sign-based significance test. |
| Should it be removed? | **No silent deletion.** It remains in the exploratory/supplementary outputs and specification record, but it is not a central mechanism or confirmatory result. |
| How should it be presented? | As a prespecified but uncertain exploratory interaction, with both PLS and observed-score sensitivity results and no claim of moderation. |

## Multi-group analysis

The fresh analysis compares application groups using the same measurement blocks and algorithms, with MICOM as a supporting diagnostic and 2,000 township-bootstrap path differences. The intervals are:

| Path | Difference interval |
|---|---:|
| Intangible cost | [−0.060, 0.284] |
| Policy support | [−0.291, 0.199] |
| Tangible cost | [−0.227, 0.112] |
| Intangible benefit | [−0.171, 0.106] |

Every interval includes zero. The correct answer is **no strong evidence of group differences conditional on the measurement assumptions**, not proof of equality and not support for compensation-experience moderation.

## Vibration of Effects / robustness / p-hacking

The fresh analysis directly implements a vibration-of-effects style specification curve in `src/fresh/robustness.R` and `results/fresh/tables/specification_curve.csv`.

It contains **360 distinct model/uncertainty combinations** after deduplicating exact duplicate inputs. It varies:

- six outcomes: four items plus three- and four-item scores;
- five adjustment families: none, background, resources, conflict, explanatory;
- raw versus log economic predictors where both are meaningful;
- retaining all observations versus excluding extreme loss or reporting contradictions;
- complete-case versus limited median/mode covariate sensitivity;
- township versus village uncertainty clustering.

The curve is complemented by county-specific associations, leave-one-township-out estimates, village clustering, overlap/balance checks, Bayesian posterior predictive checks, PLS bootstrap refits, and an omitted-confounding strength grid.

The main vibration result is heterogeneous by outcome: the application estimate remains negative across all displayed specifications for `tol1`, `tol2`, and `tol4` and for the composite scores, while `tol3` is positive across its displayed specifications. This is evidence of directional sensitivity by construct, not evidence that one universal tolerance effect is robust.

This does **not** prove that p-hacking did not occur. It makes researcher degrees of freedom and failures auditable through the decision register, complete output tables, explicit multiplicity handling, deduplication, and reporting of null/uncertain results. The fraction of negative or significant estimates is not a posterior probability and not an independent-replication rate.

## Final interpretation

The original proposed wording—“compensation experience is negatively associated with tolerance, and this relationship may be partially mediated by intangible costs”—is too strong in its mediation clause. The defensible version is:

> Respondents who reported applying for compensation reported lower tolerance on several management-related dimensions. The association is sensitive to the tolerance dimension and measurement choices, and the proposed intangible-cost and policy-support pathways are not statistically established. Because application, payment, mediator, and tolerance were not observed longitudinally or under a credible assignment mechanism, the result is an adjusted association rather than a causal compensation effect.

This answers the StaBLab questions while preserving the distinction between a useful exploratory pattern and a causal policy conclusion.
