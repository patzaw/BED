#' Feeding BED: Download Ensembl DB and load transcript information in BED
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param organism character vector of 1 element corresponding to the organism
#' of interest (e.g. "Homo sapiens")
#' @param release the Ensembl release of interest (e.g. "83")
#' @param gv the genome version (e.g. "38")
#' @param ddir path to the directory where the data should be saved
#' @param dbCref a named vector of characters providing cross-reference DB of
#' interest. These DB are also used to find indirect ID associations.
#' @param canChromosomes canonical chromosmomes to be considered as preferred
#' ID (e.g. c(1:22, "X", "Y", "MT") for human)
#'
getEnsemblTranscriptIds <- function(
    organism,
    release,
    gv,
    ddir,
    dbCref,
    canChromosomes
){

    tdbname <- "Ens_transcript"
    gdbname <- "Ens_gene"

    ## Data files
    attrib_type <- gene_attrib <- transcript <-
       external_db <- gene <- translation <-
       external_synonym <- object_xref <- xref <-
       stable_id_event <- mapping_session <-
       seq_region <- coord_system <- NULL
    toDump <- c(
        "attrib_type", "gene_attrib", "transcript",
        "external_db", "gene", "translation",
        "external_synonym", "object_xref", "xref",
        "stable_id_event", "mapping_session",
        "seq_region", "coord_system"
    )
    dumpEnsCore(organism, release, gv, ddir, toDump)

    ################################################@
    ## Current Ensembl database and organism ----
    taxId <- getTaxId(organism)

    ################################################@
    ## Add stable IDs ----
    message(Sys.time(), " --> Importing internal IDs")
    toAdd <- seq_region[
       match(transcript$seq_region_id, seq_region$"seq_region_id"),
       c("name", "coord_system_id")
       ]
    toAdd <- cbind(
       toAdd,
       coord_system[
          match(toAdd$"coord_system_id", coord_system$"coord_system_id"),
          ]
    )
    toAdd <- toAdd[,c(1, 5, 6)]
    colnames(toAdd) <- c("region", "system", "genome")
    toAdd$genome <- ifelse(toAdd$genome=="\\N", "", toAdd$genome)
    transcript <- cbind(transcript, toAdd)
    transcript$"seq_region" <- sub(
       "^ ", "", paste(toAdd$genome, toAdd$system, toAdd$region)
    )
    transcript$preferred <- transcript$region %in% canChromosomes
    toImport <- unique(transcript[, c("stable_id", "preferred"), drop=F])
    colnames(toImport) <- c("id", "preferred")
    loadBE(
        d=toImport, be="Transcript",
        dbname=tdbname,
        version=release,
        taxId=NA
    )
    message("      Importing attribute")
    toImport <- unique(transcript[, c("stable_id", "seq_region"), drop=F])
    colnames(toImport) <- c("id", "value")
    loadBeAttribute(
       d=toImport, be="Transcript",
       dbname=tdbname,
       attribute="seq_region"
    )

    ################################################@
    ## Add expression events ----
    message(Sys.time(), " --> Importing expression events")
    canTrans <- dplyr::inner_join(
        gene[,c("stable_id", "canonical_transcript_id")],
        transcript[,c("transcript_id", "stable_id")],
        by=c("canonical_transcript_id"="transcript_id")
    )[,c("stable_id.x", "stable_id.y")]
    colnames(canTrans) <- c("gid", "tid")
    canTrans$canonical <- TRUE
    ##
    expTrans <- dplyr::inner_join(
        gene[,c("gene_id", "stable_id")],
        transcript[,c("transcript_id", "stable_id", "gene_id")],
        by=c("gene_id"="gene_id")
    )[,c("stable_id.x", "stable_id.y")]
    colnames(expTrans) <- c("gid", "tid")
    expTrans$canonical <- FALSE
    expTrans <- expTrans[which(
        !paste(expTrans$gid, expTrans$tid, sep=".") %in%
            paste(canTrans$gid, canTrans$tid, sep=".")
    ),]
    toImport <- unique(rbind(canTrans, expTrans))
    loadIsExpressedAs(
        d=toImport,
        gdb=gdbname,
        tdb=tdbname
    )

    ################################################@
    ## Add cross references ----
    for(ensDb in names(dbCref)){
        db <- dbCref[ensDb]
        message(Sys.time(), " --> ", ensDb)
        dbid <- external_db$external_db_id[which(external_db$db_name == ensDb)]
        takenXref <- xref[
            which(xref$external_db_id == dbid),
            c("xref_id", "dbprimary_acc")
        ]
        if(nrow(takenXref)>0){
            cref <- dplyr::inner_join(
                takenXref,
                object_xref[,c("ensembl_id", "xref_id")],
                by="xref_id"
            )
            cref <- dplyr::inner_join(
                cref,
                transcript[,c("stable_id", "transcript_id")],
                by=c("ensembl_id"="transcript_id")
            )[, c("dbprimary_acc", "stable_id")]
            if(length(grep("Vega", ensDb))>0){
                cref <- cref[
                    grep("^OTT", cref$dbprimary_acc),
                ]
            }
            if(nrow(cref) > 0){
                cref <- unique(cref)
                ## NCBI cross-references
                if(db=="RefSeq"){
                    cref <- cleanDubiousXRef(cref)
                }
                ## External DB IDs
                toImport <- unique(cref[, "dbprimary_acc", drop=F])
                colnames(toImport) <- "id"
                loadBE(
                    d=toImport, be="Transcript",
                    dbname=db,
                    taxId=NA
                )
                ## The cross references
                toImport <- cref
                colnames(toImport) <- c("id1", "id2")
                loadCorrespondsTo(
                    d=toImport,
                    db1=db,
                    db2=tdbname,
                    be="Transcript"
                )
            }
        }
    }

    ################################################@
    ## Add symbols ----
    message(Sys.time(), " --> Importing transcript symbols")
    disp <- dplyr::inner_join(
        dplyr::mutate_all(
            transcript[,c("stable_id", "display_xref_id")], as.character
        ),
        dplyr::mutate_all(
            xref[,c("xref_id", "display_label", "description")], as.character
        ),
        by=c("display_xref_id"="xref_id")
    )
    tSymb <- data.frame(
        disp[,c("stable_id", "display_label")],
        canonical=TRUE,
        stringsAsFactors=F
    )
    colnames(tSymb) <- c("id", "symbol", "canonical")
    toImport <- unique(tSymb)
    # toImport <- unique(toImport[,c("id", "symbol")])
    toImport <- unique(toImport[which(
        !toImport[,2] %in% c("", "\\N") & !is.na(toImport[,2])
    ),])
    loadBESymbols(d=toImport, be="Transcript", dbname=tdbname)

    ################################################@
    ## Add names ----
    message(Sys.time(), " --> Importing transcript names")
    toImport <- disp[,c("stable_id", "description")]
    toImport <- unique(toImport[which(
        !toImport[,2] %in% c("", "\\N") & !is.na(toImport[,2])
    ),])
    colnames(toImport) <- c("id", "name")
    loadBENames(d=toImport, be="Transcript", dbname=tdbname)

    ################################################@
    ## History ----
    message(Sys.time(), " --> Importing transcript history")
    beidToAdd <- stable_id_event[
        which(
            !stable_id_event$old_stable_id %in% transcript$stable_id &
                stable_id_event$old_stable_id != "\\N" &
                stable_id_event$type=="transcript"
        ),
        c("old_stable_id", "mapping_session_id")
        ]
    beidToAdd <- dplyr::inner_join(
        beidToAdd,
        mapping_session[, c("mapping_session_id", "old_release", "created")],
        by="mapping_session_id"
    )
    beidToAdd <- beidToAdd[,setdiff(colnames(beidToAdd), "mapping_session_id")]
    colnames(beidToAdd) <- c("id", "version", "deprecated")
    beidToAdd <- unique(beidToAdd)
    toAdd <- stable_id_event[
        which(
            !stable_id_event$new_stable_id %in% transcript$stable_id &
                stable_id_event$new_stable_id != "\\N" &
                stable_id_event$type=="transcript"
        ),
        c("new_stable_id", "mapping_session_id")
        ]
    toAdd <- dplyr::inner_join(
        toAdd,
        mapping_session[, c("mapping_session_id", "new_release")],
        by="mapping_session_id"
    )
    toAdd <- toAdd[,setdiff(colnames(toAdd), "mapping_session_id")]
    toAdd$deprecated <- "NA"
    colnames(toAdd) <- c("id", "version", "deprecated")
    toAdd <- unique(toAdd)
    beidToAdd <- rbind(beidToAdd, toAdd)
    beidToAdd <- beidToAdd[order(beidToAdd$deprecated),]
    versions <- sort(unique(beidToAdd$version), decreasing = T)
    v <- versions[1]
    tmp <- beidToAdd[which(beidToAdd$version==v),]
    tmp <- tmp[which(!duplicated(tmp$id)),]
    for(v in versions[-1]){
        toAdd <- beidToAdd[which(beidToAdd$version==v),]
        toAdd <- toAdd[which(!duplicated(toAdd$id)),]
        toAdd <- toAdd[which(!toAdd$id %in% tmp$id),]
        tmp <- rbind(tmp, toAdd)
    }
    beidToAdd <- tmp
    rm(tmp)
    toDel <- by(
        beidToAdd,
        beidToAdd$version,
        function(d){
            by(
                d,
                d$deprecated,
                function(subd){
                    version <- as.character(unique(subd$version))
                    deprecated <- unique(subd$deprecated)
                    if(deprecated=="NA"){
                        deprecated <- NA
                    }else{
                        deprecated <- as.Date(deprecated)
                    }
                    loadBE(
                        subd[,"id", drop=F], be="Transcript",
                        dbname=tdbname,
                        version=version,
                        deprecated=deprecated,
                        taxId=NA,
                        onlyId=TRUE
                    )
                }
            )
        }
    )
    rm(toDel)
    ##
    tvmap <- stable_id_event[
        which(
            stable_id_event$old_stable_id != "\\N" &
                stable_id_event$new_stable_id != "\\N" &
                stable_id_event$new_stable_id != stable_id_event$old_stable_id &
                stable_id_event$type == "transcript"
        ),
        c("new_stable_id", "old_stable_id")
    ]
    ##
    tvmap <- tvmap[which(!tvmap$old_stable_id %in% transcript$stable_id),]
    toTake <- which(tvmap$new_stable_id %in% transcript$stable_id)
    if(length(toTake) > 0){
       toImport <- tvmap[toTake,]
       colnames(toImport) <- c("new", "old")
       loadHistory(d=toImport, dbname=tdbname, be="Transcript")
       tvmap <- tvmap[-toTake,]
    }
    for(v in sort(unique(beidToAdd$version), decreasing = TRUE)){
       tvmap <- tvmap[
          which(
             !tvmap$old_stable_id %in% beidToAdd$id[which(beidToAdd$version==v)]
          ),
       ]
       toTake <- which(
          tvmap$new_stable_id %in% beidToAdd$id[which(beidToAdd$version==v)]
       )
       if(length(toTake) > 0){
          toImport <- tvmap[toTake,]
          colnames(toImport) <- c("new", "old")
          loadHistory(d=toImport, dbname=tdbname, be="Transcript")
          tvmap <- tvmap[-toTake,]
       }
    }

}

