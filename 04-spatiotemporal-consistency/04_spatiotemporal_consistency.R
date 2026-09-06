# Module 04: Spatio-temporal consistency before assessment
#
# Purpose
# -------
# Extend the individual-level length-frequency simulation from Module 03 and ask
# whether apparent temporal changes persist within comparable spatial, seasonal,
# fleet/gear and source strata. The emphasis is design-aware consistency, not
# stock-status inference.
#
# The underlying data are entirely simulated and shareable.

module3_path <- if (file.exists("../03-length-frequency/03_length_frequency_analysis.R")) {
  "../03-length-frequency/03_length_frequency_analysis.R"
} else {
  "03-length-frequency/03_length_frequency_analysis.R"
}
source(module3_path)

# -----------------------------------------------------------------------------
# 1. Define the comparison dataset
# -----------------------------------------------------------------------------

# Start from plausible, de-duplicated, full-measurement-scope observations. Known
# marketable-only samples are excluded here because their truncated length range
# would confound the consistency exercise by design.
consistency_fish <- full_scope_fish
consistency_fish$stratum <- with(
  consistency_fish,
  paste(area, season, gear, source, sep = "|")
)
consistency_fish$design_cell <- consistency_fish$stratum

# Keep the original fish-level information, but conduct most consistency checks
# on stratum-year summaries so that very large samples do not dominate simply
# because more fish happened to be measured.
stratum_year_n <- aggregate(
  fish_id ~ year + stratum + area + season + gear + source,
  data = consistency_fish,
  FUN = length
)
names(stratum_year_n)[7] <- "n_fish"

stratum_year_mean <- aggregate(
  length_cm ~ year + stratum + area + season + gear + source,
  data = consistency_fish,
  FUN = mean
)
names(stratum_year_mean)[7] <- "mean_length_cm"

stratum_year_median <- aggregate(
  length_cm ~ year + stratum + area + season + gear + source,
  data = consistency_fish,
  FUN = median
)
names(stratum_year_median)[7] <- "median_length_cm"

stratum_year <- merge(
  stratum_year_mean,
  stratum_year_median,
  by = c("year", "stratum", "area", "season", "gear", "source")
)
stratum_year <- merge(
  stratum_year,
  stratum_year_n,
  by = c("year", "stratum", "area", "season", "gear", "source")
)

# -----------------------------------------------------------------------------
# 2. Identify comparable, persistent strata
# -----------------------------------------------------------------------------

# Requiring a minimum fish count in every year is deliberately conservative. It
# prevents a nominally present but extremely sparse stratum from being treated as
# equivalent to a well-sampled one.
min_n_per_year <- 35
coverage_matrix <- xtabs(n_fish ~ year + stratum, data = stratum_year)
persistent_strata <- colnames(coverage_matrix)[
  apply(coverage_matrix >= min_n_per_year, 2, all)
]

persistent <- stratum_year[stratum_year$stratum %in% persistent_strata, ]
persistent <- persistent[order(persistent$stratum, persistent$year), ]

stopifnot(
  length(persistent_strata) >= 20,
  all(table(persistent$stratum) == length(unique(persistent$year)))
)

# -----------------------------------------------------------------------------
# 3. Sampling-composition diagnostics
# -----------------------------------------------------------------------------

area_year_n <- aggregate(
  fish_id ~ year + area,
  data = consistency_fish,
  FUN = length
)
names(area_year_n)[3] <- "n_fish"
area_year_total <- aggregate(n_fish ~ year, data = area_year_n, FUN = sum)
area_year_n <- merge(area_year_n, area_year_total, by = "year", suffixes = c("", "_total"))
area_year_n$share <- area_year_n$n_fish / area_year_n$n_fish_total

gear_year_n <- aggregate(
  fish_id ~ year + gear,
  data = consistency_fish,
  FUN = length
)
names(gear_year_n)[3] <- "n_fish"
gear_year_total <- aggregate(n_fish ~ year, data = gear_year_n, FUN = sum)
gear_year_n <- merge(gear_year_n, gear_year_total, by = "year", suffixes = c("", "_total"))
gear_year_n$share <- gear_year_n$n_fish / gear_year_n$n_fish_total

# Jensen-Shannon divergence between each year's design-cell composition and the
# overall reference composition. This measures design drift, not biology.
composition_table <- table(consistency_fish$year, consistency_fish$design_cell)
reference_composition <- colSums(composition_table) / sum(composition_table)

js_divergence <- function(p, q) {
  p <- p / sum(p)
  q <- q / sum(q)
  m <- 0.5 * (p + q)
  kl <- function(a, b) {
    idx <- a > 0 & b > 0
    sum(a[idx] * log2(a[idx] / b[idx]))
  }
  0.5 * kl(p, m) + 0.5 * kl(q, m)
}

design_drift <- data.frame(
  year = as.integer(rownames(composition_table)),
  js_divergence = apply(
    composition_table,
    1,
    function(x) js_divergence(as.numeric(x), reference_composition)
  )
)

# -----------------------------------------------------------------------------
# 4. Pooled versus design-standardized annual length
# -----------------------------------------------------------------------------

pooled_annual <- aggregate(
  length_cm ~ year,
  data = consistency_fish,
  FUN = mean
)
names(pooled_annual)[2] <- "pooled_mean_cm"

# Fixed reference weights are based on the long-term composition of persistent
# strata. Applying the same weights every year removes year-to-year changes in
# sampling composition while retaining a realistic, non-equal reference design.
reference_n <- aggregate(
  n_fish ~ stratum,
  data = persistent,
  FUN = sum
)
reference_n$reference_weight <- reference_n$n_fish / sum(reference_n$n_fish)

persistent_weighted <- merge(
  persistent,
  reference_n[, c("stratum", "reference_weight")],
  by = "stratum"
)

standardized_annual <- do.call(
  rbind,
  lapply(split(persistent_weighted, persistent_weighted$year), function(d) {
    data.frame(
      year = d$year[1],
      standardized_mean_cm = weighted.mean(
        d$mean_length_cm,
        d$reference_weight
      ),
      equal_strata_mean_cm = mean(d$mean_length_cm),
      n_persistent_strata = nrow(d)
    )
  })
)
rownames(standardized_annual) <- NULL

annual_comparison <- merge(pooled_annual, standardized_annual, by = "year")
annual_comparison <- merge(annual_comparison, design_drift, by = "year")
annual_comparison$composition_bias_cm <-
  annual_comparison$pooled_mean_cm - annual_comparison$standardized_mean_cm

# -----------------------------------------------------------------------------
# 5. Within-stratum anomalies: ask whether changes persist after matching design
# -----------------------------------------------------------------------------

stratum_reference <- aggregate(
  mean_length_cm ~ stratum,
  data = persistent,
  FUN = mean
)
names(stratum_reference)[2] <- "stratum_reference_mean"

persistent <- merge(persistent, stratum_reference, by = "stratum")
persistent$within_stratum_anomaly <-
  persistent$mean_length_cm - persistent$stratum_reference_mean
persistent <- persistent[order(persistent$stratum, persistent$year), ]

annual_anomaly <- aggregate(
  within_stratum_anomaly ~ year,
  data = persistent,
  FUN = mean
)
names(annual_anomaly)[2] <- "mean_within_stratum_anomaly_cm"

area_year_anomaly <- aggregate(
  within_stratum_anomaly ~ year + area,
  data = persistent,
  FUN = mean
)

gear_year_anomaly <- aggregate(
  within_stratum_anomaly ~ year + gear,
  data = persistent,
  FUN = mean
)

season_year_anomaly <- aggregate(
  within_stratum_anomaly ~ year + season,
  data = persistent,
  FUN = mean
)

# -----------------------------------------------------------------------------
# 6. Directional consistency of year-to-year change
# -----------------------------------------------------------------------------

persistent$annual_delta_cm <- ave(
  persistent$mean_length_cm,
  persistent$stratum,
  FUN = function(x) c(NA_real_, diff(x))
)

change_rows <- persistent[is.finite(persistent$annual_delta_cm), ]
annual_change_consistency <- do.call(
  rbind,
  lapply(split(change_rows, change_rows$year), function(d) {
    data.frame(
      year = d$year[1],
      median_delta_cm = median(d$annual_delta_cm),
      q25_delta_cm = unname(quantile(d$annual_delta_cm, 0.25)),
      q75_delta_cm = unname(quantile(d$annual_delta_cm, 0.75)),
      share_positive = mean(d$annual_delta_cm > 0),
      share_negative = mean(d$annual_delta_cm < 0),
      n_strata = nrow(d)
    )
  })
)
rownames(annual_change_consistency) <- NULL

# A strong pooled change accompanied by roughly half positive and half negative
# matched-stratum changes is evidence against a simple stock-wide interpretation.

# -----------------------------------------------------------------------------
# 7. Spatial synchrony after removing stable stratum differences
# -----------------------------------------------------------------------------

area_anomaly_wide <- reshape(
  area_year_anomaly,
  idvar = "year",
  timevar = "area",
  direction = "wide"
)
area_cols <- grep("^within_stratum_anomaly\\.", names(area_anomaly_wide), value = TRUE)
area_synchrony <- cor(area_anomaly_wide[, area_cols, drop = FALSE], use = "pairwise.complete.obs")
colnames(area_synchrony) <- sub("within_stratum_anomaly\\.", "", colnames(area_synchrony))
rownames(area_synchrony) <- sub("within_stratum_anomaly\\.", "", rownames(area_synchrony))

area_synchrony_table <- data.frame(
  comparison = c("West vs Central", "West vs East", "Central vs East"),
  correlation = c(
    area_synchrony["West", "Central"],
    area_synchrony["West", "East"],
    area_synchrony["Central", "East"]
  ),
  row.names = NULL
)

# -----------------------------------------------------------------------------
# 8. Matched spatial contrasts
# -----------------------------------------------------------------------------

# Compare areas only within the same year x season x gear x source cell. This
# avoids mixing spatial differences with seasonal or gear composition.
spatial_wide <- reshape(
  persistent[, c("year", "season", "gear", "source", "area", "mean_length_cm")],
  idvar = c("year", "season", "gear", "source"),
  timevar = "area",
  direction = "wide"
)

if (all(c("mean_length_cm.West", "mean_length_cm.Central", "mean_length_cm.East") %in% names(spatial_wide))) {
  spatial_wide$west_minus_east <- spatial_wide$mean_length_cm.West - spatial_wide$mean_length_cm.East
  spatial_wide$west_minus_central <- spatial_wide$mean_length_cm.West - spatial_wide$mean_length_cm.Central
  spatial_wide$central_minus_east <- spatial_wide$mean_length_cm.Central - spatial_wide$mean_length_cm.East
}

spatial_contrast_year <- do.call(
  rbind,
  lapply(split(spatial_wide, spatial_wide$year), function(d) {
    data.frame(
      year = d$year[1],
      west_minus_east_cm = median(d$west_minus_east, na.rm = TRUE),
      west_minus_central_cm = median(d$west_minus_central, na.rm = TRUE),
      central_minus_east_cm = median(d$central_minus_east, na.rm = TRUE),
      matched_cells = sum(is.finite(d$west_minus_east))
    )
  })
)
rownames(spatial_contrast_year) <- NULL

# -----------------------------------------------------------------------------
# 9. Leave-one-area-out sensitivity
# -----------------------------------------------------------------------------

leave_one_area_out <- do.call(
  rbind,
  lapply(sort(unique(persistent$year)), function(y) {
    d <- persistent[persistent$year == y, ]
    do.call(
      rbind,
      lapply(c("None", sort(unique(d$area))), function(omit) {
        use <- if (omit == "None") d else d[d$area != omit, ]
        data.frame(
          year = y,
          omitted_area = omit,
          mean_anomaly_cm = mean(use$within_stratum_anomaly),
          n_strata = nrow(use)
        )
      })
    )
  })
)
rownames(leave_one_area_out) <- NULL

# -----------------------------------------------------------------------------
# 10. Flag the simulated gillnet selectivity change explicitly
# -----------------------------------------------------------------------------

# Module 03 introduced a gillnet mesh/selectivity change from 2023. Here we test
# whether the post-2023 signal is concentrated in that gear rather than shared by
# other sampling streams.
gear_period <- gear_year_anomaly
gear_period$period <- ifelse(gear_period$year >= 2023, "2023-2025", "2016-2022")
gear_period_summary <- aggregate(
  within_stratum_anomaly ~ gear + period,
  data = gear_period,
  FUN = mean
)

pre <- gear_period_summary[gear_period_summary$period == "2016-2022", c("gear", "within_stratum_anomaly")]
post <- gear_period_summary[gear_period_summary$period == "2023-2025", c("gear", "within_stratum_anomaly")]
names(pre)[2] <- "pre_anomaly_cm"
names(post)[2] <- "post_anomaly_cm"
gear_shift <- merge(pre, post, by = "gear")
gear_shift$shift_cm <- gear_shift$post_anomaly_cm - gear_shift$pre_anomaly_cm

# -----------------------------------------------------------------------------
# 11. Compact audit summary
# -----------------------------------------------------------------------------

consistency_audit <- data.frame(
  diagnostic = c(
    "Persistent comparable strata",
    "Maximum annual design-composition divergence",
    "Maximum absolute pooled-vs-standardized difference (cm)",
    "Largest absolute matched West-East contrast (cm)",
    "Largest leave-one-area-out deviation from all-area anomaly (cm)"
  ),
  value = c(
    length(persistent_strata),
    round(max(design_drift$js_divergence), 4),
    round(max(abs(annual_comparison$composition_bias_cm)), 3),
    round(max(abs(spatial_contrast_year$west_minus_east_cm), na.rm = TRUE), 3),
    round(max(abs(
      merge(
        leave_one_area_out[leave_one_area_out$omitted_area != "None", ],
        leave_one_area_out[leave_one_area_out$omitted_area == "None", c("year", "mean_anomaly_cm")],
        by = "year",
        suffixes = c("_omit", "_all")
      )$mean_anomaly_cm_omit -
        merge(
          leave_one_area_out[leave_one_area_out$omitted_area != "None", ],
          leave_one_area_out[leave_one_area_out$omitted_area == "None", c("year", "mean_anomaly_cm")],
          by = "year",
          suffixes = c("_omit", "_all")
        )$mean_anomaly_cm_all
    )), 3)
  ),
  interpretation = c(
    "Strata used for like-with-like temporal comparison",
    "Higher values indicate greater drift in sampled design composition",
    "Quantifies how much pooling can move the annual mean through composition alone",
    "Spatial difference estimated only from matched season/gear/source cells",
    "Checks whether one area dominates the standardized temporal signal"
  ),
  stringsAsFactors = FALSE
)

# Relationship between changing sample composition and pooled-standardized bias.
design_bias_correlation <- cor(
  annual_comparison$js_divergence,
  abs(annual_comparison$composition_bias_cm),
  use = "complete.obs"
)

stopifnot(
  nrow(annual_comparison) == length(unique(consistency_fish$year)),
  all(is.finite(annual_comparison$standardized_mean_cm)),
  all(annual_change_consistency$share_positive >= 0 & annual_change_consistency$share_positive <= 1),
  all(is.finite(area_synchrony_table$correlation)),
  is.finite(design_bias_correlation)
)
