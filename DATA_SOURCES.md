# Data Sources

## Pew Research Center American Trends Panel

All models use five waves of the ATP. Pew provides the files at no cost to
users who create a Pew Research Center account and accept its terms and
conditions. The files are not redistributed in this repository.

| Wave | Field dates | Price item | Download page |
|---|---|---|---|
| 101 | Jan. 10–17, 2022 | ECONLIST_PRCG_W101 | https://www.pewresearch.org/dataset/american-trends-panel-wave-101/ |
| 107 | Apr. 25–May 1, 2022 | NATPROBS_INFL_W107 | https://www.pewresearch.org/dataset/american-trends-panel-wave-107/ |
| 110 | Jun. 27–Jul. 4, 2022 | ECONCONC_INFL_W110 | https://www.pewresearch.org/dataset/american-trends-panel-wave-110/ |
| 116 | Oct. 10–16, 2022 | ECONCONC_PRICE_W116 | https://www.pewresearch.org/dataset/american-trends-panel-wave-116/ |
| 120 | Jan. 18–24, 2023 | ECONCONC_PRICE_W120 | https://www.pewresearch.org/dataset/american-trends-panel-wave-120/ |

The exact question wording is in `config.yml` and in Table A2 of the paper.

The code also uses these variables, which appear in every wave:

- `QKEY`, the panelist identifier
- `F_PARTY_FINAL` and `F_PARTYLN_FINAL`, party identification and leaning
- `F_GENDER`, `F_AGECAT`, `F_EDUCCAT`, `F_INC_SDT1` and `F_IDEO`, demographics
  and ideology
- `WEIGHT_W101` through `WEIGHT_W120`, the survey weights for each wave

## Bureau of Labor Statistics Consumer Price Index

The paper reports CPI-U inflation as context. These figures are not used in any
model. The values are the 12-month percent change in the all-items index, not
seasonally adjusted, for the month each wave was fielded.

| Month | CPI-U, 12-month change (percent) |
|---|---|
| January 2022 | 7.5 |
| April 2022 | 8.3 |
| June 2022 | 9.1 |
| October 2022 | 7.7 |
| January 2023 | 6.4 |

Source: Bureau of Labor Statistics, series CUUR0000SA0 (https://data.bls.gov),
and the CPI news releases cited in the paper.
