local_cp_plot <- function(data, e_hat, tau_c_hat, pi_c_hat, group = NULL,
                          point_labels = c("Control", "Treated"),
                          title = NULL, alpha = 0.35, point_size = 0.8) {
  point_labels <- validate_point_labels(point_labels)
  e <- col_data(data, e_hat, "e_hat")
  tau <- col_data(data, tau_c_hat, "tau_c_hat")
  pi_c <- col_data(data, pi_c_hat, "pi_c_hat")
  z <- col_data(data, group, "group")
  ok <- finite_complete(e, tau, pi_c) & pi_c > 0
  if (!is.null(z)) {
    validate_binary_indicator(z, arg = "group")
    ok <- ok & is.finite(z)
  }

  plot_df <- data.frame(e_hat = e[ok], tau_c_hat = tau[ok], pi_c_hat = pi_c[ok])
  if (!is.null(z)) {
    plot_df$group <- binary_group(z[ok], labels = point_labels, arg = "group")
  }

  slopes <- local_cp_slopes(
    data,
    e_hat = e_hat,
    tau_c_hat = tau_c_hat,
    pi_c_hat = pi_c_hat,
    group = group
  )
  bracketing <- cp_bracketing(slopes, local = TRUE)
  bracketing_summary <- cp_bracketing_summary(bracketing, local = TRUE)
  labels <- slopes$fit
  colors <- line_palette(labels)
  e_grid <- make_grid(plot_df$e_hat)
  line_df <- cp_line_data(plot_df, labels, e_grid, point_labels, weighted = TRUE)

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = e_hat, y = tau_c_hat))
  if (is.null(group)) {
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
      ggplot2::aes(x = e_hat, y = tau_c_hat, color = fit, linetype = fit),
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
      y = expression(hat(tau)^c * (X)),
      title = title
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.text = ggplot2::element_text(size = 8),
      legend.title = ggplot2::element_text(size = 9),
      legend.key.width = grid::unit(0.7, "cm"),
      legend.spacing.x = grid::unit(0.08, "cm")
    ) +
    ggplot2::guides(
      shape = ggplot2::guide_legend(order = 1, override.aes = list(alpha = 1, size = 2)),
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
