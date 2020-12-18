#' Feeding BED: Download Ensembl DB and load gene information in BED
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
#' @param dbAss a named vector of characters providing associated DB of
#' interest. Unlike the DB in dbCref parameter, these DB are not used for
#' indirect ID associations: the IDs are only linked to Ensembl IDs.
#' @param canChromosomes canonical chromosmomes to be considered as preferred
#' ID (e.g. c(1:22, "X", "Y", "MT") for human)
#'
getEnsemblGeneIds <- function(
   organism,
   release,
   gv,
   ddir,
   dbCref,
   dbAss,
   canChromosomes
){

   dbname <- "Ens_gene"

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
      match(gene$seq_region_id, seq_region$"seq_region_id"),
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
   gene <- cbind(gene, toAdd)
   gene$"seq_region" <- sub(
      "^ ", "", paste(toAdd$genome, toAdd$system, toAdd$region)
   )
   gene$preferred <- gene$region %in% canChromosomes
   toImport <- unique(gene[, c("stable_id", "preferred"), drop=F])
   colnames(toImport) <- c("id", "preferred")
   loadBE(
      d=toImport, be="Gene",
      dbname=dbname,
      version=release,
      taxId=taxId
   )
   message("      Importing attribute")
   toImport <- unique(gene[, c("stable_id", "seq_region"), drop=F])
   colnames(toImport) <- c("id", "value")
   loadBeAttribute(
      d=toImport, be="Gene",
      dbname=dbname,
      attribute="seq_region"
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
            gene[,c("stable_id", "gene_id")],
            by=c("ensembl_id"="gene_id")
         )[, c("dbprimary_acc", "stable_id")]
         if(length(grep("Vega", ensDb))>0){
            cref <- cref[
               grep("^OTT", cref$dbprimary_acc),
               ]
         }
         if(nrow(cref) > 0){
            cref <- unique(cref)
            ## NCBI cross-references
            if(db=="EntrezGene"){
               cref <- cleanDubiousXRef(cref)
            }
            ## External DB IDs
            toImport <- unique(cref[, "dbprimary_acc", drop=F])
            colnames(toImport) <- "id"
            toImport$id <- sub("HGNC[:]", "", sub("MGI[:]", "", toImport$id))
            loadBE(
               d=toImport, be="Gene",
               dbname=db,
               taxId=NA
            )
            ## The cross references
            toImport <- cref
            colnames(toImport) <- c("id1", "id2")
            toImport$id1 <- sub("HGNC[:]", "", sub("MGI[:]", "", toImport$id1))
            loadCorrespondsTo(
               d=toImport,
               db1=db,
               db2=dbname,
               be="Gene"
            )
         }
      }
   }

   ################################################@
   ## Add associations ----
   for(ensDb in names(dbAss)){
      db <- dbAss[ensDb]
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
            gene[,c("stable_id", "gene_id")],
            by=c("ensembl_id"="gene_id")
         )[, c("dbprimary_acc", "stable_id")]
         if(length(grep("Vega", ensDb))>0){
            cref <- cref[
               grep("^OTT", cref$dbprimary_acc),
               ]
         }
         if(nrow(cref) > 0){
            ## External DB IDs
            toImport <- unique(cref[, "dbprimary_acc", drop=F])
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
               db2=dbname,
               be="Gene"
            )
         }
      }
   }

   ################################################@
   ## Add symbols ----
   message(Sys.time(), " --> Importing gene symbols")
   disp <- dplyr::inner_join(
      dplyr::mutate_all(
         gene[,c("stable_id", "display_xref_id")], as.character
      ),
      dplyr::mutate_all(
         xref[,c("xref_id", "display_label", "description")], as.character
      ),
      by=c("display_xref_id"="xref_id")
   )
   gSymb <- data.frame(
      disp[,c("stable_id", "display_label")],
      canonical=TRUE,
      stringsAsFactors=F
   )
   colnames(gSymb) <- c("id", "symbol", "canonical")
   gSyn <- dplyr::inner_join(
      gene,
      object_xref,
      by=c("gene_id"="ensembl_id")
   )[, c("stable_id", "xref_id")]
   gSyn <- dplyr::inner_join(
      gSyn,
      external_synonym,
      by="xref_id"
   )[, c("stable_id", "synonym")]
   gSyn <- unique(data.frame(
      gSyn,
      canonical=FALSE,
      stringsAsFactors=F
   ))
   colnames(gSyn) <- c("id", "symbol", "canonical")
   gSyn <- gSyn[which(
      !paste(gSyn$id, gSyn$symbol, sep=".") %in%
         paste(gSymb$id, gSymb$symbol, sep=".")
   ),]
   toImport <- unique(rbind(gSymb, gSyn))
   # toImport <- unique(toImport[,c("id", "symbol")])
   toImport <- unique(toImport[which(
      !toImport[,2] %in% c("", "\\N") & !is.na(toImport[,2])
   ),])
   loadBESymbols(d=toImport, be="Gene", dbname=dbname)

   ################################################@
   ## Add names ----
   message(Sys.time(), " --> Importing gene names")
   toImport <- disp[,c("stable_id", "description")]
   toImport <- unique(toImport[which(
      !toImport[,2] %in% c("", "\\N") & !is.na(toImport[,2])
   ),])
   colnames(toImport) <- c("id", "name")
   loadBENames(d=toImport, be="Gene", dbname=dbname)

   ################################################@
   ## History ----
   message(Sys.time(), " --> Importing gene history")
   beidToAdd <- stable_id_event[
      which(
         !stable_id_event$old_stable_id %in% gene$stable_id &
            stable_id_event$old_stable_id != "\\N" &
            stable_id_event$type=="gene"
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
         !stable_id_event$new_stable_id %in% gene$stable_id &
            stable_id_event$new_stable_id != "\\N" &
            stable_id_event$type=="gene"
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
                  subd[,"id", drop=F], be="Gene",
                  dbname=dbname,
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
   gvmap <- stable_id_event[
      which(
         stable_id_event$old_stable_id != "\\N" &
            stable_id_event$new_stable_id != "\\N" &
            stable_id_event$new_stable_id != stable_id_event$old_stable_id &
            stable_id_event$type == "gene"
      ),
      c("new_stable_id", "old_stable_id")
      ]
   ##
   gvmap <- gvmap[which(!gvmap$old_stable_id %in% gene$stable_id),]
   toTake <- which(gvmap$new_stable_id %in% gene$stable_id)
   if(length(toTake) > 0){
      toImport <- gvmap[toTake,]
      colnames(toImport) <- c("new", "old")
      loadHistory(d=toImport, dbname=dbname, be="Gene")
      gvmap <- gvmap[-toTake,]
   }
   for(v in sort(unique(beidToAdd$version), decreasing = TRUE)){
      gvmap <- gvmap[
         which(
            !gvmap$old_stable_id %in% beidToAdd$id[which(beidToAdd$version==v)]
         ),
         ]
      toTake <- which(
         gvmap$new_stable_id %in% beidToAdd$id[which(beidToAdd$version==v)]
      )
      if(length(toTake) > 0){
         toImport <- gvmap[toTake,]
         colnames(toImport) <- c("new", "old")
         loadHistory(d=toImport, dbname=dbname, be="Gene")
         gvmap <- gvmap[-toTake,]
      }
   }

}

