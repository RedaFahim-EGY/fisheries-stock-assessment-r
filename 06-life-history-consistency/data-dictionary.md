# Data dictionary — Module 06

All data are simulated.

## Individual biological observations

| Variable | Meaning | Expected values / units |
|---|---|---|
| `fish_id` | Unique biological-sample identifier | Character |
| `year` | Sampling year | 2016–2025 |
| `month` | Sampling month | 1–12 |
| `area` | Spatial stratum | West, Central, East |
| `source` | Observation source | commercial, survey |
| `sex` | Sex code | F, M |
| `true_age` | Latent simulated age used to generate coherent biology | 0–9 |
| `length_cm` | Total length | cm |
| `weight_g` | Whole-body weight | g |
| `mature` | Binary maturity indicator | 0 immature, 1 mature |
| `gsi` | Simulated gonadosomatic index | positive ratio-scale value |

## Derived QC fields

| Variable | Meaning |
|---|---|
| `duplicate_id` | Fish identifier appears more than once |
| `invalid_length` | Length outside the plausible simulation domain |
| `invalid_weight` | Weight outside the plausible simulation domain |
| `invalid_sex` | Sex code outside controlled vocabulary |
| `invalid_maturity` | Maturity code outside 0/1 |
| `invalid_gsi` | GSI outside the plausible simulation domain |
| `condition_residual` | Residual from sex-specific log(weight)–log(length) fit |
| `condition_outlier` | Robust extreme condition/allometry residual |

## Parameter catalogue

`parameter_catalogue` mimics a literature/assessment parameter compilation. It records parameter type, stock unit, sex, period, estimation method, numerical values and units, plus transparent compatibility indicators.

The compatibility score is an educational audit device. It should not be interpreted as a universal parameter-selection rule.

## Deliberately introduced problems

The workflow intentionally contains:

1. a duplicated biological record;
2. a length measurement entered in millimetres but labelled centimetres;
3. a weight entered in kilograms but labelled grams;
4. an invalid maturity code;
5. an unresolved/invalid sex code;
6. an implausibly high GSI value;
7. weak sampling support in selected spatial/temporal strata;
8. recent commercial under-representation of small immature fish, creating an observation-protocol effect in maturity;
9. candidate life-history parameters from historical periods, adjacent stocks, combined sexes and default assumptions.

These features are deliberate and reproducible. They allow the module to distinguish **measurement error, sampling-design effects, parameter incompatibility and genuine biological variation**.
