#' Converts BE IDs
#'
#' @param ids list of identifiers
#' @param from a character corresponding to the biological entity or Probe
#' @param from.source a character corresponding to the ID source
#' @param from.org a character corresponding to the organism
#' @param to a character corresponding to the biological entity or Probe
#' @param to.source a character corresponding to the ID source
#' @param to.org a character corresponding to the organism
#' @param caseSensitive if true the case of provided ids is taken into account
#' during search.
#' @param prefFilter boolean indicating if the results should be filter
#' to keep only preferred BEID of BE when they exist (default: FALSE).
#' If there are several
#' preferred BEID of a BE, all are kept. If there are no preferred BEID
#' of a BE, all non-preferred BEID are kept.
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned:
#' \strong{Depending on history it can take a very long time to return
#' a very large result!}
#' @param recache a logical value indicating if the results should be taken from
#' cache or recomputed
#' @param limForCache if there are more ids than limForCache. Results are
#' collected for all IDs (beyond provided ids) and cached for futur queries.
#' If not, results are collected only for provided ids and not cached.
#'
#' @return a data.frame with 3 columns: \itemize{
#'  \item from: the input IDs
#'  \item to: the corresponding IDs in \code{to.source}
#'  \item to.preferred: boolean indicating if the to ID is a preferred
#'  ID for the corresponding entity.
#'  \item to.entity: the entity technical ID of the \code{to} IDs
#' }
#' This data.frame can be filtered in order to remove duplicated
#' from/to.entity associations which can lead information bias.
#'
#' @examples \dontrun{
#' oriId <- c("10", "100")
#' convBeIds(
#'    ids=oriId,
#'    from="Gene",
#'    from.source="EntrezGene",
#'    from.org="human",
#'    to.source="Ens_gene"
#' )
#' convBeIds(
#'    ids=oriId,
#'    from="Gene",
#'    from.source="EntrezGene",
#'    from.org="human",
#'    to="Peptide",
#'    to.source="Ens_translation"
#' )
#' convBeIds(
#'    ids=oriId,
#'    from="Gene",
#'    from.source="EntrezGene",
#'    from.org="human",
#'    to="Peptide",
#'    to.source="Ens_translation",
#'    to.org="mouse"
#' )
#' }
#'
#' @seealso \code{\link{getBeIdConvTable}}, \code{\link{convBeIdLists}},
#' \code{\link{convDfBeIds}}
#'
#' @export
#'
convBeIds <- function(
   ids,
   from,
   from.source,
   from.org,
   to=from,
   to.source=from.source,
   to.org=from.org,
   caseSensitive=FALSE,
   prefFilter=FALSE,
   restricted=TRUE,
   recache=FALSE,
   limForCache=2000
){
   ids <- sort(setdiff(as.character(unique(ids)), NA))
   fFilt <- length(ids) <= limForCache
   if(!fFilt){
      tn <- gsub(
         "[^[:alnum:]]", "_",
         paste(
            match.call()[[1]],
            from, from.source,
            to, to.source,
            getTaxId(from.org), getTaxId(to.org),
            ifelse(restricted, "restricted", "full"),
            sep="_"
         )
      )
      checkBedCache()
   }

   cache <- checkBedCache()
   if(!fFilt && tn %in% rownames(cache) && !recache){
      ct <- loadBedResult(tn)
   }else{
      if(getTaxId(from.org)==getTaxId(to.org)){
         if(fFilt){
            filter=ids
         }else{
            filter=NULL
         }
         ct <- getBeIdConvTable(
            from=from,
            to=to,
            from.source=from.source,
            to.source=to.source,
            organism=from.org,
            restricted=restricted,
            entity=TRUE,
            filter=filter
         )
         if(is.null(ct) || ncol(ct)==0){
            ct <- data.frame(
               from=character(),
               to=character(),
               entity=numeric(),
               stringsAsFactors=FALSE
            )
         }
      }else{
         ct <- data.frame(
            from=character(),
            to=character(),
            preferred=logical(),
            entity=numeric(),
            stringsAsFactors=FALSE
         )
         fgs <- largestBeSource(
            be="Gene", organism=from.org,
            rel="is_member_of", restricted=restricted
         )
         if(fFilt){
            filter=ids
         }else{
            filter=NULL
         }
         ct1 <- getBeIdConvTable(
            from=from,
            to="Gene",
            from.source=from.source,
            to.source=fgs,
            organism=from.org,
            restricted=restricted,
            entity=FALSE,
            filter=filter
         )
         if(!is.null(ct1) && ncol(ct1)>0){
            colnames(ct1) <- c("from", "gfrom")
            stopConv <- FALSE
         }else{
            stopConv <- TRUE
         }
         if(!stopConv){
            tgs <- largestBeSource(
               be="Gene", organism=to.org,
               rel="is_member_of", restricted=restricted
            )
            ##
            if(fFilt){
               filter=setdiff(ct1$gfrom,NA)
            }else{
               filter=NULL
            }
            ht <- getHomTable(
               from.org=from.org,
               to.org=to.org,
               from.source=fgs,
               to.source=tgs,
               filter=filter
            )
            if(!is.null(ht) && ncol(ht)>0){
               colnames(ht) <- c("gfrom", "gto")
            }else{
               stopConv <- TRUE
            }
            ##
            if(!stopConv){
               if(fFilt){
                  filter=setdiff(ht$gto, NA)
               }else{
                  filter=NULL
               }
               ct2 <- getBeIdConvTable(
                  from="Gene",
                  to=to,
                  from.source=tgs,
                  to.source=to.source,
                  organism=to.org,
                  restricted=restricted,
                  entity=TRUE,
                  filter=filter
               )
               if(!is.null(ct2) && ncol(ct2)>0){
                  colnames(ct2) <- c("gto", "to", "preferred", "entity")
               }else{
                  stopConv <- TRUE
               }
               ##
               if(!stopConv){
                  ct <- unique(merge(
                     ct1, ht,
                     by="gfrom"
                  )[, c("from", "gto")])
                  ct <- unique(merge(
                     ct, ct2,
                     by="gto"
                  )[, c("from", "to", "preferred", "entity")])
               }
            }
         }
      }
      ct <- ct[order(ct$to),]
      ##
      if(!fFilt){
         cacheBedResult(value=ct, name=tn)
      }
   }
   if(caseSensitive){
      ct <- ct[which(ct$from %in% ids),]
   }else{
      oriIds <- data.frame(
         from=ids, FROM=toupper(ids),
         stringsAsFactors=FALSE
      )
      ct$FROM <- toupper(ct$from)
      ct <- merge(oriIds, ct[,setdiff(colnames(ct), "from")], by="FROM")
      ct <- ct[, setdiff(colnames(ct), "FROM")]
   }
   ##
   toRet <- ct[,c("from", "to", "preferred", "entity")]
   ##
   if(prefFilter){
      pref <- toRet[which(toRet$preferred),]
      notPref <- toRet[
         which(!toRet$preferred | is.na(toRet$preferred)),
      ]
      toRet <- rbind(
         pref,
         notPref[which(!notPref$entity %in% pref$entity),]
      )
   }
   toRet <- toRet[order(toRet$entity),]
   ##
   notFound <- setdiff(ids, toRet$from)
   if(length(notFound)>0){
      notFound <- data.frame(
         from=notFound,
         to=NA,
         preferred=NA,
         entity=NA
      )
      toRet <- rbind(toRet, notFound)
   }
   ##
   colnames(toRet) <- c("from", "to", "to.preferred", "to.entity")
   return(toRet)
}
