# functions.R ----------------------------------------------------------------
# Shared helper functions, documented with Roxygen2.
# Sourced by the numbered scripts. Keep functions pure: data in, value out.
# -----------------------------------------------------------------------------

# --- Validation ---------------------------------------------------------------

#' Validate a data frame at a pipeline boundary
#'
#' @param df A data frame.
#' @param required Character vector of column names that must be present.
#' @return `df`, invisibly.
#' @export
validate_input <- function(df, required = character()) {
  assertthat::assert_that(is.data.frame(df), msg = "Input must be a data frame")
  assertthat::assert_that(nrow(df) > 0, msg = "Input data frame is empty")
  missing <- setdiff(required, names(df))
  assertthat::assert_that(
    length(missing) == 0,
    msg = paste("Missing columns:", paste(missing, collapse = ", "))
  )
  invisible(df)
}

#' Assert that a join did not create duplicate rows
#'
#' @param joined The data frame produced by the join.
#' @param expected_n The row count expected.
#' @return `joined`, invisibly.
#' @export
assert_no_duplicate_rows <- function(joined, expected_n) {
  assertthat::assert_that(
    nrow(joined) == expected_n,
    msg = paste("Join created duplicate rows:", nrow(joined), "!=", expected_n)
  )
  invisible(joined)
}

# --- Recoding -----------------------------------------------------------------

#' Recode a Pew response item so higher values mean more concern
#'
#' Pew codes "Refused" as 99 (and some items use 98). Those become NA. When
#' `reverse` is TRUE the scale is flipped as (n_cats + 1) - x, so on a 4-point
#' item 1 becomes 4 and 4 becomes 1.
#'
#' @param x Numeric (or haven_labelled) response vector.
#' @param n_cats Number of substantive response categories.
#' @param reverse Logical; flip the scale?
#' @return Numeric vector on 1..n_cats with NA for nonresponse.
#' @examples
#' recode_item(c(1, 4, 99), n_cats = 4, reverse = TRUE) # 4 1 NA
#' @export
recode_item <- function(x, n_cats, reverse) {
  x <- as.numeric(x)
  x[x >= 98 | x < 1 | x > n_cats] <- NA
  if (reverse) (n_cats + 1) - x else x
}

#' Convert a haven_labelled vector to a factor, with 98/99 codes set to NA
#'
#' @param x A haven_labelled vector.
#' @return A factor with unused levels dropped.
#' @export
as_labelled_factor <- function(x) {
  num <- as.numeric(x)
  f <- haven::as_factor(x, levels = "labels")
  f[num >= 98] <- NA
  droplevels(f)
}

#' Code party identification, Independents as reference
#'
#' Keeps only Republicans (1), Democrats (2) and Independents (3).
#' "Something else" (4) and refusals (99) become NA.
#'
#' @param party Numeric F_PARTY_FINAL.
#' @return Factor with levels Independent, Republican, Democrat.
#' @export
code_party <- function(party) {
  party <- as.numeric(party)
  factor(
    dplyr::case_when(
      party == 1 ~ "Republican",
      party == 2 ~ "Democrat",
      party == 3 ~ "Independent",
      TRUE ~ NA_character_
    ),
    levels = c("Independent", "Republican", "Democrat")
  )
}

#' Code party with leaners
#'
#' `scheme = "grouped"`: Independents who lean to a party are grouped with that
#' party; non-leaning Independents are the reference.
#' `scheme = "five"`: Republican, Lean Republican, Non-leaning Independent,
#' Lean Democrat, Democrat (reference = Non-leaning Independent).
#' Only respondents who are Rep/Dem/Ind on F_PARTY_FINAL are coded, so the
#' sample matches the main specification.
#'
#' @param party Numeric F_PARTY_FINAL.
#' @param lean Numeric F_PARTYLN_FINAL (1 = lean Rep, 2 = lean Dem).
#' @param scheme "grouped" or "five".
#' @return A factor.
#' @export
code_party_lean <- function(party, lean, scheme = c("grouped", "five")) {
  scheme <- match.arg(scheme)
  party <- as.numeric(party)
  lean <- as.numeric(lean)
  ind <- party == 3
  lean_rep <- ind & !is.na(lean) & lean == 1
  lean_dem <- ind & !is.na(lean) & lean == 2

  if (scheme == "grouped") {
    out <- dplyr::case_when(
      party == 1 | lean_rep ~ "Republican + leaners",
      party == 2 | lean_dem ~ "Democrat + leaners",
      ind ~ "Non-leaning Independent",
      TRUE ~ NA_character_
    )
    factor(out, levels = c(
      "Non-leaning Independent", "Republican + leaners", "Democrat + leaners"
    ))
  } else {
    out <- dplyr::case_when(
      party == 1 ~ "Republican",
      lean_rep ~ "Lean Republican",
      party == 2 ~ "Democrat",
      lean_dem ~ "Lean Democrat",
      ind ~ "Non-leaning Independent",
      TRUE ~ NA_character_
    )
    factor(out, levels = c(
      "Non-leaning Independent", "Republican", "Lean Republican",
      "Lean Democrat", "Democrat"
    ))
  }
}

# --- Standardization -----------------------------------------------------------

#' Weighted standard deviation (population form, matching weighted.mean)
#'
#' @param x Numeric vector.
#' @param w Non-negative weights, same length as x.
#' @return A single number.
#' @export
weighted_sd <- function(x, w) {
  ok <- !is.na(x) & !is.na(w)
  x <- x[ok]
  w <- w[ok]
  m <- sum(w * x) / sum(w)
  sqrt(sum(w * (x - m)^2) / sum(w))
}

#' Standardize to mean zero, SD one, optionally with survey weights
#'
#' Unweighted: (x - mean) / sd, as in the submitted paper.
#' Weighted: uses the weighted mean and weighted SD, so the weighted
#' distribution has mean zero and SD one.
#'
#' @param x Numeric vector.
#' @param w Weights (ignored if `weighted = FALSE`).
#' @param weighted Logical.
#' @return Numeric vector the same length as `x`; NAs preserved.
#' @export
standardize <- function(x, w = NULL, weighted = FALSE) {
  assertthat::assert_that(is.numeric(x), msg = "x must be numeric")
  if (weighted) {
    assertthat::assert_that(!is.null(w), msg = "weights required")
    ok <- !is.na(x) & !is.na(w)
    m <- sum(w[ok] * x[ok]) / sum(w[ok])
    s <- weighted_sd(x, w)
  } else {
    m <- mean(x, na.rm = TRUE)
    s <- stats::sd(x, na.rm = TRUE)
  }
  assertthat::assert_that(s > 0, msg = "x has zero variance; cannot standardize")
  (x - m) / s
}

# --- Reading ------------------------------------------------------------------

#' Read one ATP wave and return a tidy, wave-specific data frame
#'
#' Reads only the columns needed. Fails loudly if any are missing and lists
#' near matches so a renamed variable is easy to find.
#'
#' @param w One element of cfg$waves (a list).
#' @param vars cfg$vars (a list of shared variable names).
#' @param raw_dir Directory holding the wave folders.
#' @param id_col Respondent ID column.
#' @return A tibble with one row per respondent in the wave.
#' @export
read_wave <- function(w, vars, raw_dir, id_col) {
  path <- file.path(raw_dir, w$folder, w$file)
  assertthat::assert_that(file.exists(path), msg = paste("File not found:", path))

  available <- names(haven::read_sav(path, n_max = 0))
  # F_PARTYLN_FINAL is optional (only needed for the leaner check).
  needed <- c(id_col, w$weight, w$item, unlist(vars))
  optional <- vars$party_lean
  missing <- setdiff(setdiff(needed, optional), available)
  if (length(missing) > 0) {
    hints <- vapply(missing, function(m) {
      stem <- sub("_W[0-9]+$|_FINAL$", "", m)
      paste(grep(stem, available, value = TRUE, ignore.case = TRUE),
            collapse = ", ")
    }, character(1))
    stop(
      "In ", w$wave, " missing: ",
      paste0(missing, " (near matches: ", hints, ")", collapse = "; ")
    )
  }

  raw <- haven::read_sav(path, col_select = dplyr::any_of(needed))

  tibble::tibble(
    qkey = as.character(raw[[id_col]]),
    wave = w$wave,
    item_type = w$item_type,
    weight = as.numeric(raw[[w$weight]]),
    infl_raw = recode_item(raw[[w$item]], w$n_cats, w$reverse),
    infl_top = as.numeric(
      recode_item(raw[[w$item]], w$n_cats, w$reverse) == w$n_cats
    ),
    party_num = as.numeric(raw[[vars$party]]),
    lean_num = if (vars$party_lean %in% names(raw)) {
      as.numeric(raw[[vars$party_lean]])
    } else {
      NA_real_
    },
    gender = as.numeric(raw[[vars$gender]]),
    age = as_labelled_factor(raw[[vars$age]]),
    educ = as_labelled_factor(raw[[vars$educ]]),
    income = as_labelled_factor(raw[[vars$income]]),
    ideo = as_labelled_factor(raw[[vars$ideo]])
  )
}

# --- Results helpers ----------------------------------------------------------

#' Republican-minus-Democrat contrast from a fitted svyglm
#'
#' @param model A fitted svyglm.
#' @param rep_term,dem_term Coefficient names.
#' @return One-row tibble: estimate, std.error, statistic, p.value.
#' @export
rd_contrast <- function(model,
                        rep_term = "party_fRepublican",
                        dem_term = "party_fDemocrat") {
  cvec <- stats::setNames(c(1, -1), c(rep_term, dem_term))
  ct <- survey::svycontrast(model, cvec)
  est <- as.numeric(stats::coef(ct))
  se <- as.numeric(survey::SE(ct))
  df_resid <- model$df.residual
  tstat <- est / se
  tibble::tibble(
    estimate = est,
    std.error = se,
    statistic = tstat,
    p.value = 2 * stats::pt(abs(tstat), df = df_resid, lower.tail = FALSE)
  )
}

#' Percent change from a to b, signed, in percent
#'
#' Uses absolute values so the result reads as "shrank by X percent" for
#' coefficients of either sign. pct_change(0.304, 0.269) = -11.5.
#'
#' @param from,to Numbers.
#' @return Numeric percent.
#' @export
pct_change <- function(from, to) {
  100 * (abs(to) - abs(from)) / abs(from)
}

#' Format a p-value for prose
#'
#' @param p A p-value.
#' @return Character, e.g. "p < .001" or "p = .023".
#' @export
fmt_p <- function(p) {
  ifelse(
    p < 0.001,
    "p < .001",
    paste0("p = ", sub("^0", "", formatC(p, format = "f", digits = 3)))
  )
}
