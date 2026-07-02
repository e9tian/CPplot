fit_slope <- function(data, weights = NULL, label) {
  if (!is.null(weights)) {
    if (length(weights) != nrow(data)) {
      stop("weights must have one value per row.", call. = FALSE)
    }
    if (any(weights < 0, na.rm = TRUE)) {
      stop("weights must be nonnegative.", call. = FALSE)
    }
    ok <- is.finite(weights) & weights > 0
    data <- data[ok, , drop = FALSE]
    weights <- weights[ok]
  }

  out <- data.frame(
    fit = label,
    n = nrow(data),
    slope = NA_real_,
    std_error = NA_real_,
    p_value = NA_real_
  )
  if (nrow(data) < 2L || length(unique(data$x)) < 2L) {
    return(out)
  }

  fit_args <- list(formula = y ~ x, data = data)
  if (!is.null(weights)) {
    fit_args$weights <- weights
  }
  fit <- do.call(stats::lm, fit_args)
  sm <- summary(fit)$coefficients
  if (!"x" %in% rownames(sm)) {
    return(out)
  }

  out$slope <- unname(sm["x", "Estimate"])
  out$std_error <- unname(sm["x", "Std. Error"])
  out$p_value <- unname(sm["x", "Pr(>|t|)"])
  out
}

cp_slopes <- function(data, e_hat, tau_hat, treatment = NULL) {
  e <- col_data(data, e_hat, "e_hat")
  tau <- col_data(data, tau_hat, "tau_hat")
  z <- col_data(data, treatment, "treatment")
  ok <- finite_complete(e, tau)
  if (!is.null(z)) {
    validate_binary_indicator(z, arg = "treatment")
    ok <- ok & is.finite(z)
  }

  df <- data.frame(e = e[ok], tau = tau[ok])
  out <- rbind(
    fit_slope(data.frame(y = df$tau, x = df$e), label = "Unweighted"),
    fit_slope(
      data.frame(y = df$tau, x = df$e),
      weights = df$e,
      label = "Treated weighted"
    ),
    fit_slope(
      data.frame(y = df$tau, x = df$e),
      weights = 1 - df$e,
      label = "Control weighted"
    )
  )
  rownames(out) <- NULL
  out
}

local_cp_slopes <- function(data, e_hat, tau_c_hat, pi_c_hat, group = NULL) {
  e <- col_data(data, e_hat, "e_hat")
  tau <- col_data(data, tau_c_hat, "tau_c_hat")
  pi_c <- col_data(data, pi_c_hat, "pi_c_hat")
  z <- col_data(data, group, "group")
  ok <- finite_complete(e, tau, pi_c) & pi_c > 0
  if (!is.null(z)) {
    validate_binary_indicator(z, arg = "group")
    ok <- ok & is.finite(z)
  }

  df <- data.frame(e = e[ok], tau = tau[ok], pi_c = pi_c[ok])
  out <- rbind(
    fit_slope(
      data.frame(y = df$tau, x = df$e),
      weights = df$pi_c,
      label = "Complier weighted"
    ),
    fit_slope(
      data.frame(y = df$tau, x = df$e),
      weights = df$pi_c * df$e,
      label = "Treated-complier weighted"
    ),
    fit_slope(
      data.frame(y = df$tau, x = df$e),
      weights = df$pi_c * (1 - df$e),
      label = "Control-complier weighted"
    )
  )
  rownames(out) <- NULL
  out
}
