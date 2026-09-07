# Data dictionary — Module 05

All observations in this module are simulated.

| Field | Meaning |
|---|---|
| `fish_id` | Unique simulated fish identifier |
| `year` | Sampling year, 2016–2025 |
| `area` | Monitoring area: West, Central, East |
| `season` | Winter, Spring, Summer, Autumn |
| `source` | Commercial or survey sample source |
| `gear` | Trawl or gillnet |
| `true_age` | Latent simulated age used only to generate the demonstration dataset |
| `length_cm` | Observed total length in centimetres |
| `age_reader1` | Primary age assignment used in the QC workflow |
| `age_reader2` | Independent second-reader age for a subsample |
| `duplicate_id` | Duplicate fish-ID flag |
| `invalid_length` | Length outside the accepted demonstration range |
| `invalid_age` | Primary reader age outside 0–9 |
| `age_length_outlier` | Robust within-age length anomaly flag |
| `length_bin` | Two-centimetre length class used for ALKs |

## Deliberately introduced problems

The simulation contains the following known issues so that the workflow has meaningful diagnostics to detect:

1. one duplicated fish record/identifier;
2. one length entered in millimetres but stored in the centimetre field;
3. one impossible age code (`19`);
4. a very small fish assigned an old age and a very large fish assigned age 0;
5. deliberately weak ageing coverage in selected year × area/source and year × season/gear combinations;
6. reader error that increases with age;
7. paired second readings for only part of the sample;
8. a simulated 2024–2025 primary-reader drift that tends to over-age some older fish.

## Interpretation rule

Flags are review triggers, not automatic deletion rules. The workflow distinguishes transcription/unit problems from observations that are merely biologically unusual, and evaluates sampling support before an ALK is interpreted or transferred.
