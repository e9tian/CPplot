# Reproduce paper diagnostic plots with causalcp.
#
# By default, this script uses the paper intermediate outputs bundled with the
# package:
# - res_data/*_data.RData
# - tab_401k_unit_conditional_wald.csv
#
# Example:
# source(system.file("paper-examples/reproduce-paper-plots.R", package = "causalcp"))
# reproduce_paper_plots()
#
# To use locally regenerated paper outputs instead, pass paper_dir explicitly.

bundled_paper_dir <- function() {
  causalcp::paper_data_dir()
}

load_cp_dataframe <- function(file) {
  env <- new.env(parent = emptyenv())
  load(file, envir = env)
  objs <- as.list(env)

  if ("a" %in% names(objs) && is.data.frame(objs[["a"]])) {
    return(objs[["a"]])
  }

  dfs <- Filter(is.data.frame, objs)
  for (df in dfs) {
    if (all(c("propensity_scores", "tau_hat") %in% names(df))) {
      return(df)
    }
  }

  if (length(dfs) > 0L) {
    return(dfs[[1L]])
  }

  stop("No data frame found in ", file, call. = FALSE)
}

paper_treatment_vars <- c(
  abortion = "repeal",
  adult_servicesHot = "hot",
  adult_servicesReg = "reg",
  adult_servicesUnsafe = "unsafe",
  black_politicians = "treat_out",
  cavities_smoking = "secondhand.smoking.exposure",
  ccdrug = "male",
  rhc = "treatment.swang"
)

paper_title_labels <- c(
  adult_servicesHot = "adult_services (hot)",
  adult_servicesReg = "adult_services (reg)",
  adult_servicesUnsafe = "adult_services (unsafe)"
)

make_paper_cp_plot <- function(file) {
  setting <- sub("_data[.]RData$", "", basename(file))
  df <- load_cp_dataframe(file)

  required <- c("propensity_scores", "tau_hat")
  if (!all(required %in% names(df))) {
    stop("Missing required columns in ", file, ": ", paste(required, collapse = ", "), call. = FALSE)
  }

  treatment <- paper_treatment_vars[[setting]]
  if (is.null(treatment) || !treatment %in% names(df)) {
    stop("Missing treatment column for ", setting, call. = FALSE)
  }

  title <- if (setting %in% names(paper_title_labels)) {
    paper_title_labels[[setting]]
  } else {
    setting
  }

  fit <- causalcp::cp_plot(
    df,
    ehat = "propensity_scores",
    tau_hat = "tau_hat",
    treat = treatment,
    title = title
  )
  fit$setting <- setting
  fit
}

make_observational_cp_panel <- function(paper_dir, output_dir) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required.", call. = FALSE)
  }
  if (!requireNamespace("grid", quietly = TRUE)) {
    stop("Package 'grid' is required.", call. = FALSE)
  }
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    stop("Package 'gridExtra' is required. Install it with install.packages('gridExtra').", call. = FALSE)
  }

  files <- list.files(file.path(paper_dir, "res_data"), pattern = "data[.]RData$", full.names = TRUE)
  if (length(files) == 0L) {
    stop("No *_data.RData files found in ", file.path(paper_dir, "res_data"), call. = FALSE)
  }
  files <- sort(files)
  if (length(files) >= 8L) {
    files <- files[seq_len(8L)]
  }

  fits <- lapply(files, make_paper_cp_plot)
  plots <- lapply(fits, function(fit) fit$plot + ggplot2::theme(legend.position = "none"))
  slopes <- do.call(rbind, lapply(fits, function(fit) {
    data.frame(setting = fit$setting, fit$slopes, row.names = NULL)
  }))

  line_colors <- c("#D55E00", "#0072B2", "#009E73")
  line_labels <- c("All data", "Treated units", "Control units")

  legend <- grid::grobTree(
    grid::textGrob("Points:", x = grid::unit(0.11, "npc"), y = grid::unit(0.72, "npc"), just = "right", gp = grid::gpar(fontsize = 11)),
    grid::pointsGrob(x = grid::unit(0.15, "npc"), y = grid::unit(0.72, "npc"), pch = 1, gp = grid::gpar(col = "grey60", cex = 0.9)),
    grid::textGrob("Control points", x = grid::unit(0.18, "npc"), y = grid::unit(0.72, "npc"), just = "left", gp = grid::gpar(fontsize = 11)),
    grid::pointsGrob(x = grid::unit(0.35, "npc"), y = grid::unit(0.72, "npc"), pch = 16, gp = grid::gpar(col = "grey35", cex = 0.9)),
    grid::textGrob("Treated points", x = grid::unit(0.38, "npc"), y = grid::unit(0.72, "npc"), just = "left", gp = grid::gpar(fontsize = 11)),
    grid::textGrob("Linear fit:", x = grid::unit(0.11, "npc"), y = grid::unit(0.30, "npc"), just = "right", gp = grid::gpar(fontsize = 11)),
    grid::segmentsGrob(
      x0 = grid::unit(c(0.15, 0.37, 0.61), "npc"),
      x1 = grid::unit(c(0.20, 0.42, 0.66), "npc"),
      y0 = grid::unit(c(0.30, 0.30, 0.30), "npc"),
      y1 = grid::unit(c(0.30, 0.30, 0.30), "npc"),
      gp = grid::gpar(col = line_colors, lwd = 2, lty = c("solid", "dashed", "dotdash"))
    ),
    grid::textGrob(line_labels[[1L]], x = grid::unit(0.22, "npc"), y = grid::unit(0.30, "npc"), just = "left", gp = grid::gpar(fontsize = 11)),
    grid::textGrob(line_labels[[2L]], x = grid::unit(0.44, "npc"), y = grid::unit(0.30, "npc"), just = "left", gp = grid::gpar(fontsize = 11)),
    grid::textGrob(line_labels[[3L]], x = grid::unit(0.68, "npc"), y = grid::unit(0.30, "npc"), just = "left", gp = grid::gpar(fontsize = 11))
  )

  panel <- gridExtra::arrangeGrob(grobs = plots, ncol = 2)
  title <- grid::textGrob(
    expression(paste("Estimated Conditional Treatment Effect ", hat(tau)(X), " vs Propensity Score ", hat(e)(X))),
    gp = grid::gpar(fontsize = 14)
  )
  combined <- gridExtra::arrangeGrob(title, panel, legend, ncol = 1, heights = c(0.045, 0.86, 0.095))

  pdf_file <- file.path(output_dir, "combined_4x2_causalcp.pdf")
  ggplot2::ggsave(pdf_file, combined, width = 12, height = 12.8)

  slopes_file <- file.path(output_dir, "combined_4x2_causalcp_slopes.csv")
  utils::write.csv(slopes, slopes_file, row.names = FALSE)

  list(plot_file = pdf_file, slopes_file = slopes_file, slopes = slopes)
}

make_401k_local_cp_plot <- function(paper_dir, output_dir) {
  csv_file <- file.path(paper_dir, "tab_401k_unit_conditional_wald.csv")
  if (!file.exists(csv_file)) {
    stop("Cannot find ", csv_file, call. = FALSE)
  }

  unit_summary <- utils::read.csv(csv_file)
  required <- c("ehat", "Z", "delta_d", "tau_c_hat")
  if (!all(required %in% names(unit_summary))) {
    stop("Missing required columns in ", csv_file, ": ", paste(required, collapse = ", "), call. = FALSE)
  }

  fit <- causalcp::local_cp_plot(
    unit_summary,
    ehat = "ehat",
    tau_c_hat = "tau_c_hat",
    pi_c_hat = "delta_d",
    group = "Z",
    title = expression(paste("401(k) application: local CP plot of ", hat(tau)^c * (X), " vs ", hat(e)(X)))
  )

  pdf_file <- file.path(output_dir, "fig_401k_unit_conditional_wald_causalcp.pdf")
  ggplot2::ggsave(pdf_file, fit$plot, width = 7, height = 5)

  slopes_file <- file.path(output_dir, "fig_401k_unit_conditional_wald_causalcp_slopes.csv")
  utils::write.csv(fit$slopes, slopes_file, row.names = FALSE)

  list(plot_file = pdf_file, slopes_file = slopes_file, slopes = fit$slopes)
}

reproduce_paper_plots <- function(paper_dir = bundled_paper_dir(),
                                  output_dir = file.path(getwd(), "paper_demo_outputs")) {
  paper_dir <- normalizePath(paper_dir, mustWork = TRUE)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  output_dir <- normalizePath(output_dir, mustWork = TRUE)

  observational <- make_observational_cp_panel(paper_dir = paper_dir, output_dir = output_dir)
  local_iv <- make_401k_local_cp_plot(paper_dir = paper_dir, output_dir = output_dir)

  message("Created observational CP plot: ", observational$plot_file)
  message("Created 401(k) local CP plot: ", local_iv$plot_file)
  message("Created slope summaries in: ", output_dir)

  invisible(list(
    observational = observational,
    local_iv = local_iv,
    output_dir = output_dir
  ))
}
