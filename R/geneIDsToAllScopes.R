#' Find all BEID and ProbeID
#'
#' @param geneids a character vector of gene identifiers
#' @param source the source of gene identifiers
#' @param organism the gene organism
#' @param entities a numeric vector of gene entity. If NULL (default),
#' geneids, source and organism arguments are used to identify genes.
#' Be carefull when using entities as these identifiers are not stable.
#' @param canonical_symbols return only canonical symbols (default: TRUE).
#' @param entity_warning by default (TRUE) a warning is shown when
#' the entities argument is used. Set this argument to FALSE to avoid this
#' warning.
#'
#' @return A data.frame with the following fields:
#' - **value**: the identifier
#' - **be**: the type of BE
#' - **organism**: the BE organism
#' - **source**: the source of the identifier
#'
#' @importFrom dplyr as_tibble mutate select filter rename distinct bind_rows
#' @importFrom stringr str_remove
#' @export
#'
geneIDsToAllScopes <- function(
   geneids, source, organism, entities=NULL, canonical_symbols=TRUE,
   entity_warning=TRUE
){
   if(is.null(entities)){
      query <- sprintf(paste(
         'MATCH (gid:GeneID {database:"%s"})-[:identifies]->(g)',
         '-[:belongs_to]->(:TaxID)',
         '-[:is_named]->(o:OrganismName {value_up:"%s"})',
         'WHERE gid.value IN $ids',
      ), source, toupper(organism))
      ids <- geneids
   }else{
      if(entity_warning){
         warning(
            'Be carefull when using entities as these identifiers are ',
            'not stable.',
            '\nYou can disable this warning by setting entity_warning to FALSE.'
         )
      }
      query <- paste(
         'MATCH (g:Gene) WHERE id(g) IN $ids'
      )
      ids <- entities
   }
   query <- paste(
      query,
      'MATCH (g)-[:identifies|is_member_of*0..4]-(ag:Gene)',
      'MATCH (ag)-[:codes_for|is_expressed_as|is_translated_in*0..3]->()',
      '<-[:identifies]-()<-[:is_associated_to|is_replaced_by|targets*0..]-',
      '(beid)',
      'MATCH (ag)-[:belongs_to]->(:TaxID)',
      '-[:is_named {nameClass:"scientific name"}]->(beo:OrganismName)',
      sprintf(
         'OPTIONAL MATCH (beid)-[:is_known_as%s]->(bes)',
         ifelse(canonical_symbols, " {canonical:true}", "")
      ),
      'RETURN DISTINCT',
      'beid.value as value, labels(beid) as be,',
      'beid.database as db, beid.platform as pl,',
      'bes.value as bes,',
      'beo.value as organism'
   )
   toRet <- bedCall(cypher, query=query, parameters=list(ids=as.list(ids)))
   if(!is.null(toRet)){
      toRet <- dplyr::as_tibble(toRet)
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
   }
   return(as.data.frame(toRet))
}
