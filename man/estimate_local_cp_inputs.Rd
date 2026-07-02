\name{estimate_local_cp_inputs}
\alias{estimate_local_cp_inputs}
\title{Estimate basic local CP-plot inputs}
\usage{
estimate_local_cp_inputs(data, outcome, treatment, instrument, covariates,
  e_method = "logistic", contrast_method = "ols",
  family = stats::binomial(), min_first_stage = 1e-6)
}
\arguments{
\item{data}{A data frame.}
\item{outcome}{Character name of the outcome column.}
\item{treatment}{Character name of the treatment column.}
\item{instrument}{Character name of the binary instrument column.}
\item{covariates}{Character vector of covariate column names.}
\item{e_method}{IV propensity-score method. One of \code{"logistic"} or
\code{"random_forest"}.}
\item{contrast_method}{Conditional contrast method. One of \code{"ols"} or
\code{"random_forest"}.}
\item{family}{Family passed to \code{stats::glm()} for the IV propensity score.}
\item{min_first_stage}{Minimum absolute first stage used before setting the Wald ratio to \code{NA}.}
}
\value{
The input data frame with added \code{e_hat}, \code{delta_y}, \code{delta_d},
\code{pi_c_hat}, and \code{tau_c_hat} columns.
}
\description{
Estimates IV propensity scores with logistic regression and conditional
reduced-form and first-stage contrasts with simple linear models by default.
Random forest estimation is available through the optional \code{ranger}
package. This helper is intended for transparent examples; users can supply
estimates from any model to \code{local_cp_plot()}.
}
