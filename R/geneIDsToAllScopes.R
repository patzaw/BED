#' Find all GeneID, ObjectID, TranscriptID, PeptideID and ProbeID corresponding to a Gene in any organism
#'
#' @param geneids a character vector of gene identifiers
#' @param source the source of gene identifiers. **Guessed if not provided**
#' @param organism the gene organism. **Guessed if not provided**
#' @param entities a numeric vector of gene entity. If NULL (default),
#' geneids, source and organism arguments are used to identify genes.
#' Be carefull when using entities as these identifiers are not stable.
#' @param orthologs return identifiers from orthologs
#' @param canonical_symbols return only canonical symbols (default: TRUE).
#'
#' @return A data.frame with the following fields:
#'
#' - **value**: the identifier
#' - **preferred**: preferred identifier for the same BE in the same scope
#' - **be**: the type of BE
#' - **organism**: the BE organism
#' - **source**: the source of the identifier
#' - **canonical**: canonical gene product (logical)
#' - **symbol**: canonical symbol of the identifier
#' - **Gene_entity**: the gene entity input
#' - **GeneID** (optional): the gene ID input
#' - **Gene_source** (optional): the gene source input
#' - **Gene_organism** (optional): the gene organism input
#'
#' @export
#'
geneIDsToAllScopes <- function(
   geneids,
   source, organism,
   entities=NULL,
   orthologs=TRUE,
   canonical_symbols=TRUE
){
   stopifnot(
      is.logical(orthologs), length(orthologs)==1, !is.na(orthologs)
   )
   if(is.null(entities)){
      stopifnot(
         is.character(geneids), all(!is.na(geneids)), length(geneids)>0
      )
      ##
      if(missing(source) || missing(organism)){
         toWarn <- TRUE
      }else{
         toWarn <- FALSE
      }
      be <- "Gene"
      guess <- guessIdScope(ids=geneids, be=be, source=source, organism=organism)
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
      query <- sprintf(paste(
         'MATCH (gid:GeneID {database:"%s"})',
         '-[:is_associated_to|is_replaced_by*0..]->()-[:identifies]->(g)',
         '-[:belongs_to]->(:TaxID)',
         '-[:is_named]->(o:OrganismName {value_up:"%s"})',
         'WHERE gid.value IN $ids'
      ), source, toupper(organism))
      ids <- geneids
   }else{
      stopifnot(
         is.numeric(entities), all(!is.na(entities)), length(entities)>0
      )
      warning(
         'Be carefull when using entities as these identifiers are ',
         'not stable.'
      )
      query <- paste(
         'MATCH (g:Gene) WHERE id(g) IN $ids'
      )
      ids <- unique(entities)
   }
   query <- paste(
      query,
      sprintf(
         'MATCH (g)-[:identifies|is_member_of%s]-(ag:Gene)',
         ifelse(orthologs, "*0..4", "*0")
      ),
      'MATCH (ag)-[:codes_for|is_expressed_as|is_translated_in*0..3]->()',
      '<-[:identifies]-()<-[:is_associated_to|is_replaced_by|targets*0..]-',
      '(beid)',
      'MATCH (ag)-[:belongs_to]->(:TaxID)',
      '-[:is_named {nameClass:"scientific name"}]->(beo:OrganismName)',
      sprintf(
         'OPTIONAL MATCH (beid)-[k:is_known_as%s]->(bes)',
         ifelse(canonical_symbols, " {canonical:true}", "")
      ),
      'OPTIONAL MATCH',
      '(beid)<-[p:codes_for|is_expressed_as|is_translated_in*1..2]-(:GeneID)',
      'RETURN DISTINCT',
      'beid.value as value, labels(beid) as be,',
      'reduce(canonical=true, n IN p| canonical AND n.canonical) as canonical,',
      'beid.database as db, beid.platform as pl,',
      'beid.preferred as preferred,',
      'bes.value as bes,',
      'k.canonical as canBes,',
      'beo.value as organism,',
      'id(g) as Gene_entity'
   )
   if(is.null(entities)){
      query <- paste(
         query,
         ', gid.value as GeneID,',
         'gid.database as Gene_source,',
         'o.value as Gene_organism'
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
      # toRet1 <- toRet
      toRet1 <- dplyr::arrange(toRet, desc(.data$canBes))
      toRet1 <- dplyr::group_by(
         toRet1,
         .data$value, .data$preferred, .data$be,
         .data$source, .data$organism, .data$Gene_entity
      )
      toRet1 <- dplyr::summarise_all(toRet1, function(x)x[1])
      toRet1 <- dplyr::ungroup(toRet1)
      toRet1 <- dplyr::select(toRet1, -"canBes")
      # toRet1 <- dplyr::distinct(dplyr::select(toRet, "bes"))
      toRet2 <- dplyr::select(toRet, -"value", -"preferred")
      toRet2 <- dplyr::filter(toRet2, !is.na(toRet2$bes))
      ##
      # toRet2 <- dplyr::mutate(
      #    toRet2, "value"=.data$bes, "preferred"=NA
      # )
      toRet2 <- dplyr::mutate(
         toRet2,
         "value"=.data$bes,
         source="Symbol"
      )
      toRet2 <- dplyr::rename(toRet2, "preferred"="canBes")
      ##
      toRet2 <- dplyr::mutate(toRet2, source="Symbol")
      toRet2 <- dplyr::distinct(toRet2)
      toRet <- dplyr::bind_rows(toRet1, toRet2)
      toRet <- dplyr::rename(toRet, "symbol"="bes")
      if(is.null(entities)){
         toRet <- dplyr::select(
            toRet, "value", "preferred", "be", "source", "organism",
            "canonical", "symbol",
            "Gene_entity",
            "GeneID", "Gene_source", "Gene_organism"
         )
      }else{
         toRet <- dplyr::select(
            toRet, "value", "preferred", "be", "source", "organism",
            "canonical", "symbol",
            "Gene_entity"
         )
      }
   }
   return(toRet)
}
