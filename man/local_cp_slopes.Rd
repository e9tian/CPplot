\name{local_cp_slopes}
\alias{local_cp_slopes}
\title{Compute local CP-plot weighted slopes}
\usage{
local_cp_slopes(data, e_hat, tau_c_hat, pi_c_hat, group = NULL)
}
\arguments{
\item{data}{A data frame.}
\item{e_hat}{Character name of the estimated IV propensity-score column.}
\item{tau_c_hat}{Character name of the estimated conditional complier treatment effect column.}
\item{pi_c_hat}{Character name of the estimated complier score or first-stage column used as weights.}
\item{group}{Optional character name of a 0/1 instrument-group column.}
}
\value{
A data frame with fit label, sample size, weighted slope, standard error, and
p-value.
}
\description{
Computes \code{pi_c_hat}-weighted slopes from linear regressions of estimated
conditional complier treatment effects on estimated IV propensity scores using
full-sample weights \eqn{\hat\pi^c(X)}, \eqn{\hat\pi^c(X)\hat e(X)}, and
\eqn{\hat\pi^c(X)\{1-\hat e(X)\}}. When \code{group} is supplied, it is used
only to keep the finite analysis sample aligned with the plotted points.
}
