# Data dictionary — Module 03

The module generates all observations in `03_length_frequency_analysis.R`. No external or confidential fisheries data are used.

## Event-level fields

| Field | Meaning | Notes |
|---|---|---|
| `event_id` | Unique simulated sampling-event identifier | One event is a year × month × area × fleet/gear combination. |
| `year` | Calendar year | 2016–2025. |
| `month` | Month | 1–12. |
| `quarter` | Calendar quarter | Derived from month. |
| `season` | Broad seasonal group | Winter, Spring, Summer, Autumn. |
| `area` | Simulated spatial stratum | West, Central, East. |
| `fleet` | Fleet/sampling group | `trawler`, `coastal`, or `survey`. |
| `gear` | Gear/sampling method | `bottom_trawl`, `gillnet`, `longline`, `survey_trawl`. |
| `source` | Observation source | Commercial or survey. |
| `n_measured_planned` | Intended number of fish measured in the event | Varies intentionally through space and time. |

## Individual-fish fields

| Field | Meaning | Expected use |
|---|---|---|
| `fish_id` | Simulated individual record identifier | Used for duplicate detection. |
| `length_cm` | Observed total length in centimetres | Primary LFD variable; deliberate entry/heaping problems are embedded. |
| `weight_g` | Simulated observed weight in grams | Used only for basic plausibility support in this module. |
| `measurement_scope` | Whether the event measured the full available length range | `full` or `marketable_only`. |
| `duplicate_fish_id` | Duplicate-ID flag | Created during QC. |
| `length_plausible` | Broad plausibility flag for length | Defined here as 5–80 cm. |
| `weight_plausible` | Basic positive-weight flag | Not a life-history consistency check. |
| `is_5cm_heap` | Whether an observation lies exactly on a 5-cm multiple | Used to diagnose rounding/digit preference. |
| `length_bin_1cm` | Integer 1-cm length class | Used for primary binned LFDs. |
| `stratum` | Area × gear × source combination | Used for composition-standardized LFD sensitivity analysis. |

## Deliberately embedded observation/sampling issues

### Reduced coverage

Commercial samples in the East during 2019 are reduced to roughly one quarter of their otherwise expected sample size. This demonstrates how a pooled LFD can change when spatial coverage changes.

### Missing stratum

East longline observations are absent in April–June 2020. This is missing sampling and must not be encoded or interpreted as zero abundance.

### Length heaping

Thirty-five percent of commercial gillnet observations in 2020–2021 are rounded to the nearest 5 cm. This creates artificial spikes that can resemble biological modes.

### Incomplete measurement scope

West bottom-trawl samples in July–September 2022 retain only fish at least 22 cm. The remaining records are valid measurements but do not represent the full available length range.

### Gear-selectivity change

From 2023 onward, the simulated gillnet stream shifts toward larger fish. This mimics a mesh/selectivity change and demonstrates why temporal shifts within a gear cannot automatically be interpreted as stock-level biological change.

### Unit-entry error

Eight East survey-trawl records in 2024 have their centimetre values multiplied by ten, mimicking millimetre values stored in a centimetre field. These are flagged as implausible and excluded from the analysis version pending correction.

### Duplicate records

Six Central-area fish records from 2018 are duplicated with the same `fish_id`. Duplicate IDs are flagged before frequency calculations.

## Analytical datasets

`fish` preserves the simulated raw observations and all deliberate problems.

`analysis_fish` contains plausible, positive-weight, de-duplicated observations but still retains records from incomplete measurement-scope events so that representativeness can be assessed explicitly.

`full_scope_fish` is a sensitivity dataset excluding `marketable_only` events. It is not treated as universally superior; it answers a different comparability question.

## Weighting note

The equal-stratum standardized annual LFD is a diagnostic sensitivity calculation, not a general prescription. Real fisheries datasets may require survey-design weights, catch/landing raising factors, swept-area weights or other estimand-specific procedures.
