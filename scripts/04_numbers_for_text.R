# 04_numbers_for_text.R --------------------------------------------------------
# Every number quoted in the paper's text, computed from the saved models.
# Copy numbers into the draft from this file only, so prose cannot drift from
# the tables (fixes the reporting errors flagged by the reviewers).
# Inputs:  output/model_results.rds
# Outputs: output/numbers_for_text.md
# -----------------------------------------------------------------------------

library(here)
source(here("scripts", "functions.R"))

res <- readRDS(here("output", "model_results.rds"))

b <- function(m, term) unname(stats::coef(m)[term])
p_of <- function(m, term) {
  broom::tidy(m) |> dplyr::filter(.data$term == !!term) |> dplyr::pull(p.value)
}
r3 <- function(x) sprintf("%.3f", x)
r1 <- function(x) sprintf("%.1f", x)

rep <- "party_fRepublican"
dem <- "party_fDemocrat"
m <- res$main
rd <- res$rd_main
ss <- res$sample_sizes

rep_b <- purrr::map_dbl(m, b, term = rep)
dem_b <- purrr::map_dbl(m, b, term = dem)

lines <- c(
  "# Numbers for the text",
  "",
  glue::glue("Outcome: `{res$dv}` (within-wave z-score). SEs clustered by respondent."),
  "",
  "## Sample",
  glue::glue(
    "- Model {1:3}: {format(ss$n_obs, big.mark = ',')} respondent-wave ",
    "observations from {format(ss$n_unique, big.mark = ',')} unique respondents."
  ),
  glue::glue(
    "- Respondents appearing in {res$waves_per_person$n_waves} wave(s): ",
    "{format(res$waves_per_person$n_respondents, big.mark = ',')}"
  ),
  "",
  "## Party coefficients (Table 1)",
  glue::glue(
    "- Model {1:3}: Republican {r3(rep_b)} ({fmt_p(purrr::map_dbl(m, p_of, term = rep))}); ",
    "Democrat {r3(dem_b)} ({fmt_p(purrr::map_dbl(m, p_of, term = dem))}); ",
    "R - D = {r3(rd$estimate)} (SE {r3(rd$std.error)}, {purrr::map_chr(rd$p.value, fmt_p)})."
  ),
  "",
  "## Changes across models (absolute size, percent)",
  glue::glue("- Republican, Model 1 -> 2: {r1(pct_change(rep_b[1], rep_b[2]))}%"),
  glue::glue("- Republican, Model 2 -> 3: {r1(pct_change(rep_b[2], rep_b[3]))}%"),
  glue::glue("- Republican, Model 1 -> 3: {r1(pct_change(rep_b[1], rep_b[3]))}%"),
  glue::glue("- Democrat,   Model 1 -> 2: {r1(pct_change(dem_b[1], dem_b[2]))}% (positive = gap grew)"),
  glue::glue("- Democrat,   Model 2 -> 3: {r1(pct_change(dem_b[2], dem_b[3]))}%"),
  glue::glue("- R - D gap,  Model 1 -> 2: {r1(pct_change(rd$estimate[1], rd$estimate[2]))}%"),
  glue::glue("- R - D gap,  Model 2 -> 3: {r1(pct_change(rd$estimate[2], rd$estimate[3]))}%"),
  glue::glue("- R - D gap,  Model 1 -> 3: {r1(pct_change(rd$estimate[1], rd$estimate[3]))}%"),
  "",
  "## By wave (Model 1 specification)",
  glue::glue(
    "- {res$rd_by_wave$wave[res$rd_by_wave$spec == 'm1']}: R - D = ",
    "{r3(res$rd_by_wave$estimate[res$rd_by_wave$spec == 'm1'])} ",
    "({purrr::map_chr(res$rd_by_wave$p.value[res$rd_by_wave$spec == 'm1'], fmt_p)})"
  ),
  glue::glue(
    "- Equal gaps across waves: F = {sprintf('%.2f', res$test_wave_het$Ftest)}, ",
    "df = {res$test_wave_het$df}, {fmt_p(res$test_wave_het$p)}"
  ),
  glue::glue(
    "- Equal gaps across item types: F = {sprintf('%.2f', res$test_item_het$Ftest)}, ",
    "df = {res$test_item_het$df}, {fmt_p(res$test_item_het$p)}"
  ),
  "",
  "## Original scales",
  glue::glue(
    "- {res$top_shares$wave_f}, {res$top_shares$party_f}: ",
    "{r1(100 * res$top_shares$share)}% in the most-concerned category"
  ),
  glue::glue(
    "- {res$rd_by_wave$wave[res$rd_by_wave$spec == 'top']}: Republicans minus ",
    "Democrats, most-concerned category = ",
    "{r1(100 * res$rd_by_wave$estimate[res$rd_by_wave$spec == 'top'])} percentage points"
  ),
  "",
  "## Leaners",
  if (!is.null(res$rd_leaners)) {
    glue::glue(
      "- Model {1:3}, leaners grouped: R - D = {r3(res$rd_leaners$estimate)} ",
      "({purrr::map_chr(res$rd_leaners$p.value, fmt_p)})"
    )
  } else {
    "- F_PARTYLN_FINAL not available; leaner models not estimated."
  },
  "",
  "## Robustness (Model 2 specification)",
  glue::glue(
    "- {res$rd_robust$model}: R - D = {r3(res$rd_robust$estimate)} ",
    "({purrr::map_chr(res$rd_robust$p.value, fmt_p)})"
  )
)

writeLines(lines, here("output", "numbers_for_text.md"))
message("04_numbers_for_text.R complete: output/numbers_for_text.md")
