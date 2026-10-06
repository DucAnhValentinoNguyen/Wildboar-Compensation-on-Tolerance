options(repos = c(CRAN = "https://cloud.r-project.org"))
pkgs <- c(
  "readxl","dplyr","tidyr","ggplot2","stringr","purrr","forcats","tibble",
  "psych","GPArotation","lavaan","semTools","corrplot",
  "seminr","cSEM","car","MASS","lme4","ordinal","broom","broom.mixed",
  "knitr","rmarkdown","gt","patchwork","scales","boot","effectsize",
  "performance","see","jiebaR","cluster","factoextra"
)
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
cat("Installing:", paste(to_install, collapse=", "), "\n")
if (length(to_install) > 0) install.packages(to_install, Ncpus = 4)
