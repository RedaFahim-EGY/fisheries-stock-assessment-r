# Reusable age-length and ageing diagnostics
#
# These functions are independent of the simulated Module 05 dataset. They are
# intended for adapting the workflow to real ageing data after explicit mapping
# of column names and stock-specific choices. No stock-assessment model is fitted.

.check_columns_age <- function(data, cols) {
  cols <- cols[!is.na(cols) & nzchar(cols)]
  missing <- setdiff(cols, names(data))
  if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
  invisible(TRUE)
}

# Flag record-level issues without automatically deleting observations.
flag_age_length_records <- function(data, length_col, age_col, id_col = NULL,
                                    min_length = 0, max_length = Inf,
                                    min_age = 0, max_age = Inf) {
  .check_columns_age(data, c(length_col, age_col, id_col))
  out <- data
  L <- out[[length_col]]
  A <- out[[age_col]]

  out$length_missing <- is.na(L)
  out$length_nonfinite <- !is.na(L) & !is.finite(L)
  out$length_out_of_range <- is.finite(L) & (L < min_length | L > max_length)
  out$age_missing <- is.na(A)
  out$age_nonfinite <- !is.na(A) & !is.finite(A)
  out$age_out_of_range <- is.finite(A) & (A < min_age | A > max_age)
  out$age_noninteger <- is.finite(A) & abs(A - round(A)) > sqrt(.Machine$double.eps)
  out$duplicate_id <- FALSE

  if (!is.null(id_col)) {
    id <- out[[id_col]]
    out$duplicate_id <- !is.na(id) & (duplicated(id) | duplicated(id, fromLast = TRUE))
  }
  out
}

# Summarise support across any ageing-sampling strata, e.g.
# year x area x season x source x gear.
ageing_coverage <- function(data, strata, id_col = NULL, min_n = 15) {
  .check_columns_age(data, c(strata, id_col))
  if (!length(strata)) stop("strata must contain at least one column name")
  if (!is.numeric(min_n) || length(min_n) != 1 || min_n < 1)
    stop("min_n must be one positive number")

  key <- interaction(data[strata], drop = TRUE, lex.order = TRUE)
  first <- !duplicated(key)
  out <- data[first, strata, drop = FALSE]
  if (is.null(id_col)) {
    counts <- table(key)
  } else {
    counts <- tapply(!is.na(data[[id_col]]), key, sum)
  }
  out$n_aged <- as.integer(counts[as.character(key[first])])
  out$weak_support <- out$n_aged < min_n
  rownames(out) <- NULL
  out
}

# Robust within-age screening of suspicious length-at-age combinations.
# The returned object contains the original records plus group-level median/MAD
# diagnostics and a flag. Small age groups can be retained but are not flagged.
age_length_outliers <- function(data, age_col, length_col,
                                mad_multiplier = 5, min_n = 8) {
  .check_columns_age(data, c(age_col, length_col))
  if (mad_multiplier <= 0 || min_n < 2) stop("mad_multiplier and min_n must be positive")
  out <- data
  A <- out[[age_col]]
  L <- out[[length_col]]
  out$age_length_group_n <- NA_integer_
  out$age_length_median <- NA_real_
  out$age_length_mad <- NA_real_
  out$age_length_outlier <- FALSE

  ages <- sort(unique(A[is.finite(A)]))
  for (a in ages) {
    ii <- is.finite(A) & A == a & is.finite(L)
    n <- sum(ii)
    med <- if (n) median(L[ii]) else NA_real_
    m <- if (n > 1) mad(L[ii], constant = 1) else NA_real_
    out$age_length_group_n[ii] <- n
    out$age_length_median[ii] <- med
    out$age_length_mad[ii] <- m
    if (n >= min_n && is.finite(m) && m > 0) {
      out$age_length_outlier[ii] <- abs(L[ii] - med) > mad_multiplier * m
    }
  }
  out
}

# Age-specific length summaries with a simple monotonicity diagnostic.
length_at_age_summary <- function(data, age_col, length_col, min_n = 5) {
  .check_columns_age(data, c(age_col, length_col))
  keep <- is.finite(data[[age_col]]) & is.finite(data[[length_col]])
  d <- data[keep, c(age_col, length_col), drop = FALSE]
  if (!nrow(d)) stop("No finite age-length records available")

  ages <- sort(unique(d[[age_col]]))
  out <- do.call(rbind, lapply(ages, function(a) {
    x <- d[[length_col]][d[[age_col]] == a]
    data.frame(
      age = a, n = length(x), mean_length = mean(x), median_length = median(x),
      sd_length = if (length(x) > 1) sd(x) else NA_real_,
      q10 = unname(quantile(x, 0.10, names = FALSE)),
      q90 = unname(quantile(x, 0.90, names = FALSE)),
      stringsAsFactors = FALSE
    )
  }))
  out$adequate_support <- out$n >= min_n
  out$delta_mean_to_next <- c(diff(out$mean_length), NA_real_)
  out$non_increasing_next <- !is.na(out$delta_mean_to_next) &
    out$adequate_support & c(out$adequate_support[-1], FALSE) &
    out$delta_mean_to_next <= 0
  out
}

# Paired-reader agreement. Optional strata permit comparison by period, reader
# pair, laboratory, source, etc. No arbitrary acceptable-agreement threshold is
# imposed; the analyst interprets the diagnostics in context.
reader_agreement <- function(data, reader1_col, reader2_col,
                             strata = character(), tolerance = 1) {
  .check_columns_age(data, c(reader1_col, reader2_col, strata))
  if (tolerance < 0) stop("tolerance must be non-negative")
  keep <- is.finite(data[[reader1_col]]) & is.finite(data[[reader2_col]])
  d <- data[keep, c(strata, reader1_col, reader2_col), drop = FALSE]
  if (!nrow(d)) stop("No paired finite readings available")
  d$.diff <- d[[reader1_col]] - d[[reader2_col]]

  summarize_one <- function(z) {
    data.frame(
      n_pairs = nrow(z),
      exact_agreement = mean(z$.diff == 0),
      within_tolerance = mean(abs(z$.diff) <= tolerance),
      mean_difference = mean(z$.diff),
      mean_absolute_difference = mean(abs(z$.diff)),
      rmse_difference = sqrt(mean(z$.diff^2)),
      stringsAsFactors = FALSE
    )
  }

  if (!length(strata)) return(summarize_one(d))
  key <- interaction(d[strata], drop = TRUE, lex.order = TRUE)
  groups <- split(seq_len(nrow(d)), key)
  result <- lapply(groups, function(ii) cbind(d[ii[1], strata, drop = FALSE], summarize_one(d[ii, , drop = FALSE])))
  out <- do.call(rbind, result)
  rownames(out) <- NULL
  out
}

# Construct an age-length key (ALK), optionally by strata. Probabilities sum to
# one within each length-bin x stratum combination. Support is retained so sparse
# cells remain visible rather than silently treated as reliable.
make_alk_generic <- function(data, length_col, age_col, strata = character(),
                             bin_width = 2, origin = 0, min_bin_n = 25) {
  .check_columns_age(data, c(length_col, age_col, strata))
  if (bin_width <= 0 || min_bin_n < 1) stop("bin_width and min_bin_n must be positive")
  keep <- is.finite(data[[length_col]]) & is.finite(data[[age_col]])
  d <- data[keep, c(strata, length_col, age_col), drop = FALSE]
  if (!nrow(d)) stop("No finite age-length records available")
  d$length_bin <- origin + bin_width * floor((d[[length_col]] - origin) / bin_width)
  d$age <- d[[age_col]]

  cell_cols <- c(strata, "length_bin", "age")
  key <- interaction(d[cell_cols], drop = TRUE, lex.order = TRUE)
  first <- !duplicated(key)
  cells <- d[first, cell_cols, drop = FALSE]
  cells$n <- as.integer(table(key)[as.character(key[first])])

  bin_cols <- c(strata, "length_bin")
  bin_key <- interaction(cells[bin_cols], drop = TRUE, lex.order = TRUE)
  cells$n_length <- ave(cells$n, bin_key, FUN = sum)
  cells$p_age_given_length <- cells$n / cells$n_length
  cells$weak_bin <- cells$n_length < min_bin_n
  rownames(cells) <- NULL
  cells
}

# Apply an ALK to individual lengths. 'expected' retains the full age
# probability vector; 'modal' uses the most likely age. Rows outside ALK support
# receive NA predictions and remain visible in coverage metrics.
apply_alk <- function(data, alk, length_col, strata = character(),
                      bin_width = 2, origin = 0,
                      prediction = c("expected", "modal")) {
  prediction <- match.arg(prediction)
  .check_columns_age(data, c(length_col, strata))
  .check_columns_age(alk, c(strata, "length_bin", "age", "p_age_given_length"))

  d <- data
  d$length_bin <- origin + bin_width * floor((d[[length_col]] - origin) / bin_width)
  join_cols <- c(strata, "length_bin")
  d$.row_id_alk <- seq_len(nrow(d))
  merged <- merge(d[c(".row_id_alk", join_cols)], alk, by = join_cols, all.x = TRUE)

  pred <- rep(NA_real_, nrow(d))
  groups <- split(seq_len(nrow(merged)), merged$.row_id_alk)
  for (nm in names(groups)) {
    ii <- groups[[nm]]
    z <- merged[ii, , drop = FALSE]
    ok <- is.finite(z$age) & is.finite(z$p_age_given_length)
    if (!any(ok)) next
    if (prediction == "expected") {
      p <- z$p_age_given_length[ok]
      pred[as.integer(nm)] <- sum(z$age[ok] * p) / sum(p)
    } else {
      zz <- z[ok, , drop = FALSE]
      pred[as.integer(nm)] <- zz$age[which.max(zz$p_age_given_length)]
    }
  }
  pred
}

# Quantify historical/contemporary ALK transferability on an independent test
# period. This reports support coverage and prediction error; a high coverage
# value alone does not demonstrate biological transferability.
evaluate_alk_transfer <- function(train, test, length_col, age_col,
                                  strata = character(), bin_width = 2,
                                  origin = 0, min_bin_n = 25,
                                  prediction = c("expected", "modal")) {
  prediction <- match.arg(prediction)
  alk <- make_alk_generic(train, length_col, age_col, strata,
                          bin_width, origin, min_bin_n)
  pred <- apply_alk(test, alk, length_col, strata, bin_width, origin, prediction)
  obs <- test[[age_col]]
  ok <- is.finite(pred) & is.finite(obs)
  data.frame(
    prediction = prediction,
    n_test = length(obs),
    n_predicted = sum(ok),
    coverage = mean(is.finite(pred)),
    mean_error = if (any(ok)) mean(pred[ok] - obs[ok]) else NA_real_,
    mean_absolute_error = if (any(ok)) mean(abs(pred[ok] - obs[ok])) else NA_real_,
    rmse = if (any(ok)) sqrt(mean((pred[ok] - obs[ok])^2)) else NA_real_,
    stringsAsFactors = FALSE
  )
}

# Compare length-at-age across time against an explicitly chosen reference set.
# This is descriptive: deviations can reflect biology, ageing practice, sampling
# composition, or all three, and should be investigated rather than auto-corrected.
age_length_stability <- function(data, year_col, age_col, length_col,
                                 reference_years, min_n = 10) {
  .check_columns_age(data, c(year_col, age_col, length_col))
  keep <- is.finite(data[[year_col]]) & is.finite(data[[age_col]]) & is.finite(data[[length_col]])
  d <- data[keep, , drop = FALSE]
  if (!nrow(d)) stop("No finite records available")
  ref <- d[d[[year_col]] %in% reference_years, , drop = FALSE]
  if (!nrow(ref)) stop("No records fall within reference_years")

  ref_mean <- tapply(ref[[length_col]], ref[[age_col]], mean)
  key <- interaction(d[[year_col]], d[[age_col]], drop = TRUE, lex.order = TRUE)
  groups <- split(seq_len(nrow(d)), key)
  out <- lapply(groups, function(ii) {
    y <- d[[year_col]][ii[1]]; a <- d[[age_col]][ii[1]]; x <- d[[length_col]][ii]
    r <- ref_mean[as.character(a)]
    data.frame(year = y, age = a, n = length(x), mean_length = mean(x),
               reference_mean = unname(r), deviation = mean(x) - unname(r),
               adequate_support = length(x) >= min_n, stringsAsFactors = FALSE)
  })
  ans <- do.call(rbind, out)
  rownames(ans) <- NULL
  ans[order(ans$age, ans$year), ]
}
