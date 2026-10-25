# Wildboar-Compensation-on-Tolerance
Understanding the compensation policy impact on local resident’s tolerance towards wild boars in Giant Panda National Park, China 

## Live artifact page

https://ducanhvalentinonguyen.com/wildboar-compensation-analysis-2026-09-17.html

## Fresh analysis release

The rebuilt R-first pipeline is documented in [docs/PLAN.md](docs/PLAN.md) and [docs/ANALYSIS_DECISIONS.md](docs/ANALYSIS_DECISIONS.md). It preserves the original workbook, creates the audited derived dataset under `data/derived/`, and writes all tables, figures, model objects, reports, slides, and logs under `results/fresh/`.

From the project root:

```bash
Rscript run_project.R --restore   # first run; uses/restores the local R library
Rscript run_project.R             # targets pipeline (rebuilds changed stages)
Rscript run_project.R --render    # report, PDF, PowerPoint, speaker notes
Rscript run_project.R --verify    # reproducibility/acceptance checks
```
