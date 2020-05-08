#' Feeding BED: Load homology between BE IDs
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the homologies
#' to be loaded. It should contain the following fields: "id1" and "id2".
#' @param db1 the DB of id1
#' @param db2 the DB of id2
#' @param be a character corresponding to the BE type (default: "Gene")
#'
loadIsHomologOf <- function(
    d,
    db1, db2, be="Gene"
){

    beid <- paste0(be, "ID", sep="")
    befam <- paste0(be, "IDFamily", sep="")

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
    ## First record the "is_homolog_of" edges before clustering "Homologs" nodes
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
        'MERGE (beid2)-[:is_homolog_of]-(beid1)'
    )
    bedImport(cql, d)

    ##
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
          'MERGE (beid1)-[:is_member_of]->(:%s)',
          befam
       )
    )
    bedImport(cql, d)

    ##
    cql <- c(
       sprintf(
          paste(
             'MATCH',
             '(beid2:%s',
             '{value: row.id2, database:"%s"})'
          ),
          beid, db2
       ),
       sprintf('USING INDEX beid2:%s(value)', beid),
       sprintf(
          'MERGE (beid2)-[:is_member_of]->(:%s)',
          befam
       )
    )
    bedImport(cql, d)

    ################################################
    ## Clustering "Homologs" nodes according to relationships
    odb1 <- db1
    odb2 <- db2
    rem <- d
    db1 <- odb1
    db2 <- odb2
    message(nrow(rem))
    while(nrow(rem) > 0){
        ##
        if(db1==db2){
            id <- unique(c(rem$id1, rem$id2))
            cql <- c(
                sprintf(
                    'MATCH (beid:%s)-[:is_member_of]->(bef)',
                    beid
                ),
                'WHERE beid.database=$db',
                'AND beid.value IN $limitTo'
            )
            cql <- c(
                cql,
                'RETURN beid.value as id1, id(bef) as bef1'
            )
            qres <- bedCall(
                f=neo2R::cypher, neo2R::prepCql(cql),
                parameters=list(
                    db=db1,
                    limitTo=as.list(as.character(id))
                )
            )
            if(is.null(qres)){
                qres <- data.frame(id1=character(), bef1=numeric())
            }
            colnames(qres) <- c("id1", "bef1")
            rem <- dplyr::inner_join(rem, qres, by="id1")
            colnames(qres) <- c("id2", "bef2")
            rem <- dplyr::inner_join(rem, qres, by="id2")
        }else{
            ##
            id <- unique(rem$id1)
            cql <- c(
                sprintf(
                    'MATCH (beid:%s)-[:is_member_of]->(bef)',
                    beid
                ),
                'WHERE beid.database=$db',
                'AND beid.value IN $limitTo'
            )
            cql <- c(
                cql,
                'RETURN beid.value as id1, id(bef) as bef1'
            )
            qres <- bedCall(
                f=neo2R::cypher, neo2R::prepCql(cql),
                parameters=list(
                    db=db1,
                    limitTo=as.list(as.character(id))
                )
            )
            if(is.null(qres)){
                qres <- data.frame(id1=character(), bef1=numeric())
            }
            colnames(qres) <- c("id1", "bef1")
            rem <- dplyr::inner_join(rem, qres, by="id1")
            ##
            id <- unique(rem$id2)
            cql <- c(
                sprintf(
                    'MATCH (beid:%s)-[:is_member_of]->(bef)',
                    beid
                ),
                'WHERE beid.database=$db',
                'AND beid.value IN $limitTo'
            )
            cql <- c(
                cql,
                'RETURN beid.value as id2, id(bef) as bef2'
            )
            qres <- bedCall(
                f=neo2R::cypher, neo2R::prepCql(cql),
                parameters=list(
                    db=db2,
                    limitTo=as.list(as.character(id))
                )
            )
            if(is.null(qres)){
                qres <- data.frame(id2=character(), bef2=numeric())
            }
            colnames(qres) <- c("id2", "bef2")
            rem <- dplyr::inner_join(rem, qres, by="id2")
        }
        ##
        ## Filter uninformative nodes
        rem <- rem[which(rem$bef1!=rem$bef2),]
        rem <- rem[
            !duplicated(t(apply(
                rem[,c("bef1", "bef2")],
                1,
                sort
            ))),
        ]
        if(nrow(rem)==0){
            break()
        }
        rownames(rem) <- paste("r", 1:nrow(rem), sep=".")
        #######
        toI <- rem[!duplicated(rem$bef1),]
        toI <- toI[sample(1:nrow(toI), nrow(toI), replace=F),]
        ##
        tt <- data.frame(
            id=c(toI$bef1, toI$bef2),
            r=c(1:nrow(toI), 1:nrow(toI))
        )
        tt <- tt[order(tt$r),]
        tt <- tt[which(!duplicated(tt$id)),]
        tt <- tt[which(duplicated(tt$r)),"r"]
        ##
        toI1 <- toI[which(!toI$bef1 %in% toI$bef2),]
        toI2 <- toI[tt,]
        toI2 <- toI2[which(!toI2$bef1 %in% toI2$bef2),]
        if(nrow(toI2)>nrow(toI1)){
            toI <- toI2
        }else{
            toI <- toI1
        }
        #######
        ##
        if(nrow(toI)==0){
            toI <- rem[1,]
        }
        toI <- toI[,c("id1", "id2")]
        ##
        cqlId <- c(
            sprintf(
                paste(
                    'MATCH',
                    '(beid1:%s',
                    '{value: row.id1, database:"%s"}',
                    ')',
                    '-[:is_member_of]->(bef1:%s)'
                ),
                beid, db1, befam
            ),
            sprintf('USING INDEX beid1:%s(value)', beid),
            sprintf(
                paste(
                    'MATCH',
                    '(beid2:%s',
                    '{value: row.id2, database:"%s"})',
                    '-[:is_member_of]->(bef2:%s)'
                ),
                beid, db2, befam
            ),
            sprintf('USING INDEX beid2:%s(value)', beid),
            'WITH bef1, bef2 WHERE bef1<>bef2'
        )
        ##
        cql <- c(
            cqlId,
            sprintf(
                'MATCH (obeid1:%s)-[:is_member_of]->(bef1)',
                beid
            ),
            'MERGE (obeid1)-[:is_member_of]->(bef2)'
        )
        bedImport(cql, toI)
        ##
        cql <- c(
            cqlId,
            'MATCH (bef1)-[rtodel]-()',
            'DELETE rtodel, bef1'
        )
        bedImport(cql, toI)
        ##
        rem <- rem[setdiff(rownames(rem), rownames(toI)), c("id1", "id2")]
        message(nrow(rem))
    }
}
