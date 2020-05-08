#' Guess biological entity (BE), database source and organism of a vector
#' of identifiers.
#'
#' @param ids a character vector of identifiers
#' @param be one BE or "Probe". **Guessed if not provided**
#' @param source the BE ID database or "Symbol" if BE or
#' the probe platform if Probe. **Guessed if not provided**
#' @param organism organism name. **Guessed if not provided**
#' @param tcLim number of identifiers to check to guess origin for the whole set.
#' Inf ==> no limit.
#'
#' @return A list (NULL if no match):
#'
#'  - **be**: a character vector of length 1 providing the best BE guess
#'  (NA if inconsistent with user input: be, source or organism)
#'  - **source**: a character vector of length 1 providing the best source
#'  guess (NA if inconsistent with user input: be, source or organism)
#'  - **organism*$: a character vector of length 1 providing the best organism
#'  guess (NA if inconsistent with user input: be, source or organism)
#'
#' The "details" attribute (`attr(x, "details")``) is a data frame providing
#' numbers supporting the guess
#'
#' @examples \dontrun{
#' guessIdScope(ids=c("10", "100"))
#' }
#'
#' @export
#'
guessIdScope <- function(ids, be, source, organism, tcLim=100){
    ##
    tcLim <- as.numeric(tcLim)
    if(!is.atomic(tcLim) || length(tcLim)!=1 || is.na(tcLim) || tcLim <= 0){
        stop("tcLim should be a positive numeric value")
    }
    ids <- unique(ids)
    if(length(ids) > tcLim){
        toCheck <- sample(x=ids, size=tcLim, replace=F)
    }else{
        toCheck <- ids
    }
    parameters <- list(ids=as.list(as.character(toCheck)))
    parameters.symb <- list(ids=as.list(toupper(as.character(toCheck))))
    ##
    beids <- bedCall(
        f=neo2R::cypher,
        query=neo2R::prepCql(
            'MATCH (n:BEID) WHERE n.value IN $ids',
            'MATCH (n)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
            'MATCH (ni)-[:identifies]->(e)',
            'WITH DISTINCT n, ni, e',
            'MATCH (e)<-[cr:codes_for|is_expressed_as|is_translated_in*0..2]-(g:Gene)',
            'MATCH (g)-[:belongs_to]->(t:TaxID)',
            'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
            # 'AND NOT "identifies" IN extract(r IN cr |type(r))',
            # Line above not necessary thanks to the data model.
            'RETURN labels(e) as be, n.database as source',
            ', o.value as organism, count(DISTINCT n.value) as nb',
            'ORDER BY nb DESC'
        ),
        parameters=parameters
    )
    ##
    besymbs <- bedCall(
        f=neo2R::cypher,
        query=neo2R::prepCql(
            'MATCH (n:BESymbol)',
            'WHERE n.value_up IN $ids',
            ##
            # The line below uses lucene index in order to allow fulltext
            # searches including case insensitive searches! LEGACY !!
            # sprintf(
            #     'START n=node:node_auto_index(\'value:("%s")\')',
            #     paste(toCheck, collapse='" "')
            # ),
            # 'WHERE "BESymbol" IN labels(n)',
            # 'WITH n',
            ##
            'MATCH (n)<-[:is_known_as]-(nii:BEID)',
            'MATCH (nii)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
            'MATCH (ni)-[:identifies]->(e)',
            'WITH DISTINCT n, nii, ni, e',
            'MATCH (e)<-[cr:codes_for|is_expressed_as|is_translated_in*0..2]-(g:Gene)',
            'MATCH (g)-[:belongs_to]->(t:TaxID)',
            'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
            'RETURN labels(e) as be, "Symbol" as source',
            ', o.value as organism, count(DISTINCT n.value) as nb',
            'ORDER BY nb DESC'
        ),
        parameters=parameters.symb
    )
    ##
    probes <- bedCall(
        f=neo2R::cypher,
        query=neo2R::prepCql(
            'MATCH (n:ProbeID)',
            'WHERE n.value IN $ids',
            'WITH DISTINCT n',
            'MATCH (n)-[:targets]->(nii:BEID)',
            'MATCH (nii)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
            'MATCH (ni)-[:identifies]->(e)',
            'WITH DISTINCT n, nii, ni, e',
            'MATCH (e)<-[cr:codes_for|is_expressed_as|is_translated_in*0..2]-(g:Gene)',
            'MATCH (g)-[:belongs_to]->(t:TaxID)',
            'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
            'RETURN "Probe" as be, n.platform as source',
            ', o.value as organism, count(distinct n.value) as nb',
            'ORDER BY nb DESC'
        ),
        parameters=parameters
    )
    ##
    toRetDetails <- rbind(beids, besymbs, probes)
    if(!is.null(toRetDetails)){
        toRetDetails <- toRetDetails[order(toRetDetails$nb, decreasing=T),]
        toRetDetails$proportion <- toRetDetails$nb/length(toCheck)
    }else{
        return(NULL)
    }
    ## Select scope according to user input
    sel <- 1:nrow(toRetDetails)
    if(!missing(be)){
        be <- match.arg(be, c(listBe(), "Probe"))
        sel <- intersect(sel, which(toRetDetails$be==be))
    }
    if(!missing(source)){
        stopifnot(is.character(source), length(source)==1, !is.na(source))
        sel <- intersect(sel, which(toRetDetails$source==source))
    }
    if(!missing(organism)){
        stopifnot(
            is.character(organism), length(organism)==1, !is.na(organism)
        )
        tid <- getTaxId(organism)
        if(length(tid)!=1){
            stop(sprintf("Could find %s organism in BED", organism))
        }
        sn <- getOrgNames(tid)
        sn <- sn$name[which(sn$nameClass=="scientific name")]
        sel <- intersect(sel, which(toRetDetails$organism==sn))
    }
    sel <- sel[1]
    ##
    toRet <- list(
        "be"=toRetDetails[sel, "be"],
        "source"=toRetDetails[sel, "source"],
        "organism"=toRetDetails[sel, "organism"]
    )
    attr(x=toRet, which="details") <- toRetDetails
    return(toRet)
}


#' @describeIn guessIdScope
#'
#' Deprecated version of guessIdScope
#'
#' @param ... params for `guessIdScope`
#'
#' @export
guessIdOrigin <- function(...){
    warning("Deprecated. Use guessIdScope instead")
    guessIdScope(...)
}

