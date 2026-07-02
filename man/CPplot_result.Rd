\name{CPplot_result}
\alias{CPplot_result}
\alias{print.CPplot_result}
\title{Causal CP result object}
\usage{
\method{print}{CPplot_result}(x, ...)
}
\arguments{
\item{x}{A \code{CPplot_result} object.}
\item{...}{Unused.}
}
\value{
The input object, invisibly.
}
\description{
Objects returned by \code{cp_plot()} and \code{local_cp_plot()} contain a
\code{ggplot} object, slope summaries, bracketing interpretations, a compact
bracketing summary, and the filtered plotting data.
}
