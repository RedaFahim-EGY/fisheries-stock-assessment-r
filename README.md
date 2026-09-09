# Fisheries Stock Assessment in R

Reproducible workflows and worked examples for **quantitative fisheries science and stock assessment in R**.

This repository is being developed as a transparent scientific portfolio. Its current emphasis is deliberately placed on **understanding, auditing and structuring fisheries information before any assessment model is fitted**.

🌐 **Live Quarto website:** https://redafahim-egy.github.io/fisheries-stock-assessment-r/

📘 **Use with your own stock:** [`USING-YOUR-OWN-DATA.md`](USING-YOUR-OWN-DATA.md)

## Scope

The repository is not tied to one assessment method. Examples are organized around the scientific question, the observation process, data support, diagnostics and transparent interpretation.

Current topics include data exploration and quality control; sampling design and coverage; length-frequency distributions; spatio-temporal consistency; age–length information and ALKs; life-history data and parameter compatibility; and an integrated assessment-readiness review. Assessment models, diagnostics, reference points, forecasts and harvest strategies remain deliberately downstream.

## Scientific approach

1. **Understand the observation process first** — sampling design, fleet behaviour, spatial coverage and monitoring changes can shape apparent biological patterns.
2. **Reproducibility** — analyses should run from clearly documented inputs and code.
3. **Transparency** — assumptions, limitations, exclusions and harmonization decisions should be explicit.
4. **Diagnostics before conclusions** — conflicting or unusual observations should be investigated before interpretation.
5. **Model fitting comes later** — model choice follows evidence-building, not the other way around.
6. **Shareable data** — examples use simulated, open or otherwise publicly shareable information.

## Current workflow

### 01 — Data exploration
Catch, effort and CPUE are explored before assessment.

### 02 — Data quality and consistency
A structured monitoring dataset is audited for coverage, duplicates, units/codes, invalid values, CPUE consistency, outliers and protocol changes.

### 03 — Length-frequency distributions
Individual-level data are explored across year × month × area × fleet × gear × source using binned LFDs, densities, ridgelines, heatmaps, heaping checks and pooling-versus-standardization diagnostics.

### 04 — Spatio-temporal consistency
Persistent area × season × gear × source strata are used to separate apparent biological change from sampling-design drift.

### 05 — Age–length consistency
A simulated ageing programme audits age-support, length-at-age plausibility, reader agreement, temporal reader drift, ALK support and transferability of historical ALKs to later years.

### 06 — Life-history data quality and parameter consistency
A simulated biological programme audits weight–length relationships, maturity/L50, sex structure, GSI phenology, growth information, sampling support and parameter provenance. Natural mortality is now compared explicitly across Pauly, Hoenig/Then longevity-based, Then growth-based and Gislason length-dependent empirical approaches rather than represented by an unexplained fixed value.

Reusable mortality functions are provided in [`06-life-history-consistency/natural_mortality_methods.R`](06-life-history-consistency/natural_mortality_methods.R).

### 07 — Integrated assessment-readiness review
Diagnostics from Modules 02–06 are converted into an explicit evidence register with readiness categories, input gates, follow-up priorities, sensitivity treatments and a stop/go statement before model fitting.

- [Live Quarto module](https://redafahim-egy.github.io/fisheries-stock-assessment-r/07-assessment-readiness/)
- [`07-assessment-readiness/index.qmd`](07-assessment-readiness/index.qmd)
- [`07-assessment-readiness/07_assessment_readiness.R`](07-assessment-readiness/07_assessment_readiness.R)

## Reusing the workflows

The modules are worked examples, not a black-box assessment pipeline. Analysts adapting them to real stocks should map variable definitions and units explicitly, retain the original sampling structure, document stock-specific assumptions and propagate unresolved choices as sensitivity analyses.

See [`USING-YOUR-OWN-DATA.md`](USING-YOUR-OWN-DATA.md) for the current module-by-module input mapping and reuse strategy.

## Next scientific stage

Before moving into model fitting, the next development layer is to make more of Modules 02–07 reusable through documented helper functions and input templates, while preserving the scientific judgement and diagnostics shown in the Quarto pages. Model-requirement mapping and candidate-framework screening should follow that refactoring rather than precede it.

## Reproducibility and data policy

No confidential or restricted institutional data are published here. Public examples use simulated, open, or otherwise shareable datasets and are intended for scientific demonstration and training.

## Author

**Reda M. Fahim**  
Quantitative fisheries science · Stock assessment · Fisheries management

---

🚧 **Repository under active development**
