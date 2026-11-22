# 00_run_all.R ----------------------------------------------------------------
# Master control script: reproduces all results from the raw ATP files.
# Usage: open inflation_partisanship.Rproj, then source this file.
# -----------------------------------------------------------------------------

library(here)

source(here("scripts", "01_clean.R"))
source(here("scripts", "02_model.R"))
source(here("scripts", "03_tables_figures.R"))
source(here("scripts", "04_numbers_for_text.R"))

# Unit tests run last so a failing helper is flagged with the results.
testthat::test_dir(here("tests", "testthat"))

writeLines(
  capture.output(sessioninfo::session_info()),
  here("docs", "sessionInfo.txt")
)

message("=== Pipeline complete ===")
