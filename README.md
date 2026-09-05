# Fisheries Stock Assessment in R

Reproducible workflows and worked examples for **quantitative fisheries science and stock assessment in R**.

This repository is being developed as a transparent scientific portfolio. Its current emphasis is deliberately placed on **understanding, auditing and structuring fisheries information before any assessment model is fitted**.

🌐 **Live Quarto website:** https://redafahim-egy.github.io/fisheries-stock-assessment-r/

## Scope

The repository is intentionally **not tied to a single assessment method or modelling framework**. Examples are added according to the scientific question, observation process and information available, including fishery-dependent and fishery-independent data.

Topics will progressively include:

- fisheries data exploration and quality control;
- sampling design, coverage and internal consistency;
- length-frequency distributions and spatio-temporal structure;
- age–length information and age composition;
- life-history data and parameter consistency;
- population dynamics and productivity;
- data-limited approaches;
- biomass-dynamic, state-space and age-structured assessment;
- diagnostics, retrospective patterns, sensitivity and uncertainty;
- biological and management reference points;
- short-term forecasting and harvest strategies;
- management strategy evaluation and management-oriented interpretation.

## Scientific approach

The examples are developed around a few principles:

1. **Understand the observation process first** — sampling design, fleet behaviour, spatial coverage and monitoring changes can shape apparent biological patterns.
2. **Reproducibility** — analyses should run from clearly documented inputs and code.
3. **Transparency** — assumptions, data limitations, exclusions and harmonization decisions should be explicit.
4. **Diagnostics before conclusions** — conflicting or unusual observations should be investigated before they are interpreted.
5. **Model fitting comes later** — a model should be selected only after the available information has been explored and its limitations understood.
6. **Management relevance** — quantitative results should ultimately connect to clearly stated fisheries-management questions.
7. **Shareable data** — examples use simulated, open, or otherwise publicly shareable information.

## Current workflow

### 01 — Data exploration

A simulated exploited stock is used to examine annual catch, effort and CPUE and to introduce the idea that these indicators require interpretation before assessment.

- [Live Quarto module](https://redafahim-egy.github.io/fisheries-stock-assessment-r/01-data-exploration/)
- [`01-data-exploration/index.qmd`](01-data-exploration/index.qmd)
- [`01-data-exploration/01_simulated_fishery.R`](01-data-exploration/01_simulated_fishery.R)

### 02 — Data quality and consistency

A richer simulated monitoring dataset is audited across year, quarter, area and fleet. The workflow examines sampling coverage, missing strata, duplicate keys, units and coding, invalid values, reported-versus-recalculated CPUE, robust outlier screening, protocol changes and explicit issue tracking.

- [Live Quarto module](https://redafahim-egy.github.io/fisheries-stock-assessment-r/02-data-quality-consistency/)
- [`02-data-quality-consistency/index.qmd`](02-data-quality-consistency/index.qmd)
- [`02-data-quality-consistency/02_data_quality_checks.R`](02-data-quality-consistency/02_data_quality_checks.R)
- [`02-data-quality-consistency/data-dictionary.md`](02-data-quality-consistency/data-dictionary.md)

### 03 — Length-frequency distributions

A simulated individual-level monitoring programme explores length structure across **year × month × area × fleet × gear × source** before any growth, mortality, recruitment or stock-status inference is attempted.

The workflow includes record-level plausibility checks, duplicate handling, sample-size and coverage diagnostics, 1-cm LFDs, length-heaping detection, density and ridgeline-style displays, area × gear comparisons, temporal quantiles, length × year heatmaps, pooled-versus-standardized LFDs, incomplete-scope sensitivity analysis and Jensen–Shannon distributional change.

- [Live Quarto module](https://redafahim-egy.github.io/fisheries-stock-assessment-r/03-length-frequency/)
- [`03-length-frequency/index.qmd`](03-length-frequency/index.qmd)
- [`03-length-frequency/03_length_frequency_analysis.R`](03-length-frequency/03_length_frequency_analysis.R)
- [`03-length-frequency/data-dictionary.md`](03-length-frequency/data-dictionary.md)

## Next scientific stage

The next stage will focus on **spatio-temporal consistency**: determining whether apparent changes in length structure remain when comparable spatial, seasonal and fleet/gear strata are examined separately, and identifying changes caused primarily by sampling composition or observation design.

Age–length consistency and life-history information will follow as later pre-assessment stages. Model fitting remains deliberately downstream of this evidence-building process.

## Reproducibility and data policy

No confidential or restricted institutional data are published here. Public examples use simulated, open, or otherwise shareable datasets and are intended for scientific demonstration and training.

## Author

**Reda M. Fahim**  
Quantitative fisheries science · Stock assessment · Fisheries management

---

🚧 **Repository under active development**
