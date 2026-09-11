# Module 05 — Age–length consistency

This module audits simulated age and length information before any age-based assessment is attempted.

It focuses on:

- record-level validity, duplicate fish IDs and unit/code checks;
- ageing sample support across year, area, season, source and gear;
- age composition support through time;
- biological plausibility of length-at-age observations;
- paired-reader agreement and temporal calibration drift;
- age–length key (ALK) construction and weak-support bins;
- transferability of historical ALKs to later years;
- comparison of global versus area × source ALK transfer;
- temporal stability of length-at-age.

The dataset is entirely simulated. Several problems are introduced deliberately so that the module demonstrates diagnosis and transparent decision-making rather than presenting unrealistically clean data.

The central scientific question is: **are the age observations coherent and sufficiently supported to be used beyond the strata and period in which they were collected?**

## Reusable functions for real ageing data

`age_length_diagnostics.R` separates the reusable diagnostics from the simulated worked example. It does not assume the example column names and can therefore be sourced for another stock after explicit field mapping.

The reusable functions include:

- `flag_age_length_records()` — missing/non-finite values, stock-specific length/age ranges, non-integer age codes and duplicate IDs;
- `ageing_coverage()` — support across any combination of year, area, season, fleet, gear, source or other sampling strata;
- `age_length_outliers()` — robust within-age length screening using median and MAD, while retaining small groups rather than over-interpreting them;
- `length_at_age_summary()` — age-specific length summaries and a transparent adjacent-age monotonicity diagnostic;
- `reader_agreement()` — exact agreement, tolerance agreement, bias, mean absolute difference and RMSE for paired readings, optionally by period or other strata;
- `make_alk_generic()` — ALK construction with explicit length-bin support and weak-bin flags;
- `apply_alk()` — expected-age or modal-age prediction while preserving records outside ALK support;
- `evaluate_alk_transfer()` — out-of-period or out-of-stratum ALK coverage, bias, MAE and RMSE;
- `age_length_stability()` — temporal length-at-age comparison against user-defined reference years.

A minimal adaptation pattern is:

```r
source("05-age-length-consistency/age_length_diagnostics.R")

age_raw <- read.csv("my_ageing_data.csv")

age_qc <- flag_age_length_records(
  age_raw,
  length_col = "length_cm",
  age_col = "age",
  id_col = "fish_id",
  min_length = 8,
  max_length = 80,
  min_age = 0,
  max_age = 12
)

coverage <- ageing_coverage(
  age_qc,
  strata = c("year", "area", "season", "source", "gear"),
  id_col = "fish_id",
  min_n = 15
)

reader_check <- reader_agreement(
  age_qc,
  reader1_col = "age_reader1",
  reader2_col = "age_reader2",
  strata = "period"
)

train <- subset(age_qc, year <= 2020)
test  <- subset(age_qc, year >= 2021)

transfer_global <- evaluate_alk_transfer(
  train, test,
  length_col = "length_cm",
  age_col = "age",
  bin_width = 2,
  prediction = "expected"
)

transfer_stratified <- evaluate_alk_transfer(
  train, test,
  length_col = "length_cm",
  age_col = "age",
  strata = c("area", "source"),
  bin_width = 2,
  prediction = "expected"
)
```

The numerical thresholds above are examples, **not universal fisheries standards**. Length/age bounds, ALK bin width, minimum support, comparison periods and useful stratification must be chosen from the biology, ageing protocol and monitoring design of the stock being analysed.

## Files

- `05_age_length_consistency.R` — complete reproducible simulation and worked diagnostics;
- `age_length_diagnostics.R` — reusable functions for adapting the workflow to another stock;
- `index.qmd` — Quarto scientific narrative and figures;
- `data-dictionary.md` — simulated variables and deliberate data-quality problems.

Run `05_age_length_consistency.R` directly or render `index.qmd` through the repository Quarto website. For a real application, start with `age_length_diagnostics.R` and the repository-level `USING-YOUR-OWN-DATA.md` guidance.