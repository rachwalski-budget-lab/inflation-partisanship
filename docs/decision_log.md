# Decision Log: inflation_partisanship
# Maintained by: Anna Rachwalski | Last updated: 2026-11-22

Choices made in the revision for the Sadie Collective Journal of Undergraduate
Research. Reviewer comment numbers refer to the reviewer memo.

---
## 2026-11-22 | Standard errors (reviewer comment 4)

Decision point:
  The ATP is a panel. The same panelist can answer in up to five waves, so
  pooled rows are not independent.

Options considered:
  1. Unclustered survey-weighted SEs (submitted paper).
  2. SEs clustered by panelist ID (QKEY) via svydesign(ids = ~qkey).

Choice made:  Option 2.
Rationale:    Standard treatment for repeated observations of the same person.
Sensitivity:  Table A1, column 4, and output/tables/tableA1_se_comparison.csv
              compare the two sets of SEs.
Reference:    scripts/02_model.R, "Survey designs"
Reviewer:     AR
---
## 2026-11-22 | Within-wave standardization

Decision point:
  The submitted paper standardized each wave's item with the unweighted mean
  and SD, then ran weighted regressions.

Options considered:
  1. Unweighted z-score (submitted paper).
  2. Weighted z-score, so the weighted distribution has mean 0, SD 1.

Choice made:  Option 1 for the main tables (continuity with the submission).
Rationale:    Coefficients change only through the SD rescaling; signs and
              tests are unaffected.
Sensitivity:  Table A1, column 2. Switch with model$standardize_weighted.
Reference:    config.yml; scripts/01_clean.R
Reviewer:     AR
---
## 2026-11-22 | Different items across waves (reviewer comments 2 and 3)

Decision point:
  W101 asks whether prices are better or worse than a year ago, W107 how big
  a problem inflation is, and W110/W116/W120 how concerned the respondent is
  personally. W101 and W107 items were asked of one random half of the wave
  (Form 2 and Form 1).

Options considered:
  1. Pool all five waves (submitted paper).
  2. Report each wave separately and test whether the gaps differ.
  3. Restrict to the three identical personal-concern waves.

Choice made:  Keep 1 as the main estimate; add 2 (Table 3, Figure 1, Wald
              tests) and 3 (Table A1, column 3).
Rationale:    Lets readers see whether the pooled result holds item by item.
Sensitivity:  Tables 3 and A1.
Reference:    scripts/02_model.R, "By-wave models"
Reviewer:     AR
---
## 2026-11-22 | Leaners (minor comment)

Decision point:
  How to treat Independents who lean toward a party.

Options considered:
  1. Leaners stay Independent (submitted paper).
  2. Leaners grouped with their party; non-leaning Independents as reference.
  3. Five categories: Rep, Lean Rep, non-leaning Ind, Lean Dem, Dem.

Choice made:  1 for the main tables; 2 and 3 in Table 5.
Rationale:    Keeps the main sample unchanged while showing how leaners behave.
              Respondents who said "something else" on F_PARTY_FINAL stay
              excluded in all versions so the sample does not change.
Sensitivity:  Table 5.
Reference:    scripts/functions.R, code_party_lean()
Reviewer:     AR
---
## 2026-11-22 | Gender coding

Decision point:
  The submitted code coded female = (F_GENDER == 2), so "in some other way"
  and refusals were counted as male.

Choice made:  Only 1 = Male and 2 = Female are coded; other responses are
              missing and drop from Models 2-3 by listwise deletion.
Rationale:    Respondents who did not report male should not be counted as male.
Sensitivity:  Changes Model 2-3 N by the small number of such respondents.
Reference:    scripts/01_clean.R
Reviewer:     AR
---
## 2026-11-22 | CPI values in wave metadata

Decision point:
  The submitted code listed April 2022 CPI-U inflation as 8.5% (the March
  figure) and January 2023 as 6.5% (the December 2022 figure).

Choice made:  Use the 12-month CPI-U change for the month each wave was
              fielded: 7.5, 8.3, 9.1, 7.7, 6.4 (BLS CPI news releases).
              W110 was fielded June 27-July 4, 2022; June CPI (9.1) is used.
Reference:    config.yml
Reviewer:     AR
---
