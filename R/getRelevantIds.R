#' Get relevant IDs for a formerly identified BE in a context of interest
#'
#' **DEPRECATED: use [searchBeid] and [geneIDsToAllScopes] instead.**
#' This function is meant to be used with [searchId] in order
#' to implement a dictonary of identifiers of interest. First
#' the [searchId] function is used to search a term.
#' Then the [getRelevantIds] function
#' is used to find the corresponding IDs in a context of interest.
#'
#' @param d the data.frame returned by [searchId].
#' @param selected the rows of interest in d
#' @param be the BE in the context of interest
#' @param source the source of the identifier in the context of interest
#' @param organism the organism in the context of interest
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned:
#' **Depending on history it can take a very long time to return**
#' **a very large result!**
#' @param simplify if TRUE (default) duplicated IDs are removed from the output
#' @param verbose if TRUE, the CQL query is shown
#'
#' @return The d data.frame with a new column providing the relevant ID
#' in the context of interest and without the gene field.
#' Scope ("be", "source" and "organism") is provided as a named list
#' in the "scope" attributes: `attr(x, "scope")`
#'
#' @seealso [searchId]
#'
#' @export
#'
getRelevantIds <- function(
   d, selected=1,
   be=c(listBe(), "Probe"), source, organism,
   restricted=TRUE,
   simplify=TRUE,
   verbose=FALSE
){
   selected <- intersect(selected, 1:nrow(d))
   if(length(selected)<1){
      stop("Only one row of d can be selected by sel parameter")
   }
   dcols <- c("found", "entity", "be", "source", "organism", "gene")
   if(!all(dcols %in% colnames(d))){
      stop(
         sprintf(
            "d should be a data.frame with the following columns: %s.",
            paste(dcols, collapse=", ")
         ),
         " This data.frame is returned by the searchId function."
      )
   }
   match.arg(be, c("Probe", listBe()), several.ok=FALSE)
   ##
   tax <- getTaxId(organism)
   organism <- getOrgNames(tax)
   organism <- organism$name[which(organism$nameClass=="scientific name")]
   ##
   toRet <- NULL
   for(sel in selected){
      from <- d[sel, "ebe"]
      from.entity <- d[sel, "entity"]
      from.source <- d[sel, "source"]
      from.org <- d[sel, "organism"]
      from.tax <- getTaxId(from.org)
      from.gene <- d[sel, "gene"][[1]]
      ##
      if(tax!=from.tax){
         hqs <- c(
            'MATCH (fg:Gene)<-[:identifies]-(:GeneID)',
            '-[:is_member_of]->(:GeneIDFamily)<-[:is_member_of]-',
            '(:GeneID)-[:identifies]->(tg:Gene)-[:belongs_to]->(tid:TaxID)',
            'WHERE id(fg) IN $fromGene AND tid.value=$tax',
            'RETURN id(tg) as gene'
         )
         if(verbose) message(neo2R::prepCql(hqs))
         targGene <- unique(bedCall(
            f=neo2R::cypher,
            query=neo2R::prepCql(hqs),
            parameters=list(fromGene=as.list(from.gene), tax=tax)
         ))[,"gene"]
         if(length(targGene)==0){
            next()
         }
         from.entity <- targGene
         from <- "Gene"
      }
      ##
      if(be=="Probe"){
         qs <- genProbePath(platform=source)
         targBE <- attr(qs, "be")
         qs <- paste0(
            sprintf(
               '(t:ProbeID {platform:"%s"})',
               source
            ),
            qs,
            sprintf(
               '(tbe:%s)',
               targBE
            )
         )
      }else{
         targBE <- be
         if(source=="Symbol"){
            qs <- paste0(
               '(t:BESymbol)<-[fika:is_known_as]-',
               sprintf(
                  '(tid:%s)',
                  paste0(targBE, "ID")
               ),
               '-[:is_replaced_by|is_associated_to*0..]->()',
               '-[:identifies]->',
               sprintf(
                  '(tbe:%s)',
                  targBE
               )
            )
         }else{
            qs <- paste0(
               sprintf(
                  '(t:%s {database:"%s"})',
                  paste0(targBE, "ID"), source
               ),
               ifelse(
                  restricted,
                  '-[:is_associated_to*0..]->',
                  '-[:is_replaced_by|is_associated_to*0..]->'
               ),
               # '-[:is_replaced_by|is_associated_to*0..]->',
               sprintf(
                  '(:%s)',
                  paste0(targBE, "ID")
               ),
               '-[:identifies]->',
               sprintf(
                  '(tbe:%s)',
                  targBE
               )
            )
         }
      }
      ##
      qs <- paste('MATCH', qs)
      ##
      if(from!="Gene"){
         if(targBE=="Gene"){
            qs <- c(
               qs,
               'WHERE id(tbe) IN $fromGene'
            )
         }else{
            qs <- c(
               qs,
               paste0(
                  'MATCH (tbe)',
                  genBePath(targBE, "Gene"),
                  '(tGene)'
               ),
               'WHERE id(tGene) IN $fromGene'
            )
         }
      }
      ##
      if(targBE==from){
         qs <- c(
            qs,
            'MATCH (tbe) WHERE id(tbe) IN $fromEntity'
         )
      }else{
         qs <- c(
            qs,
            paste0(
               'MATCH (fbe)',
               genBePath(from, targBE),
               '(tbe)'
            ),
            'WHERE id(fbe) IN $fromEntity'
         )
      }
      ##
      qs <- c(
         qs,
         'RETURN t.preferred as preferred, t.value as id'
      )
      if(verbose) message(neo2R::prepCql(qs))
      value <- unique(bedCall(
         f=neo2R::cypher,
         query=neo2R::prepCql(qs),
         parameters=list(
            fromGene=as.list(from.gene),
            fromEntity=as.list(from.entity)
         )
      ))#$id
      if(!is.null(value) && nrow(value) > 0){
         toAdd <- d[rep(sel, nrow(value)),]
         toAdd$preferred <- value$preferred
         toAdd$id <- value$id
         rownames(toAdd) <- NULL
         toRet <- rbind(toRet, toAdd)
      }
   }
   if(!is.null(toRet) && ncol(toRet)>0){
      colnames(toRet)[ncol(toRet)] <- paste0(
         be, " from ", source,
         " (", organism, ")"
      )
      rownames(toRet) <- NULL
      toRet <- toRet[,which(colnames(toRet)!="gene")]
      if(simplify){
         toRet <- toRet[order(toRet$canonical, decreasing=TRUE),]
         toRet <- toRet[
            order(toRet$found==toRet[,ncol(toRet)], decreasing=TRUE),
         ]
         toRet <- toRet[order(toRet$source==source, decreasing=TRUE),]
         toRet <- toRet[order(toRet$be==be, decreasing=TRUE),]
         toRet <- toRet[order(toRet$preferred, decreasing=TRUE),]
         toRet <- toRet[order(toRet$organism==organism, decreasing=TRUE),]
         toRet <- toRet[!duplicated(toRet[,ncol(toRet)]),]
      }
      attr(toRet, "scope") <- list(be=be, source=source, organism=organism)
   }
   return(toRet)
}
