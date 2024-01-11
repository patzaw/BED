#' Feeding BED: Load in BED objects from Clarivate Analytics
#' (formerly Thomson-Reuters) MetaBase
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param orgOfInt organims to be taken into account
#' (e.g. c("Homo sapiens", "Mus musculus", "Rattus norvegicus"))
#' @param tkmb an [MDB] object
#'
loadMBObjects_fromTKCat <- function(orgOfInt, tkmb){

    ################################################
    message(Sys.time(), " --> Dumping MetaBase tables")
    odbname <- "MetaBase_object"
    gdbname <- "MetaBase_gene"

    genes <- tkmb$MetaBase_Genes
    genOrg <- tkmb$MetaBase_GenesOrganisms
    organisms<- tkmb$MetaBase_Organisms
    geneDbs <- tkmb$MetaBase_GenesEntrez
    genecodes <- tkmb$MetaBase_GenesCodes
    objects <- tkmb$MetaBase_Objects
    geneObj <- tkmb$MetaBase_GenesObjects

    ################################################
    ## Add objects
    message(Sys.time(), " --> Importing objects")
    toImport <- objects[which(objects$id %in% geneObj$object_id), "id", drop=F]
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
    toImport <- objects[which(objects$id %in% geneObj$object_id), c("id", "name")]
    # colnames(toImport) <- c("id", "name")
    # if(any(table(toImport$name)>4)){
    #     stop("Verify gene names for NA or blank values")
    # }
    # loadBENames(d=toImport, be="Object", dbname=odbname)
    colnames(toImport) <- c("id", "symbol")
    toImport <- dplyr::filter(toImport, !is.na(symbol) & symbol!="")
    # if(any(table(toImport$symbol)>4)){
    #     stop("Verify object symbol for NA or blank values")
    # }
    toImport$canonical <- TRUE
    BED:::loadBESymbols(d=toImport, be="Object", dbname=odbname)

    ################################################
    taxOfInt <- unlist(lapply(orgOfInt, getTaxId))
    for(taxId in taxOfInt){
        message(taxId)
        ## Loading genes
        message(Sys.time(), " --> Importing genes")
        orgId <- organisms$id[which(organisms$taxonomy_id==taxId)]
        takenGenes <- genes[
            which(
                genes$id %in% genOrg$gene_id[which(genOrg$org_id==orgId)]
            ),
            ]
        toImport <- unique(takenGenes[, "id", drop=F])
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
            which(geneDbs$gene_id %in% takenGenes$id),
            c("entrez_id"),
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
            which(geneDbs$gene_id %in% takenGenes$id),
            c("entrez_id", "gene_id"),
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
        gSymb <- takenGenes %>%
            select(id, code) %>%
            mutate(canonical=TRUE)
        colnames(gSymb) <- c("id", "symbol", "canonical")
        gSyn <- genecodes %>%
            select(gene_id, code) %>%
            filter(gene_id %in% takenGenes$id) %>%
            mutate(canonical=FALSE)
        colnames(gSyn) <- c("id", "symbol", "canonical")
        toImport <- unique(rbind(gSymb, gSyn))
        toImport <- toImport[which(!duplicated(toImport[,c("id", "symbol")])),]
        toImport <- dplyr::filter(toImport, !is.na(symbol) & symbol!="")
        # if(any(table(toImport$symbol)>14)){
        #     stop("Verify gene symbols for NA or blank values")
        # }
        BED:::loadBESymbols(d=toImport, be="Gene", dbname=gdbname)

        ################################################
        ## Add gene names
        message(Sys.time(), " --> Importing gene names")
        toImport <- takenGenes[, c("id", "name")]
        colnames(toImport) <- c("id", "name")
        toImport <- dplyr::filter(toImport, !is.na(name) & name!="")
        # if(any(table(toImport$name)>22)){
        #     stop("Verify gene names for NA or blank values")
        # }
        BED:::loadBENames(d=toImport, be="Gene", dbname=gdbname)

        ################################################
        ## Add "codes_for" edges
        toImport <- geneObj[
            which(geneObj$gene_id %in% takenGenes$id),
            c("gene_id", "object_id")
        ]
        colnames(toImport) <- c("gid", "oid")
        BED:::loadCodesFor(
            d=toImport,
            gdb=gdbname,
            odb=odbname
        )
    }

}
