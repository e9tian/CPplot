col_data <- function(data, col, arg) {
  if (is.null(col)) {
    return(NULL)
  }
  if (!is.character(col) || length(col) != 1L) {
    stop(arg, " must be a single character column name.", call. = FALSE)
  }
  if (!col %in% names(data)) {
    stop(arg, " column not found in data: ", col, call. = FALSE)
  }
  out <- data[[col]]
  if (length(out) != nrow(data)) {
    stop(arg, " must have one value per row of data.", call. = FALSE)
  }
  out
}

finite_complete <- function(...) {
  vals <- list(...)
  if (length(vals) == 0L) {
    return(logical())
  }
  ok <- rep(TRUE, length(vals[[1L]]))
  for (v in vals) {
    ok <- ok & is.finite(v)
  }
  ok
}

validate_point_labels <- function(labels) {
  if (!is.character(labels) || length(labels) != 2L || anyNA(labels)) {
    stop("point_labels must be a character vector of length 2.", call. = FALSE)
  }
  if (any(labels == "")) {
    stop("point_labels cannot contain empty strings.", call. = FALSE)
  }
  if (length(unique(labels)) != 2L) {
    stop("point_labels must contain two distinct labels.", call. = FALSE)
  }
  labels
}

validate_binary_indicator <- function(x, arg = "group") {
  ux <- sort(unique(x[is.finite(x)]))
  if (!all(ux %in% c(0, 1))) {
    stop(arg, " must contain only 0/1 values.", call. = FALSE)
  }
  invisible(TRUE)
}

binary_group <- function(x, labels = c("Control", "Treated"), arg = "group") {
  labels <- validate_point_labels(labels)
  validate_binary_indicator(x, arg = arg)
  factor(ifelse(x == 1, labels[[2L]], labels[[1L]]), levels = labels)
}

make_grid <- function(x, n = 100L) {
  seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE), length.out = n)
}

line_palette <- function(labels) {
  stats::setNames(c("#252525", "#0072B2", "#D55E00")[seq_along(labels)], labels)
}

point_palette <- function(labels) {
  labels <- validate_point_labels(labels)
  stats::setNames(c("#D55E00", "#0072B2"), labels)
}

fit_line <- function(fit_data, response, e_grid, weights = NULL) {
  if (!is.null(weights)) {
    if (any(weights < 0, na.rm = TRUE)) {
      stop("weights must be nonnegative.", call. = FALSE)
    }
    ok <- is.finite(weights) & weights > 0
    fit_data <- fit_data[ok, , drop = FALSE]
    weights <- weights[ok]
  }

  line_y <- rep(NA_real_, length(e_grid))
  if (nrow(fit_data) < 2L || length(unique(fit_data$e_hat)) < 2L) {
    return(line_y)
  }

  fit_args <- list(
    formula = stats::as.formula(paste(response, "~ e_hat")),
    data = fit_data
  )
  if (!is.null(weights)) {
    fit_args$weights <- weights
  }

  fit <- do.call(stats::lm, fit_args)
  as.numeric(stats::predict(fit, newdata = data.frame(e_hat = e_grid)))
}

cp_line_data <- function(plot_df, labels, e_grid, point_labels, weighted = FALSE) {
  y_col <- if (weighted) "tau_c_hat" else "tau_hat"
  do.call(rbind, lapply(seq_along(labels), function(i) {
    if (weighted) {
      weights <- switch(
        i,
        plot_df$pi_c_hat,
        plot_df$pi_c_hat * plot_df$e_hat,
        plot_df$pi_c_hat * (1 - plot_df$e_hat)
      )
      line_y <- fit_line(plot_df, response = y_col, e_grid = e_grid, weights = weights)
    } else {
      weights <- switch(i, NULL, plot_df$e_hat, 1 - plot_df$e_hat)
      line_y <- fit_line(plot_df, response = y_col, e_grid = e_grid, weights = weights)
    }

    out <- data.frame(e_hat = e_grid, fit = labels[[i]])
    out[[y_col]] <- line_y
    out
  }))
}
