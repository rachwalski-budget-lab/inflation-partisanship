# 03_tables_figures.R ----------------------------------------------------------
# Tables and figures for the paper.
# Inputs:  output/model_results.rds, data/processed/*.rds
# Outputs: output/tables/*.docx|.tex|.csv, output/figures/*.png|.pdf
# LaTeX: tables use tinytable (preamble needs \usepackage{tabularray});
#        figures are vector PDFs sized for a 6.5-inch text width, with no
#        titles drawn in (captions go in the .tex file).
# -----------------------------------------------------------------------------

library(here)
source(here("scripts", "functions.R"))

cfg <- yaml::read_yaml(here("config.yml"))
res <- readRDS(here("output", "model_results.rds"))
wave_meta <- readRDS(here("data", "processed", "wave_meta.rds"))
sample_flow <- readRDS(here("data", "processed", "sample_flow.rds"))
df <- readRDS(here("data", "processed", cfg$data$processed_file))
n_by_wave <- dplyr::count(df, wave, name = "n")

tab_dir <- here(cfg$output$tables)
fig_dir <- here(cfg$output$figures)

stars <- c("*" = 0.10, "**" = 0.05, "***" = 0.01)
star_note <- "* p < .10. ** p < .05. *** p < .01."

# Write a table to .docx (Word drafts) and, for data-frame tables, .tex.
write_table <- function(x, name, title, notes) {
  ft <- if (inherits(x, "flextable")) x else flextable::flextable(x)
  ft <- ft |>
    flextable::set_caption(title) |>
    flextable::add_footer_lines(notes) |>
    flextable::autofit()
  flextable::save_as_docx(ft, path = file.path(tab_dir, paste0(name, ".docx")))
  if (is.data.frame(x)) {
    tinytable::tt(x, caption = title, notes = notes) |>
      tinytable::format_tt(escape = TRUE) |>
      tinytable::save_tt(file.path(tab_dir, paste0(name, ".tex")),
                         overwrite = TRUE)
  }
  invisible(NULL)
}

# Same modelsummary table written as .tex for LaTeX.
ms_tex <- function(models, name, title, notes, ...) {
  modelsummary::modelsummary(
    models, title = title, notes = notes,
    output = file.path(tab_dir, paste0(name, ".tex")), ...
  )
}

# Save a figure as PNG (Word drafts) and vector PDF (LaTeX).
save_fig <- function(p, name, width = 6.5, height = 4) {
  ggplot2::ggsave(file.path(fig_dir, paste0(name, ".png")), p,
                  width = width, height = height, dpi = 300, bg = "white")
  pdf_dev <- if (capabilities("cairo")) grDevices::cairo_pdf else "pdf"
  ggplot2::ggsave(file.path(fig_dir, paste0(name, ".pdf")), p,
                  width = width, height = height, device = pdf_dev)
}

fmt_cell <- function(est, se, p) {
  s <- dplyr::case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.10 ~ "*",
                        TRUE ~ "")
  sprintf("%.3f%s (%.3f)", est, s, se)
}

ss <- res$sample_sizes
rd <- res$rd_main

# --- Table 1: party coefficients, clustered SEs, R - D test -------------------
t1_rows <- tibble::tribble(
  ~term, ~m1, ~m2, ~m3,
  "Republican - Democrat",
  fmt_cell(rd$estimate[1], rd$std.error[1], rd$p.value[1]),
  fmt_cell(rd$estimate[2], rd$std.error[2], rd$p.value[2]),
  fmt_cell(rd$estimate[3], rd$std.error[3], rd$p.value[3]),
  "Wave fixed effects", "Yes", "Yes", "Yes",
  "Demographic controls", "No", "Yes", "Yes",
  "Ideology control", "No", "No", "Yes",
  "Observations (respondent-waves)",
  format(ss$n_obs[1], big.mark = ","), format(ss$n_obs[2], big.mark = ","),
  format(ss$n_obs[3], big.mark = ","),
  "Unique respondents",
  format(ss$n_unique[1], big.mark = ","), format(ss$n_unique[2], big.mark = ","),
  format(ss$n_unique[3], big.mark = ",")
)
names(t1_rows) <- c("term", "Model 1", "Model 2", "Model 3")

t1 <- modelsummary::modelsummary(
  list("Model 1" = res$main$m1, "Model 2" = res$main$m2,
       "Model 3" = res$main$m3),
  coef_map = c("party_fRepublican" = "Republican",
               "party_fDemocrat" = "Democrat",
               "(Intercept)" = "Constant"),
  estimate = "{estimate}{stars}", statistic = "({std.error})",
  stars = stars, gof_map = "none", add_rows = t1_rows,
  output = "flextable"
)
ms_tex(
  list("Model 1" = res$main$m1, "Model 2" = res$main$m2,
       "Model 3" = res$main$m3),
  "table1_party",
  "Partisan Gaps in Price Concern: Survey-Weighted OLS Estimates",
  paste("Outcome: price-concern item standardized within wave.",
        "Independents are the reference. Standard errors clustered by",
        "respondent in parentheses.", star_note),
  coef_map = c("party_fRepublican" = "Republican",
               "party_fDemocrat" = "Democrat",
               "(Intercept)" = "Constant"),
  estimate = "{estimate}{stars}", statistic = "({std.error})",
  stars = stars, gof_map = "none", add_rows = t1_rows
)
write_table(
  t1, "table1_party",
  "Table 1. Partisan Gaps in Price Concern: Survey-Weighted OLS Estimates",
  paste(
    "Note. Dependent variable: price-concern item, standardized within wave.",
    "Independents are the reference category. Standard errors, clustered by",
    "respondent, in parentheses. The Republican - Democrat row is a Wald",
    "contrast of the two party coefficients.", star_note
  )
)

# --- Table 2: demographic and ideology coefficients ---------------------------
t2 <- modelsummary::modelsummary(
  list("Model 2" = res$main$m2, "Model 3" = res$main$m3),
  coef_omit = "party_f|wave_f|Intercept",
  coef_rename = \(x) sub("^(age_f|gender_f|educ_f|income_f|ideo_f)", "", x),
  estimate = "{estimate}{stars}", statistic = "({std.error})",
  stars = stars, gof_map = "none", output = "flextable"
)
ms_tex(
  list("Model 2" = res$main$m2, "Model 3" = res$main$m3),
  "table2_controls",
  "Demographic and Ideological Predictors of Price Concern",
  paste("Reference categories: ages 18-29, male, H.S. graduate or less,",
        "income less than $30,000, very conservative. Party indicators and",
        "wave fixed effects included. Standard errors clustered by",
        "respondent.", star_note),
  coef_omit = "party_f|wave_f|Intercept",
  coef_rename = \(x) sub("^(age_f|gender_f|educ_f|income_f|ideo_f)", "", x),
  estimate = "{estimate}{stars}", statistic = "({std.error})",
  stars = stars, gof_map = "none"
)
write_table(
  t2, "table2_controls",
  "Table 2. Demographic and Ideological Predictors of Price Concern",
  paste(
    "Note. Reference categories: ages 18-29, male, H.S. graduate or less,",
    "income less than $30,000, very conservative. Party indicators and wave",
    "fixed effects included but not shown. Standard errors clustered by",
    "respondent.", star_note
  )
)

# --- Table 3: party coefficients estimated separately by wave -----------------
tidy_party <- function(m) {
  broom::tidy(m) |>
    dplyr::filter(term %in% c("party_fRepublican", "party_fDemocrat"))
}

by_wave_long <- purrr::imap(res$by_wave, \(ms, w) {
  purrr::imap(ms, \(m, spec) {
    dplyr::mutate(tidy_party(m), wave = w, spec = spec)
  }) |>
    purrr::list_rbind()
}) |>
  purrr::list_rbind() |>
  dplyr::mutate(party = sub("party_f", "", term))

readr::write_csv(by_wave_long, file.path(tab_dir, "table3_by_wave_long.csv"))

t3 <- by_wave_long |>
  dplyr::filter(spec %in% c("m1", "m2")) |>
  dplyr::mutate(cell = fmt_cell(estimate, std.error, p.value)) |>
  dplyr::select(wave, spec, party, cell) |>
  tidyr::pivot_wider(names_from = c(party, spec), values_from = cell) |>
  dplyr::left_join(
    res$rd_by_wave |>
      dplyr::filter(spec %in% c("m1", "m2")) |>
      dplyr::mutate(cell = fmt_cell(estimate, std.error, p.value)) |>
      dplyr::select(wave, spec, cell) |>
      tidyr::pivot_wider(names_from = spec, values_from = cell,
                         names_prefix = "RminusD_"),
    by = "wave"
  ) |>
  dplyr::left_join(n_by_wave, by = "wave") |>
  dplyr::left_join(dplyr::select(wave_meta, wave, field_dates, item_type),
                   by = "wave") |>
  dplyr::transmute(
    Wave = paste0(wave, " (", field_dates, ")"),
    `Item type` = item_type,
    `Republican` = Republican_m1, `Democrat` = Democrat_m1,
    `R - D` = RminusD_m1,
    `Republican (controls)` = Republican_m2,
    `Democrat (controls)` = Democrat_m2,
    `R - D (controls)` = RminusD_m2,
    N = format(n, big.mark = ",")
  )

wt <- res$test_wave_het
it <- res$test_item_het
write_table(
  t3, "table3_by_wave",
  "Table 3. Partisan Gaps in Price Concern, Estimated Separately by Wave",
  paste0(
    "Note. Each row is a separate survey-weighted regression of the ",
    "within-wave standardized item on party (Independents as reference). ",
    "'Controls' adds age, gender, education and income. Wald test that the ",
    "party gaps are equal across waves: F = ", sprintf("%.2f", wt$Ftest),
    " (df = ", wt$df, "), ", fmt_p(wt$p), ". Test that they are equal across ",
    "item types: F = ", sprintf("%.2f", it$Ftest), " (df = ", it$df, "), ",
    fmt_p(it$p), ". ", star_note
  )
)

# --- Table 4: direct interpretation on the original response scales ----------
t4 <- by_wave_long |>
  dplyr::filter(spec %in% c("raw", "top")) |>
  dplyr::mutate(cell = fmt_cell(estimate, std.error, p.value)) |>
  dplyr::select(wave, spec, party, cell) |>
  tidyr::pivot_wider(names_from = c(party, spec), values_from = cell) |>
  dplyr::left_join(
    res$top_shares |>
      dplyr::filter(party_f == "Independent") |>
      dplyr::transmute(wave = as.character(wave_f),
                       ind_share = sprintf("%.1f", 100 * share)),
    by = "wave"
  ) |>
  dplyr::left_join(wave_meta, by = "wave") |>
  dplyr::transmute(
    Wave = wave,
    Scale = paste0("1-", n_cats),
    `Republican (scale points)` = Republican_raw,
    `Democrat (scale points)` = Democrat_raw,
    `Independents in top category (%)` = ind_share,
    `Republican (top category, share)` = Republican_top,
    `Democrat (top category, share)` = Democrat_top
  )
write_table(
  t4, "table4_original_scales",
  "Table 4. Partisan Gaps on the Original Response Scales",
  paste(
    "Note. Scale-point columns: survey-weighted OLS of the recoded item",
    "(higher = more concern) on party. Top-category columns: linear",
    "probability models for choosing the most-concerned response ('a lot",
    "worse', 'a very big problem' or 'very concerned'); multiply by 100 for",
    "percentage points. Independents are the reference.", star_note
  )
)

# --- Table 5: leaners -----------------------------------------------------------
if (!is.null(res$leaners)) {
  rdl <- res$rd_leaners
  t5_rows <- tibble::tibble(
    term = "Republican - Democrat (with leaners)",
    `Model 1` = fmt_cell(rdl$estimate[1], rdl$std.error[1], rdl$p.value[1]),
    `Model 2` = fmt_cell(rdl$estimate[2], rdl$std.error[2], rdl$p.value[2]),
    `Model 3` = fmt_cell(rdl$estimate[3], rdl$std.error[3], rdl$p.value[3]),
    `Model 2, five categories` = ""
  )
  t5 <- modelsummary::modelsummary(
    list("Model 1" = res$leaners$m1, "Model 2" = res$leaners$m2,
         "Model 3" = res$leaners$m3,
         "Model 2, five categories" = res$leaners$five_m2),
    coef_map = c(
      "party_lean_fRepublican + leaners" = "Republican incl. leaners",
      "party_lean_fDemocrat + leaners" = "Democrat incl. leaners",
      "party_five_fRepublican" = "Republican",
      "party_five_fLean Republican" = "Lean Republican",
      "party_five_fLean Democrat" = "Lean Democrat",
      "party_five_fDemocrat" = "Democrat"
    ),
    estimate = "{estimate}{stars}", statistic = "({std.error})",
    stars = stars, gof_map = "nobs", add_rows = t5_rows,
    output = "flextable"
  )
  ms_tex(
    list("Model 1" = res$leaners$m1, "Model 2" = res$leaners$m2,
         "Model 3" = res$leaners$m3,
         "Model 2, five categories" = res$leaners$five_m2),
    "table5_leaners",
    "Partisan Gaps with Independent Leaners Grouped with Their Party",
    paste("Reference: Independents who do not lean to either party.",
          "Standard errors clustered by respondent.", star_note),
    coef_map = c(
      "party_lean_fRepublican + leaners" = "Republican incl. leaners",
      "party_lean_fDemocrat + leaners" = "Democrat incl. leaners",
      "party_five_fRepublican" = "Republican",
      "party_five_fLean Republican" = "Lean Republican",
      "party_five_fLean Democrat" = "Lean Democrat",
      "party_five_fDemocrat" = "Democrat"
    ),
    estimate = "{estimate}{stars}", statistic = "({std.error})",
    stars = stars, gof_map = "nobs", add_rows = t5_rows
  )
  write_table(
    t5, "table5_leaners",
    "Table 5. Partisan Gaps with Independent Leaners Grouped with Their Party",
    paste(
      "Note. Reference category: Independents who do not lean to either",
      "party (F_PARTYLN_FINAL). Models 2 and 3 include the same controls as",
      "Table 1. Standard errors clustered by respondent.", star_note
    )
  )
}

# --- Table A1: robustness -------------------------------------------------------
se_compare <- purrr::map2(res$main, res$main_unclustered, \(cl, un) {
  a <- tidy_party(cl)
  b <- tidy_party(un)
  tibble::tibble(term = a$term, se_clustered = a$std.error,
                 se_unclustered = b$std.error)
}) |>
  purrr::imap(\(d, nm) dplyr::mutate(d, model = nm)) |>
  purrr::list_rbind()
readr::write_csv(se_compare, file.path(tab_dir, "tableA1_se_comparison.csv"))

ta1 <- modelsummary::modelsummary(
  list("Model 2 (main)" = res$main$m2,
       "Weighted standardization" = res$robust$weighted_z,
       "Personal-concern waves only" = res$robust$concern_only,
       "Model 2, unclustered SEs" = res$main_unclustered$m2),
  coef_map = c("party_fRepublican" = "Republican",
               "party_fDemocrat" = "Democrat"),
  estimate = "{estimate}{stars}", statistic = "({std.error})",
  stars = stars, gof_map = "nobs", output = "flextable"
)
ms_tex(
  list("Model 2 (main)" = res$main$m2,
       "Weighted standardization" = res$robust$weighted_z,
       "Personal-concern waves only" = res$robust$concern_only,
       "Model 2, unclustered SEs" = res$main_unclustered$m2),
  "tableA1_robustness",
  "Robustness of the Partisan Gaps (Model 2 Specification)",
  paste("Column 2 standardizes within wave using survey weights. Column 3",
        "keeps W110, W116 and W120. Column 4 reproduces the submitted",
        "paper's standard errors.", star_note),
  coef_map = c("party_fRepublican" = "Republican",
               "party_fDemocrat" = "Democrat"),
  estimate = "{estimate}{stars}", statistic = "({std.error})",
  stars = stars, gof_map = "nobs"
)
write_table(
  ta1, "tableA1_robustness",
  "Table A1. Robustness of the Partisan Gaps (Model 2 Specification)",
  paste(
    "Note. Column 2 standardizes the item within wave using survey weights.",
    "Column 3 keeps the three waves that use the identical personal-concern",
    "question (W110, W116, W120). Column 4 reproduces the standard errors of",
    "the submitted paper, which did not cluster by respondent.", star_note
  )
)

# Measurement table (reviewer comment 2) and sample flow.
write_table(
  dplyr::transmute(wave_meta, Wave = wave, `Field dates` = field_dates,
                   Variable = item, `Item type` = item_type,
                   `Asked of` = form, `Question wording` = wording),
  "tableA2_items", "Table A2. Price Items by Wave",
  "Source: Pew Research Center ATP questionnaires and toplines."
)
readr::write_csv(sample_flow, file.path(tab_dir, "sample_flow.csv"))

# --- Figures ------------------------------------------------------------------
# Party colors (validated categorical slots; identity also carried by shape
# and direct labels, so it is never color alone).
pal <- c(Republican = "#eb6834", Democrat = "#2a78d6", Independent = "#8a8984")
shp <- c(Republican = 16, Democrat = 17, Independent = 15)

wave_lab <- wave_meta |>
  dplyr::transmute(wave, x_lab = paste0(cpi_month, "\n", item_type))

theme_paper <- ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_line(color = "grey90", linewidth = 0.3),
    legend.position = "top",
    plot.title.position = "plot"
  )

# Figure 1: by-wave party coefficients (reviewer comment 3).
fig1_df <- by_wave_long |>
  dplyr::filter(spec == "m1") |>
  dplyr::left_join(wave_lab, by = "wave") |>
  dplyr::mutate(x_lab = factor(x_lab, levels = wave_lab$x_lab))

p1 <- ggplot2::ggplot(
  fig1_df,
  ggplot2::aes(x_lab, estimate, color = party, shape = party)
) +
  ggplot2::geom_hline(yintercept = 0, color = "grey50", linewidth = 0.4) +
  ggplot2::geom_pointrange(
    ggplot2::aes(ymin = estimate - 1.96 * std.error,
                 ymax = estimate + 1.96 * std.error),
    position = ggplot2::position_dodge(width = 0.4), size = 0.4,
    linewidth = 0.6
  ) +
  ggplot2::scale_color_manual(values = pal, name = NULL) +
  ggplot2::scale_shape_manual(values = shp, name = NULL) +
  # No title: the caption is set in the paper (LaTeX or Word).
  ggplot2::labs(x = NULL, y = "Difference from Independents (SD units)") +
  theme_paper
save_fig(p1, "fig1_by_wave_coefs")

# Figure 2: share choosing the most-concerned response, by party and wave.
# Lines connect only the three waves with the identical question.
fig2_df <- res$top_shares |>
  dplyr::mutate(wave = as.character(wave_f), party = as.character(party_f)) |>
  dplyr::left_join(wave_lab, by = "wave") |>
  dplyr::left_join(dplyr::select(wave_meta, wave, item_type), by = "wave") |>
  dplyr::mutate(x_lab = factor(x_lab, levels = wave_lab$x_lab))

p2 <- ggplot2::ggplot(
  fig2_df,
  ggplot2::aes(x_lab, 100 * share, color = party, shape = party, group = party)
) +
  ggplot2::geom_line(
    data = dplyr::filter(fig2_df, item_type == "Personal concern"),
    linewidth = 0.6
  ) +
  ggplot2::geom_pointrange(
    ggplot2::aes(ymin = 100 * (share - 1.96 * se),
                 ymax = 100 * (share + 1.96 * se)),
    size = 0.4, linewidth = 0.6
  ) +
  ggplot2::scale_color_manual(values = pal, name = NULL) +
  ggplot2::scale_shape_manual(values = shp, name = NULL) +
  ggplot2::scale_y_continuous(limits = c(0, 100)) +
  # Fix the wave order explicitly (the line layer would otherwise set it).
  ggplot2::scale_x_discrete(limits = wave_lab$x_lab) +
  ggplot2::labs(
    x = NULL, y = "Percent"
  ) +
  theme_paper
save_fig(p2, "fig2_top_category_shares")

message("03_tables_figures.R complete: tables and figures written to output/")
