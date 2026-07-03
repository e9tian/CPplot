# CPplot Formula API and Tutorial Site Redesign

Date: 2026-07-04

## Goal

Make CPplot feel like a small, familiar R package: a first-time user should see
one function call, one example, the resulting plot, and the diagnostic line
interpretation. Advanced users can still pass precomputed nuisance estimates.

## Recommended Direction

Use a formula-first API as the main user path and keep precomputed-input mode as
the advanced path.

```r
cp_plot(y ~ z + x1 + x2, data = df)

local_cp_plot(y ~ d + x1 + x2 | z + x1 + x2, data = df)
```

For users who have already estimated nuisance functions:

```r
cp_plot(data = df, e_hat = "e_hat", tau_hat = "tau_hat", treatment = "z")

local_cp_plot(
  data = df,
  e_hat = "e_hat",
  tau_c_hat = "tau_c_hat",
  pi_c_hat = "pi_c_hat",
  iv = "z"
)
```

## API Design

### `cp_plot()`

New public signature:

```r
cp_plot <- function(formula = NULL, data, e_hat = NULL, tau_hat = NULL,
                    treatment = NULL, e_method = "logistic",
                    tau_method = "ols",
                    point_labels = c("Control", "Treated"),
                    title = NULL, alpha = 0.45, point_size = 1)
```

Input modes:

1. Formula mode: `cp_plot(y ~ z + x1 + x2, data = df)`.
   The left-hand side is the outcome. The first right-hand-side variable is the
   binary treatment. Remaining right-hand-side variables are covariates.
2. Fitted nuisance mode: `cp_plot(data = df, e_hat = "e_hat",
   tau_hat = "tau_hat", treatment = "z")`.

No `outcome` or `covariates` arguments are needed in the main plotting API.
Those remain available in `estimate_cp_inputs()` for users who want the helper
explicitly.

### `local_cp_plot()`

New public signature:

```r
local_cp_plot <- function(formula = NULL, data, e_hat = NULL,
                          tau_c_hat = NULL, pi_c_hat = NULL, iv = NULL,
                          e_method = "logistic", contrast_method = "ols",
                          min_first_stage = 1e-6,
                          point_labels = c("Control", "Treated"),
                          title = NULL, alpha = 0.35, point_size = 0.8)
```

Input modes:

1. Formula mode:
   `local_cp_plot(y ~ d + x1 + x2 | z + x1 + x2, data = df)`.
   The left-hand side is the outcome. In the first right-hand-side block, the
   first variable is the binary treatment and the remaining variables are
   covariates. In the instrument block, the first variable is the binary IV and
   the remaining variables should match the covariates.
2. Fitted nuisance mode:
   `local_cp_plot(data = df, e_hat = "e_hat", tau_c_hat = "tau_c_hat",
   pi_c_hat = "pi_c_hat", iv = "z")`.

Rename the visual grouping argument from `group` to `iv`. Since the package has
not yet accumulated users, do not keep `group` as a public alias.

## Formula Parsing

Add small internal helpers:

- `parse_cp_formula(formula)` returns `outcome`, `treatment`, and `covariates`.
- `parse_local_cp_formula(formula)` returns `outcome`, `treatment`, `iv`, and
  `covariates`.

Use base R formula tools where possible. Validate that:

- Formula mode receives a formula and a data frame.
- Fitted nuisance mode receives all required fitted columns.
- A user cannot mix partial formula inputs with partial fitted inputs.
- Local CP formula uses exactly one `|`.
- Treatment and IV variables are binary 0/1 columns.
- Local CP covariates after `|` match the treatment-side covariates, ignoring
  order.

## Website Design

Change the homepage headline to:

> CP plots and local CP plots in R.

Simplify the homepage to:

1. Install.
2. `cp_plot()` raw-data formula example with plot and printed diagnostics.
3. `local_cp_plot()` raw-data formula example with plot and printed diagnostics.
4. "What the diagnostic lines tell you" tables.
5. Short fitted-nuisance examples for advanced users.

Move the long API reference to a separate `docs/api.html` page. Keep a sidebar
link to the API page from the homepage. The API page should document each
argument, the two input modes, return values, and examples.

## Documentation Updates

Update:

- `README.md`
- `docs/index.html`
- `docs/api.html`
- manual pages for `cp_plot()`, `local_cp_plot()`, slope helpers, and result
  objects
- vignettes
- paper demo script calls

README should lead with the formula examples and show the fitted-input examples
only after the basic examples.

## Testing

Add or update tests for:

- `cp_plot(y ~ z + x1 + x2, data = df)` estimates inputs and returns plot,
  slopes, bracketing, and data used.
- `cp_plot(data = df, e_hat = ..., tau_hat = ..., treatment = ...)` still works.
- `local_cp_plot(y ~ d + x1 + x2 | z + x1 + x2, data = df)` estimates IV inputs
  and returns local diagnostics.
- `local_cp_plot(data = df, e_hat = ..., tau_c_hat = ..., pi_c_hat = ...,
  iv = ...)` works.
- `group` is no longer accepted by `local_cp_plot()`.
- Invalid formulas and mismatched local covariates fail with clear messages.

Run `R CMD check --no-manual` and verify the website locally before committing
the implementation.
