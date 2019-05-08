#' Feeding BED: Load BE ID associations
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' When associating one id1 to id2, the BE identified by id1
#' is deleted after that its production edges have been transferred
#' to the BE identified by id2.
#' After this operation all id "corresponding_to" id1  do not
#' directly identify any BE as they are supposed to do. Thus,
#' to run this function with id1 involved in "corresponds_to" edges.
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

    ################################################
    ## Record the is_associated_to edges
    cqlId <- c(
        sprintf(
            paste(
                'MATCH',
                '(beid1:%s',
                '{value: row.id1, database:"%s"}',
                ')',
                '-[:identifies]->(be1:%s)'
            ),
            beid, db1, be
        ),
        sprintf(
            'USING INDEX beid1:%s(value)',
            beid
        ),
        sprintf(
            paste(
                'MATCH',
                '(beid2:%s',
                '{value: row.id2, database:"%s"})',
                '-[:identifies]->(be2:%s)'
            ),
            beid, db2, be
        ),
        sprintf(
            'USING INDEX beid2:%s(value)',
            beid
        ),
        'WITH be1, be2 WHERE be1<>be2'
    )
    ##
    if(be=="Gene"){
        cql <- c(
            cqlId,
            'MATCH (be1)-[:belongs_to]->(tid:TaxID)',
            'MERGE (be2)-[:belongs_to]->(tid)'
        )
        bedImport(cql, d)
        cql <- c(
            cqlId,
            'MATCH (be1)-[:is_expressed_as]->(bet:Transcript)',
            'MERGE (be2)-[:is_expressed_as]->(bet)'
        )
        bedImport(cql, d)
        cql <- c(
            cqlId,
            'MATCH (be1)-[:codes_for]->(beo:Object)',
            'MERGE (be2)-[:codes_for]->(beo)'
        )
        bedImport(cql, d)
    }else if(be=="Object"){
        cql <- c(
            cqlId,
            'MATCH (beg:Gene)-[:codes_for]->(be1)',
            'MERGE (beg)-[:codes_for]->(be2)'
        )
        bedImport(cql, d)
    }else if(be=="Transcript"){
        cql <- c(
            cqlId,
            'MATCH (beg:Gene)-[:is_expressed_as]->(be1)',
            'MERGE (beg)-[:is_expressed_as]->(be2)'
        )
        bedImport(cql, d)
        cql <- c(
            cqlId,
            'MATCH (be1)-[:is_translated_in]->(bep:Peptide)',
            'MERGE (be2)-[:is_translated_in]->(bep)'
        )
        bedImport(cql, d)
    }else if(be=="Peptide"){
        cql <- c(
            cqlId,
            'MATCH (bet:Transcript)-[:is_translated_in]->(be1)',
            'MERGE (bet)-[:is_translated_in]->(be2)'
        )
        bedImport(cql, d)
    }else{
        stop("Check the loadCorresponds function for the BE: ", be)
    }
    ##
    cql <- c(
        cqlId,
        'MATCH (be1)-[rtodel]-()',
        'DELETE rtodel, be1'
    )
    bedImport(cql, d)

}
