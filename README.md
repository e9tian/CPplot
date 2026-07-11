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

The main plotting functions work directly from familiar R formulas. Users who
already estimated nuisance functions can also pass those fitted columns
directly.

## Installation

Install from GitHub:

```r
install.packages("remotes")
remotes::install_github("e9tian/CPplot")
```

## Observational CP Plot

For observational studies, if `y` is the outcome, `z` is the binary treatment,
and `x` is a covariate, a CP plot can be drawn with
`cp_plot(y ~ z + x, data = df)`. The example below uses two covariates in the
same way.

```r
library(CPplot)

set.seed(1)
n <- 800
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$z <- rbinom(n, 1, plogis(-0.6 + 1.1 * df$x1 + 1.0 * df$x2))
df$y <- 1 + 0.5 * df$x1 + 0.4 * df$x2 +
  df$z * (0.5 + 0.8 * df$x1 - 0.5 * df$x2) +
  rnorm(n, sd = 0.8)

fit <- cp_plot(y ~ z + x1 + x2, data = df)

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

For IV studies, if `y` is the outcome, `d` is the treatment, `z` is the binary
IV, and `x` is a covariate, a local CP plot can be drawn with
`local_cp_plot(y ~ d + x | z + x, data = df)`. The example below uses two
covariates in the same way.

```r
set.seed(2)
n <- 800
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$z <- rbinom(n, 1, plogis(-0.5 + 1.0 * df$x1 + 1.1 * df$x2))
df$d <- rbinom(n, 1, plogis(-0.8 + 1.2 * df$z + 0.4 * df$x1 - 0.2 * df$x2))
tau <- 0.6 + 1.0 * df$x1 - 0.4 * df$x2
df$y <- 1 + 0.4 * df$x1 - 0.2 * df$x2 + tau * df$d + rnorm(n, sd = 0.6)

fit <- local_cp_plot(y ~ d + x1 + x2 | z + x1 + x2, data = df)

fit$plot
```

By default, units with `z = 0` are labeled `Unencouraged`, and units with
`z = 1` are labeled `Encouraged`.

After drawing the plot, inspect the numerical diagnostics:

```r
fit$slopes
fit$bracketing
```

## Precomputed Inputs

If you already estimated \(\hat e(X_i)\), \(\hat\tau(X_i)\), or local IV
nuisance functions with your preferred model, pass those columns directly.

```r
set.seed(3)
n <- 500
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$z <- rbinom(n, 1, plogis(-0.3 + 0.9 * df$x1 - 0.4 * df$x2))
df$e_hat <- plogis(-0.4 + 1.1 * df$x1)
df$tau_hat <- 0.2 + 2.0 * df$e_hat + 1.3 * df$x2 + rnorm(n, sd = 0.35)

fit <- cp_plot(
  data = df,
  e_hat = "e_hat",
  tau_hat = "tau_hat",
  treatment = "z"
)
```

For a local CP plot with precomputed local IV inputs:

```r
set.seed(4)
n <- 800
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n))
df$e_hat <- plogis(-0.3 + 1.0 * df$x1)
df$z <- rbinom(n, 1, df$e_hat)
df$pi_c_hat <- pmax(0.05, plogis(-0.2 + 0.7 * df$x1 - 0.3 * df$x2))
df$tau_c_hat <- 0.4 + 2.4 * df$e_hat + 1.5 * df$x2 + rnorm(n, sd = 0.45)

fit <- local_cp_plot(
  data = df,
  e_hat = "e_hat",
  tau_c_hat = "tau_c_hat",
  pi_c_hat = "pi_c_hat",
  iv = "z"
)
```

The formula mode uses logistic regression for propensity scores and OLS for
conditional regressions by default. `cp_plot()` also supports
`e_method = "random_forest"` and `tau_method = "random_forest"` through the
optional `ranger` package. Advanced users can estimate nuisance functions with
causal forests, BART, SuperLearner, xgboost, or other models before plotting.

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
