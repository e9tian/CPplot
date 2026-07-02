\name{cp_slopes}
\alias{cp_slopes}
\title{Compute CP-plot linear-fit slopes}
\usage{
cp_slopes(data, e_hat, tau_hat, treatment = NULL)
}
\arguments{
\item{data}{A data frame.}
\item{e_hat}{Character name of the estimated propensity-score column.}
\item{tau_hat}{Character name of the estimated CATE column.}
\item{treatment}{Optional character name of a 0/1 treatment indicator column.}
}
\value{
A data frame with fit label, sample size, slope, standard error, and p-value.
}
\description{
Computes slopes from linear regressions of estimated CATEs on estimated
propensity scores using full-sample fits with weights \eqn{1},
\eqn{\hat e(X)}, and \eqn{1-\hat e(X)}. When \code{treatment} is supplied, it is
used only to keep the finite analysis sample aligned with the plotted points.
}
