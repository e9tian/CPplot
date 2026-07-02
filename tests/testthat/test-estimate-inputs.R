test_that("estimate_cp_inputs returns e_hat and tau_hat", {
  set.seed(1)
  n <- 80
  df <- data.frame(x = rnorm(n))
  df$z <- rbinom(n, 1, plogis(df$x))
  df$y <- 1 + df$x + df$z * (0.5 + df$x) + rnorm(n, sd = 0.1)
  out <- estimate_cp_inputs(df, outcome = "y", treatment = "z", covariates = "x")
  expect_true(all(c("e_hat", "tau_hat") %in% names(out)))
  expect_false("ehat" %in% names(out))
  expect_equal(nrow(out), n)
  expect_true(all(is.finite(out$e_hat)))
  expect_true(all(is.finite(out$tau_hat)))
})

test_that("estimate_cp_inputs supports random forest methods when ranger is installed", {
  testthat::skip_if_not_installed("ranger")
  set.seed(11)
  n <- 80
  df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
  df$z <- rbinom(n, 1, plogis(0.5 * df$x1 - 0.2 * df$x2))
  df$y <- 1 + df$x1 + df$z * (0.5 + df$x2) + rnorm(n, sd = 0.2)

  out <- estimate_cp_inputs(
    df,
    outcome = "y",
    treatment = "z",
    covariates = c("x1", "x2"),
    e_method = "random_forest",
    tau_method = "random_forest"
  )

  expect_true(all(c("e_hat", "tau_hat") %in% names(out)))
  expect_true(all(is.finite(out$e_hat)))
  expect_true(all(is.finite(out$tau_hat)))
})

test_that("estimate_local_cp_inputs returns local IV plotting inputs", {
  set.seed(2)
  n <- 100
  df <- data.frame(x = rnorm(n))
  df$z <- rbinom(n, 1, plogis(df$x))
  df$d <- rbinom(n, 1, plogis(-0.2 + 0.8 * df$z + 0.2 * df$x))
  df$y <- 1 + df$x + 2 * df$d + rnorm(n, sd = 0.1)
  out <- estimate_local_cp_inputs(
    df,
    outcome = "y",
    treatment = "d",
    instrument = "z",
    covariates = "x"
  )
  expect_true(all(c("e_hat", "delta_y", "delta_d", "tau_c_hat", "pi_c_hat") %in% names(out)))
  expect_false("ehat" %in% names(out))
  expect_equal(nrow(out), n)
})
