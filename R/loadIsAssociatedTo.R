#' Feeding BED: Load BE ID associations
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the associations
#' to be loaded. It should contain the following fields: "id1" and "id2".
#' At the end id1 is associated to id2 (this way and not the other).
#' @param db1 the DB of id1
#' @param db2 the DB of id2
#' @param be a character corresponding to the BE type (default: "Gene")
#'
loadIsAssociatedTo <- function(
    d,
    db1, db2,
    be="Gene"
){

    beid <- paste0(be, "ID", sep="")

    ##
    dColNames <- c("id1", "id2")
    if(any(!dColNames %in% colnames(d))){
        stop(paste(
            "The following columns are missing:",
            paste(setdiff(dColNames, colnames(d)), collapse=", ")
        ))
    }

    ################################################
    if(db1==db2){
        toKeep <- which(d$id1 != d$id2)
        undirRel <- apply(
            d, 1,
            function(x) paste(sort(x), collapse=".")
        )
        toKeep <- intersect(toKeep, which(!duplicated(undirRel)))
        d <- d[toKeep,]
    }

    ################################################
    ## Record the is_associated_to edges
    cql <- c(
        sprintf(
            paste(
                'MATCH',
                '(beid1:%s',
                '{value: row.id1, database:"%s"}',
                ')'
            ),
            beid, db1
        ),
        sprintf('USING INDEX beid1:%s(value)', beid),
        sprintf(
            paste(
                'MATCH',
                '(beid2:%s',
                '{value: row.id2, database:"%s"})'
            ),
            beid, db2
        ),
        sprintf('USING INDEX beid2:%s(value)', beid),
        "MERGE (beid1)-[:is_associated_to]->(beid2)"
    )
    bedImport(cql, d)

}
