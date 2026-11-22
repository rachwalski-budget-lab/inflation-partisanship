# test-functions.R ------------------------------------------------------------
# Unit tests for helpers in scripts/functions.R.
# Run: testthat::test_dir("tests/testthat")
# -----------------------------------------------------------------------------

library(testthat)
library(here)
source(here("scripts", "functions.R"))

test_that("recode_item() reverses 4-point items and drops refusals", {
  expect_equal(recode_item(c(1, 2, 3, 4, 99), 4, TRUE), c(4, 3, 2, 1, NA))
  expect_equal(recode_item(c(1, 5, 98), 5, FALSE), c(1, 5, NA))
})

test_that("code_party() keeps Rep/Dem/Ind with Independent as reference", {
  f <- code_party(c(1, 2, 3, 4, 99))
  expect_equal(levels(f)[1], "Independent")
  expect_equal(as.character(f), c("Republican", "Democrat", "Independent",
                                  NA, NA))
})

test_that("code_party_lean() moves leaners into their party", {
  party <- c(1, 2, 3, 3, 3, 3)
  lean <- c(NA, NA, 1, 2, 9, NA)
  g <- code_party_lean(party, lean, "grouped")
  expect_equal(as.character(g), c(
    "Republican + leaners", "Democrat + leaners", "Republican + leaners",
    "Democrat + leaners", "Non-leaning Independent", "Non-leaning Independent"
  ))
  five <- code_party_lean(party, lean, "five")
  expect_equal(as.character(five)[3:4], c("Lean Republican", "Lean Democrat"))
})

test_that("standardize() gives mean 0, SD 1, unweighted and weighted", {
  x <- c(1, 2, 3, 4, 5)
  expect_equal(mean(standardize(x)), 0, tolerance = 1e-10)
  expect_equal(sd(standardize(x)), 1, tolerance = 1e-10)
  w <- c(1, 1, 1, 1, 4)
  z <- standardize(x, w, weighted = TRUE)
  expect_equal(sum(w * z) / sum(w), 0, tolerance = 1e-10)
  expect_equal(weighted_sd(z, w), 1, tolerance = 1e-10)
})

test_that("standardize() preserves NAs", {
  expect_true(is.na(standardize(c(1, 2, NA, 4))[3]))
})

test_that("pct_change() reports the shrinkage the reviewers computed", {
  # Republican coefficient, submitted Model 1 -> Model 2: 0.304 -> 0.269.
  expect_equal(round(pct_change(0.304, 0.269), 1), -11.5)
  # Democratic coefficient grew in absolute size: -0.122 -> -0.137.
  expect_gt(pct_change(-0.122, -0.137), 0)
})

test_that("validate_input() and assert_no_duplicate_rows() fail loudly", {
  df <- data.frame(id = 1:3)
  expect_error(validate_input(df, required = c("id", "income")))
  expect_silent(validate_input(df, required = "id"))
  expect_error(assert_no_duplicate_rows(df, expected_n = 2))
})
