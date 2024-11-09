#' Search a BEID
#'
#' @param x a character value to search
#' @param maxHits maximum number of raw hits to return
#' @param clean_id_search clean x to avoid error during ID search.
#' Default: TRUE. Set it to false if you're sure of your lucene query.
#' @param clean_name_search clean x to avoid error during ID search.
#' Default: TRUE. Set it to false if you're sure of your lucene query.
#'
#' @return NULL if there is not any match or
#' a data.frame with the following columns:
#'
#' - **value**: the matching term
#' - **from**: the type of the matched term (e.g. BESymbol, GeneID...)
#' - **be**: the matching biological entity (BE)
#' - **beid**: the BE identifier
#' - **source**: the BEID reference database
#' - **preferred**: TRUE if the BEID is considered as a preferred identifier
#' - **symbol**: BEID canonical symbol
#' - **name**: BEID name
#' - **entity**: technical BE identifier
#' - **GeneID**: Corresponding gene identifier
#' - **Gene_source**: Gene ID database
#' - **preferred_gene**: TRUE if the GeneID is considered as a preferred identifier
#' - **Gene_symbol**: Gene symbol
#' - **Gene_name**: Gene name
#' - **Gene_entity**: technical gene identifier
#' - **organism**: gene organism (scientific name)
#' - **score**: score of the fuzzy search
#' - **included**: is the search term fully included in the value
#' - **exact**: is the value an exact match of the term
#'
#' @export
#'
searchBeid <- function(
   x, maxHits=75, clean_id_search=TRUE, clean_name_search=TRUE
){
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
            'YIELD node, score WITH DISTINCT node as mn, score limit 5',
            'MATCH (mn)-[r:targets*0..1]-(beid:BEID)'
         ),
         vi
      ),
      name=sprintf(
         paste(
            'CALL db.index.fulltext.queryNodes("bename", "%s")',
            'YIELD node, score WITH DISTINCT node as mn, score limit %s',
            'MATCH (mn)-[r:is_named|is_known_as]-(beid:BEID)'
         ),
         vn, maxHits
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
         'OPTIONAL MATCH (beid)-[bnr:is_named]->(ben:BEName)',
         'OPTIONAL MATCH (gid)-[:is_known_as {canonical:true}]->(ges:BESymbol)',
         'OPTIONAL MATCH (gid)-[gnr:is_named]->(gen:BEName)',
         'RETURN DISTINCT',
         'mn.value as value,',
         'labels(mn) as from,',
         'labels(be) as be,',
         'beid.value as beid, beid.database as source,',
         'beid.preferred as preferred,',
         'bes.value as symbol, ben.value as name,',
         'bnr.canonical as canonical_name,',
         'id(be) as entity,',
         'gid.value as GeneID, gid.database as Gene_source,',
         'gid.preferred as preferred_gene,',
         'ges.value as Gene_symbol, gen.value as Gene_name,',
         'gnr.canonical as canonical_Gene_name,',
         'id(g) as Gene_entity, o.value as organism,',
         'score'
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
      be=stringr::str_remove(.data$be, "BEID [|][|] "),
      included=stringr::str_detect(
         .data$value, pattern=regex(x, ignore_case = T)
      ),
      exact=stringr::str_detect(
         .data$value, pattern=regex(x, ignore_case = T)
      ) & nchar(.data$value) == nchar(x)
   )
   values <- dplyr::arrange(
      values,
      desc(.data$exact),
      desc(.data$included),
      desc(.data$score),
      desc(.data$Gene_symbol == .data$value),
      desc(.data$symbol == .data$value),
      desc(.data$canonical_name),
      desc(.data$canonical_Gene_name)
   )
   values <- dplyr::distinct(
      values,
      .data$value,
      .data$from,
      .data$be,
      .data$beid,
      .data$source,
      .data$preferred,
      .data$symbol,
      # .data$name,
      # .data$canonical_name,
      .data$entity,
      .data$GeneID,
      .data$Gene_source,
      .data$preferred_gene,
      .data$Gene_symbol,
      # .data$Gene_name,
      # .data$canonical_Gene_name,
      .data$Gene_entity,
      .data$organism,
      .data$score,
      .data$included,
      .data$exact,
      .keep_all = TRUE
   )
   return(values)
}
