\name{estimate_cp_inputs}
\alias{estimate_cp_inputs}
\title{Estimate basic CP-plot inputs}
\usage{
estimate_cp_inputs(data, outcome, treatment, covariates,
  e_method = "logistic", tau_method = "ols",
  family = stats::binomial())
}
\arguments{
\item{data}{A data frame.}
\item{outcome}{Character name of the outcome column.}
\item{treatment}{Character name of the binary treatment column.}
\item{covariates}{Character vector of covariate column names.}
\item{e_method}{Propensity-score method. One of \code{"logistic"} or
\code{"random_forest"}.}
\item{tau_method}{CATE method. One of \code{"ols"} or
\code{"random_forest"}.}
\item{family}{Family passed to \code{stats::glm()} for the propensity score.}
}
\value{
The input data frame with added \code{e_hat} and \code{tau_hat} columns.
}
\description{
Estimates propensity scores with logistic regression and CATEs with a simple
two-model OLS outcome contrast by default. Random forest estimation is available
through the optional \code{ranger} package. This helper is intended for
transparent examples; users can supply estimates from any model to
\code{cp_plot()}.
}
