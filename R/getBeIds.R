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
#' @param limForCache if there are more filter than limForCache results are
#' collected for all IDs (beyond provided ids) and cached for futur queries.
#' If not, results are collected only for provided ids and not cached.
#'
#' @return a data.frame mapping BE IDs with the
#' following fields:
#' \describe{
#'  \item{id}{the BE ID}
#'  \item{BE}{IF entity is TRUE the technical ID of BE}
#'  \item{db.version}{IF be is not "Probe" and source not "Symbol"
#'  the version of the DB}
#'  \item{db.deprecated}{IF be is not "Probe" and source not "Symbol"
#'  a value if the BE ID is deprecated or FALSE if it's not}
#'  \item{canonical}{IF source is "Symbol" TRUE if the symbol is canonical}
#'  \item{organism}{IF be is "Probe" the organism of the targeted BE}
#' }
#' If attributes are part of the query, additional columns for each of them.
#'
#' @examples \dontrun{
#' beids <- getBeIds(be="Gene", source="EntrezGene", organism="human", restricted=TRUE)
#' }
#'
#' @seealso \code{\link{listPlatforms}}, \code{\link{listBeIdSources}}
#'
#' @importFrom neo2R prepCql cypher
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
   limForCache=4000
){

   ## Other verifications
   bentity <- match.arg(be)
   bedSources <- c(
      getAllBeIdSources(recache=recache)$database,
      listPlatforms()$name,
      "Symbol"
   )
   source <- match.arg(source, bedSources)
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

   if(length(filter)>0 & length(filter)<=limForCache){
      noCache <- TRUE
   }else{
      noCache <- FALSE
   }

   ## Organism
   if(!is.atomic(organism) || length(organism)!=1){
      stop("organism should be a character vector of length one")
   }
   # if(is.na(organism) && bentity!="Probe"){
   #     stop("organism should be given for non 'Probe' entities")
   # }
   if(!is.na(organism) && bentity=="Probe"){
      warning("organism won't be taken into account to retrieve probes")
      organism <- NA
   }
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
      beSource=source,
      filter=as.list(as.character(filter))
   )

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
            '<-[cr*1..10]-(g:Gene)',
            ''
         )
      ),
      ifelse(
         bentity!="Probe",
         ifelse(
            !is.na(organism),
            '-[:belongs_to]->(:TaxID {value:$taxId})',
            ''
         ),
         '-[:belongs_to]->()-[:is_named {nameClass:"scientific name"}]->(o)'
      ),
      ifelse(
         noCache,
         'WHERE n.value IN $filter',
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
      'RETURN n.value as id, n.preferred as preferred',
      sprintf(
         ', id(be) as %s',
         be
      ),
      ifelse(
         bentity!="Probe" && source!="Symbol",
         ', db.version, db.deprecated',
         ''
      ),
      ifelse(
         bentity=="Probe",
         # is.na(organism),
         ', o.value as organism',
         ''
      )
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
      message(prepCql(cql))
   }
   ##
   if(noCache){
      toRet <- bedCall(
         f=cypher,
         query=prepCql(cql),
         parameters=parameters
      )
   }else{
      tn <- gsub(
         "[^[:alnum:]]", "_",
         paste(
            match.call()[[1]],
            bentity, source,
            taxId,
            ifelse(restricted, "restricted", "full"),
            paste(attributes, collapse="-"),
            sep="_"
         )
      )
      toRet <- cacheBedCall(
         f=cypher,
         query=prepCql(cql),
         tn=tn,
         recache=recache,
         parameters=parameters
      )
   }
   toRet <- unique(toRet)
   if(length(filter)>0 & !is.null(toRet)){
      toRet <- toRet[which(toRet$id %in% filter),]
   }
   ##
   if(!is.null(toRet)){
      toRet$preferred <- as.logical(toRet$preferred)
      toRet <- toRet[order(toRet[,be]),]
      ##
      if(!entity){
         toRet <- unique(toRet[, setdiff(colnames(toRet), c(be, "preferred"))])
      }
   }
   ##
   return(toRet)
}
