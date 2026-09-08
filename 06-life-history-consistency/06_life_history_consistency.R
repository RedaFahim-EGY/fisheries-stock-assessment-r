# Module 06: Life-history data quality and parameter consistency before assessment
# Entirely simulated data. No confidential or institutional information.

set.seed(20260908)

years <- 2016:2025
months <- 1:12
areas <- c("West", "Central", "East")
sources <- c("commercial", "survey")
sexes <- c("F", "M")

frame <- expand.grid(year = years, month = months, area = areas, source = sources,
                     KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
frame$n_sampled <- round(14 + 8 * (frame$source == "survey") +
  4 * (frame$area == "West") + 3 * (frame$month %in% 3:6) +
  rnorm(nrow(frame), 0, 3))
frame$n_sampled <- pmax(frame$n_sampled, 5)
frame$n_sampled[frame$year == 2018 & frame$area == "East" & frame$source == "commercial"] <- 5
frame$n_sampled[frame$year == 2023 & frame$month %in% c(1, 2) & frame$area == "Central"] <- 6

idx <- rep(seq_len(nrow(frame)), frame$n_sampled)
bio <- frame[idx, c("year", "month", "area", "source")]
rownames(bio) <- NULL
bio$fish_id <- sprintf("BIO-%06d", seq_len(nrow(bio)))

p_female <- plogis(0.10 + 0.30 * (bio$source == "survey") +
  0.20 * (bio$area == "West") - 0.18 * (bio$area == "East") +
  0.25 * sin(2 * pi * (bio$month - 2) / 12))
bio$sex <- ifelse(runif(nrow(bio)) < p_female, "F", "M")

mu_age <- 2.7 + 0.30 * (bio$source == "survey") + 0.18 * (bio$area == "West") -
  0.15 * (bio$area == "East") + 0.12 * (bio$sex == "F")
lambda <- rgamma(nrow(bio), shape = 7, rate = 7 / pmax(mu_age, 0.5))
bio$true_age <- pmin(rpois(nrow(bio), lambda), 9)

Linf_sex <- ifelse(bio$sex == "F", 61, 56)
K_sex <- ifelse(bio$sex == "F", 0.24, 0.29)
t0 <- -0.45
expected_length <- Linf_sex * (1 - exp(-K_sex * (bio$true_age - t0))) +
  0.9 * (bio$area == "West") - 0.7 * (bio$area == "East") +
  0.35 * (bio$source == "survey") + 0.10 * (bio$year - 2016) / 9
bio$length_cm <- round(rnorm(nrow(bio), expected_length,
  sd = 1.4 + 0.22 * sqrt(bio$true_age + 1)), 1)

log_a <- ifelse(bio$sex == "F", log(0.0105), log(0.0097))
b_exp <- ifelse(bio$sex == "F", 3.05, 3.01)
source_weight_effect <- ifelse(bio$source == "survey", 0.015, -0.005)
bio$weight_g <- round(exp(log_a + b_exp * log(pmax(bio$length_cm, 1)) +
  source_weight_effect + rnorm(nrow(bio), 0, 0.08)), 1)

L50 <- ifelse(bio$sex == "F", 31.8, 29.4) + 0.5 * (bio$area == "East") -
  0.3 * (bio$area == "West") + 0.06 * (bio$year - 2016)
slope <- ifelse(bio$sex == "F", 0.42, 0.48)
p_mature <- plogis(slope * (bio$length_cm - L50))
bio$mature <- rbinom(nrow(bio), 1, p_mature)

seasonal_gsi <- 0.8 + 3.8 * exp(-0.5 * ((bio$month - 4.5) / 1.4)^2)
bio$gsi <- pmax(0.05, seasonal_gsi * ifelse(bio$sex == "F", 1.15, 0.82) *
  ifelse(bio$mature == 1, 1.25, 0.45) * exp(rnorm(nrow(bio), 0, 0.18)))

# Deliberate QC problems.
bio <- rbind(bio, bio[222, ])
bio$length_cm[430] <- bio$length_cm[430] * 10
bio$weight_g[875] <- bio$weight_g[875] / 1000
bio$mature[1210] <- 7
bio$sex[1550] <- "U"
bio$gsi[1888] <- 47

drift_pool <- which(bio$year >= 2024 & bio$source == "commercial" &
  bio$length_cm < 30 & bio$mature == 0)
if (length(drift_pool) > 0) {
  remove_n <- floor(0.35 * length(drift_pool))
  if (remove_n > 0) bio <- bio[-sample(drift_pool, remove_n), ]
}
rownames(bio) <- NULL

# Record-level QC.
bio$duplicate_id <- duplicated(bio$fish_id) | duplicated(bio$fish_id, fromLast = TRUE)
bio$invalid_length <- !is.finite(bio$length_cm) | bio$length_cm < 8 | bio$length_cm > 85
bio$invalid_weight <- !is.finite(bio$weight_g) | bio$weight_g <= 1 | bio$weight_g > 8000
bio$invalid_sex <- !(bio$sex %in% sexes)
bio$invalid_maturity <- !(bio$mature %in% c(0, 1))
bio$invalid_gsi <- !is.finite(bio$gsi) | bio$gsi <= 0 | bio$gsi > 20
valid <- bio[!bio$duplicate_id & !bio$invalid_length & !bio$invalid_weight &
  !bio$invalid_sex & !bio$invalid_maturity & !bio$invalid_gsi, ]

valid$condition_residual <- NA_real_
for (sx in sexes) {
  ii <- valid$sex == sx
  fit <- lm(log(weight_g) ~ log(length_cm), data = valid[ii, ])
  valid$condition_residual[ii] <- residuals(fit)
}
med_res <- median(valid$condition_residual, na.rm = TRUE)
mad_res <- mad(valid$condition_residual, constant = 1, na.rm = TRUE)
valid$condition_outlier <- abs(valid$condition_residual - med_res) > 5 * mad_res

# Sampling support and sex composition.
support <- aggregate(fish_id ~ year + month + area + source, valid, length)
names(support)[5] <- "n_bio"
support$weak_support <- support$n_bio < 10
sex_ratio <- aggregate(I(sex == "F") ~ year + area + source, valid, mean)
names(sex_ratio)[4] <- "prop_female"
sex_ratio_n <- aggregate(fish_id ~ year + area + source, valid, length)
names(sex_ratio_n)[4] <- "n"
sex_ratio <- merge(sex_ratio, sex_ratio_n, by = c("year", "area", "source"))

# Weight-length relationships.
wl_summary_list <- list(); counter <- 1
for (sx in sexes) for (src in sources) {
  d <- valid[valid$sex == sx & valid$source == src & !valid$condition_outlier, ]
  fit <- lm(log(weight_g) ~ log(length_cm), data = d)
  co <- coef(fit)
  wl_summary_list[[counter]] <- data.frame(sex = sx, source = src, n = nrow(d),
    a = exp(co[1]), b = co[2], r2 = summary(fit)$r.squared,
    stringsAsFactors = FALSE)
  counter <- counter + 1
}
wl_summary <- do.call(rbind, wl_summary_list); rownames(wl_summary) <- NULL

wl_year_list <- list(); counter <- 1
for (yy in years) for (sx in sexes) {
  d <- valid[valid$year == yy & valid$sex == sx & !valid$condition_outlier, ]
  if (nrow(d) >= 40) {
    fit <- lm(log(weight_g) ~ log(length_cm), data = d)
    wl_year_list[[counter]] <- data.frame(year = yy, sex = sx, n = nrow(d),
      a = exp(coef(fit)[1]), b = coef(fit)[2], stringsAsFactors = FALSE)
    counter <- counter + 1
  }
}
wl_year <- do.call(rbind, wl_year_list)

# Maturity ogives and L50.
estimate_l50 <- function(d) {
  if (nrow(d) < 80 || length(unique(d$mature)) < 2) return(c(n = nrow(d), L50 = NA, slope = NA))
  fit <- glm(mature ~ length_cm, family = binomial(), data = d)
  cf <- coef(fit)
  c(n = nrow(d), L50 = unname(-cf[1] / cf[2]), slope = unname(cf[2]))
}

maturity_groups <- expand.grid(sex = sexes, source = sources,
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
maturity_summary <- do.call(rbind, lapply(seq_len(nrow(maturity_groups)), function(i) {
  sx <- maturity_groups$sex[i]; src <- maturity_groups$source[i]
  est <- estimate_l50(valid[valid$sex == sx & valid$source == src, ])
  data.frame(sex = sx, source = src, n = est["n"], L50 = est["L50"],
    slope = est["slope"], stringsAsFactors = FALSE)
}))

l50_year <- do.call(rbind, lapply(years, function(yy) do.call(rbind, lapply(sexes, function(sx) {
  est <- estimate_l50(valid[valid$year == yy & valid$sex == sx, ])
  data.frame(year = yy, sex = sx, n = est["n"], L50 = est["L50"],
    slope = est["slope"], stringsAsFactors = FALSE)
}))))

late_maturity <- valid[valid$year >= 2024, ]
late_l50 <- do.call(rbind, lapply(sexes, function(sx) do.call(rbind, lapply(sources, function(src) {
  est <- estimate_l50(late_maturity[late_maturity$sex == sx & late_maturity$source == src, ])
  data.frame(sex = sx, source = src, n = est["n"], L50 = est["L50"], stringsAsFactors = FALSE)
}))))

# Spawning-season consistency.
gsi_month <- aggregate(gsi ~ month + sex, valid[valid$mature == 1, ], mean)
gsi_month_n <- aggregate(fish_id ~ month + sex, valid[valid$mature == 1, ], length)
names(gsi_month_n)[3] <- "n"
gsi_month <- merge(gsi_month, gsi_month_n, by = c("month", "sex"))
peak_month <- do.call(rbind, lapply(sexes, function(sx) {
  d <- gsi_month[gsi_month$sex == sx, ]; d <- d[which.max(d$gsi), ]
  data.frame(sex = sx, peak_month = d$month, peak_mean_gsi = d$gsi)
}))
gsi_area_month <- aggregate(gsi ~ area + month,
  valid[valid$mature == 1 & valid$sex == "F", ], mean)

# Growth information from a reproducible age subsample.
age_subset <- valid[sample(seq_len(nrow(valid)), size = floor(0.45 * nrow(valid))), ]
age_subset$age_observed <- pmax(0, pmin(9, age_subset$true_age +
  rbinom(nrow(age_subset), 1, 0.10) * sample(c(-1, 1), nrow(age_subset), replace = TRUE)))

vb_fit_one <- function(d) {
  try_fit <- try(nls(length_cm ~ Linf * (1 - exp(-K * (age_observed - t0))),
    data = d, start = list(Linf = 60, K = 0.25, t0 = -0.4), algorithm = "port",
    lower = c(Linf = 45, K = 0.05, t0 = -2), upper = c(Linf = 80, K = 0.8, t0 = 1)),
    silent = TRUE)
  if (inherits(try_fit, "try-error")) return(c(Linf = NA, K = NA, t0 = NA, n = nrow(d)))
  c(coef(try_fit), n = nrow(d))
}
growth_summary <- do.call(rbind, lapply(sexes, function(sx) {
  est <- vb_fit_one(age_subset[age_subset$sex == sx, ])
  data.frame(sex = sx, Linf = est["Linf"], K = est["K"], t0 = est["t0"],
    n = est["n"], stringsAsFactors = FALSE)
})); rownames(growth_summary) <- NULL

# Candidate parameter provenance catalogue.
parameter_catalogue <- data.frame(
  source_id = c("local_current_F", "local_current_M", "local_old_combined",
    "adjacent_stock_F", "regional_meta", "assessment_default_M",
    "local_maturity_recent", "adjacent_maturity", "historical_weight_length"),
  parameter = c("growth", "growth", "growth", "growth", "natural_mortality",
    "natural_mortality", "maturity", "maturity", "weight_length"),
  stock_unit = c("Target", "Target", "Target", "Adjacent", "Regional", "Target",
    "Target", "Adjacent", "Target"),
  sex = c("F", "M", "combined", "F", "combined", "combined", "F", "F", "combined"),
  period = c("2021-2025", "2021-2025", "2001-2005", "2019-2024", "multi-period",
    "default", "2021-2025", "2018-2023", "2003-2007"),
  method = c("otolith_vb", "otolith_vb", "scale_vb", "otolith_vb", "empirical_meta",
    "fixed_input", "logistic_ogive", "logistic_ogive", "log_linear"),
  value_1 = c(61.1, 56.2, 64.8, 58.7, 0.31, 0.24, 31.9, 35.4, 0.0086),
  value_2 = c(0.24, 0.29, 0.18, 0.22, NA, NA, 0.43, 0.37, 3.12),
  units = c("Linf_cm;K", "Linf_cm;K", "Linf_cm;K", "Linf_cm;K", "M_per_year",
    "M_per_year", "L50_cm;slope", "L50_cm;slope", "a;b"),
  stringsAsFactors = FALSE)
parameter_catalogue$same_stock <- parameter_catalogue$stock_unit == "Target"
parameter_catalogue$current_period <- grepl("2021-2025", parameter_catalogue$period)
parameter_catalogue$sex_resolved <- parameter_catalogue$sex %in% c("F", "M")
parameter_catalogue$direct_local_method <- parameter_catalogue$method %in%
  c("otolith_vb", "logistic_ogive", "log_linear")
parameter_catalogue$compatibility_score <- rowSums(cbind(parameter_catalogue$same_stock,
  parameter_catalogue$current_period, parameter_catalogue$sex_resolved,
  parameter_catalogue$direct_local_method))
parameter_catalogue$compatibility_class <- cut(parameter_catalogue$compatibility_score,
  breaks = c(-1, 1, 2, 3, 4), labels = c("low", "limited", "moderate", "high"))

# Natural-mortality sensitivity set rather than one unquestioned value.
M_candidates <- data.frame(method = c("lower_sensitivity", "central_input", "upper_sensitivity"),
  M = c(0.22, 0.28, 0.36), rationale = c("lower bound around current candidate inputs",
  "central value for comparison", "upper bound reflecting parameter uncertainty"),
  stringsAsFactors = FALSE)
M_candidates$annual_survival <- exp(-M_candidates$M)
M_candidates$relative_to_central <- M_candidates$M / M_candidates$M[2]

female_L50 <- maturity_summary$L50[maturity_summary$sex == "F" & maturity_summary$source == "survey"][1]
female_Linf <- growth_summary$Linf[growth_summary$sex == "F"][1]
coherence_summary <- data.frame(
  diagnostic = c("female_L50_over_Linf", "female_male_growth_Linf_ratio",
    "female_male_weight_exponent_difference", "late_commercial_vs_survey_female_L50"),
  value = c(female_L50 / female_Linf,
    growth_summary$Linf[growth_summary$sex == "F"] / growth_summary$Linf[growth_summary$sex == "M"],
    wl_summary$b[wl_summary$sex == "F" & wl_summary$source == "survey"] -
      wl_summary$b[wl_summary$sex == "M" & wl_summary$source == "survey"],
    late_l50$L50[late_l50$sex == "F" & late_l50$source == "commercial"] -
      late_l50$L50[late_l50$sex == "F" & late_l50$source == "survey"]),
  interpretation = c("scale check linking maturity and growth information",
    "sex-specific growth contrast", "sex-specific body-shape/allometry contrast",
    "observation-protocol sensitivity in recent maturity data"),
  stringsAsFactors = FALSE)

issue_register <- data.frame(
  issue = c("duplicate fish ID", "invalid length", "invalid weight", "invalid sex code",
    "invalid maturity code", "invalid GSI", "condition/weight-length outlier",
    "weak biological sampling stratum", "low-compatibility candidate parameter"),
  count = c(sum(bio$duplicate_id), sum(bio$invalid_length), sum(bio$invalid_weight),
    sum(bio$invalid_sex), sum(bio$invalid_maturity), sum(bio$invalid_gsi),
    sum(valid$condition_outlier), sum(support$weak_support),
    sum(parameter_catalogue$compatibility_class == "low")),
  action = c("resolve duplicate before summaries", "verify unit and source record",
    "verify unit and source record", "resolve sex code or exclude from sex-specific analyses",
    "verify maturity-stage coding", "verify gonad/body-weight fields and transcription",
    "review condition, measurement and unit plausibility",
    "avoid unsupported stratum-specific inference",
    "do not transfer without explicit justification and sensitivity analysis"),
  stringsAsFactors = FALSE)

stopifnot(nrow(bio) > 12000, sum(bio$duplicate_id) >= 2,
  sum(bio$invalid_length) >= 1, sum(bio$invalid_weight) >= 1,
  sum(bio$invalid_sex) >= 1, sum(bio$invalid_maturity) >= 1,
  nrow(valid) > 10000, all(wl_summary$n > 1000),
  all(is.finite(maturity_summary$L50)), all(is.finite(growth_summary$Linf)),
  nrow(parameter_catalogue) >= 8)
