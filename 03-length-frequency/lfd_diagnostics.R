# Reusable length-frequency diagnostics
#
# Functions in this file are intentionally independent of the simulated Module 03
# dataset. They can be sourced and applied to a user's own individual-length data
# after mapping column names. No assessment model is fitted here.

.check_columns <- function(data, cols) {
  missing <- setdiff(cols, names(data))
  if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
  invisible(TRUE)
}

# Flag record-level problems without deleting observations.
flag_length_records <- function(data, length_col, id_col = NULL,
                                min_length = 0, max_length = Inf) {
  .check_columns(data, c(length_col, id_col))
  out <- data
  x <- out[[length_col]]
  out$length_missing <- is.na(x)
  out$length_nonfinite <- !is.na(x) & !is.finite(x)
  out$length_out_of_range <- is.finite(x) & (x < min_length | x > max_length)
  out$duplicate_id <- FALSE
  if (!is.null(id_col)) {
    z <- out[[id_col]]
    out$duplicate_id <- !is.na(z) & (duplicated(z) | duplicated(z, fromLast = TRUE))
  }
  out
}

# Summarise sampling support across any combination of year/area/fleet/gear/etc.
lfd_coverage <- function(data, strata, id_col = NULL, min_n = 30) {
  .check_columns(data, c(strata, id_col))
  if (!length(strata)) stop("strata must contain at least one column name")
  key <- interaction(data[strata], drop = TRUE, lex.order = TRUE)
  n <- if (is.null(id_col)) as.vector(table(key)) else
    tapply(!is.na(data[[id_col]]), key, sum)
  first <- !duplicated(key)
  out <- data[first, strata, drop = FALSE]
  out$n <- as.integer(n[as.character(key[first])])
  out$weak_support <- out$n < min_n
  rownames(out) <- NULL
  out
}

# Return normalized LFDs so strata with different sample sizes can be compared.
lfd_proportions <- function(data, length_col, strata,
                            bin_width = 1, origin = 0) {
  .check_columns(data, c(length_col, strata))
  if (!is.numeric(bin_width) || length(bin_width) != 1 || bin_width <= 0)
    stop("bin_width must be one positive number")
  x <- data[[length_col]]
  keep <- is.finite(x)
  d <- data[keep, c(strata, length_col), drop = FALSE]
  d$length_bin <- origin + bin_width * floor((d[[length_col]] - origin) / bin_width)
  group_cols <- c(strata, "length_bin")
  key <- interaction(d[group_cols], drop = TRUE, lex.order = TRUE)
  first <- !duplicated(key)
  counts <- d[first, group_cols, drop = FALSE]
  counts$n <- as.integer(table(key)[as.character(key[first])])
  stratum_key <- interaction(counts[strata], drop = TRUE, lex.order = TRUE)
  totals <- ave(counts$n, stratum_key, FUN = sum)
  counts$proportion <- counts$n / totals
  rownames(counts) <- NULL
  counts
}

# Digit-preference diagnostic. A high proportion on coarse grid points can flag
# rounding/heaping, but should be interpreted against the measurement protocol.
length_heaping <- function(data, length_col, strata = character(),
                           heaping_interval = 5, tolerance = 1e-8) {
  .check_columns(data, c(length_col, strata))
  x <- data[[length_col]]
  heaped <- is.finite(x) & abs(x / heaping_interval - round(x / heaping_interval)) <= tolerance
  d <- data
  d$.heaped <- heaped
  d$.valid <- is.finite(x)
  if (!length(strata)) {
    n <- sum(d$.valid)
    return(data.frame(n = n, n_heaped = sum(d$.heaped),
      proportion_heaped = if (n) sum(d$.heaped) / n else NA_real_))
  }
  key <- interaction(d[strata], drop = TRUE, lex.order = TRUE)
  first <- !duplicated(key)
  out <- d[first, strata, drop = FALSE]
  out$n <- as.integer(tapply(d$.valid, key, sum)[as.character(key[first])])
  out$n_heaped <- as.integer(tapply(d$.heaped, key, sum)[as.character(key[first])])
  out$proportion_heaped <- ifelse(out$n > 0, out$n_heaped / out$n, NA_real_)
  rownames(out) <- NULL
  out
}

# Jensen-Shannon divergence between two normalized discrete LFDs. The value is
# bounded from 0 (identical) to log(2) using natural logarithms.
js_divergence <- function(p, q) {
  if (length(p) != length(q)) stop("p and q must have equal length")
  if (any(!is.finite(p)) || any(!is.finite(q)) || any(p < 0) || any(q < 0))
    stop("p and q must be finite and non-negative")
  if (sum(p) <= 0 || sum(q) <= 0) return(NA_real_)
  p <- p / sum(p); q <- q / sum(q); m <- 0.5 * (p + q)
  kl <- function(a, b) sum(ifelse(a > 0, a * log(a / b), 0))
  0.5 * kl(p, m) + 0.5 * kl(q, m)
}

# Compare two samples on a common length-bin support.
compare_lfd <- function(x, y, bin_width = 1, origin = 0) {
  x <- x[is.finite(x)]; y <- y[is.finite(y)]
  if (!length(x) || !length(y)) stop("Both samples need finite lengths")
  lo <- min(c(x, y)); hi <- max(c(x, y))
  bins <- seq(origin + bin_width * floor((lo - origin) / bin_width),
              origin + bin_width * ceiling((hi - origin) / bin_width), by = bin_width)
  if (length(bins) < 2) bins <- c(bins, bins + bin_width)
  px <- hist(x, breaks = bins, plot = FALSE, right = FALSE)$counts
  py <- hist(y, breaks = bins, plot = FALSE, right = FALSE)$counts
  data.frame(
    n_x = length(x), n_y = length(y),
    mean_difference = mean(y) - mean(x),
    median_difference = median(y) - median(x),
    js_divergence = js_divergence(px, py),
    ks_statistic = unname(stats::ks.test(x, y)$statistic),
    stringsAsFactors = FALSE
  )
}

# Sensitivity check for a known sampling-scope flag (e.g. full vs marketable-only).
compare_measurement_scope <- function(data, length_col, scope_col,
                                      full_value = "full", bin_width = 1) {
  .check_columns(data, c(length_col, scope_col))
  all_x <- data[[length_col]]
  full_x <- data[[length_col]][data[[scope_col]] == full_value]
  result <- compare_lfd(all_x, full_x, bin_width = bin_width)
  result$comparison <- paste0("all records vs ", full_value, " scope only")
  result
}
