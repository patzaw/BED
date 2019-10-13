#' Guess biological entity (BE), database source and organism of a vector
#' of identifiers.
#'
#' @param ids a character vector of identifiers
#' @param tcLim number of identifiers to check to guess origin for the whole set.
#' Inf ==> no limit.
#'
#' @return a list: \itemize{
#'  \item{be: a character vector of length 1 providing the best BE guess}
#'  \item{source: a character vector of length 1 providing the best source guess}
#'  \item{organism: a character vector of length 1 providing the best organism guess}
#' }
#' "details" attribute (\code{attr(x, "details")}) is a data frame providing numbers
#' supporting the guess
#'
#' @examples \dontrun{
#' guessIdOrigin(ids=c("10", "100"))
#' }
#'
#' @importFrom neo2R prepCql cypher
#' @export
#'
guessIdOrigin <- function(ids, tcLim=100){
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
        f=cypher,
        query=prepCql(
            'MATCH (n:BEID) WHERE n.value IN $ids',
            'MATCH (n)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
            'MATCH (ni)-[:identifies]->(e)',
            'WITH DISTINCT n, ni, e',
            'MATCH (e)<-[cr*0..10]-(g:Gene)',
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
        f=cypher,
        query=prepCql(
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
            'MATCH (e)<-[cr*0..10]-(g:Gene)',
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
        f=cypher,
        query=prepCql(
            'MATCH (n:ProbeID)',
            'WHERE n.value IN $ids',
            'WITH DISTINCT n',
            'MATCH (n)-[:targets]->(nii:BEID)',
            'MATCH (nii)-[:is_replaced_by|is_associated_to*0..]->(ni:BEID)',
            'MATCH (ni)-[:identifies]->(e)',
            'WITH DISTINCT n, nii, ni, e',
            'MATCH (e)<-[cr*0..10]-(g:Gene)',
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
    }
    toRet <- list(
        "be"=toRetDetails[1, "be"],
        "source"=toRetDetails[1, "source"],
        "organism"=toRetDetails[1, "organism"]
    )
    attr(x=toRet, which="details") <- toRetDetails
    return(toRet)
}
