# Module 04 — Spatio-temporal consistency

This module asks whether apparent temporal changes in fish length structure remain when observations are compared **within like-for-like sampling strata**.

It extends the fully simulated individual-fish monitoring programme from Module 03 and deliberately stays upstream of any stock-assessment model.

## Scientific questions

- Did the composition of sampled areas, seasons, gears or data sources change through time?
- How different are pooled annual mean lengths from fixed-design standardized summaries?
- Do temporal anomalies move synchronously across spatial areas?
- Are year-to-year changes directionally consistent among persistent strata?
- Is an apparent shift concentrated in one gear, potentially indicating selectivity or observation-process change?
- Do spatial contrasts persist after matching year, season, gear and source?
- Does any one area dominate the standardized temporal signal?

## Main diagnostics

The workflow includes:

- persistent-stratum screening using minimum annual sample size;
- annual sampling-composition shares by area and gear;
- Jensen–Shannon divergence as a descriptive measure of design drift;
- pooled versus fixed-reference-weight annual mean length;
- within-stratum annual anomalies;
- spatial synchrony of matched anomalies;
- gear-specific anomaly trajectories;
- directional agreement of year-to-year changes across strata;
- matched West–Central–East spatial contrasts;
- leave-one-area-out sensitivity.

## Important interpretation rule

Standardization is treated as a **sensitivity analysis**, not as an automatic correction. Raw, pooled and standardized summaries remain visible together because stratification choices can remove both observation artefacts and genuine biological variation.

## Files

- [`index.qmd`](index.qmd) — Quarto scientific narrative and figures.
- [`04_spatiotemporal_consistency.R`](04_spatiotemporal_consistency.R) — reproducible analysis objects and validation checks.
- [`data-dictionary.md`](data-dictionary.md) — derived variables and interpretation notes.

## Data policy

All observations are simulated. The module reuses the synthetic monitoring process created in Module 03 and contains no confidential or institutional data.
