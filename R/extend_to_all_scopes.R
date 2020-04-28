#' Find all BEID and ProbeID
#'
#' @export
geneIDs_to_all_scopes <- function(
   geneids, source, organism, entities=NULL, canonical_symbols=TRUE
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
      toRet <- toRet %>% dplyr::as_tibble() %>%
         dplyr::mutate(
            be=stringr::str_remove(be, "BEID [|][|] ") %>%
               stringr::str_remove("ID$"),
            source=ifelse(is.na(db), pl, db)
         ) %>%
         select(-db, -pl)
      toRet1 <- toRet %>% dplyr::select(-bes) %>% dplyr::distinct()
      toRet2 <- toRet %>%
         dplyr::select(-value) %>%
         dplyr::filter(!is.na(bes)) %>%
         dplyr::rename("value"="bes") %>%
         dplyr::mutate(source="Symbol") %>%
         dplyr::distinct()
      toRet <- dplyr::bind_rows(toRet1, toRet2)
   }
   return(toRet)
}
