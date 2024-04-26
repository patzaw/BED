#' Feeding BED: Download Uniprot information in BED
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param organism character vector of 1 element corresponding to the organism
#' of interest (e.g. "Homo sapiens")
#' @param taxDiv the taxonomic division to which the organism belong
#' (e.g., "human", "rodents", "mammals", "vertebrates")
#' @param release the release of interest (check if already downloaded)
#' @param ddir path to the directory where the data should be saved
#'
getUniprot <- function(
    organism,
    taxDiv,
    release,
    ddir
){
    ################################################@
    ## Organism ----
    taxId <- getTaxId(organism)

    ################################################@
    ## Dump ----
    gene_info <- NULL
    dumpUniprotDb(
        taxOfInt=taxId,
        divOfInt=taxDiv,
        release=release,
        ddir=ddir
    )

    ################################################@
    ## Organism focus ----
    uids <- uids[which(uids$tax==taxId),]
    deprecated <- deprecated[which(deprecated$ID %in% uids$ID),]
    rsCref <- rsCref[which(rsCref$ID %in% uids$ID),]
    ensCref <- ensCref[which(ensCref$ID %in% uids$ID),]

    ################################################@
    ## DB information ----
    pdbname <- "Uniprot"

    ################################################@
    ## Uniprot IDs ----
    message(Sys.time(), " --> Importing Uniprot IDs")
    toImport <- unique(uids[, c("ID", "status"), drop=F])
    colnames(toImport) <- c("id", "value")
    toImport$preferred <- toImport$value=="Reviewed"
    loadBE(
        d=toImport, be="Peptide",
        dbname=pdbname,
        version=release,
        taxId=NA
    )
    message("      Importing attribute")
    toImport <- toImport[,c("id", "value")]
    loadBeAttribute(
       d=toImport, be="Peptide",
       dbname=pdbname,
       attribute="status"
    )

    ################################################@
    ## Add symbols ----
    message(Sys.time(), " --> Importing Uniprot symbols")
    toImport <- data.frame(
        uids[,c("ID", "symbol")],
        canonical=TRUE,
        stringsAsFactors=F
    )
    colnames(toImport) <- c("id", "symbol", "canonical")
    loadBESymbols(d=toImport, be="Peptide", dbname=pdbname)

    ################################################@
    ## Add names ----
    message(Sys.time(), " --> Importing Uniprot names")
    toImport <- uids[,c("ID", "name")]
    colnames(toImport) <- c("id", "name")
    toImport$name <- ifelse(
        toImport$name=="-",
        gene_info$description,
        toImport$name
    )
    loadBENames(d=toImport, be="Peptide", dbname=pdbname)

    ################################################@
    ## Add Uniprot cross references ----

    ## * Ensembl ----
    db <- "Ens_translation"
    message(Sys.time(), " --> ", db, " cross references")
    ## External DB IDs
    toImport <- unique(ensCref[, "ensembl", drop=F])
    colnames(toImport) <- "id"
    loadBE(
        d=toImport, be="Peptide",
        dbname=db,
        taxId=NA
    )
    ## The cross references
    toImport <- unique(ensCref[,c("ensembl", "ID")])
    colnames(toImport) <- c("id1", "id2")
    loadCorrespondsTo(
        d=toImport,
        db1=db,
        db2=pdbname,
        be="Peptide"
    )

    ## * RefSeq ----
    db <- "RefSeq_peptide"
    message(Sys.time(), " --> ", db, " cross references")
    ## External DB IDs
    toImport <- unique(rsCref[, "refseq", drop=F])
    colnames(toImport) <- "id"
    loadBE(
        d=toImport, be="Peptide",
        dbname=db,
        taxId=NA
    )
    ## The cross references
    toImport <- unique(rsCref[,c("refseq", "ID")])
    colnames(toImport) <- c("id1", "id2")
    loadCorrespondsTo(
        d=toImport,
        db1=db,
        db2=pdbname,
        be="Peptide"
    )

    ################################################@
    ## Depreacted IDs ----
    message(Sys.time(), " --> Importing Uniprot deprecated IDs")
    toImport <- unique(deprecated[, "deprecated", drop=F])
    colnames(toImport) <- "id"
    loadBE(
        d=toImport, be="Peptide",
        dbname=pdbname,
        version="deprecated",
        deprecated=as.Date("1-1-1"),
        taxId=NA,
        onlyId=TRUE
    )
    ##
    toImport <- deprecated
    colnames(toImport) <- c("new", "old")
    loadHistory(d=toImport, dbname=pdbname, be="Peptide")

    ################################################@
    ## Orphan Uniprot IDs ----
    message(Sys.time(), " --> Managing orphan Uniprot IDs")
    gdbname <- "BEDTech_gene"
    tdbname <- "BEDTech_transcript"
    orph <- bedCall(
        neo2R::cypher,
        query=neo2R::prepCql(c(
            sprintf(
                'MATCH (pid {database:"%s"})-[:identifies]->(p:Peptide)',
                pdbname
            ),
            'WHERE NOT (p)<-[:is_translated_in]-()',
            'RETURN DISTINCT pid.value as id'
        ))
    )$id
    orph <- intersect(orph, uids$ID)
    techTrans <- data.frame(
        tid=paste0("transcript.", orph),
        pid=orph,
        stringsAsFactors=FALSE
    )
    techGene <- data.frame(
        gid=paste0("gene.", orph),
        tid=techTrans$tid,
        stringsAsFactors=FALSE
    )
    ##
    toImport <- techGene[,"gid",drop=FALSE]
    colnames(toImport) <- "id"
    loadBE(
        d=toImport,
        be="Gene",
        dbname=gdbname,
        taxId=taxId
    )
    ##
    toImport <- techGene[,"tid",drop=FALSE]
    colnames(toImport) <- "id"
    loadBE(
        d=toImport,
        be="Transcript",
        dbname=tdbname
    )
    loadIsExpressedAs(d=techGene, gdb=gdbname, tdb=tdbname)
    ##
    loadIsTranslatedIn(d=techTrans, tdb=tdbname, pdb=pdbname)
}
