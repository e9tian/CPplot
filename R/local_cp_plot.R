local_cp_plot <- function(formula = NULL, data, e_hat = NULL,
                          tau_c_hat = NULL, pi_c_hat = NULL, iv = NULL,
                          e_method = "logistic", contrast_method = "ols",
                          min_first_stage = 1e-6,
                          point_labels = c("Unencouraged", "Encouraged"),
                          title = NULL, alpha = 0.35, point_size = 0.8) {
  point_labels <- validate_point_labels(point_labels)
  if (missing(data)) {
    stop("data must be provided.", call. = FALSE)
  }

  if (!is.null(formula)) {
    if (!is_formula(formula)) {
      stop("formula must be a formula such as y ~ d + x1 + x2 | z + x1 + x2.", call. = FALSE)
    }
    if (!is.null(e_hat) || !is.null(tau_c_hat) || !is.null(pi_c_hat) || !is.null(iv)) {
      stop(
        "Use either formula mode or fitted nuisance mode, not both.",
        call. = FALSE
      )
    }
    parsed <- parse_local_cp_formula(formula)
    data <- estimate_local_cp_inputs(
      data,
      outcome = parsed$outcome,
      treatment = parsed$treatment,
      instrument = parsed$iv,
      covariates = parsed$covariates,
      e_method = e_method,
      contrast_method = contrast_method,
      min_first_stage = min_first_stage
    )
    e_hat <- "e_hat"
    tau_c_hat <- "tau_c_hat"
    pi_c_hat <- "pi_c_hat"
    iv <- parsed$iv
  } else if (is.null(e_hat) || is.null(tau_c_hat) || is.null(pi_c_hat)) {
    stop("Provide a formula, or provide e_hat, tau_c_hat, and pi_c_hat.", call. = FALSE)
  }

  e <- col_data(data, e_hat, "e_hat")
  tau <- col_data(data, tau_c_hat, "tau_c_hat")
  pi_c <- col_data(data, pi_c_hat, "pi_c_hat")
  z <- col_data(data, iv, "iv")
  ok <- finite_complete(e, tau, pi_c) & pi_c > 0
  if (!is.null(z)) {
    validate_binary_indicator(z, arg = "iv")
    ok <- ok & is.finite(z)
  }

  plot_df <- data.frame(e_hat = e[ok], tau_c_hat = tau[ok], pi_c_hat = pi_c[ok])
  if (!is.null(z)) {
    plot_df$group <- binary_group(z[ok], labels = point_labels, arg = "iv")
  }

  slopes <- local_cp_slopes(
    data,
    e_hat = e_hat,
    tau_c_hat = tau_c_hat,
    pi_c_hat = pi_c_hat,
    iv = iv
  )
  bracketing <- cp_bracketing(slopes, local = TRUE)
  bracketing_summary <- cp_bracketing_summary(bracketing, local = TRUE)
  labels <- slopes$fit
  colors <- line_palette(labels)
  point_colors <- point_palette(point_labels)
  e_grid <- make_grid(plot_df$e_hat)
  line_df <- cp_line_data(plot_df, labels, e_grid, point_labels, weighted = TRUE)

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = e_hat, y = tau_c_hat))
  if (is.null(iv)) {
    p <- p + ggplot2::geom_point(color = "grey55", alpha = alpha, size = point_size)
  } else {
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(shape = group, color = group),
        alpha = alpha,
        size = point_size
      ) +
      ggplot2::scale_shape_manual(values = stats::setNames(c(1, 17), point_labels), name = "Points")
  }

  p <- p +
    ggplot2::geom_line(
      data = line_df,
      ggplot2::aes(x = e_hat, y = tau_c_hat, color = fit, linetype = fit),
      inherit.aes = FALSE,
      linewidth = 0.9
    ) +
    ggplot2::scale_color_manual(
      values = c(point_colors, colors),
      breaks = labels,
      name = "Linear fit"
    ) +
    ggplot2::scale_linetype_manual(
      values = stats::setNames(c("solid", "longdash", "dotdash")[seq_along(labels)], labels),
      breaks = labels,
      name = "Linear fit"
    ) +
    ggplot2::labs(
      x = expression(hat(e)(X)),
      y = expression(hat(tau)^c * (X)),
      title = title
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.text = ggplot2::element_text(size = 7.2),
      legend.title = ggplot2::element_text(size = 8.2),
      legend.key.width = grid::unit(0.55, "cm"),
      legend.spacing.x = grid::unit(0.03, "cm")
    ) +
    ggplot2::guides(
      shape = ggplot2::guide_legend(
        order = 1,
        override.aes = list(
          alpha = 1,
          size = 2,
          color = unname(point_colors)
        )
      ),
      color = ggplot2::guide_legend(order = 2, nrow = 1),
      linetype = ggplot2::guide_legend(order = 2, nrow = 1)
    ) +
    ggplot2::geom_hline(yintercept = 0, linetype = "solid", color = "black", alpha = 0.7)

  new_CPplot_result(
    plot = p,
    slopes = slopes,
    bracketing = bracketing,
    bracketing_summary = bracketing_summary,
    data_used = plot_df
  )
}
