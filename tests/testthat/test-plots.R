test_that("CPplot result stores plot, slopes, and data", {
  e <- c(0.2, 0.4, 0.6, 0.8)
  tau <- 1 + 5 * e + c(0.01, -0.03, 0.03, -0.01)
  df <- data.frame(e_hat = e, tau = tau)
  fit <- cp_plot(data = df, e_hat = "e_hat", tau_hat = "tau")
  expect_s3_class(fit, "CPplot_result")
  expect_s3_class(fit$plot, "ggplot")
  expect_true(is.data.frame(fit$slopes))
  expect_true(is.data.frame(fit$data_used))
  expect_true(is.data.frame(fit$bracketing))
  expect_true("implication" %in% names(fit$bracketing))
})

test_that("cp_plot supports treated and control point labels", {
  e <- c(0.2, 0.4, 0.6, 0.8)
  tau <- 1 + 5 * e + c(0.01, -0.03, 0.03, -0.01)
  df <- data.frame(
    e_hat = rep(e, 2),
    tau = rep(tau, 2),
    z = rep(c(0, 1), each = 4)
  )
  fit <- cp_plot(data = df, e_hat = "e_hat", tau_hat = "tau", treatment = "z")
  expect_equal(levels(fit$data_used$group), c("Control", "Treated"))
  expect_equal(fit$slopes$fit, c("Unweighted", "Treated weighted", "Control weighted"))
  point_layer <- ggplot2::ggplot_build(fit$plot)$data[[1L]]
  expect_setequal(unique(point_layer$colour), c("#D55E00", "#0072B2"))
  expect_setequal(unique(point_layer$shape), c(1, 17))
})

test_that("cp_plot lines use the same full-sample weighted fits as cp_slopes", {
  e <- c(0.2, 0.4, 0.6, 0.8)
  df <- data.frame(
    e_hat = rep(e, 2),
    tau = c(1 + 2 * e, 1 - 3 * e + c(0.2, -0.1, 0.1, -0.2)),
    z = rep(c(0, 1), each = 4)
  )
  fit <- cp_plot(data = df, e_hat = "e_hat", tau_hat = "tau", treatment = "z")
  built <- ggplot2::ggplot_build(fit$plot)
  line_data <- built$data[[2]]
  line_slopes <- vapply(split(line_data, line_data$group), function(d) {
    unname(coef(stats::lm(y ~ x, data = d))[["x"]])
  }, numeric(1))
  names(line_slopes) <- fit$slopes$fit
  expect_equal(unname(line_slopes), fit$slopes$slope, tolerance = 1e-8)
})

test_that("cp_plot estimates inputs from a formula", {
  set.seed(10)
  n <- 120
  df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
  df$z <- rbinom(n, 1, plogis(-0.2 + 0.7 * df$x1 - 0.3 * df$x2))
  df$y <- 1 + df$x1 + 0.5 * df$x2 + df$z * (0.4 + df$x1) + rnorm(n, sd = 0.2)

  fit <- cp_plot(y ~ z + x1 + x2, data = df)

  expect_true(all(c("e_hat", "tau_hat") %in% names(fit$data_used)))
  expect_equal(levels(fit$data_used$group), c("Control", "Treated"))
  expect_true(is.data.frame(fit$bracketing))
  expect_true(length(fit$bracketing_summary) >= 1)
})

test_that("cp_plot no longer accepts outcome and covariates directly", {
  df <- data.frame(y = 1:3, z = c(0, 1, 0), x = c(1, 2, 3))
  expect_error(cp_plot(df, outcome = "y", treatment = "z", covariates = "x"), "unused argument")
})

test_that("cp_plot does not accept the old ehat argument", {
  df <- data.frame(e_hat = c(0.2, 0.4, 0.6), tau = c(1, 2, 3))
  expect_error(cp_plot(data = df, ehat = "e_hat", tau_hat = "tau"), "unused argument")
})

test_that("local_cp_plot returns weighted local CP diagnostics", {
  e <- c(0.2, 0.4, 0.6, 0.8)
  tau_c <- 1 + 5 * e + c(0.01, -0.03, 0.03, -0.01)
  df <- data.frame(
    e_hat = rep(e, 2),
    tau_c = rep(tau_c, 2),
    pi_c = rep(1, 8),
    z = rep(c(0, 1), each = 4)
  )
  fit <- local_cp_plot(data = df, e_hat = "e_hat", tau_c_hat = "tau_c", pi_c_hat = "pi_c", iv = "z")
  expect_s3_class(fit, "CPplot_result")
  expect_equal(levels(fit$data_used$group), c("Unencouraged", "Encouraged"))
  expect_equal(fit$slopes$fit, c("Complier weighted", "Encouraged-complier weighted", "Unencouraged-complier weighted"))
  expect_true(is.data.frame(fit$bracketing))
  point_layer <- ggplot2::ggplot_build(fit$plot)$data[[1L]]
  expect_setequal(unique(point_layer$colour), c("#D55E00", "#0072B2"))
  expect_setequal(unique(point_layer$shape), c(1, 17))
})

test_that("local_cp_plot estimates inputs from an IV formula", {
  set.seed(11)
  n <- 180
  df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
  df$z <- rbinom(n, 1, plogis(-0.2 + 0.8 * df$x1 + 0.4 * df$x2))
  df$d <- rbinom(n, 1, plogis(-0.7 + 1.3 * df$z + 0.3 * df$x1 - 0.2 * df$x2))
  tau <- 0.5 + 0.7 * df$x1 - 0.2 * df$x2
  df$y <- 1 + 0.4 * df$x1 - 0.1 * df$x2 + tau * df$d + rnorm(n, sd = 0.5)

  fit <- local_cp_plot(y ~ d + x1 + x2 | z + x1 + x2, data = df)

  expect_s3_class(fit, "CPplot_result")
  expect_equal(levels(fit$data_used$group), c("Unencouraged", "Encouraged"))
  expect_true(all(c("e_hat", "tau_c_hat", "pi_c_hat") %in% names(fit$data_used)))
  expect_true(is.data.frame(fit$bracketing))
})

test_that("local_cp_plot does not accept the old group argument", {
  df <- data.frame(e_hat = c(0.2, 0.4), tau_c = c(1, 2), pi_c = c(1, 1), z = c(0, 1))
  expect_error(
    local_cp_plot(data = df, e_hat = "e_hat", tau_c_hat = "tau_c", pi_c_hat = "pi_c", group = "z"),
    "unused argument"
  )
})
