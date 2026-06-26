test_that("paper_datasets lists bundled paper intermediate data", {
  datasets <- paper_datasets()
  expect_true(all(c("name", "type", "loader", "description") %in% names(datasets)))
  expect_true("rhc" %in% datasets$name)
  expect_true("401k" %in% datasets$name)
})

test_that("load_paper_cp_data loads observational setting data", {
  rhc <- load_paper_cp_data("rhc")
  expect_true(all(c("propensity_scores", "tau_hat", "treatment.swang") %in% names(rhc)))
  expect_equal(attr(rhc, "setting"), "rhc")
  expect_equal(attr(rhc, "treatment_column"), "treatment.swang")
})

test_that("load_paper_401k_data loads local IV data", {
  k401 <- load_paper_401k_data()
  expect_true(all(c("ehat", "Z", "delta_d", "tau_c_hat") %in% names(k401)))
  expect_equal(attr(k401, "setting"), "401k")
})
