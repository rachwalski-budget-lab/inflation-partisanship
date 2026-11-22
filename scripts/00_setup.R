# 00_setup.R -----------------------------------------------------------------
# Install required packages, then lock versions with renv. Run once.
# -----------------------------------------------------------------------------

pkgs <- c(
  "here", "yaml", "assertthat", "glue", # project plumbing
  "haven", # read Pew .sav files
  "dplyr", "tidyr", "purrr", "forcats", "tibble", "readr", # data
  "survey", # survey-weighted, respondent-clustered models
  "broom", "modelsummary", "flextable", # tables (.docx for the paper)
  "ggplot2", # figures
  "sessioninfo", "testthat", "renv"
)

missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing)) install.packages(missing)

# renv::init()       # first time only
# renv::snapshot()   # after installing/upgrading any package

message("Setup complete. Next: renv::init(), then source 00_run_all.R")
