# Module 03: Length-frequency distributions before assessment
#
# Purpose
# -------
# Simulate individual-level fish length observations under a structured monitoring
# programme and demonstrate quality control, sampling-coverage diagnostics,
# spatio-temporal/fleet/gear comparisons, pooling-versus-stratification issues,
# length heaping, truncated sampling, and distributional change before any stock-
# assessment model is fitted.
#
# The data are entirely simulated and contain no confidential information.

set.seed(20260905)

# -----------------------------------------------------------------------------
# 1. Sampling frame
# -----------------------------------------------------------------------------

years <- 2016:2025
months <- 1:12
areas <- c("West", "Central", "East")

fleet_gear <- data.frame(
  combo = c("trawler_bottom_trawl", "coastal_gillnet", "coastal_longline", "survey_trawl"),
  fleet = c("trawler", "coastal", "coastal", "survey"),
  gear = c("bottom_trawl", "gillnet", "longline", "survey_trawl"),
  source = c("commercial", "commercial", "commercial", "survey"),
  stringsAsFactors = FALSE
)

events <- expand.grid(
  year = years,
  month = months,
  area = areas,
  combo = fleet_gear$combo,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

events <- merge(events, fleet_gear, by = "combo", sort = FALSE)
events$quarter <- ((events$month - 1) %/% 3) + 1
events$season <- c("Winter", "Spring", "Summer", "Autumn")[events$quarter]

events$event_id <- sprintf("EV-%05d", seq_len(nrow(events)))

# Monitoring effort varies by source, area, season and year.
base_n <- ifelse(events$source == "survey", 75, 60)
base_n <- base_n + ifelse(events$gear == "bottom_trawl", 25, 0)
base_n <- base_n + ifelse(events$area == "West", 10, ifelse(events$area == "East", -8, 0))
base_n <- base_n + ifelse(events$month %in% c(5, 6, 7), 12, 0)
base_n <- base_n + 2 * (events$year - min(years))

events$n_measured_planned <- pmax(15, rpois(nrow(events), lambda = pmax(20, base_n)))

# Deliberately reduced coverage in East during 2019.
low_coverage <- events$year == 2019 & events$area == "East" & events$source == "commercial"
events$n_measured_planned[low_coverage] <- pmax(
  6,
  round(events$n_measured_planned[low_coverage] * 0.25)
)

# Missing stratum: no East longline samples in Apr-Jun 2020.
missing_event <- events$year == 2020 &
  events$area == "East" &
  events$gear == "longline" &
  events$month %in% 4:6
events <- events[!missing_event, ]

# -----------------------------------------------------------------------------
# 2. Expand to individual fish and simulate biological length structure
# -----------------------------------------------------------------------------

fish <- events[rep(seq_len(nrow(events)), events$n_measured_planned), ]
rownames(fish) <- NULL
fish$fish_id <- sprintf("F-%07d", seq_len(nrow(fish)))

# Seasonal juvenile availability creates genuine multimodality in some strata.
recruitment_season <- exp(-0.5 * ((fish$month - 5.5) / 1.6)^2)
p_juvenile <- 0.12 + 0.48 * recruitment_season
p_juvenile <- p_juvenile + ifelse(fish$area == "East", 0.08, 0)
p_juvenile <- p_juvenile + ifelse(fish$gear == "bottom_trawl", 0.10, 0)
p_juvenile <- p_juvenile - ifelse(fish$gear %in% c("gillnet", "longline"), 0.10, 0)
p_juvenile <- pmin(0.78, pmax(0.04, p_juvenile))

juvenile <- rbinom(nrow(fish), 1, p_juvenile) == 1

# A modest biological temporal signal: adult size declines through 2021, then
# partially recovers. Spatial and gear effects are superimposed.
year_effect <- approx(
  x = c(2016, 2021, 2025),
  y = c(1.2, -1.4, 0.2),
  xout = fish$year
)$y

area_effect <- c(West = 1.4, Central = 0.0, East = -1.2)[fish$area]
gear_effect <- c(
  bottom_trawl = -1.0,
  gillnet = 1.2,
  longline = 2.2,
  survey_trawl = 0.0
)[fish$gear]

# Simulated gillnet mesh regulation from 2023 changes selectivity rather than
# underlying population biology.
mesh_change <- ifelse(fish$gear == "gillnet" & fish$year >= 2023, 2.4, 0)

juvenile_mean <- 17.0 + 0.85 * pmax(0, fish$month - 4) + 0.35 * area_effect
adult_mean <- 32.5 + year_effect + area_effect + gear_effect + mesh_change

fish$length_cm <- ifelse(
  juvenile,
  rnorm(nrow(fish), juvenile_mean, 2.2),
  rnorm(nrow(fish), adult_mean, 4.1)
)

fish$length_cm <- round(pmin(61, pmax(8, fish$length_cm)), 1)

# Weight is included only as a plausibility companion variable; life-history
# analysis is deliberately deferred to a later module.
fish$weight_g <- round(0.0108 * fish$length_cm^3.05 * exp(rnorm(nrow(fish), 0, 0.10)), 1)

# -----------------------------------------------------------------------------
# 3. Introduce realistic observation and sampling artefacts
# -----------------------------------------------------------------------------

# Length heaping/rounding by one commercial sampling stream in 2020-2021.
heaping_candidates <- which(
  fish$year %in% 2020:2021 &
    fish$gear == "gillnet" &
    fish$source == "commercial"
)
heap_idx <- sample(
  heaping_candidates,
  size = round(0.35 * length(heaping_candidates)),
  replace = FALSE
)
fish$length_cm[heap_idx] <- 5 * round(fish$length_cm[heap_idx] / 5)

# Truncated measurement process: in West trawl samples during Jul-Sep 2022,
# fish below 22 cm were not measured. This mimics market/sampler selection and
# should not be interpreted as absence of small fish from the population.
fish$measurement_scope <- "full"
truncated_scope <- fish$year == 2022 &
  fish$area == "West" &
  fish$gear == "bottom_trawl" &
  fish$month %in% 7:9
fish$measurement_scope[truncated_scope] <- "marketable_only"
fish <- fish[!(truncated_scope & fish$length_cm < 22), ]

# A small unit-entry problem: eight survey lengths recorded in millimetres but
# stored in the centimetre field.
unit_candidates <- which(
  fish$year == 2024 & fish$area == "East" & fish$gear == "survey_trawl"
)
unit_idx <- head(unit_candidates, 8)
fish$length_cm[unit_idx] <- fish$length_cm[unit_idx] * 10

# Exact duplicate fish records introduced during data merge.
dup_idx <- which(fish$year == 2018 & fish$area == "Central")[1:6]
fish <- rbind(fish, fish[dup_idx, ])
rownames(fish) <- NULL

# -----------------------------------------------------------------------------
# 4. Quality-control flags: preserve raw observations, create analysis version
# -----------------------------------------------------------------------------

fish$duplicate_fish_id <- duplicated(fish$fish_id) |
  duplicated(fish$fish_id, fromLast = TRUE)
fish$length_plausible <- is.finite(fish$length_cm) &
  fish$length_cm >= 5 & fish$length_cm <= 80
fish$weight_plausible <- is.finite(fish$weight_g) & fish$weight_g > 0
fish$is_5cm_heap <- fish$length_plausible &
  abs(fish$length_cm / 5 - round(fish$length_cm / 5)) < 0.01

analysis_fish <- fish[
  fish$length_plausible &
    fish$weight_plausible &
    !fish$duplicate_fish_id,
]
rownames(analysis_fish) <- NULL

# Never silently remove incomplete-scope events. Keep them identifiable so that
# broad LFDs can be compared with a sensitivity version excluding them.
full_scope_fish <- analysis_fish[analysis_fish$measurement_scope == "full", ]

# -----------------------------------------------------------------------------
# 5. Coverage and sample-size diagnostics
# -----------------------------------------------------------------------------

sample_size_year <- aggregate(
  fish_id ~ year,
  data = analysis_fish,
  FUN = length
)
names(sample_size_year)[2] <- "n_fish"

sample_size_year_area <- aggregate(
  fish_id ~ year + area,
  data = analysis_fish,
  FUN = length
)
names(sample_size_year_area)[3] <- "n_fish"

sample_size_year_gear <- aggregate(
  fish_id ~ year + gear,
  data = analysis_fish,
  FUN = length
)
names(sample_size_year_gear)[3] <- "n_fish"

sample_size_month_area <- aggregate(
  fish_id ~ year + month + area,
  data = analysis_fish,
  FUN = length
)
names(sample_size_month_area)[4] <- "n_fish"

heaping_summary <- aggregate(
  is_5cm_heap ~ year + gear,
  data = analysis_fish,
  FUN = mean
)
heaping_summary$percent_heaped <- 100 * heaping_summary$is_5cm_heap

quality_register <- data.frame(
  issue = c(
    "duplicate fish IDs",
    "implausible length range",
    "known incomplete measurement scope",
    "5-cm length heaping signal",
    "missing East-longline sampling stratum",
    "low East commercial coverage in 2019"
  ),
  diagnostic = c(
    sum(fish$duplicate_fish_id),
    sum(!fish$length_plausible),
    sum(analysis_fish$measurement_scope != "full"),
    sum(analysis_fish$is_5cm_heap),
    3,
    sum(analysis_fish$year == 2019 & analysis_fish$area == "East" & analysis_fish$source == "commercial")
  ),
  action = c(
    "resolve duplicates before frequency calculation",
    "verify units and exclude implausible values pending correction",
    "retain provenance; exclude in sensitivity comparison",
    "inspect digit preference before interpreting narrow modes",
    "document as absent sampling, not zero abundance",
    "avoid direct comparison without considering coverage/composition"
  ),
  stringsAsFactors = FALSE
)

# -----------------------------------------------------------------------------
# 6. Length summaries and binning
# -----------------------------------------------------------------------------

analysis_fish$length_bin_1cm <- floor(analysis_fish$length_cm)
full_scope_fish$length_bin_1cm <- floor(full_scope_fish$length_cm)

quantile_fun <- function(x) {
  q <- quantile(x, probs = c(0.10, 0.25, 0.50, 0.75, 0.90), na.rm = TRUE)
  c(p10 = q[1], p25 = q[2], median = q[3], p75 = q[4], p90 = q[5])
}

annual_quantiles_matrix <- do.call(
  rbind,
  lapply(split(analysis_fish$length_cm, analysis_fish$year), quantile_fun)
)
annual_quantiles <- data.frame(
  year = as.integer(rownames(annual_quantiles_matrix)),
  annual_quantiles_matrix,
  row.names = NULL,
  check.names = FALSE
)

gear_quantiles_list <- lapply(
  split(analysis_fish, interaction(analysis_fish$year, analysis_fish$gear, drop = TRUE)),
  function(d) {
    q <- quantile_fun(d$length_cm)
    data.frame(
      year = d$year[1],
      gear = d$gear[1],
      p10 = q[1], p25 = q[2], median = q[3], p75 = q[4], p90 = q[5]
    )
  }
)
gear_quantiles <- do.call(rbind, gear_quantiles_list)
rownames(gear_quantiles) <- NULL

# Annual 1-cm LFDs as proportions, not raw counts.
lfd_counts <- aggregate(
  fish_id ~ year + length_bin_1cm,
  data = analysis_fish,
  FUN = length
)
names(lfd_counts)[3] <- "n"
lfd_totals <- aggregate(n ~ year, data = lfd_counts, FUN = sum)
lfd_counts <- merge(lfd_counts, lfd_totals, by = "year", suffixes = c("", "_total"))
lfd_counts$proportion <- lfd_counts$n / lfd_counts$n_total

# Sensitivity LFD excluding known incomplete measurement-scope observations.
lfd_full_scope <- aggregate(
  fish_id ~ year + length_bin_1cm,
  data = full_scope_fish,
  FUN = length
)
names(lfd_full_scope)[3] <- "n"
lfd_full_totals <- aggregate(n ~ year, data = lfd_full_scope, FUN = sum)
lfd_full_scope <- merge(lfd_full_scope, lfd_full_totals, by = "year", suffixes = c("", "_total"))
lfd_full_scope$proportion <- lfd_full_scope$n / lfd_full_scope$n_total

# -----------------------------------------------------------------------------
# 7. Composition-standardized annual LFDs
# -----------------------------------------------------------------------------

# Pooled annual distributions can move simply because the composition of sampled
# areas/gears changes. Standardize by giving persistent area x gear x source
# strata equal weight within each year.
analysis_fish$stratum <- with(
  analysis_fish,
  paste(area, gear, source, sep = "|")
)

presence <- table(analysis_fish$year, analysis_fish$stratum)
common_strata <- colnames(presence)[colSums(presence > 0) == nrow(presence)]
standardization_fish <- analysis_fish[analysis_fish$stratum %in% common_strata, ]

stratum_lfd <- aggregate(
  fish_id ~ year + stratum + length_bin_1cm,
  data = standardization_fish,
  FUN = length
)
names(stratum_lfd)[4] <- "n"
stratum_totals <- aggregate(n ~ year + stratum, data = stratum_lfd, FUN = sum)
stratum_lfd <- merge(
  stratum_lfd,
  stratum_totals,
  by = c("year", "stratum"),
  suffixes = c("", "_total")
)
stratum_lfd$stratum_prop <- stratum_lfd$n / stratum_lfd$n_total

balanced_lfd <- aggregate(
  stratum_prop ~ year + length_bin_1cm,
  data = stratum_lfd,
  FUN = mean
)
names(balanced_lfd)[3] <- "proportion"

# Renormalize because some length bins are absent from individual strata.
balanced_totals <- aggregate(proportion ~ year, data = balanced_lfd, FUN = sum)
names(balanced_totals)[2] <- "total_prop"
balanced_lfd <- merge(balanced_lfd, balanced_totals, by = "year")
balanced_lfd$proportion <- balanced_lfd$proportion / balanced_lfd$total_prop

# -----------------------------------------------------------------------------
# 8. Distributional distance through time
# -----------------------------------------------------------------------------

js_divergence <- function(p, q) {
  p <- p / sum(p)
  q <- q / sum(q)
  m <- 0.5 * (p + q)
  kl <- function(a, b) {
    keep <- a > 0 & b > 0
    sum(a[keep] * log2(a[keep] / b[keep]))
  }
  0.5 * kl(p, m) + 0.5 * kl(q, m)
}

all_bins <- sort(unique(lfd_counts$length_bin_1cm))
get_year_distribution <- function(y, table_in = lfd_counts) {
  z <- table_in[table_in$year == y, c("length_bin_1cm", "proportion")]
  out <- setNames(rep(0, length(all_bins)), all_bins)
  out[as.character(z$length_bin_1cm)] <- z$proportion
  out
}

js_year_to_year <- data.frame(
  year_from = years[-length(years)],
  year_to = years[-1],
  js_divergence = NA_real_
)

for (i in seq_len(nrow(js_year_to_year))) {
  p <- get_year_distribution(js_year_to_year$year_from[i])
  q <- get_year_distribution(js_year_to_year$year_to[i])
  js_year_to_year$js_divergence[i] <- js_divergence(p, q)
}

# -----------------------------------------------------------------------------
# 9. Density objects for comparative visualization
# -----------------------------------------------------------------------------

# Kernel density is used as a complementary visualization only. Raw/binned LFDs
# remain the primary evidence because density shape depends on bandwidth.
density_by_year <- do.call(
  rbind,
  lapply(years, function(y) {
    d <- density(
      analysis_fish$length_cm[analysis_fish$year == y],
      from = 8,
      to = 62,
      n = 256,
      bw = "nrd0"
    )
    data.frame(year = y, length_cm = d$x, density = d$y)
  })
)

# Ridgeline-style coordinates without requiring an additional plotting package.
year_index <- setNames(seq_along(years), years)
density_by_year$baseline <- year_index[as.character(density_by_year$year)]
max_density <- max(density_by_year$density)
density_by_year$ridge_y <- density_by_year$baseline +
  0.75 * density_by_year$density / max_density

# Area x gear density table for recent period comparisons.
recent <- analysis_fish[analysis_fish$year >= 2023, ]
recent_groups <- unique(recent[, c("area", "gear")])
recent_density <- do.call(
  rbind,
  lapply(seq_len(nrow(recent_groups)), function(i) {
    d0 <- recent[
      recent$area == recent_groups$area[i] &
        recent$gear == recent_groups$gear[i],
    ]
    if (nrow(d0) < 40) return(NULL)
    d <- density(d0$length_cm, from = 8, to = 62, n = 200)
    data.frame(
      area = recent_groups$area[i],
      gear = recent_groups$gear[i],
      length_cm = d$x,
      density = d$y
    )
  })
)

# -----------------------------------------------------------------------------
# 10. Core assertions
# -----------------------------------------------------------------------------

stopifnot(
  nrow(fish) > 50000,
  nrow(analysis_fish) > 50000,
  any(fish$duplicate_fish_id),
  any(!fish$length_plausible),
  any(analysis_fish$measurement_scope != "full"),
  length(common_strata) >= 6,
  all(abs(aggregate(proportion ~ year, lfd_counts, sum)$proportion - 1) < 1e-8),
  all(abs(aggregate(proportion ~ year, balanced_lfd, sum)$proportion - 1) < 1e-8)
)
