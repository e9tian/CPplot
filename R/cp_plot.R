cp_plot <- function(formula = NULL, data, e_hat = NULL, tau_hat = NULL,
                    treatment = NULL, e_method = "logistic", tau_method = "ols",
                    point_labels = c("Control", "Treated"),
                    title = NULL, alpha = 0.45, point_size = 1) {
  point_labels <- validate_point_labels(point_labels)
  if (missing(data)) {
    stop("data must be provided.", call. = FALSE)
  }

  if (!is.null(formula)) {
    if (!is_formula(formula)) {
      stop("formula must be a formula such as y ~ z + x1 + x2.", call. = FALSE)
    }
    if (!is.null(e_hat) || !is.null(tau_hat) || !is.null(treatment)) {
      stop(
        "Use either formula mode or fitted nuisance mode, not both.",
        call. = FALSE
      )
    }
    parsed <- parse_cp_formula(formula)
    data <- estimate_cp_inputs(
      data,
      outcome = parsed$outcome,
      treatment = parsed$treatment,
      covariates = parsed$covariates,
      e_method = e_method,
      tau_method = tau_method
    )
    e_hat <- "e_hat"
    tau_hat <- "tau_hat"
    treatment <- parsed$treatment
  } else if (is.null(e_hat) || is.null(tau_hat)) {
    stop("Provide a formula, or provide e_hat and tau_hat.", call. = FALSE)
  }

  e <- col_data(data, e_hat, "e_hat")
  tau <- col_data(data, tau_hat, "tau_hat")
  z <- col_data(data, treatment, "treatment")
  ok <- finite_complete(e, tau)
  if (!is.null(z)) {
    validate_binary_indicator(z, arg = "treatment")
    ok <- ok & is.finite(z)
  }

  plot_df <- data.frame(e_hat = e[ok], tau_hat = tau[ok])
  if (!is.null(z)) {
    plot_df$group <- binary_group(z[ok], labels = point_labels, arg = "treatment")
  }

  slopes <- cp_slopes(data, e_hat = e_hat, tau_hat = tau_hat, treatment = treatment)
  bracketing <- cp_bracketing(slopes, local = FALSE)
  bracketing_summary <- cp_bracketing_summary(bracketing, local = FALSE)
  labels <- slopes$fit
  colors <- line_palette(labels)
  e_grid <- make_grid(plot_df$e_hat)
  line_df <- cp_line_data(plot_df, labels, e_grid, point_labels, weighted = FALSE)

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = e_hat, y = tau_hat))
  if (is.null(treatment)) {
    p <- p + ggplot2::geom_point(color = "grey55", alpha = alpha, size = point_size)
  } else {
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(shape = group),
        color = "grey45",
        alpha = alpha,
        size = point_size
      ) +
      ggplot2::scale_shape_manual(values = stats::setNames(c(1, 16), point_labels), name = "Points")
  }

  p <- p +
    ggplot2::geom_line(
      data = line_df,
      ggplot2::aes(x = e_hat, y = tau_hat, color = fit, linetype = fit),
      inherit.aes = FALSE,
      linewidth = 0.75
    ) +
    ggplot2::scale_color_manual(values = colors, breaks = labels, name = "Linear fit") +
    ggplot2::scale_linetype_manual(
      values = stats::setNames(c("solid", "dashed", "dotdash")[seq_along(labels)], labels),
      breaks = labels,
      name = "Linear fit"
    ) +
    ggplot2::labs(
      x = expression(hat(e)(X)),
      y = expression(hat(tau)(X)),
      title = title
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::geom_hline(yintercept = 0, linetype = "solid", color = "black", alpha = 0.7)

  new_CPplot_result(
    plot = p,
    slopes = slopes,
    bracketing = bracketing,
    bracketing_summary = bracketing_summary,
    data_used = plot_df
  )
}
