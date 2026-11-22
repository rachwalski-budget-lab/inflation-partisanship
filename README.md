# Partisan Polarization and Inflation Concern in the United States, 2022–2023

[![tests](https://github.com/rachwalski-budget-lab/inflation-partisanship/actions/workflows/tests.yml/badge.svg)](https://github.com/rachwalski-budget-lab/inflation-partisanship/actions/workflows/tests.yml)

This repository contains the code for Anna Rachwalski, "Partisan Polarization
and Inflation Concern in the United States, 2022–2023." The paper was
conditionally accepted, pending revisions, by the *Sadie Collective Journal of
Undergraduate Research*.

## Overview

The analysis estimates how concern about prices differed among Republicans,
Democrats and Independents during the 2022–2023 inflation episode. It uses five
waves of the Pew Research Center American Trends Panel (ATP), fielded from
January 2022 to January 2023. The models are survey-weighted ordinary least
squares regressions. Standard errors are clustered by respondent because the
panel interviews many people in more than one wave.

## Quick Start

```r
# 1. Place the five Pew ATP files as described in data/raw/README.md.
# 2. Open inflation_partisanship.Rproj in RStudio.
# 3. Install the locked package versions.
renv::restore()

# 4. Run the full pipeline.
source("scripts/00_run_all.R")
```

## Project Structure

```
inflation_partisanship/
├── config.yml              Analytical choices and wave metadata
├── scripts/
│   ├── 00_setup.R          Installs packages (first use only)
│   ├── 00_run_all.R        Runs the full pipeline
│   ├── 01_clean.R          Reads, recodes and standardizes the data
│   ├── 02_model.R          Fits all models
│   ├── 03_tables_figures.R Writes tables and figures
│   ├── 04_numbers_for_text.R  Writes every number quoted in the paper
│   └── functions.R         Helper functions
├── tests/testthat/         Unit tests for functions.R
├── data/
│   ├── raw/                Pew files (not included)
│   └── processed/          Cleaned data (rebuilt by 01_clean.R)
├── output/                 Tables, figures and numbers for the text
└── docs/                   Decision log and session information
```

## Model Flow

1. `01_clean.R` reads the five waves and keeps respondents who answered the
   price item and identified as Republican, Democrat or Independent. It recodes
   each item so that higher values mean more concern. It then standardizes each
   item within its wave.
2. `02_model.R` fits the pooled models, separate models for each wave, models
   with leaning Independents grouped with their party, and robustness checks.
   It also tests whether the party gaps differ across waves and item types.
3. `03_tables_figures.R` writes each table as `.docx`, `.tex` and `.csv` and
   each figure as `.png` and `.pdf`.
4. `04_numbers_for_text.R` writes `output/numbers_for_text.md`. All numbers in
   the paper's text come from this file.
5. `00_run_all.R` runs the unit tests last and saves the R session information
   to `docs/sessionInfo.txt`.

## Output Structure

The outputs are committed, so results can be checked without rerunning the
code.

| Paper | File in `output/tables/` or `output/figures/` |
|---|---|
| Table 1. Party coefficients | `table1_party` |
| Table 2. Demographic and ideology coefficients | `table2_controls` |
| Table 3. Estimates by wave | `table3_by_wave` |
| Table 4. Estimates on the original scales | `table4_original_scales` |
| Table 5. Leaning Independents grouped with their party | `table5_leaners` |
| Table A1. Robustness checks | `tableA1_robustness` |
| Table A2. Question wording | `tableA2_items` |
| Figure 1. Party coefficients by wave | `fig1_by_wave_coefs` |
| Figure 2. Share giving the most-concerned response | `fig2_top_category_shares` |

## Configuration

`config.yml` sets the file names, survey weights, question wording and response
coding for each wave, along with the model settings. `docs/decision_log.md`
records each analytical choice, the alternatives considered and where the
sensitivity checks appear.

## Data

The Pew ATP files are free but require a Pew Research Center account. They are
not included in this repository. `data/raw/README.md` explains how to download
them and where to place them. `DATA_SOURCES.md` lists every input. Consumer
Price Index figures appear in the paper as context and are not used in any
model.

## Scope

- The outcome is concern about prices, not an estimate of the inflation rate.
  The results do not show whether any group misjudged inflation.
- The estimates are associations, not causal effects.
- The five waves use three different Pew questions. Table 3 reports results for
  each wave.

## Requirements

- R 4.3 or later. Results were produced with R 4.6.1 on macOS.
- Package versions are locked in `renv.lock`. Results use version 4.5 of the
  survey package.
- About 25 MB of disk for the raw data and 85 MB for outputs.
- LaTeX tables require `\usepackage{tabularray}`.

## Citation

> Rachwalski, Anna. 2026. "Partisan Polarization and Inflation Concern in the
> United States, 2022–2023." Replication code, version 1.0.0.
> https://github.com/rachwalski-budget-lab/inflation-partisanship

```bibtex
@misc{rachwalski2026inflation,
  author = {Rachwalski, Anna},
  title  = {Partisan Polarization and Inflation Concern in the United States,
            2022--2023: Replication Code},
  year   = {2026},
  note   = {Version 1.0.0},
  url    = {https://github.com/rachwalski-budget-lab/inflation-partisanship}
}
```

## License and Contact

The code is released under the MIT License. The paper began as a research paper
for POLS 4551, Propaganda and American Politics, taught by Dr. Audrey A. Haynes
at the University of Georgia in spring 2026. It is independent research and is
not a product of The Budget Lab at Yale.

Anna Rachwalski, anna.rachwalski@yale.edu
