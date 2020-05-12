#' Find Biological Entity identifiers
#'
#' @param toGene focus on gene entities (default=TRUE): matches from other
#' BE are converted to genes.
#' @param ... parameters for [beidsServer]
#'
#' @return NULL if not any result, or a data.frame with the selected
#' values and the following column:
#'
#' - **value**: the BE identifier
#' - **preferred**: preferred identifier for the same BE in the same scope
#' - **be**: the type of biological entity
#' - **source**: the source of the identifier
#' - **organism**: the organism of the BE
#' - **canonical** (if toGene==TRUE): canonical gene product? (if known)
#' - **symbol**: the symbol of the identifier (if any)
#'
#' @importFrom shiny fluidPage reactiveValues observe renderUI uiOutput runGadget dialogViewer fluidRow column tags req isolate
#' @importFrom DT datatable renderDT DTOutput
#' @importFrom miniUI gadgetTitleBar
#' @export
#'
findBeids <- function(toGene=TRUE, ...){

   require(BED)
   if(!checkBedConn()){
      stop()
   }

   ############################################################################@
   ## UI ----
   ui <- shiny::fluidPage(
      miniUI::gadgetTitleBar("Find Identifiers of a Biological Entity"),
      beidsUI("be"),
      shiny::uiOutput("resUI")
   )

   ############################################################################@
   ## Server ----
   server <- function(input, output, session) {

      ## Application state ----
      appState <- shiny::reactiveValues(
         ## User choices
         ## Conversions
         conv=NULL
      )

      ## Search entities ----
      found <- beidsServer("be", toGene=toGene, ...)

      ## Extend to all identifiers ----
      shiny::observe({
         matches <- found()
         if(is.null(matches) || nrow(matches)==0){
            conv <- NULL
         }else{
            if(toGene){
               orthologs <- input$orthologs
               if(is.null(orthologs)){
                  conv <- NULL
               }else{
                  suppressWarnings(conv <- geneIDsToAllScopes(
                     entities=unique(matches$entity),
                     orthologs=orthologs
                  ))
                  conv <- conv[,intersect(
                     c(
                        "value", "preferred", "be", "source", "organism",
                        "canonical", "symbol"
                     ),
                     colnames(conv)
                  )]
               }
            }else{
               suppressWarnings(conv <- beIDsToAllScopes(
                  entities=unique(matches$entity)
               ))
               conv <- conv[,intersect(
                  c(
                     "value", "preferred", "be", "source", "organism",
                     "canonical", "symbol"
                  ),
                  colnames(conv)
               )]
            }
         }
         appState$conv <- conv
      })

      ## Result table ----
      output$beoi <- DT::renderDT({
         conv <- appState$conv
         req(conv)
         conv$be <- as.factor(conv$be)
         conv$organism <- as.factor(conv$organism)
         DT::datatable(
            conv,
            rownames=FALSE,
            selection="multiple",
            filter="top",
            options=list(
               pageLength=5,
               dom="tip"
            )
         )
      })

      ## Result UI ----
      output$resUI <- shiny::renderUI({
         matches <-found()
         shiny::req(matches)
         shiny::fluidRow(shiny::column(12,
            shiny::fluidRow(
               shiny::column(
                  6,
                  shiny::h4("Relevant identifiers")
               ),
               if(toGene){
                  shiny::column(
                     6,
                     shiny::checkboxInput(
                        "orthologs", label="With orthologs",
                        value=TRUE
                     )
                  )
               },
               style="margin-top:25px;"
            ),
            shiny::fluidRow(
               shiny::column(
                  12,
                  DT::DTOutput(
                     "beoi"
                  )
               )
            )
         ))
      })

      ## Done ----
      shiny::observeEvent(input$done, {
         # Return the selected ID
         toRet <- shiny::isolate(appState$conv)
         if(is.null(toRet) || nrow(toRet)==0){
            shiny::stopApp(NULL)
         }else{
            sel <- shiny::isolate(input$beoi_rows_selected)
            if(length(sel)>0){
               toRet <- toRet[sel,]
            }
            shiny::stopApp(toRet)
         }
      })

   }
   shiny::runGadget(
      ui, server,
      viewer = shiny::dialogViewer("Find BE", height=800, width=1000)
   )

}
