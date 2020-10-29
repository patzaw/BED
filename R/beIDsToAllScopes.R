#' Find all BEID and ProbeID corresponding to a BE
#'
#' @param beids a character vector of gene identifiers
#' @param be one BE. **Guessed if not provided**
#' @param source the source of gene identifiers. **Guessed if not provided**
#' @param organism the gene organism. **Guessed if not provided**
#' @param entities a numeric vector of gene entity. If NULL (default),
#' beids, source and organism arguments are used to identify BEs.
#' Be carefull when using entities as these identifiers are not stable.
#' @param canonical_symbols return only canonical symbols (default: TRUE).
#'
#' @return A data.frame with the following fields:
#'
#' - **value**: the identifier
#' - **be**: the type of BE
#' - **source**: the source of the identifier
#' - **organism**: the BE organism
#' - **symbol**: canonical symbol of the identifier
#' - **BE_entity**: the BE entity input
#' - **BEID** (optional): the BE ID input
#' - **BE_source** (optional): the BE source input
#'
#' @export
#'
beIDsToAllScopes <- function(
   beids, be, source, organism, entities=NULL, canonical_symbols=TRUE
){
   if(is.null(entities)){
      stopifnot(
         is.character(beids), all(!is.na(beids)), length(beids)>0
      )
      ##
      if(missing(be) || missing(source) || missing(organism)){
         toWarn <- TRUE
      }else{
         toWarn <- FALSE
      }
      guess <- guessIdScope(ids=beids, be=be, source=source, organism=organism)

      if(is.null(guess)){
         warning("Could not find the provided ids")
         if(missing(be) || missing(source) || missing(organism)){
            stop("Missing be, source or organism information")
         }
      }else{
         if(is.na(guess$be)){
            warning(
               "The provided ids does not match the provided scope",
               " (be, source or organism)"
            )
            if(missing(be) || missing(source) || missing(organism)){
               stop("Missing be, source or organism information")
            }
         }else{
            be <- guess$be
            source <- guess$source
            organism <- guess$organism
         }
      }

      if(toWarn){
         warning(
            "Guessing ID scope:",
            sprintf("\n   - be: %s", be),
            sprintf("\n   - source: %s", source),
            sprintf("\n   - organism: %s", organism)
         )
      }
      ##
      if(source=="Symbol"){
         stop('source cannot be "Symbol"')
      }
      query <- sprintf(
         paste(
            'MATCH (bid:%s {%s:"%s"})',
            '-[:is_associated_to|is_replaced_by|targets*0..]->()',
            '-[:identifies]->(be)',
            '<-[:is_expressed_as|is_translated_in|codes_for*0..2]-(:Gene)',
            '-[:belongs_to]->(tid:TaxID)',
            '-[:is_named]->(o:OrganismName {value_up:"%s"})',
            'WHERE bid.value IN $ids'
         ),
         paste0(be, "ID"), ifelse(be=="Probe", "platform", "database"),
         source,
         toupper(organism)
      )
      ids <- beids
   }else{
      stopifnot(
         is.numeric(entities), all(!is.na(entities)), length(entities)>0
      )
      warning(
         'Be carefull when using entities as these identifiers are ',
         'not stable.'
      )
      query <- paste(
         'MATCH (be)',
         '<-[:is_expressed_as|is_translated_in|codes_for*0..2]-(:Gene)',
         '-[:belongs_to]->(tid:TaxID)',
         'WHERE id(be) IN $ids'
      )
      ids <- unique(entities)
   }
   query <- paste(
      query,
      'MATCH (be)',
      '<-[:identifies]-()<-[:is_associated_to|is_replaced_by|targets*0..]-',
      '(beid)',
      'MATCH (tid)',
      '-[:is_named {nameClass:"scientific name"}]->(beo:OrganismName)',
      sprintf(
         'OPTIONAL MATCH (beid)-[k:is_known_as%s]->(bes)',
         ifelse(canonical_symbols, " {canonical:true}", "")
      ),
      'RETURN DISTINCT',
      'beid.value as value, labels(beid) as be,',
      'beid.database as db, beid.platform as pl,',
      'beid.preferred as preferred,',
      'bes.value as bes,',
      'k.canonical as canBes,',
      'beo.value as organism,',
      'id(be) as BE_entity'
   )
   if(is.null(entities)){
      query <- paste(
         query,
         ', bid.value as BEID,',
         sprintf(
            'bid.%s as BE_source',
            ifelse(be=="Probe", "platform", "database"), be
         )
      )
   }
   toRet <- bedCall(
      neo2R::cypher, query=query, parameters=list(ids=as.list(ids))
   )
   if(!is.null(toRet)){
      toRet <- dplyr::mutate(
         toRet,
         "be"=stringr::str_remove(
            stringr::str_remove(toRet$be, "BEID [|][|] "),
            "ID$"),
         "source"=ifelse(is.na(toRet$db), toRet$pl, toRet$db)
      )
      toRet <- dplyr::select(toRet, -"db", -"pl")
      ##
      toRet1 <- dplyr::arrange(toRet, desc(.data$canBes))
      toRet1 <- dplyr::group_by(
         toRet1,
         .data$value, .data$preferred, .data$be,
         .data$source, .data$organism, .data$BE_entity
      )
      toRet1 <- dplyr::summarise_all(toRet1, function(x)x[1])
      toRet1 <- dplyr::select(toRet1, -"canBes")
      toRet1 <- dplyr::ungroup(toRet1)
      # toRet1 <- dplyr::distinct(dplyr::select(toRet, "bes"))
      toRet2 <- dplyr::select(toRet, -"value", -"preferred")
      toRet2 <- dplyr::filter(toRet2, !is.na(toRet2$bes))
      ##
      toRet2 <- dplyr::mutate(
         toRet2,
         "value"=.data$bes,
         source="Symbol"
      )
      toRet2 <- dplyr::rename(toRet2, "preferred"="canBes")
      ##
      toRet2 <- dplyr::distinct(toRet2)
      toRet <- dplyr::bind_rows(toRet1, toRet2)
      toRet <- dplyr::rename(toRet, "symbol"="bes")
      if(is.null(entities)){
         toRet <- dplyr::select(
            toRet, "value", "preferred", "be", "source", "organism",
            "symbol",
            "BE_entity",
            "BEID", "BE_source"
         )
      }else{
         toRet <- dplyr::select(
            toRet, "value", "preferred", "be", "source", "organism",
            "symbol",
            "BE_entity"
         )
      }
   }
   return(toRet)
}
