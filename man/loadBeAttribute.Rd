% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/loadBeAttribute.R
\name{loadBeAttribute}
\alias{loadBeAttribute}
\title{Feeding BED: Load attributes for biological entities in BED}
\usage{
loadBeAttribute(d, be = "Gene", dbname, attribute)
}
\arguments{
\item{d}{a data.frame providing for each BE ID ("id" column) an attribute
value ("value" column). There can be several values for each id.}

\item{be}{a character corresponding to the BE type (default: "Gene")}

\item{dbname}{the DB from which the BE ID are taken}

\item{attribute}{the name of the attribute to be loaded}
}
\description{
Not exported to avoid unintended modifications of the DB.
}
