# Data dictionary — Module 02

The dataset in this module is entirely simulated. Variable names and quality-control examples are chosen to resemble common structures in fisheries-monitoring programmes without representing any real institution, stock or fishery.

## Variables

| Variable | Meaning | Expected unit / coding |
|---|---|---|
| `record_id` | Unique row identifier | Character |
| `year` | Calendar year | 2012–2025 |
| `quarter` | Sampling quarter | 1–4 |
| `area` | Raw spatial code | West, Central, East; one deliberate non-standard code `E` |
| `fleet` | Fleet / fishing component | `bottom_trawl`, `gillnet`, `longline` |
| `monitoring_protocol` | Simulated observation protocol | `legacy` through 2019; `revised` from 2020 |
| `trips_sampled` | Number of sampled fishing trips represented by the stratum | Count |
| `effort_days` | Simulated fishing effort | Fishing days |
| `catch_kg` | Raw catch field | Usually kg; two deliberate records in tonnes |
| `catch_unit` | Unit attached to the raw catch field | `kg` or `t` |
| `reported_cpue` | CPUE as reported in the monitoring table | Catch per effort day |
| `mean_length_cm` | Mean length of sampled fish in the stratum | cm |
| `area_standardized` | Harmonized spatial code | West, Central, East |
| `catch_kg_standardized` | Catch converted to kilograms using the recorded unit | kg |
| `cpue_recalculated` | Standardized catch divided by valid effort | kg per effort day |
| `cpue_difference_pct` | Relative disagreement between reported and recalculated CPUE | % |
| `quality_issue_count` | Number of row-level QC flags | Count |
| `quality_status` | Compact row-level screening status | `no_flag` or `review` |

## Deliberately introduced quality problems

The simulation contains a known set of problems so that the QC workflow can demonstrate detection and treatment transparently.

| Problem | Simulated example | Why it matters |
|---|---|---|
| Missing sampling stratum | East × gillnet × 2017 Q2 is absent | Aggregated indicators may become spatially or fleet unbalanced |
| Duplicate key | Central × bottom trawl × 2019 Q3 appears twice | Catch, effort or sample sizes may be double-counted |
| Unit inconsistency | Two 2021 catches are stored in tonnes | Unchecked aggregation across units can create orders-of-magnitude errors |
| Coding inconsistency | Several 2022 records use `E` instead of `East` | The same area can be split into artificial categories |
| Invalid effort | One effort observation is negative | Physically impossible; derived CPUE is not interpretable |
| Gross catch outlier | One catch is multiplied by 10 | Could represent transcription, aggregation, targeting or a genuine extreme event |
| CPUE conflict | One reported CPUE is multiplied independently of catch and effort | Related fields should be reconciled rather than accepted independently |
| Uneven sampling coverage | East-area trip coverage is strongly reduced in 2016 | Changes in observation intensity can masquerade as biological change |
| Protocol change | Monitoring switches from `legacy` to `revised` in 2020 | Observation-system changes may create discontinuities or altered precision |

## QC philosophy

The workflow preserves raw values and creates standardized or diagnostic fields alongside them. This is deliberate: a scientifically transparent audit should make it possible to reconstruct what changed, why it changed, and which uncertainties remain unresolved.

A flag does not automatically mean that a record should be deleted. Some problems can be harmonized reversibly, some require source-level verification, and some should remain visible for sensitivity analysis or later interpretation.
