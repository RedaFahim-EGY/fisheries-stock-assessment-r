# Fisheries stock assessment in R
# Module 01: Exploring a simulated exploited stock
#
# Purpose
# -------
# Create a simple reproducible fishery time series and inspect annual catch,
# effort, and catch per unit effort (CPUE) before any assessment model is fit.
#
# The dataset is simulated and contains no confidential or institutional data.

set.seed(20260904)

# -----------------------------------------------------------------------------
# 1. Simulate annual fishery information
# -----------------------------------------------------------------------------

year <- 2000:2025
n_years <- length(year)

# A latent relative biomass trajectory used only to generate the example data.
# It declines during the first part of the series and partially rebuilds later.
biomass_rel <- c(
  seq(1.00, 0.48, length.out = 16),
  seq(0.50, 0.72, length.out = n_years - 16)
)

# Fishing effort rises initially and then stabilizes.
effort <- c(
  seq(280, 470, length.out = 14),
  seq(465, 430, length.out = n_years - 14)
)
effort <- round(effort * exp(rnorm(n_years, mean = 0, sd = 0.04)))

# Assume constant catchability for this introductory simulation.
q <- 0.010

# Generate an abundance index around q * biomass, with observation noise.
cpue <- q * biomass_rel * exp(rnorm(n_years, mean = 0, sd = 0.10))

# Catch is generated from effort and CPUE, with additional process variation.
catch_t <- effort * cpue * 1000 * exp(rnorm(n_years, mean = 0, sd = 0.08))

fishery <- data.frame(
  year = year,
  catch_t = round(catch_t, 1),
  effort = effort,
  cpue = round(cpue, 4)
)

# -----------------------------------------------------------------------------
# 2. Basic checks and summaries
# -----------------------------------------------------------------------------

stopifnot(
  all(fishery$catch_t > 0),
  all(fishery$effort > 0),
  all(fishery$cpue > 0),
  !anyNA(fishery)
)

print(head(fishery))
print(summary(fishery))

cat("\nYears covered:", min(fishery$year), "-", max(fishery$year), "\n")
cat("Mean catch (t):", round(mean(fishery$catch_t), 1), "\n")
cat("Mean effort:", round(mean(fishery$effort), 1), "\n")
cat("Mean CPUE:", round(mean(fishery$cpue), 4), "\n")

# -----------------------------------------------------------------------------
# 3. Exploratory plots
# -----------------------------------------------------------------------------

op <- par(mfrow = c(3, 1), mar = c(4, 4, 2, 1))

plot(
  fishery$year,
  fishery$catch_t,
  type = "b",
  pch = 16,
  xlab = "Year",
  ylab = "Catch (t)",
  main = "Annual catch"
)

plot(
  fishery$year,
  fishery$effort,
  type = "b",
  pch = 16,
  xlab = "Year",
  ylab = "Fishing effort",
  main = "Annual fishing effort"
)

plot(
  fishery$year,
  fishery$cpue,
  type = "b",
  pch = 16,
  xlab = "Year",
  ylab = "CPUE",
  main = "Relative abundance index (CPUE)"
)

par(op)

# -----------------------------------------------------------------------------
# 4. Simple trend summaries
# -----------------------------------------------------------------------------

first_five <- fishery[1:5, ]
last_five <- fishery[(nrow(fishery) - 4):nrow(fishery), ]

trend_summary <- data.frame(
  indicator = c("catch_t", "effort", "cpue"),
  first_5_year_mean = c(
    mean(first_five$catch_t),
    mean(first_five$effort),
    mean(first_five$cpue)
  ),
  last_5_year_mean = c(
    mean(last_five$catch_t),
    mean(last_five$effort),
    mean(last_five$cpue)
  )
)

trend_summary$relative_change_pct <- with(
  trend_summary,
  100 * (last_5_year_mean / first_5_year_mean - 1)
)

print(trend_summary)

# -----------------------------------------------------------------------------
# 5. Scientific interpretation
# -----------------------------------------------------------------------------
#
# In this simulated example, increasing fishing effort coincides with a decline
# in CPUE during much of the time series. CPUE later improves as the latent stock
# trajectory partially rebuilds.
#
# This is an exploratory signal, not a stock-status estimate. In a real fishery,
# CPUE may be affected by changes in catchability, technology, targeting,
# spatial distribution, fleet composition, reporting, and environmental effects.
# These issues should be investigated before CPUE is treated as an abundance
# index in an assessment model.
