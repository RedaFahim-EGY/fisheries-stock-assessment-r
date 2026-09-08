# Fisheries Stock Assessment in R

Reproducible workflows and worked examples for **quantitative fisheries science and stock assessment in R**.

This repository is being developed as a transparent scientific portfolio. Its current emphasis is deliberately placed on **understanding, auditing and structuring fisheries information before any assessment model is fitted**.

🌐 **Live Quarto website:** https://redafahim-egy.github.io/fisheries-stock-assessment-r/

## Scope

The repository is not tied to one assessment method. Examples are organized around the scientific question, the observation process, data support, diagnostics and transparent interpretation.

Current topics include data exploration and quality control; sampling design and coverage; length-frequency distributions; spatio-temporal consistency; age–length information and ALKs; and life-history data and parameter compatibility. Assessment models, diagnostics, reference points, forecasts and harvest strategies remain deliberately downstream.

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
A simulated biological programme audits weight–length relationships, maturity/L50, sex structure, GSI phenology, growth information, sampling support, parameter provenance, transferability and natural-mortality sensitivity.

- [Live Quarto module](https://redafahim-egy.github.io/fisheries-stock-assessment-r/06-life-history-consistency/)
- [`06-life-history-consistency/index.qmd`](06-life-history-consistency/index.qmd)
- [`06-life-history-consistency/06_life_history_consistency.R`](06-life-history-consistency/06_life_history_consistency.R)
- [`06-life-history-consistency/data-dictionary.md`](06-life-history-consistency/data-dictionary.md)

## Next scientific stage

The next stage should be an **integrated assessment-readiness review**. It should combine the preceding modules into a structured evidence table covering data support, observation-process risks, LFD consistency, spatial/temporal comparability, age information, life-history compatibility and unresolved uncertainty. The output should state what information is defensible for later assessment, what requires sensitivity analysis, and what should not yet be used.

## Reproducibility and data policy

No confidential or restricted institutional data are published here. Public examples use simulated, open, or otherwise shareable datasets and are intended for scientific demonstration and training.

## Author

**Reda M. Fahim**  
Quantitative fisheries science · Stock assessment · Fisheries management

---

🚧 **Repository under active development**
