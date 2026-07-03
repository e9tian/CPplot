# CPplot Formula API and Tutorial Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add formula-first `cp_plot()` and `local_cp_plot()` interfaces, rename the local IV visual grouping argument to `iv`, and simplify the tutorial site around two main functions and two examples.

**Architecture:** Add a small formula parsing module that converts user formulas into the existing estimation helper inputs. Keep estimation helpers unchanged for named-column workflows. Plot functions dispatch between formula mode and precomputed nuisance mode, then reuse existing slope/bracketing/plot construction.

**Tech Stack:** Base R formulas, ggplot2, testthat, static HTML/CSS docs.

---

### Task 1: Add Formula Parsing Tests and Helpers

**Files:**
- Create: `R/formula.R`
- Modify: `tests/testthat/test-estimate-inputs.R`

- [ ] **Step 1: Write failing parser tests**

Add tests that call internal helpers:

```r
test_that("parse_cp_formula extracts outcome, treatment, and covariates", {
  parsed <- parse_cp_formula(y ~ z + x1 + x2)
  expect_equal(parsed$outcome, "y")
  expect_equal(parsed$treatment, "z")
  expect_equal(parsed$covariates, c("x1", "x2"))
})

test_that("parse_local_cp_formula extracts outcome, treatment, iv, and covariates", {
  parsed <- parse_local_cp_formula(y ~ d + x1 + x2 | z + x1 + x2)
  expect_equal(parsed$outcome, "y")
  expect_equal(parsed$treatment, "d")
  expect_equal(parsed$iv, "z")
  expect_equal(parsed$covariates, c("x1", "x2"))
})

test_that("parse_local_cp_formula requires matching covariates", {
  expect_error(
    parse_local_cp_formula(y ~ d + x1 | z + x2),
    "same covariates"
  )
})
```

- [ ] **Step 2: Verify tests fail**

Run:

```bash
LC_ALL=C Rscript -e 'library(testthat); test_file("tests/testthat/test-estimate-inputs.R")'
```

Expected: failures because `parse_cp_formula()` and `parse_local_cp_formula()` do not exist.

- [ ] **Step 3: Implement parser helpers**

Create `R/formula.R` with:

```r
is_formula <- function(x) {
  inherits(x, "formula")
}

formula_labels <- function(formula) {
  labels <- attr(stats::terms(formula), "term.labels")
  if (length(labels) == 0L) {
    stop("formula must include at least one right-hand-side variable.", call. = FALSE)
  }
  labels
}

formula_lhs <- function(formula) {
  vars <- all.vars(formula[[2L]])
  if (length(vars) != 1L) {
    stop("formula must have exactly one outcome on the left-hand side.", call. = FALSE)
  }
  vars[[1L]]
}

parse_cp_formula <- function(formula) {
  if (!is_formula(formula) || length(formula) != 3L) {
    stop("formula must be a two-sided formula such as y ~ z + x1 + x2.", call. = FALSE)
  }
  rhs <- formula_labels(formula)
  if (length(rhs) < 2L) {
    stop("formula must include a treatment and at least one covariate.", call. = FALSE)
  }
  list(
    outcome = formula_lhs(formula),
    treatment = rhs[[1L]],
    covariates = rhs[-1L]
  )
}

split_local_formula_rhs <- function(rhs) {
  if (!is.call(rhs) || !identical(rhs[[1L]], as.name("|"))) {
    stop("local CP formula must use the form y ~ d + x1 + x2 | z + x1 + x2.", call. = FALSE)
  }
  list(treatment_side = rhs[[2L]], iv_side = rhs[[3L]])
}

rhs_labels_from_expr <- function(expr) {
  formula_labels(stats::as.formula(call("~", expr), env = parent.frame()))
}

parse_local_cp_formula <- function(formula) {
  if (!is_formula(formula) || length(formula) != 3L) {
    stop("formula must be a two-sided formula such as y ~ d + x1 + x2 | z + x1 + x2.", call. = FALSE)
  }
  parts <- split_local_formula_rhs(formula[[3L]])
  treatment_rhs <- rhs_labels_from_expr(parts$treatment_side)
  iv_rhs <- rhs_labels_from_expr(parts$iv_side)
  if (length(treatment_rhs) < 2L || length(iv_rhs) < 2L) {
    stop("local CP formula must include treatment, instrument, and at least one covariate.", call. = FALSE)
  }
  covariates <- treatment_rhs[-1L]
  iv_covariates <- iv_rhs[-1L]
  if (!setequal(covariates, iv_covariates)) {
    stop("local CP formula must use the same covariates on both sides of |.", call. = FALSE)
  }
  list(
    outcome = formula_lhs(formula),
    treatment = treatment_rhs[[1L]],
    iv = iv_rhs[[1L]],
    covariates = covariates
  )
}
```

- [ ] **Step 4: Verify parser tests pass**

Run the same `test_file()` command. Expected: all tests in that file pass.

### Task 2: Implement Formula Mode in `cp_plot()`

**Files:**
- Modify: `R/cp_plot.R`
- Modify: `tests/testthat/test-plots.R`
- Modify: `man/cp_plot.Rd`

- [ ] **Step 1: Write failing `cp_plot()` formula tests**

Add tests:

```r
test_that("cp_plot estimates inputs from a formula", {
  set.seed(10)
  n <- 120
  df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
  df$z <- rbinom(n, 1, plogis(-0.2 + 0.7 * df$x1 - 0.3 * df$x2))
  df$y <- 1 + df$x1 + 0.5 * df$x2 + df$z * (0.4 + df$x1) + rnorm(n, sd = 0.2)

  fit <- cp_plot(y ~ z + x1 + x2, data = df)

  expect_s3_class(fit, "CPplot_result")
  expect_equal(levels(fit$data_used$group), c("Control", "Treated"))
  expect_true(all(c("e_hat", "tau_hat") %in% names(fit$data_used)))
  expect_true(is.data.frame(fit$bracketing))
})

test_that("cp_plot no longer accepts outcome and covariates directly", {
  df <- data.frame(y = 1:3, z = c(0, 1, 0), x = c(1, 2, 3))
  expect_error(cp_plot(df, outcome = "y", treatment = "z", covariates = "x"), "unused argument")
})
```

- [ ] **Step 2: Verify tests fail**

Run:

```bash
LC_ALL=C Rscript -e 'library(testthat); test_file("tests/testthat/test-plots.R")'
```

Expected: formula call fails or old direct outcome arguments still work.

- [ ] **Step 3: Update `cp_plot()`**

Change signature to:

```r
cp_plot <- function(formula = NULL, data, e_hat = NULL, tau_hat = NULL,
                    treatment = NULL, e_method = "logistic", tau_method = "ols",
                    point_labels = c("Control", "Treated"),
                    title = NULL, alpha = 0.45, point_size = 1)
```

At the start, dispatch:

```r
if (!is.null(formula)) {
  if (!is.null(e_hat) || !is.null(tau_hat)) {
    stop("Use either formula mode or fitted nuisance mode, not both.", call. = FALSE)
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
} else {
  if (is.null(e_hat) || is.null(tau_hat)) {
    stop("Provide a formula, or provide e_hat and tau_hat.", call. = FALSE)
  }
}
```

Keep the existing plot construction after this block.

- [ ] **Step 4: Verify plot tests pass**

Run the same `test_file()` command. Expected: plot tests pass.

### Task 3: Implement Formula Mode and `iv` in `local_cp_plot()`

**Files:**
- Modify: `R/local_cp_plot.R`
- Modify: `R/slopes.R`
- Modify: `tests/testthat/test-plots.R`
- Modify: `tests/testthat/test-slopes.R`
- Modify: `man/local_cp_plot.Rd`
- Modify: `man/local_cp_slopes.Rd`

- [ ] **Step 1: Write failing local formula and `iv` tests**

Add tests:

```r
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
  expect_equal(levels(fit$data_used$group), c("Control", "Treated"))
  expect_true(all(c("e_hat", "tau_c_hat", "pi_c_hat") %in% names(fit$data_used)))
  expect_true(is.data.frame(fit$bracketing))
})

test_that("local_cp_plot accepts iv for fitted nuisance mode", {
  df <- data.frame(
    e_hat = rep(c(0.2, 0.4, 0.6, 0.8), 2),
    tau_c = rep(c(1, 2, 3, 4), 2),
    pi_c = rep(1, 8),
    z = rep(c(0, 1), each = 4)
  )
  fit <- local_cp_plot(df, e_hat = "e_hat", tau_c_hat = "tau_c", pi_c_hat = "pi_c", iv = "z")
  expect_equal(levels(fit$data_used$group), c("Control", "Treated"))
})

test_that("local_cp_plot does not accept the old group argument", {
  df <- data.frame(e_hat = c(0.2, 0.4), tau_c = c(1, 2), pi_c = c(1, 1), z = c(0, 1))
  expect_error(local_cp_plot(df, e_hat = "e_hat", tau_c_hat = "tau_c", pi_c_hat = "pi_c", group = "z"), "unused argument")
})
```

- [ ] **Step 2: Verify tests fail**

Run:

```bash
LC_ALL=C Rscript -e 'library(testthat); test_file("tests/testthat/test-plots.R"); test_file("tests/testthat/test-slopes.R")'
```

Expected: local formula and `iv` calls fail before implementation.

- [ ] **Step 3: Update local plotting and slope helpers**

Change `local_cp_plot()` signature to use `formula`, `data`, and `iv`. Dispatch formula mode through `estimate_local_cp_inputs()`. In fitted mode, require `e_hat`, `tau_c_hat`, and `pi_c_hat`. Replace internal `group` uses with `iv`.

Change `local_cp_slopes()` signature from `group = NULL` to `iv = NULL` and update validation labels from `"group"` to `"iv"`.

- [ ] **Step 4: Verify local tests pass**

Run the same combined test command. Expected: all targeted tests pass.

### Task 4: Update Package Examples and Paper Demo Calls

**Files:**
- Modify: `README.md`
- Modify: `vignettes/cp-plot.Rmd`
- Modify: `vignettes/local-cp-plot.Rmd`
- Modify: `inst/paper-examples/reproduce-paper-plots.R`
- Modify: `man/*.Rd`

- [ ] **Step 1: Update examples**

Use formula examples as the first examples in README and vignettes. Use `iv = "Z"` in local fitted nuisance examples and paper demo calls. Remove `group =` from all public examples.

- [ ] **Step 2: Search for stale public API text**

Run:

```bash
rg -n "group =|outcome =|covariates =|local_cp_plot\\(|cp_plot\\(" README.md docs R tests man vignettes inst
```

Expected: `group =` should appear only in tests asserting the old argument fails. `outcome =` and `covariates =` may remain in estimation helper docs, not in main `cp_plot()` examples.

### Task 5: Simplify Tutorial Site and Add API Page

**Files:**
- Modify: `docs/index.html`
- Add: `docs/api.html`
- Modify: `docs/styles.css` if needed

- [ ] **Step 1: Simplify homepage**

Change hero title to `CP plots and local CP plots in R.`. Keep install, two formula examples, the plot output sections, and "What the diagnostic lines tell you" on the homepage. Add compact advanced fitted-input examples after the main examples.

- [ ] **Step 2: Move API reference**

Create `docs/api.html` with the full function signatures, argument tables, return values, and examples for `cp_plot()`, `local_cp_plot()`, helper functions, paper data functions, and citation.

- [ ] **Step 3: Verify website locally**

Run:

```bash
python3 -m http.server 8765 --directory docs
curl -I http://127.0.0.1:8765/
curl -I http://127.0.0.1:8765/api.html
curl -I http://127.0.0.1:8765/styles.css
```

Expected: all return `200 OK`. Stop the server after checking.

### Task 6: Full Verification and Commit

**Files:**
- All modified package and docs files

- [ ] **Step 1: Run full tests**

```bash
LC_ALL=C Rscript -e 'library(testthat); test_dir("tests/testthat")'
```

Expected: all tests pass.

- [ ] **Step 2: Run R CMD check**

```bash
LC_ALL=C R CMD build .
LC_ALL=C R CMD check --no-manual CPplot_0.0.0.9000.tar.gz
```

Expected: `Status: OK`.

- [ ] **Step 3: Clean build artifacts**

```bash
rm -rf CPplot_0.0.0.9000.tar.gz CPplot.Rcheck
```

- [ ] **Step 4: Commit and push**

```bash
git add .
git commit -m "Add formula-first CPplot API"
git push origin main
```
