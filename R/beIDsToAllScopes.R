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
#' @param entity_warning by default (TRUE) a warning is shown when
#' the entities argument is used. Set this argument to FALSE to avoid this
#' warning.
#'
#' @return A data.frame with the following fields:
#'
#' - **value**: the identifier
#' - **be**: the type of BE
#' - **organism**: the BE organism
#' - **source**: the source of the identifier
#' - **Gene_entity**: the gene entity input
#' - **GeneID** (optional): the gene ID input
#' - **Gene_source** (optional): the gene source input
#' - **Gene_organism** (optional): the gene organism input
#'
#' @export
#'
beIDsToAllScopes <- function(
   beids, be, source, organism, entities=NULL, canonical_symbols=TRUE,
   entity_warning=TRUE
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
         stop("Could not find the provided beids")
      }
      if(is.na(guess$be)){
         stop(
            "The provided beids does not match the provided scope",
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
      if(entity_warning){
         warning(
            'Be carefull when using entities as these identifiers are ',
            'not stable.',
            '\nYou can disable this warning by setting entity_warning to FALSE.'
         )
      }
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
         'OPTIONAL MATCH (beid)-[:is_known_as%s]->(bes)',
         ifelse(canonical_symbols, " {canonical:true}", "")
      ),
      'RETURN DISTINCT',
      'beid.value as value, labels(beid) as be,',
      'beid.database as db, beid.platform as pl,',
      'bes.value as bes,',
      'beo.value as organism,',
      'id(be) as BE_entity'
   )
   if(is.null(entities)){
      query <- paste(
         query,
         sprintf(', bid.value as %s,', paste0(be, "ID")),
         sprintf(
            'bid.%s as %s_source',
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
      toRet1 <- dplyr::distinct(dplyr::select(toRet, -"bes"))
      toRet2 <- dplyr::select(toRet, -"value")
      toRet2 <- dplyr::filter(toRet2, !is.na(toRet2$bes))
      toRet2 <- dplyr::rename(toRet2, "value"="bes")
      toRet2 <- dplyr::mutate(toRet2, source="Symbol")
      toRet2 <- dplyr::distinct(toRet2)
      toRet <- dplyr::bind_rows(toRet1, toRet2)
      if(is.null(entities)){
         toRet <- dplyr::select(
            toRet, "value", "be", "source", "organism", "BE_entity",
            paste0(!!be, "ID"), paste0(!!be, "_source"),
         )
      }else{
         toRet <- dplyr::select(
            toRet, "value", "be", "source", "organism", "BE_entity"
         )
      }
   }
   return(toRet)
}
