# 01 — Data exploration

Before fitting any stock-assessment model, the structure, scale, trends, and internal consistency of the available information should be examined.

This first module uses a **simulated exploited stock** to demonstrate a compact exploratory workflow based on annual catch, fishing effort, and a relative abundance index (CPUE).

## Questions addressed

- How have catch and effort changed through time?
- What does CPUE suggest about relative abundance?
- Are the apparent trends internally consistent?
- Which patterns should be investigated before model fitting?
- What information is still missing for a formal assessment?

## Files

- `01_simulated_fishery.R` — generates the simulated fishery, calculates CPUE, summarizes the data, and produces exploratory plots.

## Interpretation

The example is deliberately simple. CPUE is treated as a relative abundance index for illustration, but in real assessments its interpretation requires careful consideration of catchability, changes in fishing efficiency, fleet composition, spatial behaviour, targeting, and other factors.

The objective here is not to estimate stock status. It is to establish the habit of **examining data and assumptions before selecting or fitting an assessment model**.
