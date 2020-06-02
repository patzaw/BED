#' Find Biological Entity
#'
#' Find Biological Entity in BED based on their IDs, symbols and names
#'
#' @param be optional. If provided the search is focused on provided BEs.
#' @param organism optional.  If provided the search is focused on provided
#' organisms.
#' @param ncharSymb The minimum number of characters in searched to consider
#' incomplete symbol matches.
#' @param ncharName The minimum number of characters in searched to consider
#' incomplete name matches.
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned:
#' **Depending on history it can take a very long time to return**
#' **a very large result!**
#' @param by number of found items to be converted into relevant IDs.
#' @param exclude database to exclude from possible selection. Used to filter
#' out technical database names such as "BEDTech_gene" and "BEDTech_transcript"
#' used to manage orphan IDs (not linked to any gene based on information
#' taken from sources)
#'
#' @return A data frame with the following fields:
#' - **found**: the element found in BED corresponding to the searched term
#' - **be**: the type of the element
#' - **source**: the source of the element
#' - **organism**: the related organism
#' - **entity**: the related entity internal ID
#' - **ebe**: the BE of the related entity
#' - **canonical**: if the symbol is canonical
#' - **Relevant ID**: the seeked element id
#' - **Symbol**: the symbol(s) of the corresponding gene(s)
#' - **Name**: the symbol(s) of the corresponding gene(s)
#'
#' Scope ("be", "source" and "organism") is provided as a named list
#' in the "scope" attributes: `attr(x, "scope")``
#'
#' @importFrom shiny fluidPage fluidRow column textInput checkboxInput uiOutput reactiveValues renderUI selectInput tags actionButton observe withProgress req isolate observeEvent runGadget stopApp dialogViewer p strong
#' @importFrom DT dataTableOutput renderDataTable datatable formatStyle styleEqual
#' @importFrom miniUI gadgetTitleBar
#' @export
#'
findBe <- function(
   be=NULL, organism=NULL, ncharSymb=4, ncharName=8,
   restricted=TRUE,
   by=20,
   exclude=c("BEDTech_gene", "BEDTech_transcript")
){

   warning("Deprecated because it's too slow. Use `findBeids()` instead.")

   require(BED)
   if(!checkBedConn()){
      stop()
   }

   #############################################

   ui <- shiny::fluidPage(
      miniUI::gadgetTitleBar("Find a Biological Entity"),
      shiny::fluidRow(
         shiny::column(
            width=3,
            shiny::textInput(
               inputId="request",
               label="Searched term",
               placeholder="An ID, a symbol or name"
            )
         ),
         shiny::column(
            width=3,
            shiny::uiOutput("uiBe")
         ),
         shiny::column(
            width=3,
            shiny::uiOutput("uiOrg")
         ),
         shiny::column(
            width=3,
            shiny::uiOutput("uiSource")
         )
      ),
      shiny::fluidRow(
         shiny::column(
            width=12,
            shiny::uiOutput(
               outputId="renderRes"
            )
         )
      ),
      shiny::fluidRow(
         shiny::column(
            width=7,
            shiny::checkboxInput(
               inputId="crossOrg",
               label=shiny::p(
                  shiny::strong("Cross species search"),
                  shiny::tags$small(
                     "(time consuming and not relevant for complex objects
                     such as GO functions)"
                  )
               ),
               value=FALSE
            )
         ),
         shiny::column(
            width=5,
            shiny::checkboxInput(
               inputId="showGeneAnno",
               label=shiny::p(
                  shiny::strong("Show gene annotation"),
                  shiny::tags$small(
                     "(not relevant for complex objects such as GO functions)"
                  )
               ),
               value=FALSE
            )
         )
      )
   )

   #############################################

   server <- function(input, output, session) {

      ## Functions
      orderSearch <- function(d, r, b, o, s){
         d <- d[order(d$source==s, decreasing=TRUE),]
         d <- d[order(d$be==b, decreasing=TRUE),]
         d <- d[order(d$organism==o, decreasing=TRUE),]
         d <- d[order(nchar(d$found)),]
         d <- d[order(d$canonical, decreasing=TRUE),]
         d <- d[order(toupper(d$found)==toupper(r), decreasing=TRUE),]
         return(d)
      }
      highlightText <- function(text, value){
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

      ## Follow-up
      curSel <- shiny::reactiveValues(
         curSource=NULL,
         searchRes=NULL,
         selRes=NULL,
         results=NULL
      )

      ## Search input
      output$uiBe <- shiny::renderUI({
         return(shiny::selectInput(
            inputId="uiBe",
            label="BE of interest",
            choices=c(listBe(), "Probe")
         ))
      })
      output$uiOrg <- shiny::renderUI({
         return(shiny::selectInput(
            inputId="uiOrg",
            label="Organism of interest",
            choices=listOrganisms()
         ))
      })
      output$uiSource <- shiny::renderUI({
         be <- input$uiBe
         shiny::req(be)
         org <- input$uiOrg
         shiny::req(org)
         if(be=="Probe"){
            lp <- listPlatforms()
            choices <- lp$name
            names(choices) <- paste0(
               lp$description,
               " (", lp$name, ")"
            )
            choices <- sort(choices)
         }else{
            choices <- sort(listBeIdSources(
               be=be, organism=org,
               exclude=exclude
            )$database)
         }
         curSource <- shiny::isolate(curSel$curSource)
         if(is.null(curSource)){
            curSource <- NULL
         }else{
            curSource <- intersect(choices, curSource)
         }
         return(shiny::selectInput(
            inputId="uiSource",
            label="Source",
            choices=choices,
            selected=curSource
         ))
      })
      shiny::observe({
         curSel$curSource <- input$uiSource
      })

      ## Display output
      output$renderRes <- shiny::renderUI({
         searchRes <- curSel$searchRes
         request <- input$request
         results <- curSel$results
         sel <- curSel$selRes
         if(is.null(request) || request==""){
            return(NULL)
         }
         if(is.null(searchRes) || nrow(searchRes)==0){
            return(shiny::tags$span(
               "Input text not found anywhere",
               style='color:red;weight:bold;'
            ))
         }
         if(is.null(results) || nrow(results)==0){
            if(max(sel) < nrow(searchRes)){
               return(list(
                  shiny::tags$span(
                     sprintf(
                        "Could not find relevant IDs for the %s first terms shown below",
                        max(sel)
                     ),
                     style='color:red;weight:bold;'
                  ),
                  DT::dataTableOutput("dispRes"),
                  shiny::actionButton(
                     "nextRes",
                     label=sprintf(
                        "Try the next %s terms (%s not tried yet)",
                        by, nrow(searchRes)-max(sel)
                     )
                  )
               ))
            }
            return(list(
               shiny::tags$span(
                  "Could not find relevant IDs for terms shown below",
                  style='color:red;weight:bold;'
               ),
               DT::dataTableOutput("dispRes")
            ))
         }else{
            if(max(sel) < nrow(searchRes)){
               return(list(
                  DT::dataTableOutput("dispRes"),
                  shiny::actionButton(
                     "nextRes",
                     label=sprintf(
                        "Get results for %s additional terms (%s not tried yet)",
                        by, nrow(searchRes)-max(sel)
                     )
                  )
               ))
            }
            return(DT::dataTableOutput("dispRes"))
         }
         return(toRet)
      })

      ## Search a given term
      shiny::observe({
         curSel$searchRes <- NULL
         curSel$results <- NULL
         curSel$selRes <- NULL
         shiny::req(input$request)
         shiny::withProgress(
            message="Finding BE",
            value=0,
            style="notification",
            expr={
               searchRes <- searchId(
                  searched=input$request,
                  be=be, organism=organism,
                  ncharSymb=ncharSymb, ncharName=ncharName
               )
            }
         )
         shiny::req(searchRes)
         if(!input$crossOrg){
            searchRes <- searchRes[which(searchRes$organism==input$uiOrg),]
         }
         ibe <- shiny::isolate(input$uiBe)
         iorg <- shiny::isolate(input$uiOrg)
         isrc <- shiny::isolate(input$uiSource)
         searchRes <- orderSearch(
            d=searchRes,
            r=input$request,
            b=ibe,
            o=iorg,
            s=isrc
         )
         curSel$searchRes <- searchRes
         nsel <- sel <- 1:min(by, nrow(searchRes))
         results <- try(getRelevantIds(
            d=searchRes,
            selected=nsel,
            be=ibe, source=isrc, organism=iorg,
            restricted=restricted
         ), silent=T)
         curSel$selRes <- sel
         shiny::req(!inherits(results, "try-error"))
         # if(is.null(results) && max(sel) < nrow(searchRes)){
         #     shiny::withProgress(
         #         message="Searching for any relevant ID",
         #         value=max(sel)/nrow(searchRes),
         #         style="notification",
         #         expr={
         #             while(is.null(results) && max(sel) < nrow(searchRes)){
         #                 nsel <- (max(sel)+1):min(max(sel)+10, nrow(searchRes))
         #                 sel <- c(sel, nsel)
         #                 results <- getRelevantIds(
         #                     d=searchRes,
         #                     selected=nsel,
         #                     be=ibe, source=isrc, organism=iorg,
         #                     restricted=restricted
         #                 )
         #                 setProgress(max(sel)/nrow(searchRes))
         #             }
         #         }
         #     )
         # }
         if(!is.null(results)){
            colnames(results)[ncol(results)] <- "Relevant ID"
            if(ibe=="Gene"){
               desc <- getGeneDescription(
                  ids=setdiff(results$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(desc) <- desc$id
               colnames(desc) <- c(
                  "id", "Symbol", "Name", "Preferred",
                  "DB version", "Deprecated"
               )
            }else if(ibe=="Probe"){
               desc <- getGeneDescription(
                  ids=setdiff(results$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(desc) <- desc$id
               gs <- colnames(desc)[2]
               colnames(desc)[match(c("symbol", "name"), colnames(desc))] <-
                  paste0(
                     c("Symbol", "Name"),
                     " (", gs, ")"
                  )
               desc <- desc[,-2]
            }else{
               ddesc <- getBeIdDescription(
                  ids=setdiff(results$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(ddesc) <- ddesc$id
               colnames(ddesc) <- c(
                  "id", "Symbol", "Name", "Preferred",
                  "DB version", "Deprecated"
               )
               ddesc <- ddesc[
                  ,
                  which(apply(ddesc, 2, function(x) any(!is.na(x))))
                  ]

               if(input$showGeneAnno){
                  gdesc <- getGeneDescription(
                     ids=setdiff(results$"Relevant ID", NA),
                     be=ibe,
                     source=isrc,
                     organism=iorg
                  )
                  rownames(gdesc) <- gdesc$id
                  gs <- colnames(gdesc)[2]
                  colnames(gdesc)[match(c("symbol", "name"), colnames(gdesc))] <-
                     paste0(
                        c("Symbol", "Name"),
                        " (", gs, ")"
                     )
                  gdesc <- gdesc[,-2]
                  desc <- cbind(ddesc, gdesc[rownames(ddesc),])
               }else{
                  desc <- ddesc
               }
            }
            results <- cbind(results, desc[results$"Relevant ID", -1])
         }
         curSel$results <- results
         curSel$selRes <- sel
      })
      shiny::observe({
         ibe <- input$uiBe
         iorg <- input$uiOrg
         isrc <- input$uiSource
         curSel$results <- NULL
         curSel$selRes <- NULL
         searchRes <- shiny::isolate(curSel$searchRes)
         shiny::req(searchRes)
         searchRes <- orderSearch(
            d=searchRes,
            r=shiny::isolate(input$request),
            b=ibe,
            o=iorg,
            s=isrc
         )
         curSel$searchRes <- searchRes
         nsel <- sel <- 1:min(by, nrow(searchRes))
         results <- try(getRelevantIds(
            d=searchRes,
            selected=nsel,
            be=ibe, source=isrc, organism=iorg,
            restricted=restricted
         ), silent=TRUE)
         curSel$selRes <- sel
         shiny::req(!inherits(results, "try-error"))
         # if(is.null(results) && max(sel) < nrow(searchRes)){
         #     shiny::withProgress(
         #         message="Searching for any relevant ID",
         #         value=max(sel)/nrow(searchRes),
         #         style="notification",
         #         expr={
         #             while(is.null(results) && max(sel) < nrow(searchRes)){
         #                 nsel <- (max(sel)+1):min(max(sel)+10, nrow(searchRes))
         #                 sel <- c(sel, nsel)
         #                 results <- getRelevantIds(
         #                     d=searchRes,
         #                     selected=nsel,
         #                     be=ibe, source=isrc, organism=iorg,
         #                     restricted=restricted
         #                 )
         #                 setProgress(max(sel)/nrow(searchRes))
         #             }
         #         }
         #     )
         # }
         if(!is.null(results)){
            colnames(results)[ncol(results)] <- "Relevant ID"
            if(ibe=="Gene"){
               desc <- getGeneDescription(
                  ids=setdiff(results$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(desc) <- desc$id
               colnames(desc) <- c(
                  "id", "Symbol", "Name", "Preferred",
                  "DB version", "Deprecated"
               )
            }else if(ibe=="Probe"){
               desc <- getGeneDescription(
                  ids=setdiff(results$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(desc) <- desc$id
               gs <- colnames(desc)[2]
               colnames(desc)[match(c("symbol", "name"), colnames(desc))] <-
                  paste0(
                     c("Symbol", "Name"),
                     " (", gs, ")"
                  )
               desc <- desc[,-2]
            }else{
               ddesc <- getBeIdDescription(
                  ids=setdiff(results$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(ddesc) <- ddesc$id
               colnames(ddesc) <- c(
                  "id", "Symbol", "Name", "Preferred",
                  "DB version", "Deprecated"
               )
               ddesc <- ddesc[
                  ,
                  which(apply(ddesc, 2, function(x) any(!is.na(x))))
                  ]

               if(input$showGeneAnno){
                  gdesc <- getGeneDescription(
                     ids=setdiff(results$"Relevant ID", NA),
                     be=ibe,
                     source=isrc,
                     organism=iorg
                  )
                  rownames(gdesc) <- gdesc$id
                  gs <- colnames(gdesc)[2]
                  colnames(gdesc)[match(c("symbol", "name"), colnames(gdesc))] <-
                     paste0(
                        c("Symbol", "Name"),
                        " (", gs, ")"
                     )
                  gdesc <- gdesc[,-2]
                  desc <- cbind(ddesc, gdesc[rownames(ddesc),])
               }else{
                  desc <- ddesc
               }
            }
            results <- cbind(results, desc[results$"Relevant ID", -1])
         }
         curSel$results <- results
         curSel$selRes <- sel
      })

      shiny::observe({
         shiny::req(input$nextRes)
         ibe <- shiny::isolate(input$uiBe)
         iorg <- shiny::isolate(input$uiOrg)
         isrc <- shiny::isolate(input$uiSource)
         searchRes <- shiny::isolate(curSel$searchRes)
         shiny::req(searchRes)
         results <- shiny::isolate(curSel$results)
         sel <- shiny::isolate(curSel$selRes)
         nsel <- (max(sel)+1):min(max(sel)+by, nrow(searchRes))
         sel <- c(sel, nsel)
         toAdd <- try(getRelevantIds(
            d=searchRes,
            selected=nsel,
            be=ibe, source=isrc, organism=iorg,
            restricted=restricted
         ), silent=TRUE)
         curSel$selRes <- sel
         shiny::req(!inherits(toAdd, "try-error"))
         if(!is.null(toAdd)){
            colnames(toAdd)[ncol(toAdd)] <- "Relevant ID"
            if(ibe=="Gene"){
               desc <- getGeneDescription(
                  ids=setdiff(toAdd$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(desc) <- desc$id
               colnames(desc) <- c(
                  "id", "Symbol", "Name", "Preferred",
                  "DB version", "Deprecated"
               )
            }else if(ibe=="Probe"){
               desc <- getGeneDescription(
                  ids=setdiff(toAdd$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(desc) <- desc$id
               gs <- colnames(desc)[2]
               colnames(desc)[match(c("symbol", "name"), colnames(desc))] <-
                  paste0(
                     c("Symbol", "Name"),
                     " (", gs, ")"
                  )
               desc <- desc[,-2]
            }else{
               ddesc <- getBeIdDescription(
                  ids=setdiff(toAdd$"Relevant ID", NA),
                  be=ibe,
                  source=isrc,
                  organism=iorg
               )
               rownames(ddesc) <- ddesc$id
               colnames(ddesc) <- c(
                  "id", "Symbol", "Name", "Preferred",
                  "DB version", "Deprecated"
               )
               ddesc <- ddesc[
                  ,
                  which(apply(ddesc, 2, function(x) any(!is.na(x))))
                  ]
               if(input$showGeneAnno){
                  gdesc <- getGeneDescription(
                     ids=setdiff(toAdd$"Relevant ID", NA),
                     be=ibe,
                     source=isrc,
                     organism=iorg
                  )
                  rownames(gdesc) <- gdesc$id
                  gs <- colnames(gdesc)[2]
                  colnames(gdesc)[match(c("symbol", "name"), colnames(gdesc))] <-
                     paste0(
                        c("Symbol", "Name"),
                        " (", gs, ")"
                     )
                  gdesc <- gdesc[,-2]
                  desc <- cbind(ddesc, gdesc[rownames(ddesc),])
               }else{
                  desc <- ddesc
               }
            }
            toAdd <- cbind(toAdd, desc[toAdd$"Relevant ID", -1])
         }
         results <- rbind(results, toAdd)
         results <- results[which(!duplicated(results$"Relevant ID")),]
         curSel$results <- results
      })

      output$dispRes <- DT::renderDataTable({
         searchRes <- curSel$searchRes
         shiny::req(searchRes)
         request <- shiny::isolate(input$request)
         results <- curSel$results
         foundColumns <- c("found", "be", "source", "organism", "canonical")
         if(is.null(results) || nrow(results)==0){
            toShow <- searchRes[,foundColumns]
         }else{
            toShow <- results[,c(
               intersect(
                  colnames(results),
                  unique(c(
                     foundColumns,
                     "Relevant ID", "Preferred", "DB version", "Deprecated",
                     grep("symbol", colnames(results), value=T, ignore.case=T),
                     grep("name", colnames(results), value=T, ignore.case=T)
                  ))
               )
            )]
            tohl <- intersect(
               colnames(results),
               unique(c(
                  grep("symbol", colnames(results), value=T, ignore.case=T),
                  grep("name", colnames(results), value=T, ignore.case=T)
               ))
            )
            for(cn in tohl){
               toShow[,cn] <- highlightText(toShow[,cn], request)
            }
            ridht <- highlightText(toShow$"Relevant ID", request)
            ridurl <- getBeIdURL(
               toShow$"Relevant ID",
               shiny::isolate(input$uiSource)
            )
            toShow$"Relevant ID" <- ifelse(
               is.na(ridurl),
               ridht,
               paste0(
                  sprintf(
                     '<a href="%s" target="_blank">',
                     ridurl
                  ),
                  ridht,
                  '</a>'
               )
            )
         }
         toShow$found <- highlightText(toShow$found, request)
         toShow$Found <- paste0(
            toShow$found,
            " (", toShow$be, " ",
            ifelse(
               is.na(toShow$canonical),
               "",
               ifelse(toShow$canonical, "canonical", "non-canonical")
            ), " ",
            toShow$source,
            " in ",
            toShow$organism,
            ")"
         )

         toShow <- toShow[,c(
            "Found",
            setdiff(colnames(toShow), c("Found", foundColumns))
         ), drop=FALSE]
         shown <- DT::datatable(
            toShow,
            rownames=FALSE,
            extensions="Scroller",
            escape=FALSE,
            options=list(
               deferRender=TRUE,
               scrollY=230,
               scrollX= TRUE,
               scroller = TRUE,
               dom=c("ti")
            )
         )
         if("Relevant ID" %in% colnames(toShow)){
            shown <- DT::formatStyle(
               shown,
               'Relevant ID',
               color='darkblue',
               backgroundColor='lightgrey',
               fontWeight='bold'
            )
         }
         if("Preferred" %in% colnames(toShow)){
            shown <- DT::formatStyle(
               shown,
               'Preferred',
               backgroundColor=DT::styleEqual(
                  c(1, 0), c('green', 'transparent')
               )
            )
         }
         shown
      })

      # Handle the Done button being pressed.
      shiny::observeEvent(input$done, {
         # Return the selected ID
         toRet <- shiny::isolate(curSel$results)
         if(is.null(toRet)){
            shiny::stopApp(NULL)
         }else{
            sel <- shiny::isolate(input$dispRes_rows_selected)
            attr(toRet, "scope") <- list(
               be=shiny::isolate(input$uiBe),
               source=shiny::isolate(input$uiSource),
               organism=shiny::isolate(input$uiOrg)
            )
            shiny::stopApp(shiny::isolate(toRet[sel,]))
         }
      })
   }

   shiny::runGadget(
      ui, server,
      viewer = shiny::dialogViewer("Find BE", height=560, width=850)
   )
   # shiny::runGadget(ui, server)
}
