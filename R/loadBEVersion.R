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
       cql <- c(
          sprintf(
             'MERGE (beid:%s:BEID {value: row.id, database: "%s"})',
             beid, dbname
          ),
          sprintf(
             'ON CREATE SET beid.preferred=%s',
             prefStr
          ),
          sprintf(
             'ON MATCH SET beid.preferred=%s',
             prefStr
          )
       )
    }else{
       cql <- c(
          sprintf(
             'MERGE (beid:%s:BEID {value: row.id, database: "%s"})',
             beid, dbname
          ),
          'ON CREATE SET beid.preferred=false'
       )
    }
    ##
    bedImport(cql, toImport)

    if(!onlyId){
       cql <- c(
          sprintf(
             'MATCH (beid:%s {value: row.id, database: "%s"})',
             beid, dbname
          ),
          sprintf(
             'USING INDEX beid:%s(value)',
             beid
          ),
          sprintf(
             'MERGE (beid)-[:identifies]->(be:%s)',
             be
          )
       )
       ##
       bedImport(cql, toImport)
    }

    #########################
    ## Database and organism
    dbcql <- sprintf(
        '(db:BEDB{name: "%s"})',
        dbname
    )
    cql <- c('MERGE', dbcql)
    ##
    bedCall(neo2R::cypher, neo2R::prepCql(cql))

    cql <- c(
       sprintf(
          'MATCH (beid:%s {value: row.id, database: "%s"})',
          beid, dbname
       ),
       sprintf(
          'USING INDEX beid:%s(value)',
          beid
       ),
       'MATCH', dbcql,
       'MERGE (beid)',
       '-[:is_recorded_in {version:row.version, deprecated:row.deprecated}]->',
       '(db)'
    )
    ##
    bedImport(cql, toImport)

    if(!is.na(taxId)){
       orgcql <- sprintf(
          '(o:TaxID {value:"%s"})',
          taxId
       )
       cql <- c('MERGE', orgcql)
       ##
       bedCall(neo2R::cypher, neo2R::prepCql(cql))

       if(be=="Gene"){
          cql <- c(
             sprintf(
                'MATCH (beid:%s {value: row.id, database: "%s"})',
                beid, dbname
             ),
             sprintf(
                'USING INDEX beid:%s(value)',
                beid
             ),
             'MATCH (beid)-[:identifies]->(be)',
             'MATCH', orgcql,
             'MERGE (be)-[:belongs_to]->(o)'
          )
       }
       ##
       bedImport(cql, toImport)

    }

    #########################
    # message(cql)
    bedImport(cql, toImport)

}
