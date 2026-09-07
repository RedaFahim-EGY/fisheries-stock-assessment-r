# Module 05: Age-length consistency before assessment
# Entirely simulated data. No confidential or institutional information.

set.seed(20260907)

# -----------------------------------------------------------------------------
# 1. Simulate an ageing subsample embedded in a structured monitoring design
# -----------------------------------------------------------------------------
years <- 2016:2025
areas <- c("West", "Central", "East")
seasons <- c("Winter", "Spring", "Summer", "Autumn")
sources <- c("commercial", "survey")
gears <- c("trawl", "gillnet")

frame <- expand.grid(year = years, area = areas, season = seasons,
                     source = sources, gear = gears,
                     KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)

# Variable otolith sample sizes create realistic imbalance.
frame$n_aged <- round(22 +
  12 * (frame$source == "survey") +
  8 * (frame$gear == "trawl") +
  6 * (frame$area == "West") +
  rnorm(nrow(frame), 0, 5))
frame$n_aged <- pmax(frame$n_aged, 5)

# Deliberately weak coverage in selected strata.
frame$n_aged[frame$year == 2018 & frame$area == "East" & frame$source == "commercial"] <- 5
frame$n_aged[frame$year == 2022 & frame$season == "Winter" & frame$gear == "gillnet"] <- 6

idx <- rep(seq_len(nrow(frame)), frame$n_aged)
age_dat <- frame[idx, c("year", "area", "season", "source", "gear")]
rownames(age_dat) <- NULL
age_dat$fish_id <- sprintf("AGE-%06d", seq_len(nrow(age_dat)))

# Age composition changes modestly through time, space and observation source.
mu_age <- 2.9 +
  0.05 * (age_dat$year - 2016) +
  0.25 * (age_dat$area == "West") -
  0.20 * (age_dat$area == "East") +
  0.25 * (age_dat$source == "survey") +
  0.20 * (age_dat$gear == "gillnet")

# Negative-binomial-like overdispersion via gamma-poisson mixture, capped at 9.
lambda <- rgamma(nrow(age_dat), shape = 8, rate = 8 / pmax(mu_age, 0.5))
true_age <- pmin(rpois(nrow(age_dat), lambda = lambda), 9)
age_dat$true_age <- true_age

# Von Bertalanffy-like size-at-age with spatial/seasonal/source effects.
Linf <- 58
K <- 0.28
t0 <- -0.45
expected_length <- Linf * (1 - exp(-K * (true_age - t0))) +
  1.0 * (age_dat$area == "West") -
  0.8 * (age_dat$area == "East") +
  0.6 * (age_dat$season == "Summer") -
  0.4 * (age_dat$season == "Winter") +
  0.5 * (age_dat$source == "survey")

age_dat$length_cm <- round(rnorm(nrow(age_dat), expected_length,
                                 sd = 1.5 + 0.25 * sqrt(true_age + 1)), 1)

# Primary reader: mostly correct, with increasing error at older ages.
p_error1 <- pmin(0.06 + 0.035 * true_age, 0.35)
err1 <- rbinom(nrow(age_dat), 1, p_error1)
dir1 <- sample(c(-1, 1), nrow(age_dat), replace = TRUE)
age_dat$age_reader1 <- pmax(0, pmin(9, true_age + err1 * dir1))

# Second reader on a 35% subsample; slightly different bias profile.
read2 <- runif(nrow(age_dat)) < 0.35
p_error2 <- pmin(0.07 + 0.03 * true_age, 0.33)
err2 <- rbinom(nrow(age_dat), 1, p_error2)
dir2 <- sample(c(-1, 1), nrow(age_dat), replace = TRUE,
               prob = c(0.55, 0.45))
age_dat$age_reader2 <- ifelse(read2,
  pmax(0, pmin(9, true_age + err2 * dir2)), NA)

# -----------------------------------------------------------------------------
# 2. Introduce deliberate QC problems
# -----------------------------------------------------------------------------
# Duplicate fish identifier/record.
age_dat <- rbind(age_dat, age_dat[125, ])

# Length unit error (mm entered as cm) and impossible age code.
age_dat$length_cm[311] <- age_dat$length_cm[311] * 10
age_dat$age_reader1[712] <- 19

# Biologically suspicious age-length combinations.
age_dat$length_cm[955] <- 18.2; age_dat$age_reader1[955] <- 8
age_dat$length_cm[1444] <- 54.0; age_dat$age_reader1[1444] <- 0

# Simulated ageing-lab drift: reader 1 tends to over-age older fish in 2024-2025.
drift <- age_dat$year >= 2024 & age_dat$age_reader1 >= 5 & runif(nrow(age_dat)) < 0.28
age_dat$age_reader1[drift] <- pmin(9, age_dat$age_reader1[drift] + 1)

# -----------------------------------------------------------------------------
# 3. Record-level QC
# -----------------------------------------------------------------------------
age_dat$duplicate_id <- duplicated(age_dat$fish_id) |
  duplicated(age_dat$fish_id, fromLast = TRUE)
age_dat$invalid_length <- !is.finite(age_dat$length_cm) |
  age_dat$length_cm < 8 | age_dat$length_cm > 80
age_dat$invalid_age <- !is.finite(age_dat$age_reader1) |
  age_dat$age_reader1 < 0 | age_dat$age_reader1 > 9

valid <- age_dat[!age_dat$duplicate_id & !age_dat$invalid_length & !age_dat$invalid_age, ]

# Robust age-specific length screening using median and MAD.
valid$age_length_outlier <- FALSE
for (a in sort(unique(valid$age_reader1))) {
  ii <- valid$age_reader1 == a
  med <- median(valid$length_cm[ii])
  m <- mad(valid$length_cm[ii], constant = 1)
  if (is.finite(m) && m > 0) valid$age_length_outlier[ii] <- abs(valid$length_cm[ii] - med) > 5 * m
}

# Monotonicity diagnostic: adjacent mean length-at-age should generally increase.
mean_la <- aggregate(length_cm ~ age_reader1, valid, mean)
mean_la$n <- as.integer(table(factor(valid$age_reader1, levels = mean_la$age_reader1)))
mean_la$delta_next_cm <- c(diff(mean_la$length_cm), NA)
mean_la$non_increasing_next <- !is.na(mean_la$delta_next_cm) & mean_la$delta_next_cm <= 0

# -----------------------------------------------------------------------------
# 4. Sampling support by age, year and stratum
# -----------------------------------------------------------------------------
age_support <- as.data.frame(table(valid$year, valid$age_reader1), stringsAsFactors = FALSE)
names(age_support) <- c("year", "age", "n")
age_support$year <- as.integer(as.character(age_support$year))
age_support$age <- as.integer(as.character(age_support$age))

stratum_support <- aggregate(fish_id ~ year + area + season + source + gear,
                             valid, length)
names(stratum_support)[6] <- "n_aged"
stratum_support$weak_support <- stratum_support$n_aged < 15

# -----------------------------------------------------------------------------
# 5. Reader agreement diagnostics
# -----------------------------------------------------------------------------
pair <- valid[!is.na(valid$age_reader2), ]
pair$age_diff <- pair$age_reader1 - pair$age_reader2
pair$exact_agreement <- pair$age_diff == 0
pair$within_one <- abs(pair$age_diff) <= 1

reader_summary <- data.frame(
  n_pairs = nrow(pair),
  exact_agreement = mean(pair$exact_agreement),
  within_one_year = mean(pair$within_one),
  mean_difference = mean(pair$age_diff),
  mean_abs_difference = mean(abs(pair$age_diff))
)

agreement_by_age <- aggregate(cbind(exact_agreement, within_one) ~ age_reader2,
                              pair, mean)
agreement_n <- aggregate(fish_id ~ age_reader2, pair, length)
names(agreement_n)[2] <- "n"
agreement_by_age <- merge(agreement_by_age, agreement_n, by = "age_reader2")

agreement_by_period <- aggregate(age_diff ~ I(ifelse(year <= 2023, "2016-2023", "2024-2025")),
                                 pair, function(x) c(mean = mean(x), mad = mean(abs(x))))
agreement_by_period <- data.frame(
  period = agreement_by_period[[1]],
  mean_diff = agreement_by_period$age_diff[, "mean"],
  mean_abs_diff = agreement_by_period$age_diff[, "mad"]
)

# -----------------------------------------------------------------------------
# 6. Age-length keys (ALKs) and transferability
# -----------------------------------------------------------------------------
valid$length_bin <- floor(valid$length_cm / 2) * 2

make_alk <- function(d) {
  tab <- as.data.frame(table(d$length_bin, d$age_reader1), stringsAsFactors = FALSE)
  names(tab) <- c("length_bin", "age", "n")
  tab$length_bin <- as.numeric(as.character(tab$length_bin))
  tab$age <- as.integer(as.character(tab$age))
  totals <- aggregate(n ~ length_bin, tab, sum)
  names(totals)[2] <- "n_length"
  out <- merge(tab, totals, by = "length_bin")
  out$p_age_given_length <- ifelse(out$n_length > 0, out$n / out$n_length, NA)
  out
}

alk_all <- make_alk(valid)
alk_support <- aggregate(fish_id ~ length_bin, valid, length)
names(alk_support)[2] <- "n_aged"
alk_support$weak_bin <- alk_support$n_aged < 25

# Test transfer: build ALK on 2016-2020, predict modal age for 2021-2025 fish.
train <- valid[valid$year <= 2020, ]
test <- valid[valid$year >= 2021, ]
alk_train <- make_alk(train)
modal <- alk_train[order(alk_train$length_bin, -alk_train$p_age_given_length), ]
modal <- modal[!duplicated(modal$length_bin), c("length_bin", "age", "n_length")]
names(modal)[2] <- "pred_age_global"
test_global <- merge(test, modal, by = "length_bin", all.x = TRUE)
test_global$abs_error_global <- abs(test_global$pred_age_global - test_global$age_reader1)

# Like-for-like ALK: train by area and source, then transfer within same stratum.
strata <- unique(train[, c("area", "source")])
pred_list <- list()
for (i in seq_len(nrow(strata))) {
  tr <- train[train$area == strata$area[i] & train$source == strata$source[i], ]
  te <- test[test$area == strata$area[i] & test$source == strata$source[i], ]
  a <- make_alk(tr)
  m <- a[order(a$length_bin, -a$p_age_given_length), ]
  m <- m[!duplicated(m$length_bin), c("length_bin", "age", "n_length")]
  names(m)[2] <- "pred_age_stratified"
  z <- merge(te, m, by = "length_bin", all.x = TRUE)
  pred_list[[i]] <- z
}
test_strat <- do.call(rbind, pred_list)
test_strat$abs_error_stratified <- abs(test_strat$pred_age_stratified - test_strat$age_reader1)

transfer_summary <- data.frame(
  method = c("global_2016_2020_ALK", "area_source_2016_2020_ALK"),
  coverage = c(mean(!is.na(test_global$pred_age_global)),
               mean(!is.na(test_strat$pred_age_stratified))),
  mean_absolute_age_error = c(mean(test_global$abs_error_global, na.rm = TRUE),
                              mean(test_strat$abs_error_stratified, na.rm = TRUE))
)

# -----------------------------------------------------------------------------
# 7. Temporal stability of length-at-age
# -----------------------------------------------------------------------------
la_year <- aggregate(length_cm ~ year + age_reader1, valid, mean)
ref_la <- aggregate(length_cm ~ age_reader1, valid[valid$year <= 2020, ], mean)
names(ref_la)[2] <- "reference_mean"
la_year <- merge(la_year, ref_la, by = "age_reader1", all.x = TRUE)
la_year$deviation_cm <- la_year$length_cm - la_year$reference_mean

# -----------------------------------------------------------------------------
# 8. Explicit issue register and validation assertions
# -----------------------------------------------------------------------------
issue_register <- data.frame(
  issue = c("duplicate fish ID", "invalid length", "invalid age code",
            "age-length outlier", "weak ageing stratum", "weak ALK length bin",
            "reader disagreement >1 year"),
  count = c(sum(age_dat$duplicate_id), sum(age_dat$invalid_length),
            sum(age_dat$invalid_age), sum(valid$age_length_outlier),
            sum(stratum_support$weak_support), sum(alk_support$weak_bin),
            sum(abs(pair$age_diff) > 1)),
  action = c("resolve duplicate before summaries",
             "verify unit/source record",
             "verify ageing code",
             "inspect image/otolith and biological plausibility",
             "avoid unsupported stratum-specific inference",
             "pool only with explicit justification or increase ageing effort",
             "review readings and reader calibration"),
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(age_dat) > 10000,
  sum(age_dat$duplicate_id) >= 2,
  sum(age_dat$invalid_length) >= 1,
  sum(age_dat$invalid_age) >= 1,
  nrow(pair) > 3000,
  nrow(alk_all) > 50,
  all(transfer_summary$coverage > 0.7)
)

# Objects intentionally left available to the Quarto document:
# age_dat, valid, mean_la, age_support, stratum_support, reader_summary,
# agreement_by_age, agreement_by_period, alk_all, alk_support,
# transfer_summary, la_year, issue_register, pair
