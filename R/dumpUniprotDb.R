#' Feeding BED: Dump and preprocess flat data files from Uniprot
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param taxOfInt the organism of interest (e.g., "9606" for human,
#' "10090" for mouse or "10116" for rat)
#' @param divOfInt the taxonomic division to which the organism belong
#' (e.g., "human", "rodents", "mammals", "vertebrates")
#' @param release the release of interest (check if already downloaded)
#' @param ddir path to the directory where the data should be saved
#' @param ftp location of the ftp site
#' @param env the R environment in which to load the tables when built
#'
#' @useDynLib BED, .registration = TRUE
#'
dumpUniprotDb <- function(
    taxOfInt,
    divOfInt,
    release,
    ddir,
    ftp='ftp://ftp.expasy.org/databases/uniprot',
    env=parent.frame(n=1)
){

    ## Defining taxonomic division of interest ----
    # taxDiv <- c(
    #     "9606"="human",
    #     "10090"="rodents",
    #     "10116"="rodents",
    #     "9823"="mammals",
    #     "7955"="vertebrates"
    # )
    # taxOfInt <- match.arg(taxOfInt, names(taxDiv))
    # divOfInt <- taxDiv[taxOfInt]
    toDl <- c(
        sprintf("uniprot_sprot_%s.dat.gz", divOfInt),
        sprintf("uniprot_trembl_%s.dat.gz", divOfInt)
    )

    ## Download files if necessary ----
    ftp <- sprintf("%s/current_release/knowledgebase/taxonomic_divisions", ftp)
    dumpDir <- file.path(ddir, "Uniprot-DATA")
    if(file.exists(dumpDir)){
        load(file.path(dumpDir, "dumpRelease.rda"))
        message("Last release: ", dumpRelease)
        if(release != dumpRelease){
            toDownload <- TRUE
        }else{
            toDownload <- FALSE
        }
    }else{
        message("Not downloaded yet")
        toDownload <- TRUE
    }
    if(toDownload){
        if(file.exists(dumpDir)){
            dumpDirBck <- paste0(dumpDir,"-BCK")
            file.remove(list.files(path = dumpDirBck, full.names = T))
            file.remove(dumpDirBck)
            file.rename(dumpDir, dumpDirBck)
        }
        dir.create(dumpDir)
        dumpRelease <- release
        save(dumpRelease, file=file.path(dumpDir, "dumpRelease.rda"))
        message("Data have been downloaded")
    }else{
        message("Existing data are going to be used")
    }
    ##
    for(f in toDl){
        lf <- file.path(dumpDir, f)
        if(!file.exists(lf)){
            utils::download.file(
                url=file.path(ftp, f),
                destfile=lf,
                method="wget",
                quiet=T
            )
        }
    }

    ## Parse files if necessary ----
    parse_unigz <- function(f){
        con <- file(f, "r")
        by <- 50000000
        fuf <- character()
        tuids <- tdeprecated <- trsCref <- tensCref <-
           tsymbols <- tnames <-
           c()
        iteration <- 0
        while(TRUE){
            iteration <- iteration+1
            message(sprintf("Iteration %s", iteration))
            message(Sys.time())
            uf <- readLines(con, n=by)
            if(length(uf)==0){
                close(con)
                break()
            }
            uf <- c(fuf, uf)
            nextval <- tail(which(uf=="//"),1) + 1
            if(nextval <= length(uf)){
                fuf <- uf[nextval:length(uf)]
            }else{
                fuf <- character()
            }
            uf.val <- sub(
                "^[[:upper:]]{0,2} +",
                "",
                uf
            )
            uf.field <- sub(
                " +.*$",
                "",
                uf
            )
            tokeep <- sort(which(
                uf.field %in% c("ID", "AC", "DE", "GN", "OX", "DR") |
                    uf=="//"
            ))
            uf.val <- uf.val[tokeep]
            uf.field <- uf.field[tokeep]
            ends <- which(uf.val=="//")
            starts <- c(1, ends[-length(ends)]+1)
            spluf <- apply(
                data.frame(starts, ends-1),
                1,
                function(i){
                    return(data.frame(
                        field=uf.field[i[1]:i[2]],
                        val=uf.val[i[1]:i[2]],
                        stringsAsFactors=FALSE
                    ))
                }
            )
            ## * IDs and information ----
            ids <- unlist(lapply(
                spluf,
                function(x){
                    strsplit(
                        x[which(x$field=="AC"), "val"][1], split="; *"
                    )[[1]][1]
                }
            ))
            names(spluf) <- ids
            ##
            symbols <- unlist(
                lapply(spluf, function(x)x[which(x$field=="ID"), "val"])
            )
            status <-  sub("[;] +.*$", "", sub("^[[:alnum:]_]* +", "", symbols))
            symbols <- sub(" +.*$", "", symbols)
            canSymbols <- sub("_.*", "", symbols)
            symbols <- rbind(
               data.frame(
                  id = names(symbols),
                  symbol = as.character(canSymbols),
                  canonical = TRUE
               ),
               data.frame(
                  id = names(symbols),
                  symbol = as.character(symbols),
                  canonical = FALSE
               )
            )

            toAdd <- lapply(
               spluf,
               function(x){
                  value <- paste(
                     x$val[which(x$field=="GN")],
                     collapse = " "
                  )
                  if(is.na(value) || value == ""){
                     return(character())
                  }
                  toRet <- .extract_u_gn_r(value)
                  if(length(toRet)==0){
                     return(character())
                  }
                  return(toRet)
               }
            )
            toAdd <- dplyr::select(
               dplyr::mutate_all(
                  stack(toAdd),
                  as.character
               ),
               "id" = "ind", "symbol" = "values"
            )
            toAdd$canonical <- FALSE

            symbols <- rbind(symbols, toAdd)
            symbols <- dplyr::select(dplyr::distinct(
               symbols,
               symbols$id, symbols$symbol,
               .keep_all = TRUE
            ), "id", "symbol", "canonical")
            ##
            tax <- unlist(lapply(
                spluf,
                function(x){
                    ox <- unlist(
                        strsplit(x[which(x$field=="OX"), "val"], split="; *")
                    )
                    ox <- do.call(rbind, strsplit(ox, split="="))
                    ox[,2] <- sub(" +.*$", "", ox[,2])
                    return(ox[which(ox[,1]=="NCBI_TaxID"), 2])
                }
            ))
            if(length(tax)!=length(spluf)){
                stop("Incoherence in NCBI tax")
            }
            ##
            recNames <- lapply(
               spluf,
               function(x){
                  values <- x$val[which(x$field=="DE")]
                  toRet <- .extract_u_de_r(values)
                  return(toRet)
               }
            )
            canRecNames <- dplyr::select(
               dplyr::mutate_all(
                  stack(
                     lapply(recNames, function(x) x[1])
                  ),
                  as.character
               ),
               "id" = "ind", "name" = "values"
            )
            canRecNames$canonical = TRUE
            otherRecNames <- dplyr::select(
               dplyr::mutate_all(
                  stack(
                     lapply(recNames, function(x) x[-1])
                  ),
                  as.character
               ),
               "id" = "ind", "name" = "values"
            )
            otherRecNames$canonical = FALSE
            recNames <- rbind(canRecNames, otherRecNames)
            ##
            uids <- data.frame(
                ID=ids,
                symbol=canSymbols[ids],
                status=status[ids],
                name=canRecNames[
                   match(ids, canRecNames$id), "name", drop = TRUE
                ],
                tax=tax[ids],
                stringsAsFactors=FALSE
            )
            ## * Deprecated IDs ----
            deprecated <- stack(lapply(
                spluf,
                function(x){
                    unlist(
                        strsplit(x[which(x$field=="AC"), "val"], split="; *")
                    )[-1]
                }
            ))
            deprecated$ind <- as.character(deprecated$ind)
            colnames(deprecated) <- c("deprecated", "ID")
            deprecated <- deprecated[,c("ID", "deprecated")]
            ## * RefSeq peptides mapping ----
            rsCref <- stack(lapply(
                spluf,
                function(x){
                    rsLines <- grep(
                        "^RefSeq;", x$val[which(x$field=="DR")], value=TRUE
                    )
                    toRet <- sub("^RefSeq; *", "", rsLines)
                    toRet <- sub(";.*$", "", toRet)
                    toRet <- sub("[.].*$", "", toRet)
                    return(toRet)
                }
            ))
            rsCref$ind <- as.character(rsCref$ind)
            colnames(rsCref) <- c("refseq", "ID")
            rsCref <- rsCref[,c("ID", "refseq")]
            ## * Ensembl peptides mapping
            ensCref <- stack(lapply(
                spluf,
                function(x){
                    eLines <- grep(
                        "^Ensembl;", x$val[which(x$field=="DR")], value=TRUE
                    )
                    toRet <- strsplit(eLines, split="; ")
                    toRet <- unlist(lapply(toRet, function(l)l[3]))
                    toRet <- sub("[.].*$", "", toRet)
                    return(toRet)
                }
            ))
            ensCref$ind <- as.character(ensCref$ind)
            colnames(ensCref) <- c("ensembl", "ID")
            ensCref <- ensCref[,c("ID", "ensembl")]

            tuids <- rbind(tuids, uids)
            tdeprecated <- rbind(tdeprecated, deprecated)
            trsCref <- rbind(trsCref, rsCref)
            tensCref <- rbind(tensCref, ensCref)
            tsymbols <- rbind(tsymbols, symbols)
            tnames <- rbind(tnames, recNames)
        }
        return(list(
            uids=tuids,
            deprecated=tdeprecated,
            rsCref=trsCref,
            ensCref=tensCref,
            symbols = tsymbols,
            names = tnames
        ))
    }
    pf <- sprintf("uniprotIds-%s.rda", divOfInt)
    lpf <- file.path(dumpDir, pf)
    if(!file.exists(lpf)){
        ## * Reading and original parsing ----
        uids <- deprecated <- rsCref <- ensCref <- symbols <- names <- c()
        for(f in toDl){
            message(f)
            toAdd <- parse_unigz(file.path(dumpDir, f))
            uids <- rbind(uids, toAdd$uids)
            deprecated <- rbind(deprecated, toAdd$deprecated)
            rsCref <- rbind(rsCref, toAdd$rsCref)
            ensCref <- rbind(ensCref, toAdd$ensCref)
            symbols <- rbind(symbols, toAdd$symbols)
            names <- rbind(names, toAdd$names)
        }
        ## * Save parsed data ----
        save(
            list=c(
                "uids",
                "deprecated",
                "rsCref",
                "ensCref",
                "symbols",
                "names"
            ),
            file=lpf
        )
    }

    load(lpf, envir=env)
    load(file.path(dumpDir, "dumpRelease.rda"), envir=env)

}


.extract_u_de_r <- function(values) {
   if (!is.character(values)) stop("values must be a character vector")
   .Call("extract_u_de", values)
}

.extract_u_gn_r <- function(value){
   if (!is.character(value)) stop("value must be a character")
   .Call("extract_u_gn", value)
}
