#' Feeding BED: Download NCBI gene DATA and load gene, transcript and peptide
#' information in BED
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param organism character vector of 1 element corresponding to the organism
#' of interest (e.g. "Homo sapiens")
#' @param reDumpThr time difference threshold between 2 downloads
#' @param ddir path to the directory where the data should be saved
#' @param curDate current date as given by [Sys.Date]
#'
getNcbiGeneTransPep <- function(
   organism,
   reDumpThr=100000,
   ddir,
   curDate
){

   ################################################@
   ## Organism ----
   taxId <- getTaxId(organism)

   ################################################@
   ## Dump ----
   dumpDate <- gene_info <- gene2ensembl <-
      # gene2unigene <- gene2vega <-
      gene_group <- gene_orthologs <-
      gene_history <- gene2refseq <-
      NULL
   dumpNcbiDb(
      taxOfInt=taxId,
      reDumpThr=reDumpThr,
      ddir=ddir,
      toLoad=c(
         "gene_info", "gene2ensembl",
         # "gene2unigene", "gene2vega",
         "gene_group", "gene_orthologs",
         "gene_history", "gene2refseq"
      ),
      curDate=curDate
   )

   ################################################@
   ## DB information ----
   gdbname <- "EntrezGene"
   tdbname <- "RefSeq"
   pdbname <- "RefSeq_peptide"
   ddate <- dumpDate
   release <- format(ddate, "%Y%m%d")

   ################################################@
   ## Genes ----
   gdbCref <- c(
      # "MIM"="MIM_GENE",
      "HGNC"="HGNC",
      "MGI"="MGI",
      "RGD"="RGD",
      "ZFIN"="ZFIN_gene",
      "Ensembl"="Ens_gene",
      "Vega"="Vega_gene"
   )
   gdbAss <- c(
      "miRBase"="miRBase",
      "MIM"="MIM_GENE"
   )

   ################################################@
   ## Add gene IDs ----
   message(Sys.time(), " --> Importing gene IDs")
   geneAss <- unique(gene2refseq[,c("GeneID", "assembly")])
   notPref <- unique(c(
      which(geneAss$assembly=="-"),
      grep("ALT_REF", geneAss$assembly),
      grep("Alternate", geneAss$assembly)
   ))
   if(length(notPref)>0){
      prefId <- unique(geneAss$GeneID[-notPref])
   }else{
      prefId <- unique(geneAss$GeneID)
   }
   toImport <- unique(gene_info[, "GeneID", drop=F])
   colnames(toImport) <- "id"
   toImport$preferred <- toImport$id %in% prefId
   loadBE(
      d=toImport, be="Gene",
      dbname=gdbname,
      version=release,
      taxId=taxId
   )
   message("      Importing attribute")
   toImport <- geneAss
   colnames(toImport) <- c("id", "value")
   loadBeAttribute(
      d=toImport, be="Gene",
      dbname=gdbname,
      attribute="assembly"
   )

   ################################################@
   ## Add gene symbols ----
   message(Sys.time(), " --> Importing gene symbols")
   gSymb <- data.frame(
      gene_info[,c("GeneID", "Symbol")],
      canonical=TRUE,
      stringsAsFactors=F
   )
   colnames(gSymb) <- c("id", "symbol", "canonical")
   gSyn <- strsplit(
      gene_info$Synonyms,
      split="[|]"
   )
   names(gSyn) <- gene_info$GeneID
   gSyn <- utils::stack(gSyn)
   gSyn$ind <- as.character(gSyn$ind)
   gSyn <- gSyn[,c("ind", "values")]
   gSyn$canonical <- rep("FALSE", nrow(gSyn))
   colnames(gSyn) <- c("id", "symbol", "canonical")
   gSyn <- gSyn[which(gSyn$symbol != "-"),]
   otherSyn <- gene_info[
      which(
         gene_info$Symbol_from_nomenclature_authority != "-" &
            gene_info$Symbol_from_nomenclature_authority != gene_info$Symbol
      ),
      c("GeneID", "Symbol_from_nomenclature_authority")
      ]
   otherSyn$canonical <- rep(FALSE, nrow(otherSyn))
   colnames(otherSyn) <- c("id", "symbol", "canonical")
   toImport <- rbind(gSymb, gSyn, otherSyn)
   loadBESymbols(d=toImport, be="Gene", dbname=gdbname)

   ################################################@
   ## Add gene names ----
   message(Sys.time(), " --> Importing gene names")
   namesToImport <- gene_info[
      ,
      c("GeneID", "Full_name_from_nomenclature_authority")
   ]
   colnames(namesToImport) <- c("id", "name")
   namesToImport$name <- ifelse(
      namesToImport$name=="-",
      gene_info$description,
      namesToImport$name
   )
   namesToImport$canonical <- TRUE

   namesToAdd <- gene_info[
      ,
      c("GeneID", "Other_designations")
   ]
   namesToAdd <- strsplit(
      gene_info$Other_designations,
      split="[|]"
   )
   names(namesToAdd) <- gene_info$GeneID
   namesToAdd <- utils::stack(namesToAdd)
   namesToAdd$ind <- as.character(namesToAdd$ind)
   namesToAdd <- namesToAdd[,c("ind", "values")]
   namesToAdd$canonical <- rep(FALSE, nrow(namesToAdd))
   colnames(namesToAdd) <- c("id", "name", "canonical")
   namesToAdd <- namesToAdd[which(namesToAdd$name != "-"),]
   namesToImport <- rbind(namesToImport, namesToAdd)

   namesToAdd <- gene_info[
      which(
         gene_info$description != "-" &
            gene_info$description !=
               gene_info$Full_name_from_nomenclature_authority
      ),
      c("GeneID", "description")
   ]
   namesToAdd$canonical <- rep(FALSE, nrow(namesToAdd))
   colnames(namesToAdd) <- c("id", "name", "canonical")
   namesToImport <- rbind(namesToImport, namesToAdd)

   toImport <- dplyr::select(
      dplyr::distinct(
         namesToImport, namesToImport$id, namesToImport$name,
         .keep_all = TRUE
      ),
      "id", "name", "canonical"
   )
   loadBENames(d=toImport, be="Gene", dbname=gdbname)

   ################################################@
   ## Add gene cross references ----
   ## Cross references from gene_info
   withXref <- gene_info[which(gene_info$dbXrefs!="-"),]
   xref <- strsplit(withXref$dbXrefs, split="[|]")
   names(xref) <- withXref$GeneID
   xref <- lapply(
      xref,
      function(x){
         toRet <- strsplit(x, split="[:]")
         xdb <- unlist(lapply(toRet, function(x)x[1]))
         toRet <- unlist(lapply(toRet, function(x)paste(x[-1], collapse=":")))
         toRet <- data.frame(
            db=xdb,
            ref=toRet,
            stringsAsFactors=F
         )
         return(toRet)
      }
   )
   dbs <- unique(unlist(lapply(xref, function(x)x$db)))
   xrefByDb <- lapply(
      dbs,
      function(db){
         toRet <- utils::stack(lapply(xref, function(x) x$ref[which(x$db==db)]))
         colnames(toRet) <- c("xref", "GeneID")
         toRet <- toRet[,c("GeneID", "xref")]
         return(toRet)
      }
   )
   names(xrefByDb) <- dbs
   dbCref <- gdbCref[intersect(names(gdbCref), names(xrefByDb))]
   for(ncbiDb in names(dbCref)){
      db <- dbCref[ncbiDb]
      message(Sys.time(), " --> ", ncbiDb)
      cref <- xrefByDb[[ncbiDb]][,c("xref", "GeneID")]
      if(nrow(cref)>0){
         ## External DB IDs
         toImport <- unique(cref[, "xref", drop=F])
         colnames(toImport) <- "id"
         toImport$id <- sub("HGNC[:]", "", sub("MGI[:]", "", toImport$id))
         loadBE(
            d=toImport, be="Gene",
            dbname=db,
            taxId=NA
         )
         ## The cross references
         toImport <- unique(cref)
         colnames(toImport) <- c("id1", "id2")
         toImport$id1 <- sub("HGNC[:]", "", sub("MGI[:]", "", toImport$id1))
         loadCorrespondsTo(
            d=toImport,
            db1=db,
            db2=gdbname,
            be="Gene"
         )
      }
   }
   ## Cross references from gene2ensembl file
   db <- "Ens_gene"
   message(Sys.time(), " --> ", db)
   cref <- dplyr::mutate_all(
      unique(gene2ensembl[,c("Ensembl_gene_identifier", "GeneID")]),
      as.character
   )
   colnames(cref) <- c("xref", "GeneID")
   cref <- cref[which(cref$xref != "-" & cref$GeneID != "-"),]
   if(nrow(cref)>0){
      ## External DB IDs
      toImport <- unique(cref[, "xref", drop=F])
      colnames(toImport) <- "id"
      loadBE(
         d=toImport, be="Gene",
         dbname=db,
         taxId=NA
      )
      ## The cross references
      toImport <- unique(cref)
      colnames(toImport) <- c("id1", "id2")
      loadCorrespondsTo(
         d=toImport,
         db1=db,
         db2=gdbname,
         be="Gene"
      )
   }

   # ## Cross references from gene2vega file
   # db <- "Vega_gene"
   # message(Sys.time(), " --> ", db)
   # cref <- unique(gene2vega[,c("Vega_gene_identifier", "GeneID")])
   # colnames(cref) <- c("xref", "GeneID")
   # cref <- cref[which(cref$xref != "-" & cref$GeneID != "-"),]
   # if(nrow(cref)>0){
   #    ## External DB IDs
   #    toImport <- unique(cref[, "xref", drop=F])
   #    colnames(toImport) <- "id"
   #    loadBE(
   #       d=toImport, be="Gene",
   #       dbname=db,
   #       taxId=NA
   #    )
   #    ## The cross references
   #    toImport <- unique(cref)
   #    colnames(toImport) <- c("id1", "id2")
   #    loadCorrespondsTo(
   #       d=toImport,
   #       db1=db,
   #       db2=gdbname,
   #       be="Gene"
   #    )
   # }
   #
   # ## Associations from gene2unigene file
   # db <- "UniGene"
   # message(Sys.time(), " --> ", db)
   # cref <- unique(gene2unigene[,c("UniGene_cluster", "GeneID")])
   # colnames(cref) <- c("xref", "GeneID")
   # cref <- cref[which(cref$xref != "-" & cref$GeneID != "-"),]
   # cref <- cref[which(cref$GeneID %in% gene_info$GeneID),]
   # if(nrow(cref)>0){
   #     ## External DB IDs
   #     toImport <- unique(cref[, "xref", drop=F])
   #     colnames(toImport) <- "id"
   #     loadBE(
   #         d=toImport, be="Gene",
   #         dbname=db,
   #         taxId=NA,
   #         onlyId=TRUE
   #     )
   #     ## The cross references
   #     toImport <- unique(cref)
   #     colnames(toImport) <- c("id1", "id2")
   #     loadIsAssociatedTo(
   #         d=toImport,
   #         db1=db,
   #         db2=gdbname,
   #         be="Gene"
   #     )
   # }

   ## Associations ----
   gdbAss <- gdbAss[intersect(names(gdbAss), names(xrefByDb))]
   for(ncbiDb in names(gdbAss)){
      db <- gdbAss[ncbiDb]
      message(Sys.time(), " --> ", ncbiDb)
      cref <- xrefByDb[[ncbiDb]][,c("xref", "GeneID")]
      if(nrow(cref)>0){
         ## External DB IDs
         toImport <- unique(cref[, "xref", drop=F])
         colnames(toImport) <- "id"
         toImport$id <- sub("HGNC[:]", "", sub("MGI[:]", "", toImport$id))
         loadBE(
            d=toImport, be="Gene",
            dbname=db,
            taxId=NA,
            onlyId=TRUE
         )
         ## The associations
         toImport <- unique(cref)
         colnames(toImport) <- c("id1", "id2")
         toImport$id1 <- sub("HGNC[:]", "", sub("MGI[:]", "", toImport$id1))
         loadIsAssociatedTo(
            d=toImport,
            db1=db,
            db2=gdbname,
            be="Gene"
         )
      }
   }

   ################################################@
   ## Gene history ----
   message(Sys.time(), " --> Importing gene history")
   beidToAdd <- gene_history[
      which(
         !gene_history$Discontinued_GeneID %in% gene_info$GeneID &
            gene_history$Discontinued_GeneID != "-"
      ),
      c("Discontinued_GeneID", "Discontinue_Date")
      ]
   beidToAdd$deprecated <- beidToAdd$Discontinue_Date
   colnames(beidToAdd) <- c("id", "version", "deprecated")
   beidToAdd <- unique(beidToAdd)
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
   loadBEVersion(
      beidToAdd, be="Gene",
      dbname=gdbname,
      taxId=NA,
      onlyId=TRUE
   )
   ##
   gvmap <- gene_history[
      which(
         gene_history$GeneID != "-" &
            gene_history$Discontinued_GeneID != "-" &
            gene_history$GeneID != gene_history$Discontinued_GeneID
      ),
      c("GeneID", "Discontinued_GeneID")
      ]
   toImport <- gvmap
   colnames(toImport) <- c("new", "old")
   loadHistory(d=toImport, dbname=gdbname, be="Gene")

   ################################################@
   ## Transcription events ----
   message(Sys.time(), " --> Importing transcript IDs")
   transcriptions <- unique(
      gene2refseq[,c(
         "GeneID", "RNA_nucleotide_accession.version",
         "assembly"
      )]
   )
   colnames(transcriptions) <- c("gid", "tid", "assembly")
   transcriptions <- transcriptions[which(transcriptions$tid != "-"),]
   transcriptions$tid <- sub("[.].*$", "", transcriptions$tid)
   notPref <- unique(c(
      which(transcriptions$assembly=="-"),
      grep("ALT_REF", transcriptions$assembly),
      grep("Alternate", transcriptions$assembly)
   ))
   if(length(notPref)>0){
      prefId <- unique(transcriptions$tid[-notPref])
   }else{
      prefId <- unique(transcriptions$tid)
   }
   ##
   toImport <- unique(transcriptions[, c("tid"), drop=F])
   colnames(toImport) <- "id"
   toImport$preferred <- toImport$id %in% prefId
   loadBE(
      d=toImport, be="Transcript",
      dbname=tdbname,
      version=release,
      taxId=NA
   )
   message("      Importing attribute")
   toImport <- unique(transcriptions[, c("tid", "assembly"), drop=F])
   colnames(toImport) <- c("id", "value")
   loadBeAttribute(
      d=toImport, be="Transcript",
      dbname=tdbname,
      attribute="assembly"
   )
   ##
   toImport <- unique(transcriptions[, c("gid", "tid")])
   loadIsExpressedAs(
      d=toImport,
      gdb=gdbname,
      tdb=tdbname
   )
   ## Cross references from gene2ensembl file
   db <- "Ens_transcript"
   message(Sys.time(), " --> ", db)
   cref <- unique(gene2ensembl[,c(
      "Ensembl_rna_identifier", "RNA_nucleotide_accession.version"
   )])
   colnames(cref) <- c("xref", "TranscriptID")
   cref <- cref[which(cref$xref != "-" & cref$TranscriptID != "-"),]
   cref$xref <- sub("[.].*$", "", cref$xref)
   cref$TranscriptID <- sub("[.].*$", "", cref$TranscriptID)
   if(nrow(cref)>0){
      ## External DB IDs
      toImport <- unique(cref[, "xref", drop=F])
      colnames(toImport) <- "id"
      loadBE(
         d=toImport, be="Transcript",
         dbname=db,
         taxId=NA
      )
      ## The cross references
      toImport <- unique(cref)
      colnames(toImport) <- c("id1", "id2")
      loadCorrespondsTo(
         d=toImport,
         db1=db,
         db2=tdbname,
         be="Transcript"
      )
   }

   # ## Cross references from gene2vega file
   # db <- "Vega_transcript"
   # message(Sys.time(), " --> ", db)
   # cref <- unique(gene2vega[,c(
   #    "Vega_rna_identifier", "RNA_nucleotide_accession.version"
   # )])
   # colnames(cref) <- c("xref", "TranscriptID")
   # cref <- cref[which(cref$xref != "-" & cref$TranscriptID != "-"),]
   # cref$TranscriptID <- sub("[.].*$", "", cref$TranscriptID)
   # if(nrow(cref)>0){
   #    ## External DB IDs
   #    toImport <- unique(cref[, "xref", drop=F])
   #    colnames(toImport) <- "id"
   #    loadBE(
   #       d=toImport, be="Transcript",
   #       dbname=db,
   #       taxId=NA
   #    )
   #    ## The cross references
   #    toImport <- unique(cref)
   #    colnames(toImport) <- c("id1", "id2")
   #    loadCorrespondsTo(
   #       d=toImport,
   #       db1=db,
   #       db2=tdbname,
   #       be="Transcript"
   #    )
   # }

   ################################################@
   ## Translation events ----
   message(Sys.time(), " --> Importing peptide IDs")
   translations <- unique(gene2refseq[,c(
      "RNA_nucleotide_accession.version",
      "protein_accession.version",
      "assembly"
   )])
   colnames(translations) <- c("tid", "pid", "assembly")
   translations <- translations[which(
      translations$tid != "-" & translations$pid != "-"
   ),]
   translations$tid <- sub("[.].*$", "", translations$tid)
   translations$pid <- sub("[.].*$", "", translations$pid)
   notPref <- unique(c(
      which(translations$assembly=="-"),
      grep("ALT_REF", translations$assembly),
      grep("Alternate", translations$assembly)
   ))
   if(length(notPref)>0){
      prefId <- unique(translations$pid[-notPref])
   }else{
      prefId <- unique(translations$pid)
   }
   ##
   toImport <- unique(translations[, c("pid"), drop=F])
   colnames(toImport) <- c("id")
   toImport$preferred <- toImport$id %in% prefId
   loadBE(
      d=toImport, be="Peptide",
      dbname=pdbname,
      version=release,
      taxId=NA
   )
   message("      Importing attribute")
   toImport <- unique(translations[, c("pid", "assembly"), drop=F])
   colnames(toImport) <- c("id", "value")
   loadBeAttribute(
      d=toImport, be="Peptide",
      dbname=pdbname,
      attribute="assembly"
   )
   ##
   toImport <- unique(translations[, c("tid", "pid")])
   loadIsTranslatedIn(
      d=toImport,
      tdb=tdbname,
      pdb=pdbname
   )
   ## Cross references from gene2ensembl file
   db <- "Ens_translation"
   message(Sys.time(), " --> ", db)
   cref <- unique(gene2ensembl[,c(
      "Ensembl_protein_identifier", "protein_accession.version"
   )])
   colnames(cref) <- c("xref", "PeptideID")
   cref <- cref[which(cref$xref != "-" & cref$PeptideID != "-"),]
   cref$xref <- sub("[.].*$", "", cref$xref)
   cref$PeptideID <- sub("[.].*$", "", cref$PeptideID)
   if(nrow(cref)>0){
      ## External DB IDs
      toImport <- unique(cref[, "xref", drop=F])
      colnames(toImport) <- "id"
      loadBE(
         d=toImport, be="Peptide",
         dbname=db,
         taxId=NA
      )
      ## The cross references
      toImport <- unique(cref)
      colnames(toImport) <- c("id1", "id2")
      loadCorrespondsTo(
         d=toImport,
         db1=db,
         db2=pdbname,
         be="Peptide"
      )
   }

   # ## Cross references from gene2vega file
   # db <- "Vega_translation"
   # message(Sys.time(), " --> ", db)
   # cref <- unique(gene2vega[,c(
   #    "Vega_protein_identifier", "protein_accession.version"
   # )])
   # colnames(cref) <- c("xref", "PeptideID")
   # cref <- cref[which(cref$xref != "-" & cref$PeptideID != "-"),]
   # cref$PeptideID <- sub("[.].*$", "", cref$PeptideID)
   # if(nrow(cref)>0){
   #    ## External DB IDs
   #    toImport <- unique(cref[, "xref", drop=F])
   #    colnames(toImport) <- "id"
   #    loadBE(
   #       d=toImport, be="Peptide",
   #       dbname=db,
   #       taxId=NA
   #    )
   #    ## The cross references
   #    toImport <- unique(cref)
   #    colnames(toImport) <- c("id1", "id2")
   #    loadCorrespondsTo(
   #       d=toImport,
   #       db1=db,
   #       db2=pdbname,
   #       be="Peptide"
   #    )
   # }

}
