# Fisheries Stock Assessment in R

Reproducible workflows and worked examples for **quantitative fisheries science and stock assessment in R**.

This repository is being developed as a transparent scientific portfolio. Its current emphasis is deliberately placed on **understanding, auditing and structuring fisheries information before any assessment model is fitted**.

🌐 **Live Quarto website:** https://redafahim-egy.github.io/fisheries-stock-assessment-r/

## Scope

The repository is not tied to one assessment method. Examples are organized around the scientific question, the observation process, data support, diagnostics and transparent interpretation.

Current and planned topics include data exploration and quality control; sampling design and coverage; length-frequency distributions; spatio-temporal consistency; age–length information and ALKs; life-history data and parameter consistency; and, only later, assessment models, diagnostics, reference points, forecasts and harvest strategies.

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

- [Live Quarto module](https://redafahim-egy.github.io/fisheries-stock-assessment-r/05-age-length-consistency/)
- [`05-age-length-consistency/index.qmd`](05-age-length-consistency/index.qmd)
- [`05-age-length-consistency/05_age_length_consistency.R`](05-age-length-consistency/05_age_length_consistency.R)
- [`05-age-length-consistency/data-dictionary.md`](05-age-length-consistency/data-dictionary.md)

## Next scientific stage

The next stage will focus on **life-history data quality and parameter consistency**: weight–length relationships, maturity, sex structure, growth parameter provenance and compatibility, mortality inputs, spatial/temporal coherence and uncertainty. Model fitting remains deliberately downstream.

## Reproducibility and data policy

No confidential or restricted institutional data are published here. Public examples use simulated, open, or otherwise shareable datasets and are intended for scientific demonstration and training.

## Author

**Reda M. Fahim**  
Quantitative fisheries science · Stock assessment · Fisheries management

---

🚧 **Repository under active development**
