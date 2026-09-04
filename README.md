# Fisheries Stock Assessment in R

Reproducible workflows and worked examples for **quantitative fisheries science and stock assessment in R**.

This repository is being developed as a transparent scientific portfolio: from the structure and exploration of fisheries data through model formulation, diagnostics, uncertainty, reference points, forecasting, and interpretation for management advice.

## Scope

The repository is intentionally **not tied to a single assessment method or modelling framework**. Examples will be added according to the scientific question and information available, including fishery-dependent and fishery-independent data.

Topics will progressively include:

- fisheries data exploration and quality control;
- population dynamics and productivity;
- length- and age-structured information;
- data-limited approaches;
- biomass-dynamic and state-space models;
- age-structured assessment;
- diagnostics, retrospective patterns, sensitivity and uncertainty;
- biological and management reference points;
- short-term forecasting and harvest strategies;
- management strategy evaluation and management-oriented interpretation.

## Scientific approach

The examples are developed around a few principles:

1. **Reproducibility** — analyses should run from clearly documented inputs and code.
2. **Transparency** — assumptions, data limitations and modelling choices should be explicit.
3. **Diagnostics before conclusions** — model output is interpreted together with fit, uncertainty and sensitivity.
4. **Management relevance** — quantitative results are connected to the questions faced in fisheries management.
5. **Shareable data** — examples use simulated, open, or otherwise publicly shareable information.

## Current workflow

### 01 — Data exploration

The first worked example uses a **simulated exploited stock** to illustrate how catch, effort and a relative abundance index can be generated, visualized and interpreted before fitting an assessment model.

- [`01-data-exploration/01_simulated_fishery.R`](01-data-exploration/01_simulated_fishery.R)
- [`01-data-exploration/README.md`](01-data-exploration/README.md)

Further workflows will be added incrementally as complete, documented examples rather than as empty placeholders.

## Reproducibility and data policy

No confidential or restricted institutional data are published here. Public examples use simulated, open, or otherwise shareable datasets and are intended for scientific demonstration and training.

## Author

**Reda M. Fahim**  
Quantitative fisheries science · Stock assessment · Fisheries management

---

🚧 **Repository under active development**
