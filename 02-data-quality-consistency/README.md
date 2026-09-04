# 02 — Data quality and consistency

This module develops a reproducible workflow for auditing fisheries-monitoring data **before any stock-assessment model is fitted**.

The simulated dataset is intentionally richer and messier than the introductory example. It spans multiple years, quarters, areas and fleets and includes sampling intensity, effort, catch, reported CPUE and mean sampled length. Several realistic problems are introduced deliberately so that the workflow demonstrates detection, documentation and scientifically defensible treatment rather than simple data cleaning.

## Questions addressed

- Is the expected sampling frame complete across year, season, area and fleet?
- Are sampling intensity and spatial/fleet coverage stable through time?
- Are observation keys unique, or are some strata duplicated?
- Are units and categorical codes internally consistent?
- Do catch, effort and reported CPUE agree mechanically?
- Which observations are impossible, which are merely unusual, and which require source-level verification?
- Did the monitoring protocol or observation process change through time?
- Which problems can be harmonized reproducibly, and which remain unresolved scientific uncertainties?
- What information is sufficiently understood to carry forward to the next exploratory stage?

## Files

- `index.qmd` — portfolio-quality Quarto analysis with tables, diagnostics and interpretation.
- `02_data_quality_checks.R` — complete simulation, QC checks, harmonization logic and validation assertions.
- `data-dictionary.md` — variable definitions, expected units and a transparent register of deliberately introduced quality problems.

## Scientific position

This module does **not** treat quality control as a preprocessing chore. Sampling design, units, definitions, protocol changes, fleet composition, spatial coverage and internal consistency are part of the observation model and can affect later inference.

Records are therefore not silently removed because they look inconvenient. The workflow separates:

- reversible harmonization, such as explicit unit conversion;
- structural problems, such as duplicated or missing sampling strata;
- physically invalid observations;
- statistical outliers that may still be biologically genuine; and
- discrepancies that require verification against source information.

## Next stage

The next major module will examine **length-frequency distributions (LFDs)** in depth, including sample size, binning, seasonality, spatial structure, fleet/gear effects, spatio-temporal combinations, pooling versus stratification and the distinction between biological patterns and sampling artefacts.
