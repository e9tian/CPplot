\name{paper_datasets}
\alias{paper_datasets}
\alias{paper_data_dir}
\alias{load_paper_cp_data}
\alias{load_paper_401k_data}
\title{Access bundled paper intermediate data}
\usage{
paper_datasets()

paper_data_dir()

load_paper_cp_data(setting)

load_paper_401k_data()
}
\arguments{
\item{setting}{Character name of an observational CP-plot setting, as listed by
\code{paper_datasets()}.}
}
\value{
\code{paper_datasets()} returns a data frame describing the bundled paper
intermediate datasets. \code{paper_data_dir()} returns the path to the bundled
paper data directory. \code{load_paper_cp_data()} and
\code{load_paper_401k_data()} return data frames.
}
\description{
Access the intermediate data bundled with \code{CPplot} for reproducing the
paper diagnostic plots. These are the estimated propensity scores, treatment
effect summaries, and local IV summaries used by the paper demo, not the full
raw-data analysis workflow.
}
\examples{
paper_datasets()
rhc <- load_paper_cp_data("rhc")
head(rhc[, c("propensity_scores", "tau_hat")])
k401 <- load_paper_401k_data()
head(k401[, c("e_hat", "delta_d", "tau_c_hat")])
}
