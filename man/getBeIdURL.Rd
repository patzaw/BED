% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getBeIdURL.R
\name{getBeIdURL}
\alias{getBeIdURL}
\title{Get reference URLs for BE IDs}
\usage{
getBeIdURL(ids, databases)
}
\arguments{
\item{ids}{the BE ID}

\item{databases}{the databases from which each ID has been taken
(if only one database is provided it is chosen for all ids)}
}
\value{
A character vector of the same length than ids
corresponding to the relevant URLs.
NA is returned is there is no URL corresponding to the provided database.
}
\description{
Get reference URLs for BE IDs
}
\examples{
\dontrun{
getBeIdURL(c("100", "ENSG00000145335"), c("EntrezGene", "Ens_gene"))
}

}
