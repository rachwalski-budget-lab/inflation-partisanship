# Decision Log: inflation_partisanship
# Maintained by: Anna Rachwalski | Last updated: 2026-11-22

This log records each analytical choice made in the revision for the Sadie
Collective Journal of Undergraduate Research. Reviewer comment numbers refer to
the reviewers' memo.

---
## 2026-11-22 | Standard errors (reviewer comment 4)

Decision point:
  The ATP is a panel. The same person can answer in up to five waves, so the
  pooled observations are not independent.

Options considered:
  1. Survey-weighted standard errors without clustering, as in the submitted
     paper.
  2. Standard errors clustered by panelist (QKEY).

Choice made:  Option 2.
Rationale:    Clustering is the standard treatment when people are observed
              more than once.
Sensitivity:  Table A1, column 4, reports the unclustered standard errors.
              output/tables/tableA1_se_comparison.csv compares the two.
Reference:    scripts/02_model.R, section "Survey designs"
Reviewer:     AR
---
## 2026-11-22 | Within-wave standardization

Decision point:
  The submitted paper standardized each wave's item with the unweighted mean
  and standard deviation and then ran weighted regressions.

Options considered:
  1. Unweighted standardization, as in the submitted paper.
  2. Weighted standardization, so that the weighted distribution has a mean of
     zero and a standard deviation of one.

Choice made:  Option 1 for the main tables.
Rationale:    It keeps the main estimates comparable with the submission. The
              choice changes only the scale of the coefficients. It does not
              change their signs or the tests.
Sensitivity:  Table A1, column 2. The setting model$standardize_weighted in
              config.yml switches between the two.
Reference:    config.yml and scripts/01_clean.R
Reviewer:     AR
---
## 2026-11-22 | Different questions across waves (reviewer comments 2 and 3)

Decision point:
  The waves use three kinds of question. W101 asks whether prices are better
  or worse than a year ago. W107 asks how big a problem inflation is in the
  country. W110, W116 and W120 ask how concerned the respondent is personally.
  The W101 and W107 questions were asked of one random half of each wave.

Options considered:
  1. Pool all five waves, as in the submitted paper.
  2. Estimate each wave separately and test whether the gaps differ.
  3. Keep only the three waves that use the same personal-concern question.

Choice made:  Option 1 for the main estimate, with options 2 and 3 reported.
Rationale:    Readers can see whether the pooled result holds for each
              question.
Sensitivity:  Table 3 and Figure 1 report option 2. Table A1, column 3,
              reports option 3.
Reference:    scripts/02_model.R, section "By-wave models"
Reviewer:     AR
---
## 2026-11-22 | Independents who lean toward a party (minor comment)

Decision point:
  How to treat Independents who say they lean toward a party.

Options considered:
  1. Keep leaners with Independents, as in the submitted paper.
  2. Group leaners with their party and use non-leaning Independents as the
     reference group.
  3. Use five categories: Republican, lean Republican, non-leaning
     Independent, lean Democrat and Democrat.

Choice made:  Option 1 for the main tables, with options 2 and 3 in Table 5.
Rationale:    The main sample stays the same while showing how leaners
              compare with partisans. Respondents who answered "something
              else" on F_PARTY_FINAL are excluded in every version.
Sensitivity:  Table 5.
Reference:    scripts/functions.R, code_party_lean()
Reviewer:     AR
---
## 2026-11-22 | Gender coding

Decision point:
  The submitted code set female equal to F_GENDER == 2. Respondents who
  answered "in some other way" or refused were therefore coded as male.

Choice made:  Only 1 (male) and 2 (female) are coded. Other responses are
              missing and drop out of Models 2 and 3.
Rationale:    Respondents who did not report being male should not be coded
              as male.
Sensitivity:  The Model 2 sample falls from 17,910 to 17,784 and the Model 3
              sample from 17,714 to 17,589.
Reference:    scripts/01_clean.R
Reviewer:     AR
---
## 2026-11-22 | CPI values

Decision point:
  The submitted code listed April 2022 CPI-U inflation as 8.5 percent, which
  is the March figure. It listed January 2023 as 6.5 percent, which is the
  December 2022 figure.

Choice made:  Each wave uses the 12-month CPI-U change for the month it was
              fielded: 7.5, 8.3, 9.1, 7.7 and 6.4 percent. W110 was fielded
              from June 27 to July 4, 2022, so it uses the June figure.
Reference:    config.yml
Reviewer:     AR
---
