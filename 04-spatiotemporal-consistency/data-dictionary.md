# Module 04 data dictionary

Module 04 derives its analysis objects from the fully simulated fish-level monitoring data generated in Module 03. No external or confidential data are used.

| Variable | Level | Meaning |
|---|---|---|
| `year` | fish / stratum-year | Calendar year, 2016–2025 |
| `area` | fish / stratum-year | Simulated spatial area: West, Central or East |
| `season` | fish / stratum-year | Quarter-based season: Winter, Spring, Summer or Autumn |
| `gear` | fish / stratum-year | Bottom trawl, gillnet, longline or survey trawl |
| `source` | fish / stratum-year | Commercial or survey monitoring source |
| `stratum` | stratum-year | Area × season × gear × source comparison cell |
| `n_fish` | stratum-year | Number of plausible, de-duplicated, full-scope fish observations |
| `mean_length_cm` | stratum-year | Mean fish length in centimetres within a matched stratum-year |
| `median_length_cm` | stratum-year | Median fish length in centimetres within a matched stratum-year |
| `reference_weight` | stratum | Fixed long-term sampling weight used for the design-standardized annual mean |
| `within_stratum_anomaly` | stratum-year | Annual stratum mean minus that stratum's long-term mean |
| `annual_delta_cm` | stratum-year | Year-to-year change in mean length within the same persistent stratum |
| `js_divergence` | year | Jensen–Shannon divergence between that year's design-cell sampling composition and the long-term reference composition |
| `pooled_mean_cm` | year | Fish-weighted annual mean length using all baseline observations |
| `standardized_mean_cm` | year | Annual mean based on persistent strata and fixed reference weights |
| `composition_bias_cm` | year | Pooled mean minus fixed-design standardized mean |
| `share_positive` | year | Proportion of persistent strata with positive year-to-year mean-length change |
| `share_negative` | year | Proportion of persistent strata with negative year-to-year mean-length change |
| `mean_anomaly_cm` | year × leave-one-area scenario | Mean within-stratum anomaly after omitting no area or one specified area |

## Baseline exclusions

The consistency baseline uses Module 03 observations that are:

- within the plausible length and weight ranges;
- de-duplicated;
- from `measurement_scope == "full"`.

Known `marketable_only` observations are excluded because their truncated length range is an observation-process change that would contaminate a like-for-like comparison.

## Persistent-stratum definition

A stratum is retained for the core temporal comparisons only when it contains at least **35 fish in every year**. This threshold is a transparent simulation-specific rule for the worked example, not a universal fisheries standard.

## Interpretation notes

- `js_divergence` measures **sampling-design drift**, not ecological or stock distance.
- `standardized_mean_cm` is a sensitivity summary, not a uniquely correct estimate.
- `within_stratum_anomaly` removes stable stratum differences to highlight temporal coherence; it should not be interpreted as abundance or stock status.
- gear-specific changes can reflect selectivity, fleet behaviour or sampling protocols as well as biology.
