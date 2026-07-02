# CPplot

<p align="center">
  <img src="docs/assets/cpplot-logo-square-white.png" alt="CPplot logo" width="360">
</p>

`CPplot` implements CP-plots, which plot estimated conditional average
treatment effects against estimated propensity scores. Motivated by covariance
representations for weighted average treatment effects, these plots summarize
how treatment-effect heterogeneity varies with treatment propensity and help
diagnose bracketing relationships among weighted causal estimands. The package
also implements local CP-plots for instrumental-variable analyses of weighted
local average treatment effects.

Reference:

> Tian, P., Yang, F., & Ding, P. (2026). Bracketing Relationships of Weighted
> Average Treatment Effects. arXiv preprint arXiv:2606.11715.

Paper link: <https://arxiv.org/abs/2606.11715>

Tutorial website: <https://e9tian.github.io/CPplot/>

The main plotting functions assume that users have already estimated propensity
scores and treatment effects, possibly using their own preferred models.

## Installation

Install from GitHub:

```r
install.packages("remotes")
remotes::install_github("e9tian/CPplot")
```

## Observational CP Plot

For observational studies, `cp_plot()` can estimate simple default inputs from
an outcome, a binary treatment, and covariates.

```r
library(CPplot)

set.seed(1)
n <- 800
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$z <- rbinom(n, 1, plogis(-0.6 + 1.1 * df$x1 + 1.0 * df$x2))
df$y <- 1 + 0.5 * df$x1 + 0.4 * df$x2 +
  df$z * (0.5 + 0.8 * df$x1 - 0.5 * df$x2) +
  rnorm(n, sd = 0.8)

fit <- cp_plot(
  df,
  outcome = "y",
  treatment = "z",
  covariates = c("x1", "x2")
)

fit$plot
```

After drawing the plot, inspect the numerical diagnostics:

```r
fit$slopes
fit$bracketing
```

The returned object has five main components:

- `fit$plot`: the `ggplot` object.
- `fit$slopes`: slopes for the unweighted, treated-weighted, and
  control-weighted full-sample linear fits.
- `fit$bracketing`: slope signs and their bracketing implications.
- `fit$bracketing_summary`: a compact text summary of the ATO bracketing
  diagnostic.
- `fit$data_used`: the finite observations used in the plot.

## Local CP Plot for IV Studies

For IV studies, use `local_cp_plot()` after estimating:

- the IV propensity score \(\hat e(X)\),
- the conditional complier treatment effect \(\hat\tau^c(X)\),
- the complier score or first-stage weight \(\hat\pi^c(X)\).

Under the IV assumptions in the paper, \(\pi^c(X)=\Delta_D(X)\), so the local
CP plot uses \(\widehat\Delta_D(X)\) as the weight.

```r
set.seed(2)
n <- 800
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$e_hat <- plogis(-0.3 + 1.0 * df$x1)
df$z <- rbinom(n, 1, plogis(-0.5 + 1.0 * df$x1 + 1.1 * df$x2))
df$pi_c_hat <- pmax(0.05, plogis(-0.2 + 0.7 * df$x1 - 0.3 * df$x2))
df$tau_c_hat <- 0.4 + 2.4 * df$e_hat + 1.5 * df$x2 + rnorm(n, sd = 0.45)

fit <- local_cp_plot(
  df,
  e_hat = "e_hat",
  tau_c_hat = "tau_c_hat",
  pi_c_hat = "pi_c_hat",
  group = "z"
)

fit$plot
```

After drawing the plot, inspect the numerical diagnostics:

```r
fit$slopes
fit$bracketing
```

## Input Modes and Estimation Helpers

`CPplot` supports two input modes.

Mode 1 uses simple default estimators from an outcome, a binary treatment, and
covariates. By default, `cp_plot()` estimates the propensity score with logistic
regression and the CATE with two OLS outcome regressions:

```r
library(CPplot)

set.seed(3)
n <- 500
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$z <- rbinom(n, 1, plogis(-0.3 + 0.9 * df$x1 - 0.4 * df$x2))
df$y <- 1 + 0.5 * df$x1 + 0.4 * df$x2 +
  df$z * (0.5 + 0.8 * df$x1 - 0.5 * df$x2) +
  rnorm(n, sd = 0.8)

df2 <- estimate_cp_inputs(
  df,
  outcome = "y",
  treatment = "z",
  covariates = c("x1", "x2")
)

fit <- cp_plot(df2, e_hat = "e_hat", tau_hat = "tau_hat", treatment = "z")
fit$plot
fit$slopes
```

The same default estimation can be done in one call:

```r
fit <- cp_plot(
  df,
  outcome = "y",
  treatment = "z",
  covariates = c("x1", "x2")
)
```

Mode 2 uses precomputed inputs. If you already estimated
\(\hat e(X_i)\) and \(\hat\tau(X_i)\) with your preferred model, pass those
columns directly:

```r
df$e_hat <- plogis(-0.4 + 1.1 * df$x1)
df$tau_hat <- 0.2 + 2.0 * df$e_hat + 1.3 * df$x2 + rnorm(n, sd = 0.35)

fit <- cp_plot(
  df,
  e_hat = "e_hat",
  tau_hat = "tau_hat",
  treatment = "z"
)
```

For IV examples:

```r
library(CPplot)

set.seed(4)
n <- 800
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$z <- rbinom(n, 1, plogis(-0.2 + 0.8 * df$x1 + 0.4 * df$x2))
df$d <- rbinom(n, 1, plogis(-0.8 + 1.2 * df$z + 0.4 * df$x1 - 0.2 * df$x2))
tau <- 0.6 + 1.0 * df$x1 - 0.4 * df$x2
df$y <- 1 + 0.4 * df$x1 - 0.2 * df$x2 + tau * df$d + rnorm(n, sd = 0.6)

df2 <- estimate_local_cp_inputs(
  df,
  outcome = "y",
  treatment = "d",
  instrument = "z",
  covariates = c("x1", "x2")
)

fit <- local_cp_plot(
  df2,
  e_hat = "e_hat",
  tau_c_hat = "tau_c_hat",
  pi_c_hat = "pi_c_hat",
  group = "z"
)
fit$plot
fit$slopes
```

For Mode 1, `estimate_cp_inputs()` and `cp_plot()` also support
`e_method = "random_forest"` and `tau_method = "random_forest"` through the
optional `ranger` package. For Mode 2, users can estimate the inputs with
causal forests, BART, SuperLearner, xgboost, or other models and then pass the
resulting columns to the plotting functions.

## Paper Demo

The package includes a script showing how the paper figures can be generated
from the bundled paper intermediate outputs using the package API. These are
the intermediate files needed for the CP-plot figures, not the full raw-data
analysis workflow.

Part 1 shows which bundled paper datasets are available and how to load them.
Use `paper_datasets()` as the index of datasets and loader functions:

```r
library(CPplot)

paper_datasets()[, c("name", "type", "loader")]

rhc <- load_paper_cp_data("rhc")
rhc_treat_col <- attr(rhc, "treatment_column")
head(rhc[, c("propensity_scores", "tau_hat", rhc_treat_col)])

k401 <- load_paper_401k_data()
head(k401[, c("e_hat", "Z", "delta_d", "tau_c_hat")])
```

`load_paper_cp_data(setting)` loads one observational CP-plot intermediate
dataset, where `setting` is one of the observational names returned by
`paper_datasets()`. `load_paper_401k_data()` loads the intermediate dataset for
the 401(k) local CP plot.

Part 2 reproduces the paper demo plots from those bundled intermediate
datasets:

```r
library(CPplot)

source(system.file(
  "paper-examples/reproduce-paper-plots.R",
  package = "CPplot"
))

reproduce_paper_plots()
```

This creates package-based versions of:

- the 8-panel observational CP plot,
- the 401(k) local CP plot,
- CSV files containing the corresponding slope diagnostics.

The outputs are written to `paper_demo_outputs/` in the current working
directory.

## Citation

```r
citation("CPplot")
```
