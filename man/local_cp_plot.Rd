\name{local_cp_plot}
\alias{local_cp_plot}
\title{Draw a local CP plot}
\usage{
local_cp_plot(formula = NULL, data, e_hat = NULL,
  tau_c_hat = NULL, pi_c_hat = NULL, iv = NULL,
  e_method = "logistic", contrast_method = "ols",
  min_first_stage = 1e-6,
  point_labels = c("Control", "Treated"),
  title = NULL, alpha = 0.35, point_size = 0.8)
}
\arguments{
\item{formula}{Optional IV formula of the form
\code{y ~ d + x1 + x2 | z + x1 + x2}. The first right-hand-side block gives
the binary treatment followed by covariates; the block after \code{|} gives the
binary IV followed by the same covariates.}
\item{data}{A data frame.}
\item{e_hat}{Optional character name of the estimated IV propensity-score column.}
\item{tau_c_hat}{Optional character name of the estimated conditional complier treatment effect column.}
\item{pi_c_hat}{Optional character name of the estimated complier score or first-stage column used as weights.}
\item{iv}{Optional character name of a 0/1 IV column used for point shapes in
fitted-input mode.}
\item{e_method}{IV propensity-score method. One of \code{"logistic"} or
\code{"random_forest"}.}
\item{contrast_method}{Conditional reduced-form and first-stage method. One of
\code{"ols"} or \code{"random_forest"}.}
\item{min_first_stage}{First-stage threshold used to set unstable conditional
Wald ratios to missing in formula mode.}
\item{point_labels}{Two labels for control and treated points.}
\item{title}{Optional plot title.}
\item{alpha}{Point alpha.}
\item{point_size}{Point size.}
}
\value{
A \code{CPplot_result} object with elements \code{plot}, \code{slopes},
\code{bracketing}, \code{bracketing_summary}, and \code{data_used}.
}
\description{
Draws a diagnostic plot of modeled conditional Wald estimates against estimated
IV propensity scores and adds full-sample weighted linear fits with weights
\eqn{\hat\pi^c(X)}, \eqn{\hat\pi^c(X)\hat e(X)}, and
\eqn{\hat\pi^c(X)\{1-\hat e(X)\}}. Users can either supply an IV formula for
default estimation or supply precomputed \code{e_hat}, \code{tau_c_hat}, and
\code{pi_c_hat} columns. When \code{iv} is supplied in fitted-input mode, it
controls the point shapes but not the regression samples.
}
