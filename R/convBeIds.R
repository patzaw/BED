#' Converts BE IDs
#'
#' @param ids list of identifiers
#' @param from a character corresponding to the biological entity or Probe.
#' **Guessed if not provided**
#' @param from.source a character corresponding to the ID source.
#' **Guessed if not provided**
#' @param from.org a character corresponding to the organism.
#' **Guessed if not provided**
#' @param to a character corresponding to the biological entity or Probe
#' @param to.source a character corresponding to the ID source
#' @param to.org a character corresponding to the organism
#' @param caseSensitive if TRUE the case of provided symbols
#' is taken into account
#' during search. This option will only affect the conversion from "Symbol"
#' (default: caseSensitive=FALSE).
#' All the other conversion will be case sensitive.
#' @param prefFilter boolean indicating if the results should be filter
#' to keep only preferred BEID of BE when they exist (default: FALSE).
#' If there are several
#' preferred BEID of a BE, all are kept. If there are no preferred BEID
#' of a BE, all non-preferred BEID are kept.
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned:
#' **Depending on history it can take a very long time to return**
#' **a very large result!**
#' @param recache a logical value indicating if the results should be taken from
#' cache or recomputed
#' @param limForCache if there are more ids than limForCache. Results are
#' collected for all IDs (beyond provided ids) and cached for futur queries.
#' If not, results are collected only for provided ids and not cached.
#'
#' @return a data.frame with the following columns:
#'
#'  - **from**: the input IDs
#'  - **to**: the corresponding IDs in `to.source`
#'  - **to.preferred**: boolean indicating if the to ID is a preferred
#'  ID for the corresponding entity.
#'  - **to.entity**: the entity technical ID of the `to` IDs
#'
#' This data.frame can be filtered in order to remove duplicated
#' from/to.entity associations which can lead information bias.
#' Scope ("be", "source" and "organism") is provided as a named list
#' in the "scope" attributes: `attr(x, "scope")`
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
#' @seealso [getBeIdConvTable], [convBeIdLists], [convDfBeIds]
#'
#' @export
#'
convBeIds <- function(
   ids,
   from,
   from.source,
   from.org,
   to,
   to.source,
   to.org,
   caseSensitive=FALSE,
   prefFilter=FALSE,
   restricted=TRUE,
   recache=FALSE,
   limForCache=2000
){

   fn <- sub(
      sprintf("^%s[:][::]", utils::packageName()), "",
      sub("[(].*$", "", deparse(sys.call(), nlines=1, width.cutoff=500L))
   )

   ids <- sort(setdiff(as.character(unique(ids)), NA))

   ##
   if(missing(from) || missing(from.source) || missing(from.org)){
      toWarn <- TRUE
   }else{
      toWarn <- FALSE
   }
   guess <- guessIdScope(
      ids=ids, be=from, source=from.source, organism=from.org
   )
   if(is.null(guess)){
      warning("Could not find the provided ids")
      if(missing(from) || missing(from.source) || missing(from.org)){
         stop("Missing from, from.source or from.org information")
      }
   }else{
      if(is.na(guess$be)){
         warning(
            "The provided ids does not match the provided scope",
            " (from, from.source or from.org)"
         )
         if(missing(from) || missing(from.source) || missing(from.org)){
            stop("Missing from, from.source or from.org information")
         }
      }else{
         from <- guess$be
         from.source <- guess$source
         from.org <- guess$organism
      }
   }
   if(toWarn){
      warning(
         "Guessing ID scope:",
         sprintf("\n   - from: %s", from),
         sprintf("\n   - from.source: %s", from.source),
         sprintf("\n   - from.org: %s", from.org)
      )
   }
   ##
   if(missing(to)) to <- from
   if(missing(to.source)) to.source <- from.source
   if(missing(to.org)) to.org <- from.org
   ##

   fFilt <- length(ids) <= limForCache
   if(!fFilt){
      tn <- gsub(
         "[^[:alnum:]]", "_",
         paste(fn
            ,
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
            caseSensitive=caseSensitive,
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
            caseSensitive=caseSensitive,
            restricted=restricted,
            entity=FALSE,
            filter=filter
         )
         if(!is.null(ct1) && ncol(ct1)>0){
            ct1 <- dplyr::rename(ct1, "gfrom"="to")
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
               restricted=TRUE,
               filter=filter
            )
            if(!is.null(ht) && ncol(ht)>0){
               ht <- dplyr::rename(ht, "gfrom"="from", "gto"="to")
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
                  caseSensitive=caseSensitive,
                  restricted=restricted,
                  entity=TRUE,
                  filter=filter
               )
               if(!is.null(ct2) && ncol(ct2)>0){
                  ct2 <- dplyr::rename(ct2, "gto"="from")
               }else{
                  stopConv <- TRUE
               }
               ##
               if(!stopConv){
                  ct <- unique(dplyr::inner_join(
                     ct1, ht,
                     by="gfrom"
                  )[, c("from", "gto")])
                  ct <- unique(dplyr::inner_join(
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
   if(caseSensitive | from.source!="Symbol"){
      ct <- ct[which(ct$from %in% ids),]
   }else{
      oriIds <- data.frame(
         from=ids, FROM=toupper(ids),
         stringsAsFactors=FALSE
      )
      ct$FROM <- toupper(ct$from)
      ct <- dplyr::inner_join(
         oriIds, ct[,setdiff(colnames(ct), "from")],
         by="FROM"
      )
      ct <- unique(ct[, setdiff(colnames(ct), "FROM")])
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
   toRet <- dplyr::rename(
      toRet, "to.preferred"="preferred","to.entity"="entity"
   )
   attr(toRet, "scope") <- list(
      be=to, source=to.source, organism=to.org
   )
   return(toRet)
}
