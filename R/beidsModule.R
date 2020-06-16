###############################################################################@
## Helpers (not exported) ----

#' @importFrom shiny callModule
moduleServer <- function(id, module){
   shiny::callModule(module, id)
}

highlightText <- function(text, value){
   value <- sub('^"', '', sub('"$', '', value))
   value <- gsub("[[:punct:]]", ".?", value)
   return(unlist(lapply(
      text,
      function(x){
         if(is.na(x)){
            return(x)
         }
         p <- gregexpr(value, x, ignore.case=TRUE)[[1]]
         if(p[1]>0){
            toRet <- c(substr(x, 0, p[1]-1))
            for(i in 1:length(p)){
               toRet <- c(
                  toRet,
                  '<mark style="background-color:yellow;font-weight:bold;">',
                  substr(x, p[i], p[i]+attr(p, "match.length")[i]-1),
                  '</mark>',
                  substr(
                     x,
                     p[i]+attr(p, "match.length")[i],
                     min(
                        p[i+1]-1,
                        nchar(x)+1,
                        na.rm=TRUE
                     )
                  )
               )
            }
            toRet <- paste(toRet, collapse="")
         }else{
            toRet <- x
         }
         return(toRet)
      }
   )))
}

###############################################################################@
## Module ----

#' Shiny module for searching BEIDs
#'
#' @param id an identifier for the module instance
#' @param toGene focus on gene entities (default=TRUE): matches from other
#' BE are converted to genes.
#' @param multiple allow multiple selections (default=FALSE)
#' @param beOfInt if toGene==FALSE, BE to consider (default=NULL ==> all)
#' @param selectBe if toGene==FALSE, display an interface for selecting BE
#' @param orgOfInt organism to consider (default=NULL ==> all)
#' @param selectOrg display an interface for selecting organisms
#' @param tableHeight height of the result table (default: 150)
#'
#' @return A reactive data.frame with the following columns:
#' - **beid**: the BE identifier
#' - **preferred**: preferred identifier for the same BE in the same scope
#' - **be**: the type of biological entity
#' - **source**: the source of the identifier
#' - **organism**: the BE organism
#' - **entity**:  internal identifier of the BE
#' - **match**: the matching character string
#'
#' @examples \dontrun{
#' library(shiny)
#' library(BED)
#' library(DT)
#'
#' ui <- fluidPage(
#'    beidsUI("be"),
#'    fluidRow(
#'       column(
#'          12,
#'          tags$br(),
#'          h3("Selected gene entities"),
#'          DTOutput("result")
#'       )
#'    )
#' )
#'
#' server <- function(input, output){
#'    found <- beidsServer("be", toGene=TRUE, multiple=TRUE, tableHeight=250)
#'    output$result <- renderDT({
#'       req(found())
#'       toRet <- found()
#'       datatable(toRet, rownames=FALSE)
#'    })
#' }
#'
#' shinyApp(ui = ui, server = server)
#' }
#'
#' @importFrom shiny reactive renderUI observe fluidRow column textInput NS selectizeInput reactiveValues withProgress req
#' @importFrom DT datatable DTOutput renderDT formatStyle styleEqual
#' @export
#'
beidsServer <- function(
   id,
   toGene=TRUE,
   multiple=FALSE,
   beOfInt=NULL, selectBe=TRUE,
   orgOfInt=NULL, selectOrg=TRUE,
   tableHeight=150
){
   if(toGene){
      selectBe <- FALSE
      beOfInt <- c(listBe(), "Probe")
   }
   moduleServer(id, function(input, output, session) {

      ## Main UI ----
      allOrg <- sort(listOrganisms())
      allBe <- c(listBe(), "Probe")
      ni <- 1
      if(selectOrg){
         ni <- ni+1
      }
      if(selectBe){
         ni <- ni+1
      }
      cw <- 12 %/% ni
      output$mainUI <- shiny::renderUI({
         shiny::fluidRow(shiny::column(12,
            shiny::fluidRow(
               shiny::column(
                  cw,
                  shiny::textInput(
                     inputId=shiny::NS(id, "beSearchTerm"),
                     label="Search a gene",
                     placeholder='e.g. snca, ENSG00000186868, "M-CSF receptor"',
                     width="100%"
                  )
               ),
               if(selectBe){
                  shiny::column(
                     cw,
                     shiny::selectizeInput(
                        inputId=shiny::NS(id, "beFocus"),
                        label="Focus on BE",
                        choices=allBe,
                        selected=beOfInt,
                        multiple=TRUE,
                        width="100%"
                     )
                  )
               },
               if(selectOrg){
                  shiny::column(
                     cw,
                     shiny::selectizeInput(
                        inputId=shiny::NS(id, "beOrganisms"),
                        label="Focus on organisms",
                        choices=allOrg,
                        selected=orgOfInt,
                        multiple=TRUE,
                        width="100%"
                     )
                  )
               }
            ),
            shiny::fluidRow(
               shiny::column(
                  12,
                  DT::DTOutput(
                     shiny::NS(id, "searchRes")
                  )
               )
            )
         ))
      })

      ## Application state ----
      appState <- shiny::reactiveValues(
         ## User choices
         orgOfInt=orgOfInt,
         beOfInt=beOfInt,
         ## Matches
         matches=NULL,
         genes=NULL,
         ## Filtered matches
         fmatches=NULL,
         fgense=NULL,
         geneEntity=NULL,
         ## Selection
         sel=NULL
      )

      ## Select organisms ----
      if(selectOrg){
         shiny::observe({
            selOrg <- input$beOrganisms
            if(length(selOrg)==0){
               appState$orgOfInt <- allOrg
            }else{
               appState$orgOfInt <- selOrg
            }
            appState$sel <- NULL
         })
      }

      ## Select BE ----
      if(selectBe){
         shiny::observe({
            selBe <- input$beFocus
            if(length(selBe)==0){
               appState$beOfInt <- allBe
            }else{
               appState$beOfInt <- selBe
            }
            appState$sel <- NULL
         })
      }

      ## Search a given term ----
      shiny::observe({
         v <- input$beSearchTerm
         if(is.null(v)){
            m <- g <- NULL
         }else{
            shiny::withProgress(
               message="Searching genes",
               value=0,
               style="notification",
               expr={
                  m <- searchBeid(v)
               }
            )
            if(is.null(m) || nrow(m)==0){
               m <- g <- NULL
            }else{
               .data <- NULL
               g <- dplyr::mutate(m, order=1:nrow(m))
               g <- dplyr::mutate(
                  g, url=getBeIdURL(.data$GeneID, .data$Gene_source)
               )
               g <- dplyr::group_by(g, .data$Gene_entity, .data$organism)
               g <- dplyr::summarise(
                  g,
                  order=min(.data$order),
                  value=ifelse(
                     length(unique(.data$value)) <= 2,
                     paste(unique(.data$value), collapse=", "),
                     paste(
                        c(head(unique(.data$value), 2), "..."),
                        collapse=", "
                     )
                  ),
                  from=paste(unique(ifelse(
                     .data$from %in% c("BESymbol", "BEName"),
                     stringr::str_replace(
                        .data$from, "^BE", paste(.data$be, " ")
                     ),
                     sprintf(
                        '%s%s',
                        .data$from,
                        ifelse(
                           !is.na(.data$symbol),
                           ifelse(
                              !is.na(.data$name),
                              sprintf(': %s (%s)', .data$symbol, .data$name),
                              sprintf(': %s', .data$symbol)
                           ),
                           ifelse(
                              !is.na(.data$name),
                              sprintf(' (%s)', .data$name),
                              ''
                           )
                        )
                     )
                  )), collapse=", "),
                  symbol=paste(setdiff(.data$symbol, NA), collapse=", "),
                  name=paste(setdiff(.data$name, NA), collapse=", "),
                  GeneIDs=paste(unique(sprintf(
                     '<a href="%s" target="_blank">%s</a>',
                     url,
                     highlightText(
                        sprintf(
                           '%s%s%s',
                           ifelse(.data$preferred_gene, "<u><strong>", ""),
                           .data$GeneID,
                           ifelse(.data$preferred_gene, "</strong></u>", "")
                        ),
                        !!v
                     )
                  )[order(.data$preferred_gene, decreasing=T)]), collapse=","),
                  Gene_symbol=paste(
                     setdiff(.data$Gene_symbol, NA), collapse=", "
                  ),
                  Gene_name=paste(
                     setdiff(.data$Gene_name, NA), collapse=", "
                  )
               )
               g <- dplyr::arrange(g, .data$order)
               g <- dplyr::select(
                  g,
                  "value", "from",
                  "Gene_symbol", "Gene_name", "organism", "GeneIDs",
                  "Gene_entity"
               )
               g <- dplyr::ungroup(g)
            }
         }
         if(!is.null(m)){
            m <- dplyr::rename(m, "match"="value")
         }
         if(!is.null(g)){
            g <- dplyr::rename(g, "match"="value")
         }
         appState$matches <- m
         appState$genes <- g
         appState$sel <- NULL
      })

      ## Filter matches ----
      shiny::observe({
         fmatches <- appState$matches[
            which(
               appState$matches$organism %in% appState$orgOfInt &
                  appState$matches$be %in% appState$beOfInt
            ),
         ]
         if(!is.null(fmatches) && nrow(fmatches)==0){
            fmatches <- NULL
         }else{
            if(!toGene && !is.null(fmatches)){
               fmatches <- dplyr::distinct(dplyr::select(
                  fmatches,
                  "match", "from", "be", "beid", "source", "preferred",
                  "symbol", "name", "entity", "organism"
               ))
            }
         }
         fgenes <- appState$genes[
            which(
               appState$genes$organism %in% appState$orgOfInt
            ),
         ]
         if(!is.null(fgenes) && nrow(fgenes)==0){
            fgenes <- NULL
         }
         appState$fmatches <- fmatches
         appState$fgenes <- fgenes
         appState$sel <- NULL
      })

      ## Show the results ----
      output$searchRes <- DT::renderDataTable({
         v <- input$beSearchTerm
         if(toGene){
            toShow <- appState$fgenes
            shiny::req(toShow)
            toShow <- dplyr::select(
               dplyr::mutate(
                  toShow,
                  Match=highlightText(.data$match, !!v),
                  From=highlightText(.data$from, !!v),
                  Symbol=highlightText(.data$Gene_symbol, !!v),
                  Name=highlightText(.data$Gene_name, !!v),
                  Organism=as.factor(.data$organism)
               ),
               "Match", # "From",
               "Symbol", "Name", "Organism", "GeneIDs",
            )
         }else{
            toShow <- appState$fmatches
            shiny::req(toShow)
            toShow <- dplyr::select(
               dplyr::mutate(
                  toShow,
                  Match=highlightText(.data$match, !!v),
                  From=highlightText(.data$from, !!v),
                  Symbol=highlightText(.data$symbol, !!v),
                  Name=highlightText(.data$name, !!v),
                  Organism=as.factor(.data$organism),
                  ID=sprintf(
                     '<a href="%s" target="_blank">%s</a>',
                     getBeIdURL(.data$beid, .data$source),
                     highlightText(.data$beid, !!v)
                  )
               ),
               "Match", # "From",
               "BE"="be", "Symbol", "Name", "Organism", "ID",
               "Source"="source", "Preferred"="preferred"
            )
         }
         toShow <- DT::datatable(
            toShow,
            rownames=FALSE,
            escape=FALSE,
            selection=list(
               mode=ifelse(multiple, "multiple",  "single"),
               target="row"
            ),
            options=list(
               dom="t",
               paging=FALSE,
               scrollResize=TRUE,
               scrollY=tableHeight,
               scrollCollapse=TRUE
            )
         )
         if(!toGene){
            DT::formatStyle(
               toShow, "Preferred",
               backgroundColor=DT::styleEqual(
                  c(TRUE, FALSE), c('darkgreen', 'transparent')
               ),
               color=DT::styleEqual(
                  c(TRUE, FALSE), c('white', 'black')
               )
            )
         }else{
            toShow
         }
      })
      shiny::observe({
         appState$sel <- input$searchRes_rows_selected
      })

      ## Return the results ----
      return(shiny::reactive({
         sel <- appState$sel
         g <- appState$fgenes
         m <- appState$fmatches
         if(
            length(sel)==0 ||
            is.null(g) || nrow(g)==0 ||
            is.null(m) || nrow(m)==0
         ){
            return(NULL)
         }else{
            if(toGene){
               ge <- unique(g$Gene_entity[sel])
               toRet <- unique(m[
                  which(m$Gene_entity %in% ge),
                  c(
                     "GeneID", "preferred_gene", "Gene_source", "organism",
                     "Gene_entity"
                  )
               ])
               colnames(toRet) <- c(
                  "beid", "preferred", "source", "organism", "entity"
               )
               if(nrow(toRet)>0){
                  toRet$be <- "Gene"
                  toRet <- dplyr::left_join(
                     toRet,
                     g[,c("Gene_entity", "match")],
                     by=c("entity"="Gene_entity")
                  )
                  toRet <- toRet[
                     ,
                     c(
                        "beid", "preferred", "be", "source", "organism",
                        "entity", "match"
                     )
                  ]
               }
            }else{
               toRet <- m[
                  sel,
                  c(
                     "beid",  "preferred", "be", "source", "organism",
                     "entity", "match"
                  )
               ]
            }
            return(toRet)
         }
      }))
   })
}

###############################################################################@
#' @describeIn beidsServer
#'
#' @importFrom shiny uiOutput NS
#' @export
#'
beidsUI <- function(id) {
   shiny::uiOutput(outputId=NS(id, "mainUI"))
}
