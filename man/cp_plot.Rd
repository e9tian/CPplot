\name{cp_plot}
\alias{cp_plot}
\title{Draw a CP plot}
\usage{
cp_plot(formula = NULL, data, e_hat = NULL, tau_hat = NULL,
  treatment = NULL,
  e_method = "logistic", tau_method = "ols",
  point_labels = c("Control", "Treated"),
  title = NULL, alpha = 0.35, point_size = 1)
}
\arguments{
\item{formula}{Optional formula. For outcome \code{y}, binary treatment
\code{z}, and covariates \code{x1} and \code{x2}, use
\code{y ~ z + x1 + x2}.}
\item{data}{A data frame.}
\item{e_hat}{Optional character name of the estimated propensity-score column.}
\item{tau_hat}{Optional character name of the estimated CATE column.}
\item{treatment}{Optional character name of a 0/1 treatment indicator column
used for point shapes when \code{e_hat} and \code{tau_hat} are supplied.}
\item{e_method}{Propensity-score method. One of \code{"logistic"} or
\code{"random_forest"}.}
\item{tau_method}{CATE method. One of \code{"ols"} or
\code{"random_forest"}.}
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
Draws a diagnostic plot of estimated CATEs against estimated propensity scores
and adds full-sample linear fits with weights \eqn{1}, \eqn{\hat e(X)}, and
\eqn{1-\hat e(X)}. Users can either supply a formula for default estimation or
supply precomputed \code{e_hat} and \code{tau_hat} columns. When
\code{treatment} is supplied in fitted-input mode, it controls the point shapes
but not the regression samples.
}
