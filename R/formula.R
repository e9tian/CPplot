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
