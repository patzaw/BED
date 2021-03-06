% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/listBeIdSources.R
\name{listBeIdSources}
\alias{listBeIdSources}
\title{Lists all the databases taken into account in the BED database
for a biological entity (BE)}
\usage{
listBeIdSources(
  be = listBe(),
  organism,
  direct = FALSE,
  rel = NA,
  restricted = FALSE,
  recache = FALSE,
  verbose = FALSE,
  exclude = c()
)
}
\arguments{
\item{be}{the BE on which to focus}

\item{organism}{the name of the organism to focus on.}

\item{direct}{a logical value indicating if only "direct" BE identifiers
should be considered}

\item{rel}{a type of relationship to consider in the query
(e.g. "is_member_of") in order to focus on specific information.
If NA (default) all be are taken into account whatever their available
relationships.}

\item{restricted}{boolean indicating if the results should be restricted to
current version of to BEID db. If FALSE former BEID are also returned.
There is no impact if direct is set to TRUE.}

\item{recache}{boolean indicating if the CQL query should be run even if
the table is already in cache}

\item{verbose}{boolean indicating if the CQL query should be shown.}

\item{exclude}{database to exclude from possible selection. Used to filter
out technical database names such as "BEDTech_gene" and "BEDTech_transcript"
used to manage orphan IDs (not linked to any gene based on information
taken from sources)}
}
\value{
A data.frame indicating the number of ID in each available database
with the following fields:
\itemize{
\item \strong{database}: the database name
\item \strong{nbBe}: number of distinct entities
\item \strong{nbId}: number of identifiers
\item \strong{be}: the BE under focus
}
}
\description{
Lists all the databases taken into account in the BED database
for a biological entity (BE)
}
\examples{
\dontrun{
listBeIdSources(be="Transcript", organism="mouse")
}

}
\seealso{
\link{listBe}, \link{largestBeSource}
}
