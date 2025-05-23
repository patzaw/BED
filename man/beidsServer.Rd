% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/beidsModule.R
\name{beidsServer}
\alias{beidsServer}
\alias{beidsUI}
\title{Shiny module for searching BEIDs}
\usage{
beidsServer(
  id,
  toGene = TRUE,
  excludeTechID = FALSE,
  multiple = FALSE,
  beOfInt = NULL,
  selectBe = TRUE,
  orgOfInt = NULL,
  selectOrg = TRUE,
  groupBySymbol = FALSE,
  searchLabel = "Search a gene",
  matchColname = "Match",
  selectFirst = FALSE,
  oneColumn = FALSE,
  withId = FALSE,
  maxHits = 75,
  compact = FALSE,
  tableHeight = 150,
  highlightStyle = "",
  highlightClass = "bed-search"
)

beidsUI(id)
}
\arguments{
\item{id}{an identifier for the module instance}

\item{toGene}{focus on gene entities (default=TRUE): matches from other
BE are converted to genes.}

\item{excludeTechID}{do not display BED technical BEIDs}

\item{multiple}{allow multiple selections (default=FALSE)}

\item{beOfInt}{if toGene == FALSE, BE to consider (default=NULL ==> all)}

\item{selectBe}{if toGene == FALSE, display an interface for selecting BE}

\item{orgOfInt}{organism to consider (default=NULL ==> all)}

\item{selectOrg}{display an interface for selecting organisms}

\item{groupBySymbol}{if TRUE also use gene symbols to aggregate results with
more granularity (taken into account only when toGene == TRUE)}

\item{searchLabel}{display label for the search field or NULL for no label}

\item{matchColname}{display name of the match column}

\item{selectFirst}{if TRUE the first row is selected by default}

\item{oneColumn}{if TRUE the hits are displayed in only one column}

\item{withId}{if FALSE and one column, the BEIDs are not shown}

\item{maxHits}{maximum number of raw hits to return}

\item{compact}{compact display (default: FALSE)}

\item{tableHeight}{height of the result table (default: 150)}

\item{highlightStyle}{style to apply to the text to highlight}

\item{highlightClass}{class to apply to the text to highlight}
}
\value{
A reactive data.frame with the following columns:
\itemize{
\item \strong{beid}: the BE identifier
\item \strong{preferred}: preferred identifier for the same BE in the same scope
\item \strong{be}: the type of biological entity
\item \strong{source}: the source of the identifier
\item \strong{organism}: the BE organism
\item \strong{entity}:  internal identifier of the BE
\item \strong{match}: the matching character string
}
}
\description{
Shiny module for searching BEIDs
}
\section{Functions}{
\itemize{
\item \code{beidsUI()}: 

}}
\examples{
\dontrun{
library(shiny)
library(BED)
library(DT)

ui <- fluidPage(
   beidsUI("be"),
   fluidRow(
      column(
         12,
         tags$br(),
         h3("Selected gene entities"),
         DTOutput("result")
      )
   )
)

server <- function(input, output){
   found <- beidsServer("be", toGene=TRUE, multiple=TRUE, tableHeight=250)
   output$result <- renderDT({
      req(found())
      toRet <- found()
      datatable(toRet, rownames=FALSE)
   })
}

shinyApp(ui = ui, server = server)
}

}
