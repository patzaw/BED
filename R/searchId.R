#' Search identifier, symbol or name information
#'
#' **DEPRECATED: use [searchBeid] and [geneIDsToAllScopes] instead.**
#' This function is meant to be used with [getRelevantIds] in order
#' to implement a dictonary of identifiers of interest. First
#' the [searchId] function is used to search a term.
#' Then the [getRelevantIds] function
#' is used to find the corresponding ID in a context of interest.
#'
#' @param searched the searched term. Identifiers are searched by exact match.
#' Symbols and names are also searched for partial match when searched is
#' greater than ncharSymb and ncharName respectively.
#' @param be optional. If provided the search is focused on provided BEs.
#' @param organism optional.  If provided the search is focused on provided
#' organisms.
#' @param ncharSymb The minimum number of characters in searched to consider
#' incomplete symbol matches.
#' @param ncharName The minimum number of characters in searched to consider
#' incomplete name matches.
#' @param verbose boolean indicating if the CQL queries should be displayed
#'
#'
#' @return A data frame with the following fields:
#'
#' - **found**: the element found in BED corresponding to the searched term
#' - **be**: the type of the element
#' - **source**: the source of the element
#' - **organism**: the related organism
#' - **entity**: the related entity internal ID
#' - **ebe**: the BE of the related entity
#' - **canonical**: if the symbol is canonical
#' - **gene**: list of the related genes BE internal ID
#'
#' Exact matches are returned first folowed by the shortest elements.
#'
#' @export
#'
#' @seealso [getRelevantIds]
#'
searchId <- function(
    searched, be=NULL, organism=NULL,
    ncharSymb=4, ncharName=8,
    verbose=FALSE
){

    warning("Deprecated. Use `searchBeid()` instead.")

    ##
    if(length(searched)!=1){
        stop("search should be of length 1")
    }
    if(!is.null(be)){
        match.arg(be, c("Probe", listBe()), several.ok=TRUE)
    }
    ##
    parameters <- list(
        searched=as.character(searched),
        upSearched=toupper(as.character(searched)),
        be=as.list(be),
        org=as.list(toupper(organism))
    )
    ##
    query <- neo2R::prepCql(
       'MATCH (n:BEID)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
       'WHERE n.value = $searched',
       'MATCH (ni)-[:identifies]->(e)',
       'WITH DISTINCT n, ni, e',
       'MATCH (e)<-[cr:codes_for|is_expressed_as|is_translated_in*0..2]-(g:Gene)',
       'MATCH (g)-[:belongs_to]->(t:TaxID)',
       'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
       ifelse(
          !is.null(be),
          'WHERE SIZE(FILTER(x in labels(e) WHERE x IN $be)) > 0',
          ''
       ),
       ifelse(
          !is.null(organism),
          'MATCH (t)-[:is_named]->(on:OrganismName) WHERE on.value_up IN $org',
          ''
       ),
       'RETURN DISTINCT n.value as found',
       ', labels(e) as be, n.database as source',
       ', o.value as organism',
       ', id(e) as entity',
       ', labels(e) as ebe',
       ', id(g) as gene'
    )
    if(verbose) message(query)
    beids <- unique(bedCall(
        f=neo2R::cypher,
        query=query,
        parameters=parameters
    ))
    ##
    query <- neo2R::prepCql(
       'MATCH (n:BESymbol)',
       ifelse(
          nchar(searched)>=ncharSymb,
          'WHERE n.value_up CONTAINS $upSearched',
          'WHERE n.value_up = $upSearched'
       ),
       'MATCH (n)<-[ik:is_known_as]-(nii:BEID)',
       'MATCH (nii)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
       'MATCH (ni)-[:identifies]->(e)',
       'WITH DISTINCT n, ik, nii, ni, e',
       'MATCH (e)<-[cr:codes_for|is_expressed_as|is_translated_in*0..2]-(g:Gene)',
       ifelse(
          !is.null(be),
          # 'WHERE labels(e) IN $be',
          'WHERE SIZE(FILTER(x in labels(e) WHERE x IN $be)) > 0',
          ''
       ),
       'MATCH (g)-[:belongs_to]->(t:TaxID)',
       'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
       ifelse(
          !is.null(organism),
          'MATCH (t)-[:is_named]->(on:OrganismName) WHERE on.value_up IN $org',
          ''
       ),
       'RETURN DISTINCT n.value as found',
       ', labels(e) as be, "Symbol" as source',
       ', o.value as organism',
       ', id(e) as entity',
       ', labels(e) as ebe',
       ', id(g) as gene',
       ', ik.canonical as canonical'
    )
    if(verbose) message(query)
    besymbs <- unique(bedCall(
        f=neo2R::cypher,
        query=query,
        parameters=parameters
    ))
    ##
    query <-neo2R::prepCql(
       'MATCH (n:BEName)',
       ifelse(
          nchar(searched)>=ncharName,
          'WHERE n.value_up CONTAINS $upSearched',
          'WHERE n.value_up = $upSearched'
       ),
       'MATCH (n)<-[:is_named]-(nii:BEID)',
       'MATCH (nii)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
       'MATCH (ni)-[:identifies]->(e)',
       'WITH DISTINCT n, nii, ni, e',
       'MATCH (e)<-[cr:codes_for|is_expressed_as|is_translated_in*0..2]-(g:Gene)',
       ifelse(
          !is.null(be),
          # 'WHERE labels(e) IN $be',
          'WHERE SIZE(FILTER(x in labels(e) WHERE x IN $be)) > 0',
          ''
       ),
       'MATCH (g)-[:belongs_to]->(t:TaxID)',
       'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
       ifelse(
          !is.null(organism),
          'MATCH (t)-[:is_named]->(on:OrganismName) WHERE on.value_up IN $org',
          ''
       ),
       'RETURN DISTINCT n.value as found',
       ', labels(e) as be, "Name" as source',
       ', o.value as organism',
       ', id(e) as entity',
       ', labels(e) as ebe',
       ', id(g) as gene'
    )
    if(verbose) message(query)
    benames <- unique(bedCall(
        f=neo2R::cypher,
        query=query,
        parameters=parameters
    ))
    ##
    query <- neo2R::prepCql(
       'MATCH (n:ProbeID)',
       'WHERE n.value = $searched',
       'WITH DISTINCT n',
       'MATCH (n)-[:targets]->(nii:BEID)',
       'MATCH (nii)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
       'MATCH (ni)-[:identifies]->(e)',
       'WITH DISTINCT n, nii, ni, e',
       'MATCH (e)<-[cr:codes_for|is_expressed_as|is_translated_in*0..2]-(g:Gene)',
       'MATCH (g)-[:belongs_to]->(t:TaxID)',
       'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
       'RETURN DISTINCT n.value as found',
       ', "Probe" as be, n.platform as source',
       ', o.value as organism',
       ', id(e) as entity',
       ', labels(e) as ebe',
       ', id(g) as gene'
    )
    if(verbose) message(query)
    probes <- unique(bedCall(
        f=neo2R::cypher,
        query=query,
        parameters=parameters
    ))
    ##
    if(!is.null(beids)){
        beids$canonical <- rep(NA, nrow(beids))
    }
    if(!is.null(benames)){
        benames$canonical <- rep(NA, nrow(benames))
    }
    if(!is.null(probes)){
        probes$canonical <- rep(NA, nrow(probes))
    }
    toRet <- rbind(beids, besymbs, benames, probes)
    if(!is.null(toRet) && nrow(toRet)>0){
        gcol <- which(colnames(toRet)=="gene")
        toRet <- do.call(rbind, by(
            toRet,
            paste(
                toRet$found, toRet$be, toRet$source, toRet$organism,
                toRet$entity, toRet$ebe,
                sep="/./"
            ),
            function(x){
                x2 <- unique(x[,-gcol])
                x2$gene <- list(unique(x$gene))
                return(x2)
            }
        ))
        rownames(toRet) <- NULL
        toRet <- toRet[order(toRet$found),]
        toRet <- toRet[order(paste(toRet$organism, toRet$be)),]
        toRet <- toRet[order(nchar(toRet$found)),]
        toRet <- toRet[order(toRet$canonical, decreasing=TRUE),]
        toRet <- toRet[order(
            toupper(toRet$found)==toupper(as.character(searched)),
            decreasing=TRUE
        ),]
    }
    return(toRet)
}
