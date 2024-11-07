#' Explore the shortest convertion path between two identifiers
#'
#' This function uses visNetwork to draw all the shortest convertion paths
#' between two identifiers (including ProbeID).
#'
#' @param from.id the first identifier
#' @param to.id the second identifier
#' @param from the type of entity: `listBe()` or Probe.
#' **Guessed if not provided**
#' @param from.source the identifier source: database or platform.
#' **Guessed if not provided**
#' @param to the type of entity: `listBe()` or Probe.
#' **Guessed if not provided**
#' @param to.source the identifier source: database or platform.
#' **Guessed if not provided**
#' @param edgeDirection a logical value indicating if the direction of the
#' edges should be drawn.
#' @param showLegend boolean. If TRUE the legend is displayed.
#' @param verbose if TRUE the cypher query is shown
#'
#' @examples \dontrun{
#' exploreConvPath(
#'    from.id="ENST00000413465",
#'    from="Transcript", from.source="Ens_transcript",
#'    to.id="ENSMUST00000108658",
#'    to="Transcript", to.source="Ens_transcript"
#' )
#' }
#'
#' @export
#'
exploreConvPath <- function(
      from.id,
      to.id,
      from,
      from.source,
      to,
      to.source,
      edgeDirection=FALSE,
      showLegend = TRUE,
      verbose=FALSE
){

   ## Verifications
   from.id <- as.character(from.id)
   to.id <- as.character(to.id)
   stopifnot(
      length(from.id)==1,
      length(to.id)==1
   )

   ##
   if(
      missing(from) || missing(from.source)
   ){
      toWarn <- TRUE
   }else{
      toWarn <- FALSE
   }
   guess <- guessIdScope(ids=from.id, be=from, source=from.source)
   if(is.null(guess)){
      stop("Could not find the provided from.id")
   }
   if(is.na(guess$be)){
      stop(
         "The provided from.id does not match the provided scope",
         " (be, source or organism)"
      )
   }
   from.source <- guess$source
   from <- guess$be
   from.organism <- guess$organism
   if(toWarn){
      warning(
         'Guessing "from.id" scope:',
         sprintf("\n   - be: %s", from),
         sprintf("\n   - source: %s", from.source),
         sprintf("\n   - organism: %s", from.organism)
      )
   }
   ##
   if(
      missing(to) || missing(to.source)
   ){
      toWarn <- TRUE
   }else{
      toWarn <- FALSE
   }
   guess <- guessIdScope(ids=to.id, be=to, source=to.source)
   if(is.null(guess)){
      stop("Could not find the provided to.id")
   }
   if(is.na(guess$be)){
      stop(
         "The provided to.id does not match the provided scope",
         " (be, source or organism)"
      )
   }
   to.source <- guess$source
   to <- guess$be
   to.organism <- guess$organism
   if(toWarn){
      warning(
         'Guessing "to.id" scope:',
         sprintf("\n   - be: %s", to),
         sprintf("\n   - source: %s", to.source),
         sprintf("\n   - organism: %s", to.organism)
      )
   }
   ##

   ## From
   if(from=="Probe"){
      fqs <- "MATCH (f:ProbeID {value:$fromId, platform:$fromSource})"
      fbe <- getTargetedBe(from.source)
   }else{
      fqs <- sprintf(
         "MATCH (f:%s {value:$fromId, database:$fromSource})",
         paste0(from, "ID")
      )
      fbe <- from
   }

   ## To
   if(to=="Probe"){
      tqs <- "MATCH (t:ProbeID {value:$toId, platform:$toSource})"
      tbe <- getTargetedBe(to.source)
   }else{
      tqs <- sprintf(
         "MATCH (t:%s {value:$toId, database:$toSource})",
         paste0(to, "ID")
      )
      tbe <- to
   }

   ## Paths
   inPath <- c(
      "corresponds_to", "is_associated_to", "is_replaced_by",
      "targets", "is_homolog_of"
   )
   if(fbe != "Gene"){
      inPath <- c(inPath, genBePath(fbe, "Gene", onlyR=TRUE))
   }
   if(tbe != "Gene"){
      inPath <- c(inPath, genBePath(tbe, "Gene", onlyR=TRUE))
   }
   if(fbe != tbe){
      inPath <- c(inPath, genBePath(fbe, tbe, onlyR=TRUE))
   }
   inPath <- unique(inPath)
   notInPath <- c(
      "is_in", "is_recorded_in", "has",
      "is_named", "is_known_as",
      "identifies", "is_member_of"
   )
   pqs <- c(
      "MATCH p=allShortestpaths((f)-[*0..]-(t))",
      "WHERE ALL(r IN relationships(p) WHERE type(r) IN $inPath)"
      # "WHERE NONE(r IN relationships(p) WHERE type(r) IN $notInPath)"
   )

   ## Final query
   rqs <- c(
      'UNWIND relationships(p) as r',
      'MATCH (s)-[r]->(e)',
      'RETURN id(r) as id, type(r) as type,',
      'id(s) as start, id(e) as end'
   )
   qs <- neo2R::prepCql(c(fqs, tqs, pqs, rqs))
   if(verbose) cat(qs, fill=T)
   netRes <- bedCall(
      neo2R::cypher,
      query=qs,
      parameters=list(
         fromId=from.id, fromSource=from.source,
         toId=to.id, toSource=to.source,
         inPath=as.list(inPath)
         # notInPath=as.list(notInPath)
      ),
      result="row"
   )

   ## Plot the graph
   if(is.null(netRes) || nrow(netRes)==0){
      stop("Could not find any path between the two provided identifiers")
   }
   nodes <- bedCall(
      f=neo2R::cypher,
      query=neo2R::prepCql(
         'MATCH (n) WHERE id(n) IN $ids',
         'RETURN DISTINCT',
         'id(n) as id, labels(n) as label,',
         'n.value as value, n.database as database,',
         'n.preferred as preferred,',
         'n.platform as platform'
      ),
      result="row",
      parameters=list(ids=I(unique(c(netRes$start, netRes$end))))
   )
   nodes$label <- gsub(" [|][|] ", "", gsub("BEID", "", nodes$label))
   for(cn in colnames(nodes)){
      if(is.character(nodes[[cn]])){
         nodes[[cn]] <- ifelse(is.na(nodes[[cn]]), "", nodes[[cn]])
      }
   }
   nodes$url <- getBeIdURL(
      ids=nodes$value,
      databases=nodes$database
   )
   nodesSymbol <- c()
   for(i in 1:nrow(nodes)){
      if(
         !nodes[i, "label"] %in%
         c("GeneID", "TranscriptID", "PeptideID", "ObjectID")
      ){
         nodesSymbol <- c(nodesSymbol, "")
      }else{
         qr <- bedCall(
            neo2R::cypher,
            query=neo2R::prepCql(c(
               sprintf(
                  'MATCH (n:%s {value:"%s", database:"%s"})-[r:is_known_as]->(s)',
                  nodes[i, "label"], nodes[i, "value"], nodes[i, "database"]
               ),
               'RETURN DISTINCT s.value as symbol, r.canonical as can'
            ))
         )
         if(!is.null(qr) && nrow(qr)>0){
            nodesSymbol <- c(
               nodesSymbol,
               qr[order(qr$can, decreasing=T), "symbol"][1]
            )
         }else{
            nodesSymbol <- c(nodesSymbol, "")
         }
      }
   }
   nodes$symbol <- nodesSymbol
   edges <- netRes
   tpNodes <- nodes
   colnames(tpNodes) <- c(
      "id", "type", "label", "database", "preferred",
      "platform", "url", "symbol"
   )
   tpNodes$source <- paste0(tpNodes$database, tpNodes$platform)
   tpNodes$title <- paste0(
      '<p>',
      '<strong>',
      tpNodes$type,
      '</strong><br>',
      ifelse(
         tpNodes$label!="",
         ifelse(
            !is.na(tpNodes$url),
            paste0(
               sprintf(
                  '<a href="%s" target="_blank">',
                  tpNodes$url
               ),
               tpNodes$label,
               '</a>'
            ),
            tpNodes$label
         ),
         ""
      ),
      ifelse(
         tpNodes$source!="",
         paste0(
            '<br>',
            '<emph>', tpNodes$source, '</emph>'
         ),
         ""
      ),
      ifelse(
         !is.na(as.logical(tpNodes$preferred)) & as.logical(tpNodes$preferred),
         "<br>Preferred",
         ""
      ),
      ifelse(
         tpNodes$symbol!="",
         paste0("<br>", tpNodes$symbol),
         ""
      ),
      '</p>'
   )
   ##
   nshapes <- c(
      GeneID="dot",
      TranscriptID="diamond",
      PeptideID="square",
      ObjectID="star",
      ProbeID="triangle"
   )
   nshapes <- nshapes[which(names(nshapes) %in% tpNodes$type)]
   tpNodes$shape <- nshapes[tpNodes$type]
   ##
   ncolors <- c(
      "#E2B845", "#E4AC77", "#67E781", "#E2DBE6", "#7E58DB",
      "#B694E4", "#B4E5BC", "#7299E1", "#E56E40", "#62B0DB", "#D46EE2",
      "#B2C0E7", "#E4E3C6", "#D8E742", "#D7699E", "#66E5B0", "#E6B7E0",
      "#70D1E2", "#6778DF", "#80B652", "#E4E19E", "#E790DE", "#D8E577",
      "#6EEADD", "#DA3FE3", "#9F6D5B", "#5EA88C", "#8535E7", "#7EEA49",
      "#AB88A7", "#E24869", "#E547B1", "#BBE8E5", "#9DADA8", "#E3B9B0",
      "#B1EA9A", "#557083", "#9F9F66", "#874C99", "#E68D97"
   )
   ncol <- length(unique(tpNodes$source))
   ncolors <- rep(ncolors, (ncol %/% length(ncolors))+1)
   ncolors <- ncolors[1:ncol]
   names(ncolors) <- c(unique(tpNodes$source))
   tpNodes$color.background <- ifelse(
      tpNodes$source!="",
      ncolors[tpNodes$source],
      "grey"
   )
   tpNodes$borderWidth <- 1
   tpNodes[which(as.logical(tpNodes$preferred)),"borderWidth"] <- 4
   tpNodes$borderWidthSelected <- 2
   tpNodes[which(as.logical(tpNodes$preferred)),"borderWidthSelected"] <- 4
   tpNodes$color.border="black"
   tpEdges <- edges
   colnames(tpEdges) <- c("id", "title", "from", "to")
   if(edgeDirection){
      tpEdges$arrows <- "to"
   }else{
      tpEdges$arrows <- ""
   }
   tpEdges$dashes <- ifelse(
      tpEdges$title %in% c("is_associated_to", "is_replaced_by"),
      TRUE,
      FALSE
   )
   tpEdges$color <- ifelse(
      tpEdges$title == "is_homolog_of",
      "red",
      "black"
   )
   tpEdges <- unique(tpEdges)
   toRet <- visNetwork::visNetwork(
      nodes=tpNodes,
      edges=tpEdges
   )
   toRet <- visNetwork::visInteraction(graph=toRet, selectable=TRUE)
   toRet <- visNetwork::visOptions(
      graph=toRet,
      highlightNearest = TRUE
   )
   if(showLegend){
      toRet <-  visNetwork::visLegend(
         graph=toRet,
         addNodes=c(
            lapply(
               names(nshapes),
               function(x){
                  return(list(
                     label=x,
                     shape=as.character(nshapes[x]),
                     color=as.character(ncolors[x])
                  ))
               }
            ),
            lapply(
               setdiff(names(ncolors), c("", names(nshapes))),
               function(x){
                  return(list(
                     label=x, shape="dot", color=as.character(ncolors[x])
                  ))
               }
            )
         ),
         ncol=3,
         width=0.3,
         position="left",
         useGroups = FALSE
      )
   }
   return(toRet)

}
