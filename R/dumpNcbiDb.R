#' Feeding BED: Dump tables from the NCBI gene DATA
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param taxOfInt the organism to download (e.g. "9606").
#' @param reDumpThr time difference threshold between 2 downloads
#' @param ddir path to the directory where the data should be saved
#' @param toLoad the list of tables to load
#' @param env the R environment in which to load the tables when downloaded
#' @param curDate current date as given by [Sys.Date]
#'
dumpNcbiDb <- function(
    taxOfInt,
    reDumpThr,
    ddir,
    toLoad=c(
        "gene_info", "gene2ensembl",
        # "gene2unigene", "gene2vega",
        "gene_group", "gene_orthologs",
        "gene_history", "gene2refseq"
    ),
    env=parent.frame(n=1),
    curDate
){

    ftp <- "https://ftp.ncbi.nlm.nih.gov/gene/DATA/"

    dumpDir <- file.path(ddir, "NCBI-gene-DATA")
    if(file.exists(dumpDir)){
        load(file.path(dumpDir, "dumpDate.rda"))
        message("Last download: ", dumpDate)
        if(curDate - dumpDate > reDumpThr){
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
        dumpDate <- curDate
        save(dumpDate, file=file.path(dumpDir, "dumpDate.rda"))
        message("Data have been downloaded")
    }else{
        message("Existing data are going to be used")
    }

    loadTd <- function(td){
        message(td)
        f1 <- paste0(td, ".gz")
        f2 <- td
        f <- f1
        lf <- file.path(dumpDir, f)
        lf2 <- file.path(dumpDir, f2)
        df <- file.path(dumpDir, paste0(td, ".rda"))
        tdoi <- paste(td, paste(taxOfInt, collapse="_"), sep="-")
        dfoi <- file.path(dumpDir, paste0(tdoi, ".rda"))
        if(!file.exists(lf) & !file.exists(lf2)){
            message(Sys.time(), " --> Downloading...", f)
            dlok <- try(utils::download.file(
                url=paste0(ftp, f),
                destfile=lf,
                method="wget",
                quiet=T
            ), silent=T)
            if(dlok != 0){
                file.remove(lf)
                f <- f2
                lf <- file.path(dumpDir, f)
                message(Sys.time(), " --> Downloading...", f)
                dlok <- try(utils::download.file(
                    url=paste0(ftp, f),
                    destfile=lf,
                    method="wget",
                    quiet=T
                ), silent=T)
                if(dlok != 0){
                    file.remove(lf)
                    stop("Could not find files.")
                }
            }
        }else{
            if(!file.exists(lf)){
                f <- f2
                lf <- file.path(dumpDir, f)
            }
        }
        cn <- readLines(lf, n=1)
        # cn <- unlist(strsplit(cn, split=" "))
        # cn <- cn[-c(1, grep("^[(]", cn):length(cn))]
        cn <- sub("^#", "", cn)
        cn <- unlist(strsplit(cn, split="[ \t]"))
        if(!file.exists(df)){
            tmp <- utils::read.table(
                lf,
                sep="\t",
                header=F, skip=1,
                stringsAsFactors=F,
                quote="", comment.char=""
            )
            colnames(tmp) <- cn
            assign(x=td, value=tmp)
            save(list=td, file=df)
            if(!file.exists(dfoi) & "tax_id" %in% cn){
                tmp <- get(td)
                tmp <- tmp[which(tmp$tax_id %in% taxOfInt),]
                assign(x=td, value=tmp)
                save(list=td, file=dfoi)
            }
        }else{
            if(!file.exists(dfoi) & "tax_id" %in% cn){
                load(df)
                tmp <- get(td)
                tmp <- tmp[which(tmp$tax_id %in% taxOfInt),]
                assign(x=td, value=tmp)
                save(list=td, file=dfoi)
            }
        }
        if("tax_id" %in% cn){
            load(dfoi, envir=env)
        }else{
            load(df, envir=env)
        }
    }

    ########################################
    for(td in toLoad){
        loadTd(td=td)
    }
    load(file.path(dumpDir, "dumpDate.rda"), envir=env)

}
