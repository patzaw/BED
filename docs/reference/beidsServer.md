# Shiny module for searching BEIDs

Shiny module for searching BEIDs

## Usage

``` r
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
  fuzzy = TRUE,
  compact = FALSE,
  tableHeight = 150,
  highlightStyle = "",
  highlightClass = "bed-search",
  inputUpdateOn = c("change", "blur")
)

beidsUI(id)
```

## Arguments

- id:

  an identifier for the module instance

- toGene:

  focus on gene entities (default=TRUE): matches from other BE are
  converted to genes.

- excludeTechID:

  do not display BED technical BEIDs

- multiple:

  allow multiple selections (default=FALSE)

- beOfInt:

  if toGene == FALSE, BE to consider (default=NULL ==\> all)

- selectBe:

  if toGene == FALSE, display an interface for selecting BE

- orgOfInt:

  organism to consider (default=NULL ==\> all)

- selectOrg:

  display an interface for selecting organisms

- groupBySymbol:

  if TRUE also use gene symbols to aggregate results with more
  granularity (taken into account only when toGene == TRUE)

- searchLabel:

  display label for the search field or NULL for no label

- matchColname:

  display name of the match column

- selectFirst:

  if TRUE the first row is selected by default

- oneColumn:

  if TRUE the hits are displayed in only one column

- withId:

  if FALSE and one column, the BEIDs are not shown

- maxHits:

  maximum number of raw hits to return

- fuzzy:

  if TRUE (default) a fuzzy search is applied on names and symbols.

- compact:

  compact display (default: FALSE)

- tableHeight:

  height of the result table (default: 150)

- highlightStyle:

  style to apply to the text to highlight

- highlightClass:

  class to apply to the text to highlight

- inputUpdateOn:

  A character vector specifying when the input should be updated.
  Options are "change" (default) and "blur". Use "change" to update the
  input immediately whenever the value changes. Use "blur"to delay the
  input update until the input loses focus (the user moves away from the
  input), or when Enter is pressed.

## Value

A reactive data.frame with the following columns:

- **beid**: the BE identifier

- **preferred**: preferred identifier for the same BE in the same scope

- **be**: the type of biological entity

- **source**: the source of the identifier

- **organism**: the BE organism

- **entity**: internal identifier of the BE

- **match**: the matching character string

## Functions

- `beidsUI()`:

## Examples

``` r
if (FALSE) { # \dontrun{
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
} # }
```
