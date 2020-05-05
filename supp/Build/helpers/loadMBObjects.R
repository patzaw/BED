#' Feeding BED: Load in BED objects from Clarivate Analytics
#' (formerly Thomson-Reuters) MetaBase
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param orgOfInt organims to be taken into account
#' (e.g. c("Homo sapiens", "Mus musculus", "Rattus norvegicus"))
#'
loadMBObjects <- function(orgOfInt){

    ################################################
    message(Sys.time(), " --> Dumping MetaBase tables")
    odbname <- "MetaBase_object"
    gdbname <- "MetaBase_gene"
    if(!metabaser::metabase.alive(verbose=T)){
        stop("Not connected to metabase")
    }
    genes <- metabaser::mbquery("select * from genes")
    genOrg <- metabaser::mbquery("select * from geneorgs")
    organisms <- metabaser::mbquery("select * from orgs")
    databases <- metabaser::mbquery("select * from lst_extdbs")
    geneDbs <- metabaser::mbquery(sprintf(
        "select * from genedbs where db=%s",
        databases$ID[which(databases$DSCR=="Entrez Gene")]
    ))
    genecodes <- metabaser::mbquery("select * from genecods")
    objects <- metabaser::mbquery("select * from regulation_objects")
    geneObj <- metabaser::mbquery("select * from gene_netw")

    ################################################
    ## Add objects
    message(Sys.time(), " --> Importing objects")
    toImport <- objects[which(objects$ID %in% geneObj$ID), "ID", drop=F]
    colnames(toImport) <- "id"
    BED:::loadBE(
        d=toImport, be="Object",
        dbname=odbname,
        version=NA,
        taxId=NA
    )

    ################################################
    ## Add object names as symbols
    message(Sys.time(), " --> Importing objects names as symbols")
    toImport <- objects[which(objects$ID %in% geneObj$ID), c("ID", "NAME")]
    # colnames(toImport) <- c("id", "name")
    # if(any(table(toImport$name)>4)){
    #     stop("Verify gene names for NA or blank values")
    # }
    # loadBENames(d=toImport, be="Object", dbname=odbname)
    colnames(toImport) <- c("id", "symbol")
    if(any(table(toImport$symbol)>4)){
        stop("Verify object symbol for NA or blank values")
    }
    toImport$canonical <- TRUE
    BED:::loadBESymbols(d=toImport, be="Object", dbname=odbname)

    ################################################
    taxOfInt <- unlist(lapply(orgOfInt, getTaxId))
    for(taxId in taxOfInt){
        message(taxId)
        ## Loading genes
        message(Sys.time(), " --> Importing genes")
        orgId <- organisms$ORGID[which(organisms$TAXONOMYID==taxId)]
        takenGenes <- genes[
            which(
                genes$GENEID %in% genOrg$GENE[which(genOrg$ORG==orgId)]
            ),
            ]
        toImport <- unique(takenGenes[, "GENEID", drop=F])
        colnames(toImport) <- "id"
        BED:::loadBE(
            d=toImport, be="Gene",
            dbname=gdbname,
            version=NA,
            # taxId=taxId,
            taxId=NA,
            onlyId=TRUE
        )

        ## Entrez cross-references
        message(Sys.time(), " --> Importing Entrez cross-references")
        db <- "EntrezGene"
        toImport <- unique(geneDbs[
            which(geneDbs$GENE %in% takenGenes$GENEID),
            c("REF"),
            drop=F
        ])
        colnames(toImport) <- "id"
        BED:::loadBE(
            d=toImport, be="Gene",
            dbname=db,
            taxId=NA,
            onlyId=TRUE
        )
        toImport <- unique(geneDbs[
            which(geneDbs$GENE %in% takenGenes$GENEID),
            c("REF", "GENE"),
            drop=F
        ])
        colnames(toImport) <- c("id2", "id1")
        BED:::loadIsAssociatedTo(
            d=toImport,
            db2=db,
            db1=gdbname,
            be="Gene"
        )

        ################################################
        ## Add symbols
        message(Sys.time(), " --> Importing gene symbols")
        gSymb <- data.frame(
            takenGenes[,c("GENEID", "CODE")],
            canonical=TRUE,
            stringsAsFactors=F
        )
        colnames(gSymb) <- c("id", "symbol", "canonical")
        gSyn <- data.frame(
            genecodes[
                which(genecodes$GENE %in% takenGenes$GENEID),
                c("GENE", "CODE")
                ],
            canonical=FALSE,
            stringsAsFactors=F
        )
        colnames(gSyn) <- c("id", "symbol", "canonical")
        toImport <- unique(rbind(gSymb, gSyn))
        toImport <- toImport[which(!duplicated(toImport[,c("id", "symbol")])),]
        if(any(table(toImport$symbol)>14)){
            stop("Verify gene symbols for NA or blank values")
        }
        BED:::loadBESymbols(d=toImport, be="Gene", dbname=gdbname)

        ################################################
        ## Add gene names
        message(Sys.time(), " --> Importing gene names")
        toImport <- takenGenes[, c("GENEID", "GNAME")]
        colnames(toImport) <- c("id", "name")
        if(any(table(toImport$name)>22)){
            stop("Verify gene names for NA or blank values")
        }
        BED:::loadBENames(d=toImport, be="Gene", dbname=gdbname)

        ################################################
        ## Add "codes_for" edges
        toImport <- geneObj[
            which(geneObj$GENE %in% takenGenes$GENEID),
            c("GENE", "ID")
        ]
        colnames(toImport) <- c("gid", "oid")
        BED:::loadCodesFor(
            d=toImport,
            gdb=gdbname,
            odb=odbname
        )
    }

}
