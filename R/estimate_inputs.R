rhs_formula <- function(lhs, x) {
  if (!is.character(x) || length(x) < 1L) {
    stop("covariates must contain at least one covariate column name.", call. = FALSE)
  }
  stats::as.formula(paste(lhs, "~", paste(x, collapse = " + ")))
}

match_estimation_method <- function(method, choices, arg) {
  if (!is.character(method) || length(method) != 1L) {
    stop(arg, " must be a single character string.", call. = FALSE)
  }
  if (!method %in% choices) {
    stop(arg, " must be one of: ", paste(choices, collapse = ", "), call. = FALSE)
  }
  method
}

validate_estimation_columns <- function(data, outcome, treatment, covariates) {
  col_data(data, outcome, "outcome")
  tv <- col_data(data, treatment, "treatment")
  for (nm in covariates) {
    col_data(data, nm, "covariates")
  }
  validate_binary_indicator(tv, arg = "treatment")
  if (!any(tv == 1, na.rm = TRUE) || !any(tv == 0, na.rm = TRUE)) {
    stop("treatment must contain both 0 and 1.", call. = FALSE)
  }
  invisible(tv)
}

require_ranger <- function() {
  if (!requireNamespace("ranger", quietly = TRUE)) {
    stop(
      "Package 'ranger' is required for random_forest methods. ",
      "Install it with install.packages('ranger').",
      call. = FALSE
    )
  }
}

binary_probability <- function(predictions) {
  if (is.null(dim(predictions))) {
    return(as.numeric(predictions))
  }
  if ("1" %in% colnames(predictions)) {
    return(as.numeric(predictions[, "1"]))
  }
  as.numeric(predictions[, ncol(predictions)])
}

predict_conditional_mean <- function(data, response, covariates, newdata,
                                     method, family = stats::binomial()) {
  formula <- rhs_formula(response, covariates)
  if (method == "ols") {
    fit <- stats::lm(formula, data = data)
    return(as.numeric(stats::predict(fit, newdata = newdata)))
  }

  if (method == "logistic") {
    fit <- stats::glm(formula, data = data, family = family)
    return(as.numeric(stats::predict(fit, newdata = newdata, type = "response")))
  }

  if (method == "random_forest") {
    require_ranger()
    rf_data <- data
    probability <- FALSE
    if (all(stats::na.omit(unique(rf_data[[response]])) %in% c(0, 1))) {
      rf_data[[response]] <- factor(rf_data[[response]], levels = c(0, 1))
      probability <- TRUE
    }
    fit <- ranger::ranger(formula, data = rf_data, probability = probability)
    pred <- stats::predict(fit, data = newdata)$predictions
    if (probability) {
      return(binary_probability(pred))
    }
    return(as.numeric(pred))
  }

  stop("Unknown estimation method: ", method, call. = FALSE)
}

estimate_cp_inputs <- function(data, outcome, treatment, covariates,
                               e_method = "logistic",
                               tau_method = "ols",
                               family = stats::binomial()) {
  e_method <- match_estimation_method(e_method, c("logistic", "random_forest"), "e_method")
  tau_method <- match_estimation_method(tau_method, c("ols", "random_forest"), "tau_method")
  tv <- validate_estimation_columns(data, outcome, treatment, covariates)

  e_hat <- predict_conditional_mean(
    data = data,
    response = treatment,
    covariates = covariates,
    newdata = data,
    method = e_method,
    family = family
  )
  data_treated <- data[tv == 1, , drop = FALSE]
  data_control <- data[tv == 0, , drop = FALSE]
  mu1 <- predict_conditional_mean(
    data = data_treated,
    response = outcome,
    covariates = covariates,
    newdata = data,
    method = tau_method,
    family = family
  )
  mu0 <- predict_conditional_mean(
    data = data_control,
    response = outcome,
    covariates = covariates,
    newdata = data,
    method = tau_method,
    family = family
  )
  tau_hat <- as.numeric(mu1 - mu0)

  out <- data
  out$e_hat <- e_hat
  out$tau_hat <- tau_hat
  out
}

estimate_local_cp_inputs <- function(data, outcome, treatment, instrument, covariates,
                                     e_method = "logistic",
                                     contrast_method = "ols",
                                     family = stats::binomial(),
                                     min_first_stage = 1e-6) {
  e_method <- match_estimation_method(e_method, c("logistic", "random_forest"), "e_method")
  contrast_method <- match_estimation_method(contrast_method, c("ols", "random_forest"), "contrast_method")
  zv <- col_data(data, instrument, "instrument")
  for (nm in c(outcome, treatment, covariates)) {
    col_data(data, nm, "column")
  }
  validate_binary_indicator(zv, arg = "instrument")

  e_hat <- predict_conditional_mean(
    data = data,
    response = instrument,
    covariates = covariates,
    newdata = data,
    method = e_method,
    family = family
  )
  data_z1 <- data[zv == 1, , drop = FALSE]
  data_z0 <- data[zv == 0, , drop = FALSE]
  y1 <- predict_conditional_mean(data_z1, outcome, covariates, data, contrast_method, family)
  y0 <- predict_conditional_mean(data_z0, outcome, covariates, data, contrast_method, family)
  d1 <- predict_conditional_mean(data_z1, treatment, covariates, data, contrast_method, family)
  d0 <- predict_conditional_mean(data_z0, treatment, covariates, data, contrast_method, family)
  delta_y <- as.numeric(y1 - y0)
  delta_d <- as.numeric(d1 - d0)
  tau_c_hat <- delta_y / delta_d
  tau_c_hat[!is.finite(tau_c_hat) | abs(delta_d) <= min_first_stage] <- NA_real_

  out <- data
  out$e_hat <- e_hat
  out$delta_y <- delta_y
  out$delta_d <- delta_d
  out$pi_c_hat <- delta_d
  out$tau_c_hat <- tau_c_hat
  out
}
