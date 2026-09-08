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
- natural-mortality sensitivity rather than false precision;
- coherence among growth, maturity, allometry and other life-history inputs.

The central scientific question is:

> **Are the biological parameters internally coherent, adequately supported and transferable to the stock, sex, period and observation process relevant to the assessment?**

The dataset is entirely simulated and includes deliberate problems so the workflow demonstrates diagnosis, documentation and sensitivity analysis rather than simply fitting curves.

## Files

- `06_life_history_consistency.R` — reproducible simulation, QC and diagnostics.
- `index.qmd` — Quarto scientific narrative and figures.
- `data-dictionary.md` — variables, simulated structure and deliberate inconsistencies.

No confidential or institutional data are used.
