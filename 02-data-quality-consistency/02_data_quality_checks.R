# Module 02: Data quality and consistency before assessment
#
# Purpose
# -------
# Build a realistic, reproducible simulated fishery-monitoring dataset containing
# several common data-quality problems, then diagnose and harmonize them before
# any stock-assessment analysis is attempted.
#
# The data are entirely simulated and contain no confidential or institutional
# information.

set.seed(20260905)

# -----------------------------------------------------------------------------
# 1. Simulate a structured fishery-monitoring dataset
# -----------------------------------------------------------------------------

years <- 2012:2025
quarters <- 1:4
areas <- c("West", "Central", "East")
fleets <- c("bottom_trawl", "gillnet", "longline")

sampling_frame <- expand.grid(
  year = years,
  quarter = quarters,
  area = areas,
  fleet = fleets,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

n <- nrow(sampling_frame)

area_effect <- c(West = 1.00, Central = 0.88, East = 0.78)
fleet_q <- c(bottom_trawl = 1.00, gillnet = 0.72, longline = 0.55)
quarter_effect <- c(`1` = 0.92, `2` = 1.05, `3` = 1.10, `4` = 0.95)

# A smooth abundance signal with decline and partial recovery.
stock_signal <- approx(
  x = c(2012, 2018, 2021, 2025),
  y = c(1.00, 0.66, 0.58, 0.76),
  xout = sampling_frame$year
)$y

sampling_frame$trips_sampled <- pmax(
  2,
  round(
    18 +
      4 * (sampling_frame$fleet == "bottom_trawl") +
      2 * (sampling_frame$area == "West") +
      rnorm(n, 0, 3)
  )
)

sampling_frame$effort_days <- round(
  sampling_frame$trips_sampled *
    runif(n, 0.8, 1.5) *
    c(bottom_trawl = 1.25, gillnet = 0.95, longline = 0.80)[sampling_frame$fleet],
  1
)

true_cpue <- 42 *
  stock_signal *
  area_effect[sampling_frame$area] *
  fleet_q[sampling_frame$fleet] *
  quarter_effect[as.character(sampling_frame$quarter)]

sampling_frame$catch_kg <- round(
  sampling_frame$effort_days * true_cpue * exp(rnorm(n, 0, 0.13)),
  1
)

sampling_frame$reported_cpue <- round(
  sampling_frame$catch_kg / sampling_frame$effort_days * exp(rnorm(n, 0, 0.025)),
  2
)

sampling_frame$mean_length_cm <- round(
  31.5 +
    1.4 * (sampling_frame$fleet == "longline") -
    1.1 * (sampling_frame$fleet == "bottom_trawl") +
    0.8 * (sampling_frame$area == "West") -
    0.9 * (sampling_frame$area == "East") +
    0.25 * (sampling_frame$quarter - 2.5) +
    rnorm(n, 0, 0.8),
  1
)

sampling_frame$catch_unit <- "kg"
sampling_frame$monitoring_protocol <- ifelse(
  sampling_frame$year <= 2019,
  "legacy",
  "revised"
)

raw_fishery <- sampling_frame
raw_fishery$record_id <- sprintf("SIM-%04d", seq_len(nrow(raw_fishery)))
raw_fishery <- raw_fishery[, c(
  "record_id", "year", "quarter", "area", "fleet", "monitoring_protocol",
  "trips_sampled", "effort_days", "catch_kg", "catch_unit",
  "reported_cpue", "mean_length_cm"
)]

# -----------------------------------------------------------------------------
# 2. Introduce realistic, deliberate data-quality problems
# -----------------------------------------------------------------------------

# Missing sampling stratum: East gillnet, 2017 Q2.
raw_fishery <- raw_fishery[!(
  raw_fishery$year == 2017 &
    raw_fishery$quarter == 2 &
    raw_fishery$area == "East" &
    raw_fishery$fleet == "gillnet"
), ]

# Duplicate record with a different record_id.
dup_idx <- which(
  raw_fishery$year == 2019 &
    raw_fishery$quarter == 3 &
    raw_fishery$area == "Central" &
    raw_fishery$fleet == "bottom_trawl"
)[1]
duplicate_row <- raw_fishery[dup_idx, ]
duplicate_row$record_id <- "SIM-DUP-001"
raw_fishery <- rbind(raw_fishery, duplicate_row)

# Unit inconsistency: two catches entered in tonnes rather than kilograms.
unit_idx <- which(
  raw_fishery$year == 2021 &
    raw_fishery$quarter == 1 &
    raw_fishery$area == "West"
)[1:2]
raw_fishery$catch_kg[unit_idx] <- round(raw_fishery$catch_kg[unit_idx] / 1000, 3)
raw_fishery$catch_unit[unit_idx] <- "t"

# Coding inconsistency for area.
area_idx <- which(raw_fishery$year == 2022 & raw_fishery$quarter == 4)[1:3]
raw_fishery$area[area_idx] <- "E"

# Implausible effort value.
effort_idx <- which(
  raw_fishery$year == 2018 &
    raw_fishery$quarter == 2 &
    raw_fishery$area == "West" &
    raw_fishery$fleet == "gillnet"
)[1]
raw_fishery$effort_days[effort_idx] <- -3

# Gross catch transcription error.
outlier_idx <- which(
  raw_fishery$year == 2016 &
    raw_fishery$quarter == 3 &
    raw_fishery$area == "Central" &
    raw_fishery$fleet == "longline"
)[1]
raw_fishery$catch_kg[outlier_idx] <- raw_fishery$catch_kg[outlier_idx] * 10

# CPUE inconsistency independent of catch/effort fields.
cpue_idx <- which(
  raw_fishery$year == 2023 &
    raw_fishery$quarter == 1 &
    raw_fishery$area == "East" &
    raw_fishery$fleet == "bottom_trawl"
)[1]
raw_fishery$reported_cpue[cpue_idx] <- raw_fishery$reported_cpue[cpue_idx] * 2.4

# Reduced sampling coverage for one area-year to demonstrate uneven intensity.
coverage_idx <- which(raw_fishery$year == 2016 & raw_fishery$area == "East")
raw_fishery$trips_sampled[coverage_idx] <- pmax(
  1,
  round(raw_fishery$trips_sampled[coverage_idx] * 0.25)
)

rownames(raw_fishery) <- NULL

# -----------------------------------------------------------------------------
# 3. Structural checks
# -----------------------------------------------------------------------------

raw_fishery$key <- with(
  raw_fishery,
  paste(year, quarter, area, fleet, sep = "|")
)

duplicate_keys <- raw_fishery[duplicated(raw_fishery$key) |
                                duplicated(raw_fishery$key, fromLast = TRUE), ]

expected_frame <- expand.grid(
  year = years,
  quarter = quarters,
  area = areas,
  fleet = fleets,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
expected_frame$key <- with(
  expected_frame,
  paste(year, quarter, area, fleet, sep = "|")
)

observed_keys_standardized <- with(
  transform(raw_fishery, area = ifelse(area == "E", "East", area)),
  paste(year, quarter, area, fleet, sep = "|")
)

missing_strata <- expected_frame[!(expected_frame$key %in% observed_keys_standardized), ]

unit_summary <- as.data.frame(table(raw_fishery$catch_unit), stringsAsFactors = FALSE)
names(unit_summary) <- c("catch_unit", "records")

coding_summary <- as.data.frame(table(raw_fishery$area), stringsAsFactors = FALSE)
names(coding_summary) <- c("area_code", "records")

# -----------------------------------------------------------------------------
# 4. Harmonize fields while preserving the raw data
# -----------------------------------------------------------------------------

clean_fishery <- raw_fishery
clean_fishery$area_standardized <- ifelse(clean_fishery$area == "E", "East", clean_fishery$area)
clean_fishery$catch_kg_standardized <- ifelse(
  clean_fishery$catch_unit == "t",
  clean_fishery$catch_kg * 1000,
  clean_fishery$catch_kg
)

clean_fishery$duplicate_key <- duplicated(clean_fishery$key) |
  duplicated(clean_fishery$key, fromLast = TRUE)
clean_fishery$invalid_effort <- !is.finite(clean_fishery$effort_days) |
  clean_fishery$effort_days <= 0
clean_fishery$invalid_catch <- !is.finite(clean_fishery$catch_kg_standardized) |
  clean_fishery$catch_kg_standardized <= 0

clean_fishery$cpue_recalculated <- ifelse(
  clean_fishery$invalid_effort,
  NA_real_,
  clean_fishery$catch_kg_standardized / clean_fishery$effort_days
)

clean_fishery$cpue_difference_pct <- 100 * (
  clean_fishery$reported_cpue / clean_fishery$cpue_recalculated - 1
)
clean_fishery$cpue_inconsistent <- !is.na(clean_fishery$cpue_difference_pct) &
  abs(clean_fishery$cpue_difference_pct) > 15

# Robust within-fleet/area outlier flag on recalculated CPUE.
clean_fishery$cpue_outlier <- FALSE
strata <- unique(clean_fishery[, c("fleet", "area_standardized")])

for (i in seq_len(nrow(strata))) {
  idx <- clean_fishery$fleet == strata$fleet[i] &
    clean_fishery$area_standardized == strata$area_standardized[i] &
    is.finite(clean_fishery$cpue_recalculated) &
    clean_fishery$cpue_recalculated > 0

  x <- log(clean_fishery$cpue_recalculated[idx])
  med <- median(x)
  mad_x <- mad(x, constant = 1)

  if (is.finite(mad_x) && mad_x > 0) {
    clean_fishery$cpue_outlier[idx] <- abs(x - med) > 4 * mad_x
  }
}

clean_fishery$quality_issue_count <- rowSums(cbind(
  clean_fishery$duplicate_key,
  clean_fishery$invalid_effort,
  clean_fishery$invalid_catch,
  clean_fishery$cpue_inconsistent,
  clean_fishery$cpue_outlier,
  clean_fishery$area != clean_fishery$area_standardized,
  clean_fishery$catch_unit != "kg"
), na.rm = TRUE)

clean_fishery$quality_status <- ifelse(
  clean_fishery$quality_issue_count == 0,
  "no_flag",
  "review"
)

# -----------------------------------------------------------------------------
# 5. Coverage and consistency summaries
# -----------------------------------------------------------------------------

coverage_year_area <- aggregate(
  trips_sampled ~ year + area_standardized,
  data = clean_fishery,
  FUN = sum
)

coverage_year_fleet <- aggregate(
  trips_sampled ~ year + fleet,
  data = clean_fishery,
  FUN = sum
)

valid_cpue <- clean_fishery[!clean_fishery$invalid_effort &
                              !clean_fishery$duplicate_key &
                              !clean_fishery$cpue_inconsistent &
                              !clean_fishery$cpue_outlier, ]

annual_indicators <- aggregate(
  cbind(catch_kg_standardized, effort_days, trips_sampled) ~ year,
  data = valid_cpue,
  FUN = sum
)
annual_cpue <- aggregate(
  cpue_recalculated ~ year,
  data = valid_cpue,
  FUN = mean
)
annual_indicators <- merge(annual_indicators, annual_cpue, by = "year")

protocol_summary <- aggregate(
  cpue_recalculated ~ monitoring_protocol + fleet,
  data = valid_cpue,
  FUN = mean
)

# Issue register for transparent review rather than silent deletion.
issue_register <- data.frame(
  issue = c(
    "duplicate sampling key",
    "non-standard catch unit",
    "non-standard area code",
    "invalid effort",
    "reported/recalculated CPUE mismatch",
    "robust CPUE outlier",
    "missing expected sampling stratum"
  ),
  records_or_strata = c(
    sum(clean_fishery$duplicate_key),
    sum(clean_fishery$catch_unit != "kg"),
    sum(clean_fishery$area != clean_fishery$area_standardized),
    sum(clean_fishery$invalid_effort),
    sum(clean_fishery$cpue_inconsistent),
    sum(clean_fishery$cpue_outlier),
    nrow(missing_strata)
  ),
  action = c(
    "review and resolve duplicate before aggregation",
    "convert using recorded unit; retain provenance",
    "recode to controlled vocabulary",
    "exclude from effort-derived indicators pending verification",
    "verify source fields before using CPUE",
    "investigate transcription, targeting or genuine extreme event",
    "document sampling gap; do not impute automatically"
  ),
  stringsAsFactors = FALSE
)

# Compact validation assertions for the simulated workflow.
stopifnot(
  nrow(raw_fishery) > 400,
  nrow(missing_strata) >= 1,
  nrow(duplicate_keys) >= 2,
  any(clean_fishery$catch_unit != "kg"),
  any(clean_fishery$invalid_effort),
  any(clean_fishery$cpue_inconsistent),
  any(clean_fishery$quality_status == "review")
)
