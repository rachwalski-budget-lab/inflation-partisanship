# 01_clean.R ------------------------------------------------------------------
# Read the five ATP waves (read-only), recode, standardize, write one file.
# Inputs:  ../wave data/<wave folder>/ATP W###.sav   (see config.yml)
# Outputs: data/processed/analysis_clean.rds
# -----------------------------------------------------------------------------

library(here)
source(here("scripts", "functions.R"))

cfg <- yaml::read_yaml(here("config.yml"))
raw_dir <- here(cfg$data$raw_dir)

# --- Read all waves -----------------------------------------------------------
waves_raw <- purrr::map(
  cfg$waves,
  read_wave,
  vars = cfg$vars,
  raw_dir = raw_dir,
  id_col = cfg$data$id_col
) |>
  purrr::list_rbind()

n_read <- nrow(waves_raw)
message("Rows read across waves: ", n_read)

# Wave metadata as a table (for joins and for the paper's measurement table).
wave_meta <- purrr::map(cfg$waves, \(w) {
  tibble::tibble(
    wave = w$wave,
    item = w$item,
    item_type = w$item_type,
    n_cats = w$n_cats,
    form = w$form,
    field_dates = w$field_dates,
    cpi_month = w$cpi_month,
    cpi_yoy = w$cpi_yoy,
    wording = w$wording
  )
}) |>
  purrr::list_rbind()

# --- Sample restrictions --------------------------------------------------------
# Logged in docs/decision_log.md. Count what each restriction drops.
sample_flow <- tibble::tibble(
  step = c(
    "All respondents in five waves",
    "Answered the price item (split-form waves: half sample)",
    "Rep, Dem or Ind on F_PARTY_FINAL"
  ),
  n = c(
    n_read,
    sum(!is.na(waves_raw$infl_raw)),
    sum(!is.na(waves_raw$infl_raw) & waves_raw$party_num %in% 1:3)
  )
)

df <- waves_raw |>
  dplyr::filter(!is.na(infl_raw), party_num %in% 1:3) |>
  dplyr::mutate(
    party_f = code_party(party_num),
    party_lean_f = code_party_lean(party_num, lean_num, "grouped"),
    party_five_f = code_party_lean(party_num, lean_num, "five"),
    gender_f = factor(
      dplyr::case_when(gender == 1 ~ "Male", gender == 2 ~ "Female"),
      levels = c("Male", "Female")
    ),
    age_f = droplevels(age),
    educ_f = forcats::fct_relevel(droplevels(educ), "H.S. graduate or less"),
    income_f = forcats::fct_relevel(droplevels(income), "Less than $30,000"),
    ideo_f = forcats::fct_relevel(droplevels(ideo), "Very conservative"),
    wave_f = factor(wave, levels = purrr::map_chr(cfg$waves, "wave")),
    item_type_f = factor(
      item_type,
      levels = c("Comparative", "Problem severity", "Personal concern")
    )
  ) |>
  dplyr::group_by(wave) |>
  dplyr::mutate(
    infl_std = standardize(infl_raw),
    infl_std_w = standardize(infl_raw, weight, weighted = TRUE)
  ) |>
  dplyr::ungroup() |>
  dplyr::left_join(
    dplyr::select(wave_meta, wave, cpi_yoy),
    by = "wave"
  )

assert_no_duplicate_rows(df, expected_n = sample_flow$n[3])

# Gender codes other than 1/2 (e.g., "In some other way") are NA and drop out
# of Models 2-3 by listwise deletion, as in the submitted paper.

# --- Complete-case flags for each model (explicit, not left to svyglm) -------
demo_vars <- c("age_f", "gender_f", "educ_f", "income_f")
df <- df |>
  dplyr::mutate(
    cc_m1 = TRUE,
    cc_m2 = stats::complete.cases(dplyr::pick(dplyr::all_of(demo_vars))),
    cc_m3 = cc_m2 & !is.na(ideo_f),
    cc_lean = !is.na(party_lean_f)
  )

# --- Assertions on the output -------------------------------------------------
assertthat::assert_that(nrow(df) > 0, msg = "Cleaning removed all rows")
assertthat::assert_that(!any(is.na(df$qkey)), msg = "NA respondent IDs")
assertthat::assert_that(all(df$weight > 0), msg = "Non-positive weights")
assertthat::assert_that(
  all(abs(tapply(df$infl_std, df$wave, mean)) < 1e-8),
  msg = "Within-wave z-scores do not have mean zero"
)
# A respondent should appear at most once per wave.
assertthat::assert_that(
  !anyDuplicated(df[c("qkey", "wave")]),
  msg = "Respondent appears twice in the same wave"
)
if (all(is.na(df$lean_num))) {
  warning("F_PARTYLN_FINAL not found in any wave; leaner models will be empty.")
}

# --- Write ------------------------------------------------------------------
saveRDS(df, here("data", "processed", cfg$data$processed_file))
saveRDS(wave_meta, here("data", "processed", "wave_meta.rds"))
saveRDS(sample_flow, here("data", "processed", "sample_flow.rds"))

message("01_clean.R complete: ", nrow(df), " respondent-wave rows; ",
        dplyr::n_distinct(df$qkey), " unique respondents")
