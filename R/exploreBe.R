#' Explore BE identifiers
#'
#' This function uses visNetwork to draw all the identifiers
#' corresponding to one BE (including ProbeID and BESymbol)
#'
#' @param id one ID for the BE
#' @param source the ID source database. **Guessed if not provided**
#' @param be the type of BE. **Guessed if not provided**
#' @param showProbes boolean. If TRUE, probes targeting any BEID are shown.
#' @param showBE boolean. If TRUE the Biological Entity corresponding to the
#' id is shown. If id is isolated (not mapped to any other ID or symbol)
#' BE is shown anyway.
#'
#' @examples \dontrun{
#' exploreBe("Gene", "100", "EntrezGene")
#' }
#'
#' @export
#'
exploreBe <- function(id, source, be, showBE=FALSE, showProbes=FALSE){
   id <- as.character(id)
   stopifnot(length(id)==1)
   ##
   if(missing(be) || missing(source)){
      toWarn <- TRUE
   }else{
      toWarn <- FALSE
   }
   guess <- guessIdScope(ids=id, be=be, source=source)
   if(is.null(guess)){
      stop("Could not find the provided id")
   }
   if(is.na(guess$be)){
      stop(
         "The provided id does not match the provided scope",
         " (be, source or organism)"
      )
   }
   be <- guess$be
   source <- guess$source
   organism <- guess$organism
   if(toWarn){
      warning(
         "Guessing ID scope:",
         sprintf("\n   - be: %s", be),
         sprintf("\n   - source: %s", source),
         sprintf("\n   - organism: %s", organism)
      )
   }
   ##
   if(be=="Probe"){
      showProbes <- TRUE
   }
   net <- bedCall(
      f=neo2R::cypher,
      query=neo2R::prepCql(
         sprintf(
            'MATCH (s:%s {value:$id, %s:$db})',
            paste0(be, "ID"),
            ifelse(be=="Probe", "platform", "database")
         ),
         '-[:is_replaced_by|is_associated_to|targets*0..]->()',
         '-[:identifies]->(be)',
         'WITH DISTINCT be',
         'MATCH (be)<-[ir:identifies]-(di)',
         'OPTIONAL MATCH (di)<-[iir:is_replaced_by|is_associated_to*0..]-(ii)',
         'OPTIONAL MATCH (di)-[cr:corresponds_to]-()',
         'OPTIONAL MATCH (di)-[dkr:is_known_as {canonical:$can}]->(dis:BESymbol)',
         'OPTIONAL MATCH (ii)-[ikr:is_known_as {canonical:$can}]->(iis:BESymbol)',
         'OPTIONAL MATCH (di)<-[dtr:targets]-(dip:ProbeID)',
         'OPTIONAL MATCH (ii)<-[itr:targets]-(iip:ProbeID)',
         'RETURN DISTINCT be, di, ii, dis, iis, dip, iip, ir, iir, cr, dkr, ikr, dtr, itr'
      ),
      result="graph",
      parameters=list(id=id, db=source, can=TRUE)
   )
   if(length(net$nodes)==0){
      stop(sprintf(
         '"%s" (id) not found as a "%s" (be) in "%s" database (source).',
         id, be, source
      ))
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
                  ids=paste(n$properties$value, collapse=""),
                  databases=paste(n$properties$database, collapse="")
               ),
               stringsAsFactors=FALSE
            )
            return(toRet)
         }
      )
   ))
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
   if(!showProbes){
      toRm <- nodes$id[which(nodes$label=="ProbeID")]
      nodes <- nodes[which(!nodes$id %in% toRm),]
      edges <- edges[which(!edges$start %in% toRm & !edges$end %in% toRm),]
   }
   if(!showBE){
      if(nrow(nodes)<=2){
         showBE <- TRUE
      }else{
         toRm <- nodes$id[which(nodes$label==be)]
         nodes <- nodes[which(!nodes$id %in% toRm),]
         edges <- edges[which(!edges$start %in% toRm & !edges$end %in% toRm),]
      }
   }
   tpNodes <- nodes
   colnames(tpNodes) <- c(
      "id", "type", "label", "database", "preferred", "platform", "url"
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
      '</p>'
   )
   ##
   nshapes <- c(
      if(showBE){c(be="diamond")}else{c()},
      beid="dot",
      BESymbol="box"
   )
   if(showBE){
      names(nshapes) <- c(be, paste0(be, "ID"), "BESymbol")
   }else{
      names(nshapes) <- c(paste0(be, "ID"), "BESymbol")
   }
   if(showProbes){
      nshapes <- c(nshapes, ProbeID="triangle")
   }
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
   ncol <- length(unique(tpNodes$source))+2
   ncolors <- rep(ncolors, (ncol %/% length(ncolors))+1)
   ncolors <- ncolors[1:ncol]
   names(ncolors) <- c(be, "BESymbol", unique(tpNodes$source))
   tpNodes$color.background <- ifelse(
      tpNodes$type==be, ncolors[be],
      ifelse(
         tpNodes$type=="BESymbol", ncolors["BESymbol"],
         ifelse(
            tpNodes$source!="",
            ncolors[tpNodes$source],
            "grey"
         )
      )
   )
   tpNodes$borderWidth <- 1
   tpNodes[which(as.logical(tpNodes$preferred)),"borderWidth"] <- 4
   tpNodes$borderWidthSelected <- 2
   tpNodes[which(as.logical(tpNodes$preferred)),"borderWidthSelected"] <- 4
   # tpNodes$color.background <- "#BB6ED4"
   # tpNodes$color.background[which(tpNodes$type=="BESymbol")] <- "#DB9791"
   # tpNodes$color.background[grep("ID", tpNodes$type)] <- "#B1DE79"
   # tpNodes$color.background[which(tpNodes$type=="ProbeID")] <- "#A4D0D3"
   tpNodes$color.border="black"
   tpEdges <- edges
   colnames(tpEdges) <- c("id", "title", "from", "to")
   tpEdges$arrows <- "to"
   tpEdges$dashes <- ifelse(
      tpEdges$title %in% c("is_associated_to", "is_replaced_by"),
      TRUE,
      FALSE
   )
   toRet <- visNetwork::visNetwork(
      nodes=tpNodes,
      edges=tpEdges
   )
   toRet <- visNetwork::visInteraction(graph=toRet, selectable=TRUE)
   toRet <- visNetwork::visOptions(
      graph=toRet,
      highlightNearest = TRUE,
      nodesIdSelection=list(
         selected=tpNodes$id[which(
            tpNodes$label==id & tpNodes$source==source
         )]
      )
   )
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
         # if(showProbes){
            lapply(
               setdiff(names(ncolors), c("", be, names(nshapes))),
               function(x){
                  return(list(
                     label=x, shape="dot", color=as.character(ncolors[x])
                  ))
               }
            )
         # }else{
         #    list()
         # }
      ),
      ncol=ifelse(showProbes, 3, 2),
      width=ifelse(showProbes, 0.3, 0.2),
      position="left",
      useGroups = FALSE
   )
   return(toRet)
}
