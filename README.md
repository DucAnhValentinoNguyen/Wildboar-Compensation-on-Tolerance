# Wildboar-Compensation-on-Tolerance
Understanding the compensation policy impact on local resident’s tolerance towards wild boars in Giant Panda National Park, China 

## Live artifact page

https://ducanhvalentinonguyen.com/wildboar-compensation-analysis-2026-09-17.html

## Reproducing the analysis

The code that produces every table, figure, and number of the analysis is on the branch
[`final-analysis`](https://github.com/DucAnhValentinoNguyen/Wildboar-Compensation-on-Tolerance/tree/final-analysis).
To check the results yourself:

```bash
git clone --branch final-analysis https://github.com/DucAnhValentinoNguyen/Wildboar-Compensation-on-Tolerance.git
cd Wildboar-Compensation-on-Tolerance

# 1. Put the survey data file at data/3_Data.xlsx (sheets "Input Data" and "Raw data").
#    The data are not in the repository: they are subject to usage restrictions agreed with the project partner.

# 2. Install the R packages (R 4.5; Python 3 with pandas and openpyxl is also needed)
Rscript latest_analysis/install_packages.R

# 3. Run the whole analysis (about an hour on 4 or more cores)
bash latest_analysis/run_all.sh
```

The results are written to `latest_analysis/output/` (tables, figures, fitted models), with one log per
script in `latest_analysis/logs/rerun/`. Random steps use fixed seeds, so the numbers match those of the
analysis; the one exception is the permutation p-values of the multi-group analysis, which vary slightly
between runs. The README on the `final-analysis` branch lists every script and what it produces.
