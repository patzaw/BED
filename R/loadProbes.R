#' Feeding BED: Load probes targeting BE IDs
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the entities to be loaded.
#' It should contain the following fields: "id" and "probeID".
#' @param be a character corresponding to the BE
#' targeted by the probes (default: "Transcript")
#' @param platform the plateform gathering the probes
#' @param dbname the DB from which the BE ID are taken
#'
loadProbes <- function(
    d,
    be="Transcript",
    platform,
    dbname
){

    beid <- paste0(be, "ID")

    ##
    dColNames <- c("id", "probeID")
    if(any(!dColNames %in% colnames(d))){
        stop(paste(
            "The following columns are missing:",
            paste(setdiff(dColNames, colnames(d)), collapse=", ")
        ))
    }

    ##
    toLoad <- unique(d[, "probeID", drop=F])
    cql <- c(
        sprintf(
            'MATCH (pl:Platform {name:"%s"})',
            platform
        ),
        sprintf(
            'MERGE (pid:ProbeID {value:row.probeID, platform: "%s"})',
            platform
        )
    )
    bedImport(cql, toLoad)

    cql <- c(
       sprintf(
          'MATCH (pl:Platform {name:"%s"})',
          platform
       ),
       sprintf(
          'MATCH (pid:ProbeID {value:row.probeID, platform: "%s"})',
          platform
       ),
       'USING INDEX pid:ProbeID(value)',
       'MERGE (pid)-[:is_in]->(pl)'
    )
    bedImport(cql, toLoad)

    ##
    cql <- c(
        sprintf(
            'MATCH (pid:ProbeID {value:row.probeID, platform: "%s"})',
            platform
        ),
        'USING INDEX pid:ProbeID(value)',
        sprintf(
            'MATCH (beid:%s {value:row.id, database: "%s"})',
            beid, dbname
        ),
        sprintf('USING INDEX beid:%s(value)', beid),
        'MERGE (pid)-[:targets]->(beid)'
    )
    bedImport(cql, d)

}
