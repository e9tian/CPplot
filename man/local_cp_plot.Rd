\name{local_cp_plot}
\alias{local_cp_plot}
\title{Draw a local CP plot}
\usage{
local_cp_plot(data, e_hat, tau_c_hat, pi_c_hat, group = NULL,
  point_labels = c("Control", "Treated"),
  title = NULL, alpha = 0.35, point_size = 0.8)
}
\arguments{
\item{data}{A data frame.}
\item{e_hat}{Character name of the estimated IV propensity-score column.}
\item{tau_c_hat}{Character name of the estimated conditional complier treatment effect column.}
\item{pi_c_hat}{Character name of the estimated complier score or first-stage column used as weights.}
\item{group}{Optional character name of a 0/1 instrument-group column.}
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
\eqn{\hat\pi^c(X)\{1-\hat e(X)\}}. When \code{group} is supplied, it controls
the point shapes but not the regression samples.
}
