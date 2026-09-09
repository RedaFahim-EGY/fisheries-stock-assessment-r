# Reusable natural-mortality estimators for Module 06
#
# These functions expose the assumptions and required inputs for several commonly
# used empirical estimators of natural mortality (M). They are intended for
# comparison and sensitivity analysis, not for selecting a universally "best" M.
#
# Units used here:
#   Linf, L: cm
#   K: year^-1
#   temperature: degrees C
#   tmax: years
#   M: year^-1

.check_positive <- function(x, name) {
  if (any(!is.finite(x)) || any(x <= 0)) {
    stop(name, " must contain finite positive values.")
  }
  invisible(TRUE)
}

# Pauly (1980): temperature- and growth-based scalar M.
# log10(M) = -0.0066 - 0.279 log10(Linf) + 0.6543 log10(K)
#            + 0.4634 log10(T)
M_pauly1980 <- function(Linf_cm, K, temperature_C) {
  .check_positive(Linf_cm, "Linf_cm")
  .check_positive(K, "K")
  .check_positive(temperature_C, "temperature_C")

  10^(
    -0.0066 - 0.279 * log10(Linf_cm) +
      0.6543 * log10(K) +
      0.4634 * log10(temperature_C)
  )
}

# Hoenig (1983), teleost longevity relationship.
# Original relationship predicts total mortality Z from maximum age. It is often
# used as a proxy for M only when fishing mortality is negligible or as a
# comparative life-history diagnostic. Do not silently equate Z and M.
M_hoenig1983_proxy <- function(tmax_years) {
  .check_positive(tmax_years, "tmax_years")
  exp(1.46 - 1.01 * log(tmax_years))
}

# Then et al. (2015): recommended tmax-based empirical estimator.
M_then2015_tmax <- function(tmax_years) {
  .check_positive(tmax_years, "tmax_years")
  4.899 * tmax_years^(-0.916)
}

# Then et al. (2015): growth-based estimator, with Linf in cm.
# The 2018 correction to the paper clarified the Linf unit convention.
M_then2015_growth <- function(Linf_cm, K) {
  .check_positive(Linf_cm, "Linf_cm")
  .check_positive(K, "K")
  4.118 * K^0.73 * Linf_cm^(-0.33)
}

# Gislason et al. (2010): length-dependent M.
# ln(M) = 0.55 - 1.61 ln(L) + 1.44 ln(Linf) + ln(K)
M_gislason2010 <- function(L_cm, Linf_cm, K) {
  .check_positive(L_cm, "L_cm")
  .check_positive(Linf_cm, "Linf_cm")
  .check_positive(K, "K")
  if (length(Linf_cm) != 1L && length(Linf_cm) != length(L_cm)) {
    stop("Linf_cm must be scalar or the same length as L_cm.")
  }
  if (length(K) != 1L && length(K) != length(L_cm)) {
    stop("K must be scalar or the same length as L_cm.")
  }

  exp(0.55 - 1.61 * log(L_cm) + 1.44 * log(Linf_cm) + log(K))
}

vb_length_at_age <- function(age, Linf_cm, K, t0) {
  .check_positive(Linf_cm, "Linf_cm")
  .check_positive(K, "K")
  if (any(!is.finite(age)) || any(!is.finite(t0))) {
    stop("age and t0 must be finite.")
  }
  Linf_cm * (1 - exp(-K * (age - t0)))
}

# Compare scalar estimators for one set of life-history inputs.
# The Hoenig value is retained under an explicit 'proxy' label because the
# original estimator targets Z rather than M directly.
compare_scalar_M <- function(Linf_cm, K, temperature_C, tmax_years) {
  data.frame(
    method = c(
      "Pauly (1980)",
      "Hoenig (1983) longevity proxy",
      "Then et al. (2015) tmax",
      "Then et al. (2015) growth"
    ),
    M = c(
      M_pauly1980(Linf_cm, K, temperature_C),
      M_hoenig1983_proxy(tmax_years),
      M_then2015_tmax(tmax_years),
      M_then2015_growth(Linf_cm, K)
    ),
    estimator_type = c(
      "scalar; growth + temperature",
      "scalar; longevity relationship for Z",
      "scalar; maximum age",
      "scalar; growth"
    ),
    stringsAsFactors = FALSE
  )
}

# Produce a length/age-dependent Gislason vector from von Bertalanffy inputs.
M_gislason_at_age <- function(age, Linf_cm, K, t0) {
  L <- vb_length_at_age(age, Linf_cm, K, t0)
  keep <- is.finite(L) & L > 0
  out <- data.frame(age = age, length_cm = L, M = NA_real_)
  out$M[keep] <- M_gislason2010(L[keep], Linf_cm, K)
  out
}
