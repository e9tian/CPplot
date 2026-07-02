\name{cp_plot}
\alias{cp_plot}
\title{Draw a CP plot}
\usage{
cp_plot(data, e_hat = NULL, tau_hat = NULL, treatment = NULL,
  outcome = NULL, covariates = NULL,
  e_method = "logistic", tau_method = "ols",
  point_labels = c("Control", "Treated"),
  title = NULL, alpha = 0.45, point_size = 1)
}
\arguments{
\item{data}{A data frame.}
\item{e_hat}{Optional character name of the estimated propensity-score column.}
\item{tau_hat}{Optional character name of the estimated CATE column.}
\item{treatment}{Character name of a 0/1 treatment indicator column. Required
when estimating default inputs and optional when \code{e_hat} and
\code{tau_hat} are supplied.}
\item{outcome}{Optional character name of the outcome column. Used with
\code{treatment} and \code{covariates} to estimate default inputs.}
\item{covariates}{Optional character vector of covariate column names.}
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
\eqn{1-\hat e(X)}. Users can either supply precomputed \code{e_hat} and
\code{tau_hat} columns or supply \code{outcome}, \code{treatment}, and
\code{covariates} for default estimation. When \code{treatment} is supplied, it
controls the point shapes but not the regression samples.
}
