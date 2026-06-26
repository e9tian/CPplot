# causalcp

`causalcp` draws CP plots and local CP plots for causal diagnostic summaries.
It is developed for the paper:

> Pengfei Tian, Fan Yang, and Peng Ding. "Bracketing Relationships of Weighted
> Average Treatment Effects." arXiv:2606.11715.

Paper link: <https://arxiv.org/abs/2606.11715>

The package is intentionally plot-first. Its main functions assume that users
have already estimated propensity scores and treatment effects, possibly using
their own preferred models.

## Installation

This repository is currently private. After accepting the GitHub collaborator
invitation, install from R with either GitHub credentials or SSH access.

```r
install.packages("remotes")
remotes::install_github("e9tian/causalcp")
```

If the repository is private and `install_github()` cannot authenticate, install
through SSH instead:

```r
remotes::install_git("git@github.com:e9tian/causalcp.git")
```

## Observational CP Plot

For observational studies, use `cp_plot()` after estimating the propensity
score \(\hat e(X)\) and CATE \(\hat\tau(X)\) for each unit.

```r
library(causalcp)

set.seed(1)
n <- 300
df <- data.frame(x = rnorm(n))
df$z <- rbinom(n, 1, plogis(df$x))
df$ehat <- plogis(df$x)
df$tau_hat <- 1 + df$x

fit <- cp_plot(
  df,
  ehat = "ehat",
  tau_hat = "tau_hat",
  treat = "z"
)

fit$plot
fit$slopes
```

The returned object has three components:

- `fit$plot`: the `ggplot` object.
- `fit$slopes`: slopes for the all-units, treated-units, and control-units
  linear fits.
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
n <- 300
df <- data.frame(x = rnorm(n))
df$z <- rbinom(n, 1, plogis(df$x))
df$ehat <- plogis(df$x)
df$pi_c_hat <- pmax(0.05, plogis(-0.5 + df$x))
df$tau_c_hat <- 1 + 0.5 * df$x

fit <- local_cp_plot(
  df,
  ehat = "ehat",
  tau_c_hat = "tau_c_hat",
  pi_c_hat = "pi_c_hat",
  group = "z"
)

fit$plot
fit$slopes
```

## Basic Estimation Helpers

The package includes simple transparent helpers for quick examples:

```r
df2 <- estimate_cp_inputs(df, y = "y", z = "z", x = c("x1", "x2"))
fit <- cp_plot(df2, ehat = "ehat", tau_hat = "tau_hat", treat = "z")
```

For IV examples:

```r
df2 <- estimate_local_cp_inputs(
  df,
  y = "y",
  d = "d",
  z = "z",
  x = c("x1", "x2")
)
fit <- local_cp_plot(
  df2,
  ehat = "ehat",
  tau_c_hat = "tau_c_hat",
  pi_c_hat = "pi_c_hat",
  group = "z"
)
```

These helpers use logistic regression for propensity scores and linear models
for conditional contrasts. They are not required for the package workflow:
users can estimate the inputs with causal forests, BART, SuperLearner, xgboost,
or other models and then pass the resulting columns to the plotting functions.

## Paper Demo

The package includes a script showing how the paper figures can be generated
from the bundled paper intermediate outputs using the package API. These are
the intermediate files needed for the CP-plot figures, not the full raw-data
analysis workflow.

After installing `causalcp`, run:

```r
library(causalcp)

source(system.file(
  "paper-examples/reproduce-paper-plots.R",
  package = "causalcp"
))

reproduce_paper_plots()
```

This creates package-based versions of:

- the 8-panel observational CP plot,
- the 401(k) local CP plot,
- CSV files containing the corresponding slope diagnostics.

The outputs are written to `paper_demo_outputs/` in the current working
directory.

If you locally regenerate the paper analysis outputs and want to use those
instead of the bundled copies, pass `paper_dir` explicitly:

```r
paper_dir <- "/path/to/your/paper-analysis-directory"

reproduce_paper_plots(
  paper_dir = paper_dir,
  output_dir = file.path(paper_dir, "paper_demo_outputs")
)
```

## Citation

```r
citation("causalcp")
```
