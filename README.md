# Partisan Polarization and Inflation Concern in the United States, 2022–2023

Replication code for Rachwalski, "Partisan Polarization and Inflation Concern in
the United States, 2022–2023," *Sadie Collective Journal of Undergraduate
Research* (forthcoming).

The paper estimates differences in concern about prices among Republicans,
Democrats and Independents in five waves of the Pew Research Center American
Trends Panel, January 2022 to January 2023. Models are survey-weighted OLS with
standard errors clustered by respondent.

## Data

The Pew data are not included. `data/raw/README.md` describes how to download
them (free Pew account) and where to place them. CPI-U figures cited in the
paper come from Bureau of Labor Statistics news releases and are not used in
any model.

## Software

R 4.3 or later. Package versions are recorded in `renv.lock`; run
`renv::restore()` to install them. Without renv, `scripts/00_setup.R` installs
the required packages. Results in the paper were produced with the survey
package, version 4.5.

## Reproducing the results

Open `inflation_partisanship.Rproj` and run `scripts/00_run_all.R`. The scripts
run in order:

| Script | Does | Writes |
|---|---|---|
| `01_clean.R` | Reads and recodes the five waves; standardizes the outcome within wave | `data/processed/` |
| `02_model.R` | Fits all models | `output/model_results.rds` |
| `03_tables_figures.R` | Tables and figures | `output/tables/` (.docx, .tex, .csv), `output/figures/` (.png, .pdf) |
| `04_numbers_for_text.R` | Every number quoted in the text | `output/numbers_for_text.md` |

`scripts/functions.R` holds the helper functions; unit tests are in
`tests/testthat/` and run at the end of `00_run_all.R`. Analytical choices are
set in `config.yml` and explained in `docs/decision_log.md`. Run time is under
five minutes on a laptop.

## Map from paper to output

| Paper | File |
|---|---|
| Table 1 | `output/tables/table1_party` |
| Table 2 | `output/tables/table2_controls` |
| Table 3 | `output/tables/table3_by_wave` |
| Table 4 | `output/tables/table4_original_scales` |
| Table 5 | `output/tables/table5_leaners` |
| Table A1 | `output/tables/tableA1_robustness` |
| Table A2 | `output/tables/tableA2_items` |
| Figure 1 | `output/figures/fig1_by_wave_coefs` |
| Figure 2 | `output/figures/fig2_top_category_shares` |

LaTeX tables use tinytable and require `\usepackage{tabularray}`.

## License and citation

Code is released under the MIT License. See `CITATION.cff` to cite.

## Contact

Anna Rachwalski, anna.rachwalski@yale.edu
