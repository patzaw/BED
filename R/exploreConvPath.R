#' Explore the shortest convertion path between two identifiers
#'
#' This function uses visNetwork to draw all the shortest convertion paths
#' between two identifiers (including ProbeID).
#'
#' @param from.id the first identifier
#' @param from the type of entity: \code{listBe()} or Probe
#' @param from.source the identifier source: database or platform
#' @param to.id the first identifier
#' @param to the type of entity: \code{listBe()} or Probe
#' @param to.source the identifier source: database or platform
#' @param edgeDirection a logical value indicating if the direction of the
#' edges should be drawn.
#' @param verbose if TRUE the cypher query is shown
#'
#' @examples \dontrun{
#' exploreConvPath(
#'    from.id="ENST00000413465", from="Transcript", from.source="Ens_transcript",
#'    to.id="ENSMUST00000108658", to="Transcript", to.source="Ens_transcript"
#' )
#' }
#'
#' @importFrom neo2R prepCql cypher
#' @importFrom visNetwork visNetwork visLegend visInteraction visOptions
#' @export
#'
exploreConvPath <- function(
   from.id,
   from,
   from.source,
   to.id,
   to=from,
   to.source=from.source,
   edgeDirection=FALSE,
   verbose=FALSE
){

   ## Verifications
   echoices <- c("Probe", listBe())
   match.arg(from, echoices)
   match.arg(to, echoices)

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
   qs <- prepCql(c(fqs, tqs, pqs, "RETURN p"))
   if(verbose) cat(qs, fill=T)
   net <- bedCall(
      cypher,
      query=qs,
      parameters=list(
         fromId=from.id, fromSource=from.source,
         toId=to.id, toSource=to.source,
         inPath=as.list(inPath)
         # notInPath=as.list(notInPath)
      ),
      result="graph"
   )

   ## Plot the graph
   if(length(net$nodes)==0){
      stop("Could not find any path between the two provided identifiers")
   }
   nodes <- unique(do.call(
      rbind,
      lapply(
         net$nodes,
         function(n){
            toRet <- data.frame(
               "id"=n$id,
               "label"=setdiff(unlist(n$labels), "BEID"),
               "value"=paste(n$properties$value, collapse=""),
               "database"=paste(n$properties$database, collapse=""),
               "preferred"=paste(n$properties$preferred, collapse=""),
               "platform"=paste(n$properties$platform, collapse=""),
               "url"=getBeIdURL(
                  id=paste(n$properties$value, collapse=""),
                  database=paste(n$properties$database, collapse="")
               ),
               stringsAsFactors=FALSE
            )
            return(toRet)
         }
      )
   ))
   nodesSymbol <- c()
   for(i in 1:nrow(nodes)){
      if(!nodes[i, "label"] %in% c("GeneID", "TranscriptID", "PeptideID", "ObjectID")){
         nodesSymbol <- c(nodesSymbol, "")
      }else{
         qr <- bedCall(
            cypher,
            query=prepCql(c(
               sprintf(
                  'MATCH (n:%s {value:"%s", database:"%s"})-[r:is_known_as]->(s)',
                  nodes[i, "label"], nodes[i, "value"], nodes[i, "database"]
               ),
               'RETURN s.value as symbol, r.canonical as can'
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
   edges <- unique(do.call(
      rbind,
      lapply(
         net$relationships,
         function(r){
            toRet <- data.frame(
               "id"=r$id,
               "type"=r$type,
               "start"=r$startNode,
               "end"=r$endNode,
               stringsAsFactors=FALSE
            )
            return(toRet)
         }
      )
   ))
   tpNodes <- nodes
   colnames(tpNodes) <- c(
      "id", "type", "label", "database", "preferred", "platform", "url", "symbol"
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
   toRet <- visNetwork(
      nodes=tpNodes,
      edges=tpEdges
   )
   toRet <- visInteraction(graph=toRet, selectable=TRUE)
   toRet <- visOptions(
      graph=toRet,
      highlightNearest = TRUE
      # nodesIdSelection=list(selected=tpNodes$id[which(tpNodes$label==from.id)])
   )
   toRet <-  visLegend(
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
   return(toRet)

}
