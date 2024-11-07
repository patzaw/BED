#' Get biological entities identifiers
#'
#' @param be one BE or "Probe"
#' @param source the BE ID database or "Symbol" if BE or
#' the probe platform if Probe
#' @param organism organism name
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned.
#' @param entity boolean indicating if the technical ID of BE should be
#' returned
#' @param attributes a character vector listing attributes that should be
#' returned.
#' @param verbose boolean indicating if the CQL query should be displayed
#' @param recache boolean indicating if the CQL query should be run even if
#' the table is already in cache
#' @param filter character vector on which to filter id. If NULL (default),
#' the result is not filtered: all IDs are taken into account.
#' @param caseSensitive if TRUE the case of provided symbols
#' is taken into account.
#' This option will only affect "Symbol" source
#' (default: caseSensitive=FALSE).
#' @param limForCache if there are more filter than limForCache results are
#' collected for all IDs (beyond provided ids) and cached for futur queries.
#' If not, results are collected only for provided ids and not cached.
#' @param bef For internal use only
#'
#' @return a data.frame mapping BE IDs with the
#' following fields:
#'
#'  - **id**: the BE ID
#'  - **preferred**: true if the id is the preferred identifier for the BE
#'  - **BE**: IF entity is TRUE the technical ID of BE
#'  - **db.version**: IF be is not "Probe" and source not "Symbol"
#'  the version of the DB
#'  - **db.deprecated**: IF be is not "Probe" and source not "Symbol"
#'  a value if the BE ID is deprecated or FALSE if it's not
#'  - **canonical**: IF source is "Symbol" TRUE if the symbol is canonical
#'  - **organism**: IF be is "Probe" the organism of the targeted BE
#'
#' If attributes are part of the query, additional columns for each of them.
#' Scope ("be", "source" and "organism") is provided as a named list
#' in the "scope" attributes: `attr(x, "scope")`
#'
#' @examples \dontrun{
#' beids <- getBeIds(be="Gene", source="EntrezGene", organism="human", restricted=TRUE)
#' }
#'
#' @seealso [listPlatforms], [listBeIdSources]
#'
#' @export
#'
getBeIds <- function(
   be=c(listBe(), "Probe"),
   source,
   organism=NA,
   restricted,
   entity=TRUE,
   attributes=NULL,
   verbose=FALSE,
   recache=FALSE,
   filter=NULL,
   caseSensitive=FALSE,
   limForCache=100,
   bef=NULL
){

   fn <- sub(
      sprintf("^%s[:][::]", utils::packageName()), "",
      sub("[(].*$", "", deparse(sys.call(), nlines=1, width.cutoff=500L))
   )

   ## Other verifications
   bentity <- match.arg(be)
   bedSources <- c(
      getAllBeIdSources(recache=recache)$database,
      listPlatforms()$name,
      "Symbol"
   )
   # source <- match.arg(source, bedSources)
   if(!is.atomic(source) || length(source)!=1){
      stop("source should be a character vector of length one")
   }
   if(!is.logical(restricted) || length(restricted)!=1){
      stop("restricted should be a logical vector of length one")
   }
   if(!is.logical(entity) || length(entity)!=1){
      stop("entity should be a logical vector of length one")
   }
   if(!is.logical(verbose) || length(verbose)!=1){
      stop("verbose should be a logical vector of length one")
   }
   if(!is.logical(recache) || length(recache)!=1){
      stop("recache should be a logical vector of length one")
   }
   if(be=="Probe" || source=="Symbol"){
      attributes <- NULL
   }else{
      attributes <- intersect(attributes, listDBAttributes(source))
   }



   ## Filter
   noCache <- FALSE
   if(length(filter)>0){
      if(length(bef)>0){
         stop("Cannot set filter and bef together")
      }
      if(!inherits(filter, "character")){
         stop("filter should be a character vector")
      }
      if(source=="Symbol" & !caseSensitive){
         filter <- toupper(filter)
      }
      FILT <- "beid"
      if(length(filter)<=limForCache){
         noCache <- TRUE
      }
   }
   ## Filter
   if(length(bef)>0){
      FILT <- "be"
      if(length(bef)<=limForCache){
         noCache <- TRUE
      }
   }

   ## Organism
   if(!is.atomic(organism) || length(organism)!=1){
      stop("organism should be a character vector of length one")
   }
   # if(is.na(organism) && bentity!="Probe"){
   #     stop("organism should be given for non 'Probe' entities")
   # }
   # if(!is.na(organism) && bentity=="Probe"){
   #    warning("organism won't be taken into account to retrieve probes")
   #    organism <- NA
   # }
   if(is.na(organism)){
      taxId <- NA
   }else{
      taxId <- getTaxId(name=organism)
      if(length(taxId)==0){
         stop("organism not found")
      }
      if(length(taxId)>1){
         print(getOrgNames(taxId))
         stop("Multiple TaxIDs match organism")
      }
   }
   parameters <- list(
      taxId=taxId,
      beSource=source
   )
   if(noCache){
      if(FILT=="beid"){
         parameters$filter <- as.list(as.character(filter))
      }else{
         parameters$filter <- as.list(bef)
      }
   }

   if(bentity != "Probe"){
      be <- bentity
      beid <- paste0(be, "ID")
      if(source=="Symbol"){
         cql <- c(
            sprintf(
               'MATCH (n:BESymbol)<-[ika:is_known_as]-(:%s)',
               beid
            )
         )
      }else{
         cql <- sprintf('MATCH (n:%s {database:$beSource})', beid)
      }
      cql <- c(
         cql,
         ifelse(
            restricted,
            '-[:is_associated_to*0..]->',
            '-[:is_replaced_by|is_associated_to*0..]->'
         ),
         '(ni)',
         '-[:identifies]->(be)'
      )
   }else{
      qs <- genProbePath(platform=source)
      be <- attr(qs, "be")
      cql <- paste0(
         'MATCH (n:ProbeID {platform:$beSource})',
         qs,
         sprintf('(be:%s)', be)
      )
   }

   cql <- c(
      cql,
      ifelse(
         be=="Gene",
         '',
         ifelse(
            !is.na(organism) || bentity=="Probe",
            '<-[cr:codes_for|is_expressed_as|is_translated_in*1..2]-(g:Gene)',
            ''
         )
      ),
      # ifelse(
      #    bentity!="Probe",
      #    ifelse(
      #       !is.na(organism),
      #       '-[:belongs_to]->(:TaxID {value:$taxId})',
      #       ''
      #    ),
      #    '-[:belongs_to]->()-[:is_named {nameClass:"scientific name"}]->(o)'
      # ),
      ifelse(
         !is.na(organism),
         '-[:belongs_to]->(:TaxID {value:$taxId})',
         ''
      ),
      ifelse(
         noCache,
         ifelse(
            FILT=="beid",
            sprintf(
               'WHERE n.%s IN $filter',
               ifelse(
                  source=="Symbol" & !caseSensitive,
                  "value_up",
                  "value"
               )
            ),
            'WHERE id(be) IN $filter'
         ),
         ""
      ),
      ifelse(
         bentity!="Probe" && source!="Symbol",
         'OPTIONAL MATCH (n)-[db:is_recorded_in]->()',
         ''
      )
   )
   ##
   for(at in attributes){
      cql <- c(
         cql,
         sprintf(
            'OPTIONAL MATCH (n)-[%s:has]->(:Attribute {name:"%s"})',
            gsub("[^[:alnum:] ]", "_", at), at
         )
      )
   }
   ##
   cql <- c(
      cql,
      'RETURN DISTINCT n.value as id, n.preferred as preferred',
      sprintf(
         ', id(be) as %s',
         be
      ),
      ifelse(
         bentity!="Probe" && source!="Symbol",
         ', db.version, db.deprecated',
         ''
      )#,
      # ifelse(
      #    bentity=="Probe",
      #    # is.na(organism),
      #    ', o.value as organism',
      #    ''
      # )
   )
   if(source=="Symbol"){
      cql <- c(
         cql,
         ", ika.canonical as canonical"
      )
   }
   ##
   for(at in attributes){
      cql <- c(
         cql,
         sprintf(
            ', %s.value as %s',
            gsub("[^[:alnum:] ]", "_", at), gsub("[^[:alnum:] ]", "_", at)
         )
      )
   }

   if(verbose){
      message(neo2R::prepCql(cql))
   }
   ##
   if(noCache){
      toRet <- bedCall(
         f=neo2R::cypher,
         query=neo2R::prepCql(cql),
         parameters=parameters
      )
   }else{
      tn <- gsub(
         "[^[:alnum:]]", "_",
         paste(
            fn,
            bentity, source,
            taxId,
            ifelse(restricted, "restricted", "full"),
            paste(attributes, collapse="-"),
            sep="_"
         )
      )
      toRet <- cacheBedCall(
         f=neo2R::cypher,
         query=neo2R::prepCql(cql),
         tn=tn,
         recache=recache,
         parameters=parameters
      )
   }
   toRet <- unique(toRet)
   if(length(filter)>0 & !is.null(toRet)){
      .data <- NULL
      if(source=="Symbol" & !caseSensitive){
         toRet <- dplyr::filter(
            toRet,
            toupper(.data$id) %in% filter
         )
      }else{
         toRet <- dplyr::filter(
            toRet,
            .data$id %in% filter
         )
      }
   }
   if(length(bef)>0 & !is.null(toRet)){
      toRet <- dplyr::filter(toRet, get(!!be) %in% !!bef)
   }
   ##
   if(!is.null(toRet)){
      toRet$preferred <- as.logical(toRet$preferred)
      toRet <- dplyr::arrange(toRet, get(!!be))
      ##
      if(!entity){
         toRet <- dplyr::distinct(dplyr::select(toRet, -!!be, -"preferred"))
      }
      attr(toRet, "scope") <- list(be=be, source=source, organism=organism)
   }
   ##
   return(toRet)
}
