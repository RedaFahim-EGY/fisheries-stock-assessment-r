# Using the workflows with your own fisheries data

This repository is designed first as a transparent scientific portfolio and worked teaching resource. The examples use simulated data so that the code, diagnostics and deliberate data problems can be shared openly.

The workflows can also be used as a **guide for real stocks**, but they should not be treated as a one-click assessment pipeline. A real application requires deliberate mapping of variable definitions, units, sampling design, stock boundaries and biological assumptions.

## General adaptation workflow

For each module:

1. **Read the module data dictionary first.** Identify the variables, units, coding conventions and sampling strata assumed by the example.
2. **Map your fields explicitly.** Do not silently rename variables without documenting what the original field meant.
3. **Preserve raw fields.** Create harmonized/derived variables alongside raw values rather than overwriting source data.
4. **Run validity and coverage checks before excluding records.** A flag should trigger investigation; it is not automatically a deletion rule.
5. **Retain sampling structure.** Year, season/month, area, source, fleet and gear often matter because apparent biological change can be created by changing sample composition.
6. **Document every stock-specific assumption.** This is especially important for CPUE, ALKs, growth, maturity and natural mortality.
7. **Carry unresolved choices forward as sensitivity analyses.** Do not convert uncertainty into a single fixed input simply to allow a model to run.

## Module-by-module input mapping

### 01 — Annual fishery indicators

Typical fields:

- `year`
- catch in a documented unit
- fishing effort in a clearly defined effort unit
- CPUE or the fields required to calculate it

The main task is to determine whether catch, effort and CPUE are comparable through time and whether the effort definition is biologically meaningful.

### 02 — Data quality and consistency

Typical fields:

- `year`
- season/quarter/month
- area
- fleet and/or gear
- catch
- effort
- reported CPUE where available
- sampling/monitoring source

Before adapting the code, define valid codes, expected units, duplicate keys, missing-stratum rules and any known monitoring-protocol changes.

### 03 — Length-frequency distributions

Typical fields:

- fish or observation identifier
- length
- length unit and measurement type
- year
- month/season
- area
- fleet/gear
- commercial/survey source

The workflow should retain binned LFDs as the primary scientific representation while using density, ridgeline and heatmap displays as complementary exploratory tools. Pooling across strata should be justified rather than assumed.

Reusable functions are available in:

`03-length-frequency/lfd_diagnostics.R`

They support record-level length flags, arbitrary sampling-stratum coverage summaries, normalized LFD construction, heaping checks, Jensen–Shannon divergence, two-sample LFD comparison and measurement-scope sensitivity analysis.

### 04 — Spatio-temporal consistency

This module builds on Module 03. The essential requirement is enough persistent area × time × gear/source structure to make like-with-like comparisons.

The key question is whether an apparent temporal change survives within comparable strata or is driven by changing sampling composition.

### 05 — Age–length consistency

Typical fields:

- fish identifier;
- length and documented measurement unit/type;
- observed age;
- year/season/area/source/gear where available;
- reader identifier where available;
- repeat or paired readings where available.

Reusable functions are available in:

`05-age-length-consistency/age_length_diagnostics.R`

The file separates stock-independent calculations from the simulated Module 05 example. It includes record-level age/length flags, ageing-coverage summaries, robust length-at-age screening, reader-agreement diagnostics, ALK construction, ALK application, transferability evaluation and temporal length-at-age stability checks.

A typical sequence is:

```r
source("05-age-length-consistency/age_length_diagnostics.R")

x <- read.csv("my_ageing_data.csv")

x_qc <- flag_age_length_records(
  x,
  length_col = "length_cm",
  age_col = "age",
  id_col = "fish_id",
  min_length = 8,
  max_length = 80,
  min_age = 0,
  max_age = 12
)

coverage <- ageing_coverage(
  x_qc,
  strata = c("year", "area", "season", "source", "gear"),
  id_col = "fish_id",
  min_n = 15
)

plausibility <- age_length_outliers(
  x_qc,
  age_col = "age",
  length_col = "length_cm",
  mad_multiplier = 5,
  min_n = 8
)

alk <- make_alk_generic(
  x_qc,
  length_col = "length_cm",
  age_col = "age",
  strata = c("area", "source"),
  bin_width = 2,
  min_bin_n = 25
)
```

For a historical-ALK transfer test, split the ageing data into a training and independent test period and use `evaluate_alk_transfer()` both globally and under biologically defensible stratification. Compare **coverage, bias, MAE and RMSE**, rather than assuming that an ALK is transferable because its length bins overlap.

Age–length keys should therefore be evaluated for support and transferability before they are applied to periods, areas, fleets or monitoring components outside the data from which they were estimated. Minimum sample sizes, plausible age/length ranges and ALK bin widths are stock- and programme-specific choices, not universal thresholds.

### 06 — Life-history information

Typical fields may include:

- fish identifier
- length and weight
- sex
- age
- maturity stage or mature/immature classification
- gonad weight/GSI where available
- year/month/area/source

The module also separates reusable natural-mortality functions into:

`06-life-history-consistency/natural_mortality_methods.R`

These functions can be sourced directly with reviewed stock-specific inputs:

```r
source("06-life-history-consistency/natural_mortality_methods.R")

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

The current reusable implementation includes Pauly (1980), a cautiously labelled Hoenig (1983) longevity proxy, Then et al. (2015) maximum-age and growth-based estimators, and Gislason et al. (2010) length-dependent M.

PRODBIOM is not approximated with an ad-hoc equation. A future implementation should reproduce and validate the actual mortality-at-age/length methodology rather than only reuse the name.

### 07 — Integrated assessment readiness

The readiness classifications in the worked example are **not universal thresholds**. A real stock should construct its own evidence register from the preceding diagnostics and document why each evidence family is supported, conditional, sensitivity-sensitive or unresolved.

## What should be reusable versus stock-specific?

Reusable code should handle operations such as:

- validity checks;
- coverage summaries;
- LFD construction and comparison;
- persistent-stratum diagnostics;
- age–length support checks;
- paired-reader diagnostics;
- ALK construction and transfer testing;
- biological relationship fitting;
- empirical natural-mortality calculations;
- standardized reporting tables and figures.

Stock-specific judgement is still required for:

- spatial stock definition;
- fleet and métier structure;
- effort definition;
- CPUE standardization;
- appropriate length bins;
- pooling/raising rules;
- ageing interpretation and accepted ageing protocol;
- ALK stratification and transfer periods;
- parameter provenance;
- environmental inputs;
- choice of natural-mortality estimators;
- assessment-model suitability.

## Repository development direction

The current modules were built as complete worked examples first. The next development layer is to extract more of the repeated analysis logic into documented reusable functions and input templates while preserving the scientific explanations in the Quarto pages.

The aim is therefore not to turn the repository into a black-box stock-assessment package. It is to make the analytical steps **easier to reuse without hiding the decisions that require fisheries-science judgement**.