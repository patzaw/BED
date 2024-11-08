#' Feeding BED: Load correspondances between BE IDs
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the correspondances
#' to be loaded. It should contain the following fields: "id1" and "id2".
#' @param db1 the DB of id1
#' @param db2 the DB of id2
#' @param be a character corresponding to the BE type (default: "Gene")
#'
loadCorrespondsTo <- function(
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
    ## First record the corresponds edges before clustering BE
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
        sprintf(
           'USING INDEX beid1:%s(value)',
           beid
        ),
        sprintf(
            paste(
                'MATCH',
                '(beid2:%s',
                '{value: row.id2, database:"%s"})'
            ),
            beid, db2
        ),
        sprintf(
           'USING INDEX beid2:%s(value)',
           beid
        ),
        "MERGE (beid2)-[:corresponds_to]-(beid1)"
    )
    bedImport(cql, d)

    ################################################
    ## Clustering BE according to relationships
    odb1 <- db1
    odb2 <- db2
    rem <- d
    db1 <- odb1
    db2 <- odb2
    message(nrow(rem))
    while(nrow(rem) > 0){
        # rem <- d
        # db1 <- odb1
        # db2 <- odb2
        ##
        if(db1==db2){
            id <- unique(c(rem$id1, rem$id2))
            cql <- c(
                sprintf(
                    'MATCH (beid:%s)-[:identifies]->(be)',
                    beid
                ),
                'WHERE beid.database=$db',
                'AND beid.value IN $limitTo'
            )
            cql <- c(
                cql,
                'RETURN beid.value as id1, id(be) as be1'
            )
            qres <- bedCall(
                f=neo2R::cypher,
                query=neo2R::prepCql(cql),
                parameters=list(
                    db=db1,
                    limitTo=as.list(as.character(id))
                )
            )
            if(is.null(qres)){
                qres <- data.frame(id1=character(), be1=numeric())
            }
            colnames(qres) <- c("id1", "be1")
            rem <- dplyr::inner_join(rem, qres, by="id1")
            colnames(qres) <- c("id2", "be2")
            rem <- dplyr::inner_join(rem, qres, by="id2")
        }else{
            ##
            id <- unique(rem$id1)
            cql <- c(
                sprintf(
                    'MATCH (beid:%s)-[:identifies]->(be)',
                    beid
                ),
                'WHERE beid.database=$db',
                'AND beid.value IN $limitTo'

            )
            cql <- c(
                cql,
                'RETURN beid.value as id1, id(be) as be1'
            )
            qres <- bedCall(
                f=neo2R::cypher, query=neo2R::prepCql(cql),
                parameters=list(
                    db=db1,
                    limitTo=as.list(as.character(id))
                )
            )
            if(is.null(qres)){
                qres <- data.frame(id1=character(), be1=numeric())
            }
            colnames(qres) <- c("id1", "be1")
            rem <- dplyr::inner_join(rem, qres, by="id1")
            ##
            id <- unique(rem$id2)
            cql <- c(
                sprintf(
                    'MATCH (beid:%s)-[:identifies]->(be)',
                    beid
                ),
                'WHERE beid.database=$db',
                'AND beid.value IN $limitTo'

            )
            cql <- c(
                cql,
                'RETURN beid.value as id2, id(be) as be2'
            )
            qres <- bedCall(
                f=neo2R::cypher, query=neo2R::prepCql(cql),
                parameters=list(
                    db=db2,
                    limitTo=as.list(as.character(id))
                )
            )
            if(is.null(qres)){
                qres <- data.frame(id2=character(), be2=numeric())
            }
            colnames(qres) <- c("id2", "be2")
            rem <- dplyr::inner_join(rem, qres, by="id2")
        }
        ##
        ## Filter uninformative nodes
        rem <- rem[which(rem$be1!=rem$be2),]
        if(nrow(rem)==0){
           break()
        }
        rem <- rem[
            !duplicated(t(apply(
                rem[,c("be1", "be2")],
                1,
                sort
            ))),
        ]
        if(nrow(rem)==0){
            break()
        }
        rownames(rem) <- paste("r", 1:nrow(rem), sep=".")
        ## Take only compatible nodes for current treatment
        # if(sum(!duplicated(rem$be2)) > sum(!duplicated(rem$be1))){
        #     convCn <- c(
        #         "id1"="id2", "id2"="id1",
        #         "be1"="be2", "be2"="be1"
        #     )
        #     colnames(rem) <- convCn[colnames(rem)]
        #     db.tp <- db2
        #     db2 <- db1
        #     db1 <- db.tp
        # }
        ##
        #######
        # toI <- rem
        # toI <- toI[sample(1:nrow(toI), nrow(toI), replace=F),]
        # tt <- data.frame(
        #     id=c(toI$be1, toI$be2),
        #     r=c(1:nrow(toI), 1:nrow(toI))
        # )
        # tt <- tt[order(tt$r),]
        # tt <- tt[which(!duplicated(tt$id)),]
        # tt <- tt[which(duplicated(tt$r)),"r"]
        # toI2 <- toI[tt,]
        # toI2 <- toI2[which(!toI2$be1 %in% toI2$be2),]
        # toI <- toI2
        #######
        toI <- rem[!duplicated(rem$be1),]
        toI <- toI[sample(1:nrow(toI), nrow(toI), replace=F),]
        ##
        tt <- data.frame(
            id=c(toI$be1, toI$be2),
            r=c(1:nrow(toI), 1:nrow(toI))
        )
        tt <- tt[order(tt$r),]
        tt <- tt[which(!duplicated(tt$id)),]
        tt <- tt[which(duplicated(tt$r)),"r"]
        ##
        toI1 <- toI[which(!toI$be1 %in% toI$be2),]
        toI2 <- toI[tt,]
        toI2 <- toI2[which(!toI2$be1 %in% toI2$be2),]
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
        cql <- c(
            cqlId,
            sprintf(
                'MATCH (obeid1:%s)-[:identifies]->(be1)',
                beid
            ),
            'MERGE (obeid1)-[:identifies]->(be2)'
        )
        bedImport(cql, toI)
        ##
        if(be=="Gene"){
            cql <- c(
                cqlId,
                'MATCH (be1)-[:belongs_to]->(tid:TaxID)',
                'MERGE (be2)-[:belongs_to]->(tid)'
            )
            bedImport(cql, toI)
            cql <- c(
                cqlId,
                'MATCH (be1)-[:is_expressed_as]->(bet:Transcript)',
                'MERGE (be2)-[:is_expressed_as]->(bet)'
            )
            bedImport(cql, toI)
            cql <- c(
                cqlId,
                'MATCH (be1)-[:codes_for]->(beo:Object)',
                'MERGE (be2)-[:codes_for]->(beo)'
            )
            bedImport(cql, toI)
        }else if(be=="Object"){
            cql <- c(
                cqlId,
                'MATCH (beg:Gene)-[:codes_for]->(be1)',
                'MERGE (beg)-[:codes_for]->(be2)'
            )
            bedImport(cql, toI)
        }else if(be=="Transcript"){
            cql <- c(
                cqlId,
                'MATCH (beg:Gene)-[:is_expressed_as]->(be1)',
                'MERGE (beg)-[:is_expressed_as]->(be2)'
            )
            bedImport(cql, toI)
            cql <- c(
                cqlId,
                'MATCH (be1)-[:is_translated_in]->(bep:Peptide)',
                'MERGE (be2)-[:is_translated_in]->(bep)'
            )
            bedImport(cql, toI)
        }else if(be=="Peptide"){
            cql <- c(
                cqlId,
                'MATCH (bet:Transcript)-[:is_translated_in]->(be1)',
                'MERGE (bet)-[:is_translated_in]->(be2)'
            )
            bedImport(cql, toI)
        }else{
            stop("Check the loadCorresponds function for the BE: ", be)
        }
        ##
        cql <- c(
            cqlId,
            'MATCH (be1)-[rtodel]-()',
            'DELETE rtodel, be1'
        )
        bedImport(cql, toI)
        ##
        rem <- rem[setdiff(rownames(rem), rownames(toI)), c("id1", "id2")]
        message(nrow(rem))
    }
}
