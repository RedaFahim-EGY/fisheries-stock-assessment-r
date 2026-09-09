# Module 06 — Life-history data quality and parameter consistency

This module audits simulated life-history information before any stock-assessment model is fitted.

It focuses on:

- biological record validity, duplicate IDs and unit/code errors;
- sampling support through year × month × area × source combinations;
- sex- and source-specific weight–length relationships;
- temporal stability of weight–length parameters;
- maturity ogives, L50 and observation-source sensitivity;
- sex-ratio differences across monitoring components;
- spawning-season consistency using GSI;
- sex-specific growth information;
- provenance and compatibility of candidate biological parameters;
- explicit comparison of natural-mortality estimators rather than an unexplained fixed M;
- coherence among growth, maturity, allometry and other life-history inputs.

The central scientific question is:

> **Are the biological parameters internally coherent, adequately supported and transferable to the stock, sex, period and observation process relevant to the assessment?**

The dataset is entirely simulated and includes deliberate problems so the workflow demonstrates diagnosis, documentation and sensitivity analysis rather than simply fitting curves.

## Natural mortality

The module now implements reusable functions for several common empirical approaches:

- Pauly (1980), using `Linf`, `K` and mean environmental temperature;
- Hoenig (1983) as an explicitly labelled longevity-based proxy, with the important caveat that the original relationship predicts total mortality `Z`;
- Then et al. (2015) `tmax`-based estimator;
- Then et al. (2015) growth-based estimator;
- Gislason et al. (2010) length-dependent natural mortality.

These estimates are compared as alternative evidence. The module does **not** assume that disagreement should be averaged away or that one estimator is universally correct.

PRODBIOM is not approximated with an ad-hoc formula. Because it is a structurally different mortality-at-age/length method based on biomass production and loss, it should be implemented separately and validated against the original methodology before being offered as a reusable routine.

## Using the code with another stock

The simulated analysis and the reusable mortality functions are deliberately separated. Analysts can source `natural_mortality_methods.R` directly and supply reviewed stock-specific inputs without recreating the simulated dataset.

For example:

```r
source("natural_mortality_methods.R")

compare_scalar_M(
  Linf_cm = 42.5,
  K = 0.31,
  temperature_C = 18,
  tmax_years = 9
)

M_gislason_at_age(
  age = 1:8,
  Linf_cm = 42.5,
  K = 0.31,
  t0 = -0.4
)
```

The numbers above are examples only. For a real assessment, each input should be traceable to its stock, sex, spatial unit, time period and estimation method, and the assumptions of each mortality estimator should be reviewed before use.

The same reusable-data philosophy will progressively be extended to the other modules.

## Files

- `06_life_history_consistency.R` — reproducible simulation, QC and diagnostics.
- `natural_mortality_methods.R` — reusable empirical natural-mortality functions.
- `index.qmd` — Quarto scientific narrative, comparisons and figures.
- `data-dictionary.md` — variables, simulated structure and deliberate inconsistencies.

No confidential or institutional data are used.
