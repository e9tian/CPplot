test_that("cp_slopes returns full-sample weighted slopes", {
  e <- c(0.2, 0.4, 0.6, 0.8)
  df <- data.frame(
    e_hat = rep(e, 2),
    tau = c(1 + 2 * e, 1 - 3 * e + c(0.2, -0.1, 0.1, -0.2)),
    z = rep(c(0, 1), each = 4)
  )
  out <- cp_slopes(df, e_hat = "e_hat", tau_hat = "tau", treatment = "z")
  expected <- c(
    unname(coef(stats::lm(tau ~ e_hat, data = df))[["e_hat"]]),
    unname(coef(stats::lm(tau ~ e_hat, data = df, weights = e_hat))[["e_hat"]]),
    unname(coef(stats::lm(tau ~ e_hat, data = df, weights = 1 - e_hat))[["e_hat"]])
  )
  expect_equal(out$fit, c("Unweighted", "Treated weighted", "Control weighted"))
  expect_equal(out$n, rep(nrow(df), 3))
  expect_equal(out$slope, expected)
})

test_that("local_cp_slopes returns full-sample complier-weighted slopes", {
  e <- c(0.2, 0.4, 0.6, 0.8)
  df <- data.frame(
    e_hat = rep(e, 2),
    tau_c = c(1 + 2 * e, 1 - 3 * e + c(0.2, -0.1, 0.1, -0.2)),
    pi_c = c(1, 0.7, 1.3, 1.6, 2, 1.8, 1.2, 0.9),
    z = rep(c(0, 1), each = 4)
  )
  out <- local_cp_slopes(df, e_hat = "e_hat", tau_c_hat = "tau_c", pi_c_hat = "pi_c", iv = "z")
  expected <- c(
    unname(coef(stats::lm(tau_c ~ e_hat, data = df, weights = pi_c))[["e_hat"]]),
    unname(coef(stats::lm(tau_c ~ e_hat, data = df, weights = pi_c * e_hat))[["e_hat"]]),
    unname(coef(stats::lm(tau_c ~ e_hat, data = df, weights = pi_c * (1 - e_hat)))[["e_hat"]])
  )
  expect_equal(out$fit, c("Complier weighted", "Treated-complier weighted", "Control-complier weighted"))
  expect_equal(out$n, rep(nrow(df), 3))
  expect_equal(out$slope, expected)
})
