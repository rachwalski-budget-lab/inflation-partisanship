# 02_model.R ------------------------------------------------------------------
# Fit all models and save them in one list.
# Inputs:  data/processed/analysis_clean.rds
# Outputs: output/model_results.rds
# -----------------------------------------------------------------------------

library(here)
library(survey)
source(here("scripts", "functions.R"))

cfg <- yaml::read_yaml(here("config.yml"))
df <- readRDS(here("data", "processed", cfg$data$processed_file))
validate_input(df, required = c("qkey", "weight", "infl_std", "party_f"))

# Outcome used in the main models (config switch; see decision log).
dv <- if (isTRUE(cfg$model$standardize_weighted)) "infl_std_w" else "infl_std"

# --- Survey designs -------------------------------------------------------------
# Clustered on respondent: the ATP is a panel, so one person can contribute up
# to five rows. ids = ~qkey makes the SEs robust to that within-person
# correlation (reviewer comment 4). The unclustered design reproduces the
# submitted paper's SEs, for comparison only.
design_cl <- svydesign(ids = ~qkey, weights = ~weight, data = df)
design_un <- svydesign(ids = ~1, weights = ~weight, data = df)
design <- if (isTRUE(cfg$model$cluster_on_respondent)) design_cl else design_un

# --- Formulas -----------------------------------------------------------------
demo <- "age_f + gender_f + educ_f + income_f"
f1 <- function(party = "party_f", y = dv) {
  stats::as.formula(paste(y, "~", party, "+ wave_f"))
}
f2 <- function(party = "party_f", y = dv) {
  stats::as.formula(paste(y, "~", party, "+", demo, "+ wave_f"))
}
f3 <- function(party = "party_f", y = dv) {
  stats::as.formula(paste(y, "~", party, "+", demo, "+ ideo_f + wave_f"))
}

# Fit on an explicit complete-case subset so N and unique-respondent counts
# are known exactly. Row-indexing a design keeps the full design for SEs
# (domain estimation), unlike filtering the data before svydesign().
keep <- function(des, rows) des[rows, ]
fit <- function(formula, des, cc) {
  svyglm(formula, design = keep(des, des$variables[[cc]]))
}

# --- Main pooled models (Table 1, Table 2) --------------------------------------
main <- list(
  m1 = fit(f1(), design, "cc_m1"),
  m2 = fit(f2(), design, "cc_m2"),
  m3 = fit(f3(), design, "cc_m3")
)

# Same models, unclustered (to show how much clustering changes the SEs).
main_unclustered <- list(
  m1 = fit(f1(), design_un, "cc_m1"),
  m2 = fit(f2(), design_un, "cc_m2"),
  m3 = fit(f3(), design_un, "cc_m3")
)

# Republican-minus-Democrat contrasts (minor comment: test of R - D).
rd_main <- purrr::imap(main, \(m, nm) dplyr::mutate(rd_contrast(m), model = nm)) |>
  purrr::list_rbind()

# --- Sample sizes: observations and unique respondents ------------------------
sample_sizes <- tibble::tibble(
  model = c("m1", "m2", "m3"),
  cc = c("cc_m1", "cc_m2", "cc_m3")
) |>
  dplyr::mutate(
    n_obs = purrr::map_int(cc, \(v) sum(df[[v]])),
    n_unique = purrr::map_int(cc, \(v) dplyr::n_distinct(df$qkey[df[[v]]]))
  )

# How many waves each respondent appears in (main sample).
waves_per_person <- df |>
  dplyr::count(qkey, name = "n_waves") |>
  dplyr::count(n_waves, name = "n_respondents")

# --- By-wave models (reviewer comment 3) ----------------------------------------
# One respondent per row within a wave, so clustering is moot there; the same
# design object is subset by wave for consistency.
wave_ids <- levels(df$wave_f)

by_wave <- purrr::map(wave_ids, \(w) {
  in_w <- design$variables$wave == w
  d1 <- keep(design, in_w)
  d2 <- keep(design, in_w & design$variables$cc_m2)
  list(
    m1 = svyglm(stats::as.formula(paste(dv, "~ party_f")), design = d1),
    m2 = svyglm(stats::as.formula(paste(dv, "~ party_f +", demo)), design = d2),
    # Raw response scale (1..n_cats): coefficients in scale points.
    raw = svyglm(infl_raw ~ party_f, design = d1),
    # Linear probability of the most-concerned category: percentage points.
    top = svyglm(infl_top ~ party_f, design = d1)
  )
}) |>
  purrr::set_names(wave_ids)

rd_by_wave <- purrr::imap(by_wave, \(ms, w) {
  purrr::imap(ms, \(m, spec) {
    dplyr::mutate(rd_contrast(m), wave = w, spec = spec)
  }) |>
    purrr::list_rbind()
}) |>
  purrr::list_rbind()

# Formal test: do the party gaps differ across waves? (party x wave interaction)
m_interact_wave <- svyglm(
  stats::as.formula(paste(dv, "~ party_f * wave_f")),
  design = design
)
test_wave_het <- regTermTest(m_interact_wave, ~ party_f:wave_f, method = "Wald")

# Pooled by item type (comparative / severity / personal concern). Wave fixed
# effects are omitted here because item type is a function of wave (they would
# be collinear with the item-type main effects); the outcome is already
# centered within wave.
m_interact_item <- svyglm(
  stats::as.formula(paste(dv, "~ party_f * item_type_f")),
  design = design
)
test_item_het <- regTermTest(m_interact_item, ~ party_f:item_type_f, method = "Wald")

# Weighted share in the top category, by party and wave (descriptive).
top_shares <- svyby(
  ~infl_top, ~ wave_f + party_f, design = design, FUN = svymean, na.rm = TRUE
) |>
  tibble::as_tibble() |>
  dplyr::rename(share = infl_top)

# --- Leaners (minor comment) ---------------------------------------------------
lean_terms <- c(rep = "party_lean_fRepublican + leaners",
                dem = "party_lean_fDemocrat + leaners")
leaners <- if (any(df$cc_lean & !is.na(df$lean_num))) {
  list(
    m1 = fit(f1("party_lean_f"), design, "cc_lean"),
    m2 = svyglm(f2("party_lean_f"),
                design = keep(design, df$cc_lean & df$cc_m2)),
    m3 = svyglm(f3("party_lean_f"),
                design = keep(design, df$cc_lean & df$cc_m3)),
    five_m2 = svyglm(f2("party_five_f"),
                     design = keep(design, df$cc_lean & df$cc_m2))
  )
} else {
  NULL
}
rd_leaners <- if (!is.null(leaners)) {
  purrr::imap(leaners[c("m1", "m2", "m3")], \(m, nm) {
    dplyr::mutate(
      rd_contrast(m, rep_term = lean_terms[["rep"]],
                  dem_term = lean_terms[["dem"]]),
      model = nm
    )
  }) |>
    purrr::list_rbind()
}

# --- Robustness -----------------------------------------------------------------
robust <- list(
  # Weighted within-wave standardization.
  weighted_z = fit(f2(y = if (dv == "infl_std") "infl_std_w" else "infl_std"),
                   design, "cc_m2"),
  # Only the three waves with the identical personal-concern item.
  # Built as its own design so unused wave levels drop out (no aliased terms).
  concern_only = svyglm(
    f2(),
    design = svydesign(
      ids = ~qkey, weights = ~weight,
      data = droplevels(dplyr::filter(df, cc_m2,
                                      item_type == "Personal concern"))
    )
  )
)
rd_robust <- purrr::imap(robust, \(m, nm) dplyr::mutate(rd_contrast(m), model = nm)) |>
  purrr::list_rbind()

# --- Save ---------------------------------------------------------------------
results <- list(
  dv = dv,
  main = main,
  main_unclustered = main_unclustered,
  rd_main = rd_main,
  sample_sizes = sample_sizes,
  waves_per_person = waves_per_person,
  by_wave = by_wave,
  rd_by_wave = rd_by_wave,
  test_wave_het = test_wave_het,
  test_item_het = test_item_het,
  top_shares = top_shares,
  leaners = leaners,
  rd_leaners = rd_leaners,
  robust = robust,
  rd_robust = rd_robust
)
saveRDS(results, here("output", "model_results.rds"))

message("02_model.R complete: model list saved to output/model_results.rds")
