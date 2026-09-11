# Lightweight reproducibility checks for age_length_diagnostics.R
#
# This is not a stock assessment and does not validate biological thresholds.
# It verifies that the reusable functions behave coherently on deterministic,
# shareable simulated data and catches interface/syntax regressions in CI.

source("05-age-length-consistency/age_length_diagnostics.R")

set.seed(20260911)
n <- 800
x <- data.frame(
  fish_id = sprintf("T-%04d", seq_len(n)),
  year = sample(2018:2025, n, replace = TRUE),
  area = sample(c("West", "East"), n, replace = TRUE),
  season = sample(c("Winter", "Summer"), n, replace = TRUE),
  source = sample(c("commercial", "survey"), n, replace = TRUE),
  gear = sample(c("trawl", "gillnet"), n, replace = TRUE),
  stringsAsFactors = FALSE
)
x$age <- pmin(rpois(n, 3.2), 8)
x$length_cm <- 12 + 7.0 * x$age - 0.35 * x$age^2 +
  ifelse(x$area == "West", 0.8, -0.4) + rnorm(n, 0, 1.8)
x$age_reader1 <- x$age
x$age_reader2 <- x$age
idx <- sample(seq_len(n), 90)
x$age_reader2[idx] <- pmax(0, pmin(8, x$age_reader2[idx] + sample(c(-1, 1), length(idx), TRUE)))
x$period <- ifelse(x$year <= 2021, "early", "late")

# Record-level flags are deliberately tested on a corrupted copy so that the
# analytical dataset remains suitable for the downstream diagnostics.
bad <- rbind(x, x[15, ])
bad$length_cm[20] <- 999
bad$age_reader1[30] <- 20
bad$age_reader1[40] <- 2.5
flags <- flag_age_length_records(
  bad, "length_cm", "age_reader1", "fish_id",
  min_length = 5, max_length = 100, min_age = 0, max_age = 10
)
stopifnot(
  sum(flags$duplicate_id) >= 2,
  sum(flags$length_out_of_range) >= 1,
  sum(flags$age_out_of_range) >= 1,
  sum(flags$age_noninteger) >= 1
)

coverage <- ageing_coverage(
  x, c("year", "area", "season", "source", "gear"), "fish_id", min_n = 5
)
stopifnot(nrow(coverage) > 20, all(coverage$n_aged > 0), is.logical(coverage$weak_support))

plaus <- x
i4 <- which(plaus$age == 4)[1]
plaus$length_cm[i4] <- 95
plaus_checked <- age_length_outliers(plaus, "age", "length_cm", mad_multiplier = 5, min_n = 8)
stopifnot(any(plaus_checked$age_length_outlier))

la <- length_at_age_summary(x, "age", "length_cm", min_n = 5)
stopifnot(nrow(la) >= 7, all(c("mean_length", "q10", "q90") %in% names(la)))

agree <- reader_agreement(x, "age_reader1", "age_reader2", strata = "period", tolerance = 1)
stopifnot(nrow(agree) == 2, all(agree$within_tolerance == 1), all(agree$exact_agreement < 1))

alk <- make_alk_generic(
  x, "length_cm", "age", strata = c("area", "source"),
  bin_width = 2, min_bin_n = 8
)
prob_sums <- aggregate(p_age_given_length ~ area + source + length_bin, alk, sum)
stopifnot(max(abs(prob_sums$p_age_given_length - 1)) < 1e-10)

train <- x[x$year <= 2021, ]
test <- x[x$year >= 2022, ]
transfer_global <- evaluate_alk_transfer(
  train, test, "length_cm", "age", bin_width = 2,
  min_bin_n = 8, prediction = "expected"
)
transfer_stratified <- evaluate_alk_transfer(
  train, test, "length_cm", "age", strata = c("area", "source"),
  bin_width = 2, min_bin_n = 8, prediction = "expected"
)
stopifnot(
  transfer_global$coverage > 0.80,
  transfer_stratified$coverage > 0.70,
  is.finite(transfer_global$mean_absolute_error),
  is.finite(transfer_stratified$rmse)
)

stability <- age_length_stability(
  x, "year", "age", "length_cm", reference_years = 2018:2021, min_n = 5
)
stopifnot(nrow(stability) > 20, all(c("reference_mean", "deviation") %in% names(stability)))

cat("Reusable age-length diagnostics passed deterministic CI checks.\n")
