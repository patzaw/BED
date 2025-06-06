% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getBeIdNames.R
\name{getBeIdNames}
\alias{getBeIdNames}
\title{Get names of Biological Entity identifiers}
\usage{
getBeIdNames(ids, be, source, organism, limForCache = 4000, ...)
}
\arguments{
\item{ids}{list of identifiers}

\item{be}{one BE. \strong{Guessed if not provided}}

\item{source}{the BE ID database. \strong{Guessed if not provided}}

\item{organism}{organism name. \strong{Guessed if not provided}}

\item{limForCache}{if there are more ids than limForCache results are
collected for all IDs (beyond provided ids) and cached for futur queries.
If not, results are collected only for provided ids and not cached.}

\item{...}{params for the \link{getBeIdNameTable} function}
}
\value{
a data.frame mapping BE IDs and names with the
following fields:
\itemize{
\item \strong{id}: the BE ID
\item \strong{name}: the corresponding name
\item \strong{canonical}: true if the name is canonical for the direct BE ID
(often FALSE for backward compatibility)
\item \strong{direct}: true if the name is directly related to the BE ID
\item \strong{preferred}: true if the id is the preferred identifier for the BE
\item \strong{entity}: (optional) the technical ID of to BE
}
}
\description{
Get names of Biological Entity identifiers
}
\examples{
\dontrun{
getBeIdNames(
   ids=c("10", "100"),
   be="Gene",
   source="EntrezGene",
   organism="human"
)
}

}
\seealso{
\link{getBeIdNameTable}, \link{getBeIdSymbols}
}
