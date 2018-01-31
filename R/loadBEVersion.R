#' Feeding BED: Load biological entities in BED with information about
#' DB version
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the entities to be loaded.
#' It should contain the following fields: "id", "version" and "deprecated".
#' @param be a character corresponding to the BE type (default: "Gene")
#' @param dbname the DB from which the BE ID are taken
#' @param taxId the taxonomy ID of the BE organism
#' @param onlyId a logical. If TRUE, only an BEID is created and not the
#' corresponding BE.
#'
loadBEVersion <- function(
    d, be="Gene", dbname,
    taxId=NA,
    onlyId=FALSE
){

    beid <- paste0(be, "ID")

    ##
    dColNames <- c("id", "version", "deprecated")
    if(any(!dColNames %in% colnames(d))){
        stop(paste(
            "The following columns are missing:",
            paste(setdiff(dColNames, colnames(d)), collapse=", ")
        ))
    }

    ##
    prefInfo <- "preferred" %in% colnames(d)
    if(prefInfo){
       toImport <- unique(d[, c("id", "version", "deprecated", "preferred"), drop=F])
       if(!inherits(d$preferred, "logical") || any(is.na(d$preferred))){
          stop("preferred column should be logical values without any NA")
       }
       if(length(unique(d$id)) != nrow(d)){
          stop("Each id should have only one preferred value")
       }
    }else{
       toImport <- unique(d[, c("id", "version", "deprecated"), drop=F])
    }

    ################################################
    ## Add IDs

    if(prefInfo){
       prefStr <- '(case row.preferred when "TRUE" then true else false end)'
       cql <- sprintf(
          'MERGE (beid:BEID:%s {value: row.id, database: "%s"}) SET beid.preferred=%s',
          beid, dbname, prefStr
       )
    }else{
       cql <- sprintf(
          'MERGE (beid:BEID:%s {value: row.id, database: "%s"}) ON CREATE SET beid.preferred=false',
          beid, dbname
       )
    }
    withStr <- 'WITH row.version as rversion, row.deprecated as rdepr, beid'
    if(!onlyId){
        cql <- c(
            cql,
            sprintf(
                '-[:identifies]->(be:%s)',
                be
            )
        )
        withStr <- paste0(withStr, ', be')
    }

    #########################
    ## Database and organism
    dbcql <- sprintf(
        '(db:BEDB{name: "%s"})',
        dbname
    )
    cql <- c(
        cql, withStr,
        'MERGE', dbcql,
        'CREATE UNIQUE (beid)',
        '-[:is_recorded_in {version:rversion, deprecated:rdepr}]->',
        '(db)'
    )
    if(!is.na(taxId)){
        orgcql <- sprintf(
            '(o:TaxID {value:"%s"})',
            taxId
        )
        cql <- c(
            cql, withStr,
            'MERGE', orgcql,
            'CREATE UNIQUE (be)-[:belongs_to]->(o)'
        )
    }

    #########################
    # message(cql)
    bedImport(cql, toImport)

}
