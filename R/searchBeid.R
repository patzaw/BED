#' Search a BEID
#'
#' @param x a character value to search
#' @param clean_id_search clean x to avoid error during ID search.
#' Default: TRUE. Set it to false if you're sure of your lucene query.
#' @param clean_name_search clean x to avoid error during ID search.
#' Default: TRUE. Set it to false if you're sure of your lucene query.
#'
#' @return NULL if there is not any match or
#' a data.frame with the following columns:
#'
#' - **Value**: the matching term
#' - **From**: the type of the matched term (e.g. BESymbol, GeneID...)
#' - **BE**: the matching biological entity (BE)
#' - **BEID**: the BE identifier
#' - **Database**: the BEID reference database
#' - **Preferred**: TRUE if the BEID is considered as a preferred identifier
#' - **Symbol**: BEID canonical symbol
#' - **Name**: BEID name
#' - **Entity**: technical BE identifier
#' - **GeneID**: Corresponding gene identifier
#' - **Gene_DB**: Gene ID database
#' - **Preferred_gene**: TRUE if the GeneID is considered as a preferred identifier
#' - **Gene_symbol**: Gene symbol
#' - **Gene_name**: Gene name
#' - **Gene_entity**: technical gene identifier
#' - **Organism**: gene organism (scientific name)
#'
#' @export
#'
searchBeid <- function(x, clean_id_search=TRUE, clean_name_search=TRUE){
   stopifnot(
      is.character(x),
      length(x)==1,
      !is.na(x)
   )
   clean_search_name <- function(x){
      if(nchar(stringr::str_remove_all(x, '[^"]')) %% 2 != 0){
         x <- stringr::str_remove_all(x, '"')
      }
      x <- stringr::str_replace_all(x, '"', '\\\\"')
      x <- stringr::str_replace_all(x, "'", "\\\\'")
      x <- stringr::str_replace_all(x, stringr::fixed('^'), '\\\\^')
      x <- stringr::str_remove_all(x, '~')
      x <- stringr::str_remove(x, ' *$')
      x <- stringr::str_replace_all(x, ' +', '~ ')
      while(
         substr(x, nchar(x), nchar(x)) %in%
         c(
            "+", "-",  "&", "|",  "!", "(" , ")",
            "{", "}", "[", "]", "?", ":", "/",
            "~", " "
         )
      ){
         x <- substr(x, 1, nchar(x)-1)
      }
      clean_brack <- function(x, bl, br){
         y <- x
         yc <- stringr::str_remove_all(
            y,
            sprintf('[%s][^%s%s]*[%s]', bl, bl, br, br)
         )
         while(nchar(yc) < nchar(y)){
            y <- yc
            yc <- stringr::str_remove_all(
               y,
               sprintf('[%s][^%s%s]*[%s]', bl, bl, br, br)
            )
         }
         if(sum(stringr::str_detect(y, sprintf('[%s%s]', br, bl)))==1){
            x <- stringr::str_replace_all(x, sprintf('[%s%s]', br, bl), " ")
         }
         return(x)
      }
      x <- clean_brack(x, "(", ")")
      x <- clean_brack(x, "{", "}")
      x <- clean_brack(x, "\\[", "\\]")
      if(nchar(x)>0){
         x <- paste0(x, "~")
      }
      return(x)
   }
   clean_search_id <- function(x){
      x <- stringr::str_remove_all(x, '"')
      x <- stringr::str_replace_all(x, "'", "\\\\'")
      x <- stringr::str_replace_all(x, stringr::fixed('^'), '\\\\^')
      x <- stringr::str_remove_all(x, '~')
      x <- stringr::str_remove(x, ' *$')
      if(nchar(x)>0){
         x <- sprintf('\\"%s\\"', x)
      }
      return(x)
   }
   if(clean_id_search) vi <- clean_search_id(x)
   if(clean_name_search) vn <- clean_search_name(x)
   if(nchar(vi)==0 || nchar(vn)==0){
      return(NULL)
   }

   # 'CALL db.index.fulltext.queryNodes("beid", "%s")',
   # 'YIELD node WITH collect(node) as l1',
   # 'CALL db.index.fulltext.queryNodes("bename", "%s")',
   # 'YIELD node WITH collect(node) as l2, l1',
   # 'UNWIND l1+l2 as mn WITH DISTINCT mn limit 50',
   # 'MATCH (mn)-[r:targets|is_named|is_known_as*0..1]-(beid:BEID)',

   queries <- c(
      id=sprintf(
         paste(
            'CALL db.index.fulltext.queryNodes("beid", "%s")',
            'YIELD node WITH DISTINCT node as mn limit 5',
            'MATCH (mn)-[r:targets*0..1]-(beid:BEID)'
         ),
         vi
      ),
      name=sprintf(
         paste(
            'CALL db.index.fulltext.queryNodes("bename", "%s")',
            'YIELD node WITH DISTINCT node as mn limit 50',
            'MATCH (mn)-[r:is_named|is_known_as]-(beid:BEID)'
         ),
         vn
      )
   )
   queries <- paste(
      queries,
      paste(
         '-[:is_associated_to|is_replaced_by*0..]->()-[:identifies]->(be)',
         'MATCH (be)<-[:is_expressed_as|is_translated_in|codes_for*0..2]-(g:Gene)',
         'MATCH (gid:GeneID)-[:identifies]->(g)',
         '-[:belongs_to]->(:TaxID)',
         '-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
         'OPTIONAL MATCH (beid)-[:is_known_as {canonical:true}]->(bes:BESymbol)',
         'OPTIONAL MATCH (beid)-[:is_named]->(ben:BEName)',
         'OPTIONAL MATCH (gid)-[:is_known_as {canonical:true}]->(ges:BESymbol)',
         'OPTIONAL MATCH (gid)-[:is_named]->(gen:BEName)',
         'RETURN DISTINCT',
         'mn.value as value,',
         'labels(mn) as from,',
         'labels(be) as be,',
         'beid.value as beid, beid.database as source,',
         'beid.preferred as preferred,',
         'bes.value as symbol, ben.value as name,',
         'id(be) as entity,',
         'gid.value as GeneID, gid.database as Gene_source,',
         'gid.preferred as preferred_gene,',
         'ges.value as Gene_symbol, gen.value as Gene_name,',
         'id(g) as Gene_entity, o.value as organism'
      )
   )
   values <- bedCall(
      neo2R::multicypher,
      queries=queries
   )
   values <- do.call(rbind, values)

   if(is.null(values) || nrow(values)==0){
      return(NULL)
   }
   .data <- NULL
   values <- dplyr::mutate(
      values,
      from=stringr::str_remove(.data$from, "BEID [|][|] "),
      be=stringr::str_remove(.data$be, "BEID [|][|] ")
   )
   return(values)
}
